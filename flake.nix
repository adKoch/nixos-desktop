{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    firefox-addons,
  } @ inputs: {
    inherit (self) outputs;
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "betterttv"
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
            firefox-addons-allowUnfree = (import nixpkgs-unstable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            }).callPackage firefox-addons { };
          };
          home-manager.backupFileExtension = "backup";
        }
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
