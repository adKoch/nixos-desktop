{
  config,
  pkgs,
  ...
}: {
  home.file.".vibe/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/mistral/vibe-config.toml";
}
