{ config, ... }: {
  home.file.".codex/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/codex/config.toml";

  home.file.".codex/skills".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/codex/skills";
}
