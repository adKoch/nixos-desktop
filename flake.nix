{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Repackages the official Windows build; no Linux build is published upstream.
    # Deliberately not following our nixpkgs -- upstream pins a tested electron.
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    firefox-addons,
    sops-nix,
    claude-desktop,
  } @ inputs: {
    inherit (self) outputs;
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "betterttv"
              "jules"
              "lmstudio"
              "opencode"
            ];
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.adam = import ./home.nix;
          home-manager.extraSpecialArgs = {
            inherit inputs;
            pkgs-unstable = import nixpkgs-unstable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
            firefox-addons-allowUnfree = (import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
              overlays = [ firefox-addons.overlays.default ];
            }).firefox-addons;
          };
          home-manager.backupFileExtension = "backup";
        }
      ];
      specialArgs = {
        inherit inputs;
        pkgs-unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              mistral-vibe = prev.mistral-vibe.overridePythonAttrs (old: {
                doCheck = false;
              });
            })
          ];
        };
      };
    };
  };
}
