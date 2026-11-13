#!/bin/sh

nix profile upgrade --all

nix flake update

sudo nix-channel --update

# Bump the packages pinned in versions.txt, which live outside nixpkgs and so
# are untouched by the flake update above. Runs after it, so each bump is
# build-checked against the same inputs the rebuild will use. A package that
# fails to build is reverted and the run carries on; major versions are held
# back and listed at the end. Pass --include-major to take those too.
./update-versions.sh "$@"

./rebuild.sh
