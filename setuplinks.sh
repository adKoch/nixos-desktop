#!/bin/sh

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Setting up symlinks from /etc/nixos/ to $SCRIPT_DIR"

# Create symlinks in /etc/nixos/
sudo ln -sf "$SCRIPT_DIR/configuration.nix" /etc/nixos/configuration.nix
sudo ln -sf "$SCRIPT_DIR/programs" /etc/nixos/programs
sudo ln -sf "$SCRIPT_DIR/bg.png" /etc/nixos/bg.png

echo "Symlinks created successfully"