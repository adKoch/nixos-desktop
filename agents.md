# AI Agents

This repository includes configuration for several AI coding agents and model
providers as part of the NixOS desktop setup. Agents are configured as
home-manager modules under `programs/` and start automatically on login where
applicable.

Packages fetched from outside the official NixOS repository are listed in
[versions.txt](versions.txt) with their source URLs. Before rebuilding after
introducing changes that require a new package version, check that file and
consider whether a version bump is warranted.
