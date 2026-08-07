{ pkgs, lib, ... }: {
  home.packages = [ pkgs.goose-cli ];

  home.shellAliases.goose = "GOOSE_TINFOIL_API_KEY=local GOOSE_DISABLE_KEYRING=true goose";

  # Default provider and model.
  home.file.".config/goose/config.yaml".text = ''
    GOOSE_PROVIDER: tinfoil
    GOOSE_MODEL: gemma4-31b
  '';

  # Tinfoil as a declarative custom provider.
  home.file.".config/goose/custom_providers/tinfoil.json".text = builtins.toJSON {
    name = "tinfoil";
    engine = "openai";
    display_name = "Tinfoil";
    description = "Privacy-preserving inference via Tinfoil secure enclaves";
    api_key_env = "GOOSE_TINFOIL_API_KEY";
    base_url = "http://127.0.0.1:3301";
    models = [
      {
        name = "gemma4-31b";
        context_limit = 256000;
      }
    ];
  };
}
