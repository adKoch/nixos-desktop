#!/bin/sh

nix profile upgrade --all

nix flake update

sudo nix-channel --update

export NIXPKGS_ALLOW_UNFREE=1

sudo bash -c 'NIXPKGS_ALLOW_UNFREE=1 ulimit -n 1048576;  nixos-rebuild switch --flake .'

sudo nix-collect-garbage --delete-older-than 7d

