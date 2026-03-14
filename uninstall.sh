#!/bin/bash
set -e

COMMANDS_DIR="$HOME/.claude/commands"

echo "Uninstalling SDF (Supervised Decision Flow)..."

# Remove subcommands
if [ -d "$COMMANDS_DIR/sdf" ]; then
    rm -rf "$COMMANDS_DIR/sdf"
    echo "  Removed $COMMANDS_DIR/sdf/"
fi

# Remove main orchestrator
if [ -f "$COMMANDS_DIR/sdf.md" ]; then
    rm "$COMMANDS_DIR/sdf.md"
    echo "  Removed $COMMANDS_DIR/sdf.md"
fi

echo ""
echo "SDF uninstalled. Your .sdf/ project folders are untouched."
