#!/bin/sh

nix --extra-experimental-features "nix-command flakes" profile upgrade --all

nix --extra-experimental-features "nix-command flakes" flake update

sudo nix-channel --update

export NIXPKGS_ALLOW_UNFREE=1

sudo bash -c 'NIXPKGS_ALLOW_UNFREE=1 ulimit -n 1048576;  nixos-rebuild switch --flake .#desktop'

sudo nix-collect-garbage --delete-older-than 7d

