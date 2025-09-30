{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  #nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  # "steam"
  # "steam-original"
  # "steam-unwrapped"
  #  "steam-run"
  #];
  #programs.steam = {
  #  enable = true;
  #remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  #  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  #  localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  #};
  programs.firefox = {
    enable = true;
    #profiles.default = {
    #  extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
    #    bitwarden
    #    ublock-origin
    #   betterttv
    #   darkreader
    # ];

    # settings = {
    #   "browser.startup.homepage" = "https://nixos.org";
    #   "privacy.resistFingerprinting" = true;
    #};
    #};
  };
}
