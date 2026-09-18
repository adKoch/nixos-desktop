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
    extraDependencyGroups = [ "voice" ];

    # The module runtime path is only bash/coreutils/git. Hermes own installer
    # provides ffmpeg, and voice-memo decoding expects it, so add it here.
    extraPackages = [ pkgs.ffmpeg ];

    settings.stt.provider = "local";

    # To transcribe on tinfoil instead (whisper-large-v3-turbo in an attested
    # enclave -- better model, but the audio leaves this machine), swap the
    # line above for these three and drop "voice" from the groups:
    #   settings.stt.provider = "openai";
    #   environment.STT_OPENAI_BASE_URL = "http://127.0.0.1:3301/v1";
    #   environment.STT_OPENAI_MODEL = "whisper-large-v3-turbo";

    # Not a secret: the Caddy layer on 3301 swaps this placeholder for the
    # real key out of sops, exactly as opencode does. See programs/tinfoil.nix.
    environment.OPENAI_API_KEY = "local";
  };
}
