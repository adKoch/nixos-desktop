#!/bin/sh

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create symlinks in /etc/nixos/
sudo ln -sf "$SCRIPT_DIR/configuration.nix" /etc/nixos/configuration.nix
sudo ln -sf "$SCRIPT_DIR/programs" /etc/nixos/programs
sudo ln -sf "$SCRIPT_DIR/bg.png" /etc/nixos/bg.png

nix flake update

sudo nix-channel --update

sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --flake . --impure

nix-collect-garbage --delete-older-than 2d
