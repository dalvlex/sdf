#!/bin/bash
set -e

COMMANDS_DIR="$HOME/.claude/commands"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing SDF (Supervised Decision Flow)..."

# Create directories
mkdir -p "$COMMANDS_DIR/sdf"

# Copy main orchestrator
cp "$SCRIPT_DIR/commands/sdf.md" "$COMMANDS_DIR/sdf.md"

# Copy subcommands
cp "$SCRIPT_DIR/commands/sdf/"*.md "$COMMANDS_DIR/sdf/"

echo ""
echo "SDF installed successfully."
echo ""
echo "Commands available:"
echo "  /sdf              Start a new flow or resume an existing one"
echo "  /sdf:help         Show all commands"
echo "  /sdf:status       Show flow status"
echo ""
echo "Run /sdf in any project to get started."
