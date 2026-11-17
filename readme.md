# NixOS

My NixOS configurations, built on [Aquatic](https://git.aquaticservers.com/aqua/AquaticOS), flake-parts and Home Manager.

| Host | Purpose |
| --- | --- |
| `jay-desktop` | AMD desktop and gaming |
| `jay-framework` | AMD laptop and gaming |
| `jay-mopo` | Intel work laptop |
| `g9-switcher` | Monitor-switching appliance |

## Working on the configuration

Run commands from `/etc/nixos`.

```sh
# Format and lint.
nix fmt

# Evaluate a host without building it.
nix eval .#nixosConfigurations.jay-framework.config.system.build.toplevel.drvPath

# Build without activating.
nix build .#nixosConfigurations.jay-framework.config.system.build.toplevel --no-link
```

On a configured workstation, `b --skip-update` builds the current host, shows the changes and prompts for activation. Plain `b` updates both the main flake lock and the nested dockmgr lock first. Use `--skip-update` to keep the existing pins.

To deploy to another configured host, pass its name explicitly:

```sh
./deploy.sh g9-switcher
```

This builds locally and switches the target over SSH, asking for its sudo password.

## Modules

`core.nix` imports AquaticOS and discovers this repository's modules through import-tree. Files under `modules/` are flake-parts modules that register NixOS and Home Manager modules:

```nix
{ inputs, ... }:
{
  flake.modules.nixos.program-example = {
    # NixOS settings.
  };

  flake.modules.homeManager.program-example = {
    # Home Manager settings.
  };
}
```

Registration makes a module available; importing it into a host enables it. Use flat, hyphenated names such as `hardware-gpu-amd`, `program-git` and `service-borgmatic`. Host modules use their hostname directly.

Import the appropriate namespace and keep imports sorted:

```nix
imports = with inputs.self.modules.nixos; [
  role-laptop
  role-nix-builder
  user-jay
];
```

Use `with inputs.self.modules.homeManager;` for Home Manager imports. Import roles in both namespaces when they provide both system and user configuration.

| Path | Contents |
| --- | --- |
| `modules/hosts/` | Host registration, hardware, storage and host-specific settings |
| `modules/roles/` | Groups of features for laptops, workstations, gaming and building |
| `modules/hardware/` | Reusable hardware support |
| `modules/desks/` | Monitors and peripherals at each desk |
| `modules/desktop/` | Hyprland, Dux and desktop defaults |
| `modules/programs/` | Individual applications |
| `modules/services/` | Services and their user configuration |
| `modules/system/` | System integration, boot, Nix authentication and caching |
| `modules/themes/` | Appearance |
| `modules/user/` | Jay's account and Home Manager integration |
| `packages/` | Local packages, including the separate dockmgr flake |
| `scripts/` | Build, activation and maintenance helpers |
| `secrets/` | SOPS-encrypted shared and host-specific secrets |

Copy [example.nix](example.nix) to start a module, then rename the file and its exports. Files named `example.nix` are excluded from discovery and formatting.

`user-jay` sets up Jay's account, Nix trust and Home Manager. It also imports the Home Manager module matching the hostname, when one exists. There is no separate Home Manager configuration to register for each host.

New files must be Git-tracked before Git-backed flake commands can see them.

## Inputs and updates

`flake.nix` is generated. Edit input declarations and output generation in [core.nix](core.nix), then run:

```sh
nix run .#write-flake
nix flake lock
```

`nix flake lock` resolves changed or new inputs while retaining existing pins where possible. Use `nix flake update` when intentionally upgrading inputs; pass input names to limit an update.

The default package set is `nixos-unstable`, paired with Home Manager's `master` branch. `nixpkgs-stable` explicitly provides `nixos-26.05` for packages that need it. Multiverse supplies historical package versions where a particular version or range is required.

Builder hosts use the Attic cache for downloads and uploads. Builds currently run locally. Cache credentials are decrypted by SOPS at activation.

## Setup and recovery

- [New host guide](docs/new-host.md)
- [Editing secrets](secrets/README.md)
- [Disaster recovery](disaster-recovery.md)
- [Monitor switching](docs/monitor-switch.md)
- [dockmgr](packages/dockmgr/README.md)
