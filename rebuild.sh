#!/bin/sh

nix flake update

sudo nix-channel --update

sudo nixos-rebuild switch --flake .
