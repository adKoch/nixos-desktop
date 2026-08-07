#!/bin/sh

export NIXPKGS_ALLOW_UNFREE=1

sudo bash -c 'NIXPKGS_ALLOW_UNFREE=1 ulimit -n 1048576;  nixos-rebuild switch --flake .'

# Garbage collection is handled automatically by nix.gc (weekly, --delete-older-than 7d)


