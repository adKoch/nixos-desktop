{ config, ... }: {
  home.file.".gemini/antigravity/mcp_config.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/antigravity/mcp_config.json";

  home.file.".gemini/antigravity/skills".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/antigravity/skills";
}
