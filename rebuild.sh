#!/bin/sh

nix flake update

sudo nix-channel --update

sudo bash -c 'ulimit -n 1048576; NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --flake . --impure --max-jobs 3 --cores 3 --option sandbox false'

#nix-collect-garbage --delete-older-than 2d
