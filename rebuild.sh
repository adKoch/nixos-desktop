#!/bin/sh

nix profile upgrade --all

nix flake update

sudo nix-channel --update

export NIXPKGS_ALLOW_UNFREE=1

sudo bash -c 'NIXPKGS_ALLOW_UNFREE=1 ulimit -n 1048576;  nixos-rebuild switch --flake .'

sudo nix-collect-garbage --delete-older-than 7d

# Install/upgrade Python CLI tools via pipx
pipx upgrade virtual-context 2>/dev/null || pipx install virtual-context

# Pull/upgrade Ollama models (only on machines with Ollama installed)
command -v ollama >/dev/null 2>&1 && ollama pull qwen3:4b
