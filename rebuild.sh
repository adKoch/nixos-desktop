#!/bin/sh

nix --extra-experimental-features "nix-command flakes" profile upgrade --all

nix --extra-experimental-features "nix-command flakes" flake update

sudo nix-channel --update

export NIXPKGS_ALLOW_UNFREE=1

sudo bash -c 'NIXPKGS_ALLOW_UNFREE=1 ulimit -n 1048576;  nixos-rebuild switch --flake .#desktop'

sudo nix-collect-garbage --delete-older-than 7d

# Install/upgrade Python CLI tools via pipx
pipx upgrade virtual-context 2>/dev/null || pipx install virtual-context

# Pull/upgrade Ollama models (only on machines with Ollama installed)
command -v ollama >/dev/null 2>&1 && ollama pull nomic-embed-text:v1.5
