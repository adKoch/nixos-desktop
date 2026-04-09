# Using buildNpmPackage

If an npm package contains a `package-lock.json` or `npm-shrinkwrap.json`, it can be built from source using `buildNpmPackage`.

## Pattern

```nix
{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "<pkg-name>";
  version = "<version>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "v${version}";
    hash = "sha256-<src-hash>";
  };

  npmDepsHash = "sha256-<deps-hash>";

  # The package name in package.json (e.g., @scope/name)
  # npmPackFlags = [ "--ignore-scripts" ];

  meta = with lib; {
    description = "<description>";
    homepage = "<homepage>";
    license = licenses.unfree;
  };
}
```

## How to get npmDepsHash
1. Set `npmDepsHash = lib.fakeHash;`
2. Try to build the derivation.
3. Nix will fail and provide the actual hash in the error message.
4. Replace `lib.fakeHash` with the provided hash.
