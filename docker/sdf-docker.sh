#!/usr/bin/env bash
set -euo pipefail

# Optional argument: "bash" to drop into shell instead of Claude Code
CONTAINER_CMD=(claude --dangerously-skip-permissions)
if [ "${1:-}" = "bash" ]; then
    CONTAINER_CMD=(bash)
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR"
PROJECT_DIR="$(pwd)"
IMAGE_NAME="sdf-claude"
PROJECT_NAME="$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
if command -v md5sum &>/dev/null; then
    PATH_HASH="$(echo -n "$PROJECT_DIR" | md5sum | head -c 6)"
else
    PATH_HASH="$(echo -n "$PROJECT_DIR" | md5 -q | head -c 6)"
fi
CONTAINER_NAME="sdf-${PROJECT_NAME}-${PATH_HASH}"
CLAUDE_HOME="$HOME/.claude"

# --- Preflight checks ---

if ! command -v docker &>/dev/null; then
    echo "Error: Docker is not installed or not in PATH."
    exit 1
fi

if ! docker info &>/dev/null 2>&1; then
    echo "Error: Docker daemon is not running."
    exit 1
fi

# --- Resolve authentication ---
# Priority: ANTHROPIC_API_KEY > CLAUDE_CODE_OAUTH_TOKEN > macOS Keychain extraction
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "Auth: using ANTHROPIC_API_KEY (API billing)."
elif [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    echo "Auth: using CLAUDE_CODE_OAUTH_TOKEN (subscription)."
else
    # Try to extract OAuth token from macOS Keychain
    if command -v security &>/dev/null; then
        CRED_JSON="$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)"
        if [ -n "$CRED_JSON" ]; then
            # CLAUDE_CODE_OAUTH_TOKEN expects just the access token string
            OAUTH_TOKEN="$(echo "$CRED_JSON" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null || true)"
            if [ -n "$OAUTH_TOKEN" ] && [ "$OAUTH_TOKEN" != "null" ]; then
                export CLAUDE_CODE_OAUTH_TOKEN="$OAUTH_TOKEN"
                echo "Auth: extracted OAuth token from macOS Keychain (subscription)."
            else
                echo "Warning: Found Keychain entry but unexpected format. You may need to /login inside the container."
            fi
        else
            echo "Warning: No Claude Code credentials in macOS Keychain. Set ANTHROPIC_API_KEY or /login inside the container."
        fi
    else
        echo "Warning: No auth configured. Set ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN."
    fi
fi

if [ ! -d "$CLAUDE_HOME" ]; then
    echo "Error: ~/.claude/ not found. Run Claude Code at least once first."
    exit 1
fi

# --- Prepare packages.txt ---

# Use project-specific packages.txt if it exists, otherwise empty
PACKAGES_FILE="$DOCKER_DIR/packages.txt"
if [ -f "$PROJECT_DIR/.sdf/packages.txt" ]; then
    cp "$PROJECT_DIR/.sdf/packages.txt" "$PACKAGES_FILE"
    echo "Found .sdf/packages.txt -- extra packages will be installed."
else
    : > "$PACKAGES_FILE"
fi

# --- Build image ---

echo "Building SDF Docker image..."
docker build -t "$IMAGE_NAME" "$DOCKER_DIR"

# Clean up temporary packages.txt
: > "$PACKAGES_FILE"

# --- Collect mounts ---

MOUNTS=()

# Helper: mount with existence check and status message
mount_if_exists_dir() {
    local src="$1" dst="$2" mode="${3:-ro}" label="$4"
    if [ -d "$src" ]; then
        MOUNTS+=(-v "$src:$dst:$mode")
        echo "  [mounted]     $label ($mode)"
    else
        echo "  [not found]   $label -- $src"
    fi
}

mount_if_exists_file() {
    local src="$1" dst="$2" mode="${3:-ro}" label="$4"
    if [ -f "$src" ]; then
        MOUNTS+=(-v "$src:$dst:$mode")
        echo "  [mounted]     $label ($mode)"
    else
        echo "  [not found]   $label -- $src"
    fi
}

echo ""
echo "Mounts:"

# Entire ~/.claude/ directory (read-write base)
mount_if_exists_dir "$CLAUDE_HOME" "/home/node/.claude" "rw" "~/.claude/ (base)"

# Protected paths (read-only overlays on top of the rw base)
mount_if_exists_dir "$CLAUDE_HOME/commands" "/home/node/.claude/commands" "ro" "~/.claude/commands/ (protected)"
mount_if_exists_dir "$CLAUDE_HOME/skills" "/home/node/.claude/skills" "ro" "~/.claude/skills/ (protected)"
mount_if_exists_file "$CLAUDE_HOME/CLAUDE.md" "/home/node/.claude/CLAUDE.md" "ro" "~/.claude/CLAUDE.md (protected)"
mount_if_exists_file "$CLAUDE_HOME/settings.json" "/home/node/.claude/settings.json" "ro" "~/.claude/settings.json (protected)"

# Claude Code runtime config
mount_if_exists_file "$HOME/.claude.json" "/home/node/.claude.json" "rw" "~/.claude.json"

# SSH keys and config
mount_if_exists_dir "$HOME/.ssh" "/home/node/.ssh" "ro" "~/.ssh/"

# Git config
mount_if_exists_file "$HOME/.gitconfig" "/home/node/.gitconfig" "ro" "~/.gitconfig"
mount_if_exists_file "$HOME/.gitignore_global" "$HOME/.gitignore_global" "ro" "~/.gitignore_global"
mount_if_exists_dir "$HOME/.config/git" "/home/node/.config/git" "ro" "~/.config/git/"

# npm config
mount_if_exists_file "$HOME/.npmrc" "/home/node/.npmrc" "ro" "~/.npmrc"

# --- Clean up stale container ---

docker rm -f "$CONTAINER_NAME" &>/dev/null || true

echo ""
echo "Starting SDF container for: $PROJECT_DIR"
echo "  Project: $PROJECT_DIR (read-write, same path as host)"
echo "  Claude: ~/.claude (read-write, commands/skills/settings protected read-only)"
echo "  SSH keys, git config (read-only)"
echo ""
# To drop into bash instead: change CMD below to just "$IMAGE_NAME"
# and uncomment these lines:
#   echo "Inside the container, run:"
#   echo "  claude --dangerously-skip-permissions  (or: claude-sudo)"
echo ""

ENV_ARGS=(-e DISABLE_AUTOUPDATER=1)
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    ENV_ARGS+=(-e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY")
elif [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    ENV_ARGS+=(-e CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN")
fi

# --- Start sound relay (plays Docker sound requests on host macOS) ---

SOUND_PID=""
SOUND_RELAY_DIR=""
if command -v afplay &>/dev/null; then
    SOUND_RELAY_DIR=$(mktemp -d)
    MOUNTS+=(-v "$SOUND_RELAY_DIR:/tmp/sound-relay")
    (while true; do
        for f in "$SOUND_RELAY_DIR"/play-*; do
            [ -f "$f" ] || continue
            SOUND_FILE=$(cat "$f")
            rm -f "$f"
            [ -n "$SOUND_FILE" ] && afplay "$SOUND_FILE" 2>/dev/null &
        done
        sleep 0.2
    done) &
    SOUND_PID=$!
    echo "Sound relay started (shared dir)"
fi

cleanup() {
    [ -n "$SOUND_PID" ] && kill "$SOUND_PID" 2>/dev/null && wait "$SOUND_PID" 2>/dev/null
    [ -n "$SOUND_RELAY_DIR" ] && rm -rf "$SOUND_RELAY_DIR"
    echo ""
    echo "SDF container stopped. Cleanup complete."
}
trap cleanup EXIT

# --- Run container ---

docker run -it --rm \
    --name "$CONTAINER_NAME" \
    "${ENV_ARGS[@]}" \
    -v "$PROJECT_DIR:$PROJECT_DIR" \
    -w "$PROJECT_DIR" \
    "${MOUNTS[@]}" \
    --add-host=host.docker.internal:host-gateway \
    "$IMAGE_NAME" \
    "${CONTAINER_CMD[@]}"
