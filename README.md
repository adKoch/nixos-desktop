# nixos-desktop

NixOS configuration for personal machines.

## Setup on a new machine

1. Install NixOS and generate `hardware-configuration.nix` (`nixos-generate-config`)
2. Clone this repo and run `setuplinks.sh` to symlink into `/etc/nixos/`
3. Run `rebuild.sh`

### NVIDIA GPU

If the machine has an NVIDIA GPU, add this to `hardware-configuration.nix`:

```nix
services.xserver.videoDrivers = ["nvidia"];
```

This automatically enables:
- NVIDIA drivers (`hardware.nvidia`)
