{
  pkgs,
  lib,
  ...
}: let
  # Caddyfile: listens on 3301, injects the API key from env, forwards to
  # the tinfoil attestation proxy on 3300. Local callers need no credentials.
  caddyfile = pkgs.writeText "tinfoil-caddyfile" ''
    {
      admin off
      auto_https off
    }
    http://127.0.0.1:3301 {
      reverse_proxy 127.0.0.1:3300 {
        header_up Authorization "Bearer {env.TINFOIL_API_KEY}"
      }
    }
  '';

  # Reads the key from sops at start time so it never lands in a config file.
  startAuthProxy = pkgs.writeShellScript "start-tinfoil-auth-proxy" ''
    export TINFOIL_API_KEY=$(cat /run/secrets/TINFOIL_API_KEY)
    exec ${pkgs.caddy}/bin/caddy run --config ${caddyfile} --adapter caddyfile
  '';

  # opencode.json: no real key — auth is handled by the Caddy layer.
  generateOpencodeConfig = pkgs.writeShellScript "generate-opencode-config" ''
    set -euo pipefail
    mkdir -p "$HOME/.config/opencode"
    ${pkgs.jq}/bin/jq -n '{
      "$schema": "https://opencode.ai/config.json",
      provider: {
        tinfoil: {
          npm: "@ai-sdk/openai-compatible",
          name: "Tinfoil",
          options: {
            baseURL: "http://127.0.0.1:3301/v1",
            apiKey: "local"
          },
          models: {
            "gemma4-31b": {
              name: "Gemma 4 31B",
              limit: {context: 256000, output: 32768}
            }
          }
        }
      }
    }' > "$HOME/.config/opencode/opencode.json"
    chmod 600 "$HOME/.config/opencode/opencode.json"
  '';
in {
  # Internal tinfoil attestation proxy on port 3300.
  systemd.user.services.tinfoil-proxy = {
    Unit = {
      Description = "Tinfoil attestation proxy (internal)";
      After = ["network.target"];
    };
    Service = {
      ExecStart = "${pkgs.tinfoil-cli}/bin/tinfoil proxy -p 3300 -e inference.tinfoil.sh -r tinfoilsh/confidential-model-router";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Auth-injecting proxy on port 3301 — local requests need no credentials.
  systemd.user.services.tinfoil-auth-proxy = {
    Unit = {
      Description = "Tinfoil auth-injecting proxy";
      After = ["tinfoil-proxy.service"];
      Requires = ["tinfoil-proxy.service"];
    };
    Service = {
      ExecStart = "${startAuthProxy}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  home.activation.opencode-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${generateOpencodeConfig}
  '';
}
