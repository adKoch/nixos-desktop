#!/bin/sh

nix profile upgrade --all

nix flake update

sudo nix-channel --update

./rebuild.sh
