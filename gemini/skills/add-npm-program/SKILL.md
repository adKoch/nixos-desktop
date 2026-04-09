---
name: add-npm-program
description: Add a new program from the NPM registry to the NixOS configuration. Use when asked to install or add a tool that is distributed via npm.
---

# Add NPM Program Skill

This skill guides you through adding an NPM package to the current NixOS configuration. It handles both packages available in `nixpkgs` and those that require a custom derivation.

## Workflow

### 1. Research the Package
- Determine the latest version: `nix-shell -p nodejs --run "npm view <pkg> version"`
- Check if it's already in `nixpkgs`: `nix search github:nixos/nixpkgs/nixos-unstable <pkg>`
- Investigate the package structure: `nix-shell -p nodejs --run "npm view <pkg> dist.tarball"` then `tar -tf` or `tar -xOf ... package/package.json`.
- Determine if it's a JS/TS package with a lockfile or a wrapper for a binary.

### 2. Strategy Selection
- **Case A: Package is in `nixpkgs`**
  - Just add it to `home.packages` in `home.nix`.
  - Create a companion `programs/<pkg>.nix` if it needs configuration (symlinks, aliases).
- **Case B: Package is NOT in `nixpkgs`**
  - Create a custom derivation in `programs/<pkg>.nix`.
  - Use `buildNpmPackage` if it has a lockfile.
  - Use `stdenv.mkDerivation` if it's a binary wrapper (like Jules).

### 3. Implementation

#### Custom Derivation Pattern (Binary Wrapper)
```nix
{ pkgs, ... }: {
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "<pkg-name>";
      version = "<version>";
      src = pkgs.fetchurl {
        url = "<binary-url>";
        hash = "sha256-<hash>";
      };
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      sourceRoot = ".";
      installPhase = ''
        install -m755 -D <binary-name> $out/bin/<pkg-name>
      '';
      meta = with pkgs.lib; {
        description = "<description>";
        homepage = "<homepage>";
        license = licenses.unfree;
        platforms = platforms.linux;
      };
    })
  ];
}
```

#### Integration
1. Add `git add programs/<pkg>.nix` (Flakes need the file tracked).
2. Add `./programs/<pkg>.nix` to `imports` in `home.nix`.
3. If unfree, add it to `nixpkgs.config.allowUnfreePredicate` in `flake.nix`.

### 4. Verification
- Run `./rebuild.sh` to apply changes.
- Test the command: `<pkg-name> --version` or `<pkg-name> help`.

## Key Commands for Hashes
- Prefetch: `nix-prefetch-url <url>`
- Prefetch with unpack: `nix-prefetch-url --unpack <url>`
- Convert hash to SRI: `nix hash convert --to sri --type sha256 <hash>`
