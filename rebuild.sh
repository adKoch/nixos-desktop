#!/bin/sh

nix flake update

sudo nix-channel --update

sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --flake . --impure

nix-collect-garbage --delete-older-than 2d
