{ config, ... }: {
  home.file.".gemini/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/gemini/settings.json";

  home.file.".gemini/skills".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/gemini/skills";
}
