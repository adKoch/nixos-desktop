{ inputs, pkgs, ... }: {
  imports = [ inputs.hermes-agent.homeManagerModules.default ];

  # The CLI and the Electron app. `programs.` alone only puts binaries on
  # PATH -- it deliberately manages no configuration.
  programs.hermes-agent = {
    enable = true;
    desktop.enable = true;
  };

  # `services.` is what owns ~/.hermes/config.yaml declaratively. It starts
  # nothing on its own: the messaging gateway is off, and backend.mode
  # defaults to "none", so there is no daemon and no linger requirement.
  # Enabling gateway later would need per-platform tokens in sops.
  services.hermes-agent = {
    enable = true;
    gateway.enable = false;

    # GLM 5.3 Flash over gemma4-31b: 320B MoE with only 18B active, so it runs
    # at small-model speed, and it is tuned for agentic tool-calling, which is
    # most of what Hermes does. Both are served by the same tinfoil proxy.
    settings.model = {
      provider = "openai-api";
      default = "glm-5-3-flash";
      base_url = "http://127.0.0.1:3301/v1";
    };

    # Speech-to-text, entirely on this machine. "voice" pulls faster-whisper,
    # sounddevice and numpy into hermes own sealed venv -- uv resolves them
    # alongside the pinned core deps, so there is no version skew and no
    # PYTHONPATH patching. No audio leaves the machine.
    #
    # The "wake" group ("Hey Hermes" hotword) is deliberately absent: its
    # openwakeword dep needs tflite-runtime 2.14.0, for which uv finds no
    # compatible wheel or sdist, and the evaluation fails outright.
    # "mcp" carries mcp==2.0.0 + httpx2 + starlette -- the MCP SDK on its own.
    # Without it MCP support is silently disabled, with no error anywhere.
    # Note it is NOT reachable via "dev": that group also drags pytest, ruff,
    # debugpy and setuptools into the venv for no benefit here.
    extraDependencyGroups = [ "voice" "mcp" ];

    # The module runtime path is only bash/coreutils/git. Hermes own installer
    # provides ffmpeg, and voice-memo decoding expects it, so add it here.
    extraPackages = [ pkgs.ffmpeg ];

    settings.stt.provider = "local";

    # Hermes writes this key itself, and the module merges rather than
    # replaces, so an app-written `true` survives every rebuild. The "wake"
    # group is not installed (see above), and a CLI-only install would try to
    # lazy-install openwakeword at first use -- into a read-only Nix venv.
    # Stating it here keeps the config honest about what is actually present.
    settings.wake_word.enabled = false;

    # To transcribe on tinfoil instead (whisper-large-v3-turbo in an attested
    # enclave -- better model, but the audio leaves this machine), swap the
    # line above for these three and drop "voice" from the groups:
    #   settings.stt.provider = "openai";
    #   environment.STT_OPENAI_BASE_URL = "http://127.0.0.1:3301/v1";
    #   environment.STT_OPENAI_MODEL = "whisper-large-v3-turbo";

    # plogger over native StreamableHTTP with OAuth 2.1 PKCE -- no npx, no
    # mcp-remote shim, no static client JSON, and no client secret (PKCE is a
    # public-client flow). Tokens land in $HERMES_HOME/mcp-tokens/.
    #
    # Raw settings rather than the typed `mcpServers` option: that option has
    # no `oauth` sub-key and no freeform passthrough, and both keys below are
    # required here. Authelia supports neither RFC 7591 DCR nor CIMD, so the
    # client_id must be stated; and redirect_port must be pinned because the
    # SDK otherwise takes a fresh ephemeral port, which cannot be registered
    # as a fixed redirect_uri. Both match the `plogger-hermes` client in
    # personal-server (roles/authelia/templates/configuration.yml.j2).
    #
    # connect_timeout is raised because the first connection opens a browser
    # for the Authelia consent screen and the 60s default expires mid-login.
    settings.mcp_servers.plogger = {
      url = "https://plogger.adkoch.com/mcp";
      auth = "oauth";
      connect_timeout = 120;
      oauth = {
        client_id = "plogger-hermes";
        redirect_port = 3335;
        scope = "openid profile email address phone offline_access groups";
      };
    };

    # Not a secret: the Caddy layer on 3301 swaps this placeholder for the
    # real key out of sops, exactly as opencode does. See programs/tinfoil.nix.
    environment.OPENAI_API_KEY = "local";
  };

  # The desktop file shipped inside the hermes-desktop package declares
  # `Categories=Utility;`, so XFCE files it under Accessories rather than
  # Development where goose and the other agent GUIs live. home-manager
  # builds this entry into its own tiny package and adds it to the profile
  # at hiPrio, so it wins the collision against the one hermes-desktop
  # installs at the same path -- no overlay, no Electron rebuild.
  #
  # Exec/Icon are deliberately unqualified rather than store paths: the
  # binary is on the session PATH and the icon is installed into the hicolor
  # theme, so neither needs re-pinning when the package version moves.
  xdg.desktopEntries.hermes = {
    name = "Hermes";
    genericName = "Hermes Desktop";
    comment = "Launch Hermes Desktop";
    exec = "hermes-desktop";
    icon = "hermes";
    terminal = false;
    type = "Application";
    categories = [ "Development" ];
    startupNotify = true;
    # Not a first-class option; it is what lets the window manager match the
    # running Electron window back to this launcher.
    settings.StartupWMClass = "Hermes";
  };
}
