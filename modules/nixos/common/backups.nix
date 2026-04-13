{ config, inputs, lib, pkgs, ... }:

let
  # These options are the per-device interface. The Home Manager module reads
  # them from osConfig and renders a single shared borgmatic configuration file.
  cfg = config.my.backups.borgmatic;
  borg14Package = inputs."nixpkgs-borg14".legacyPackages.${pkgs.system}.borgbackup;
  defaultHomeDirectory = config.my.identity.homeDirectory;
  defaultRepositoryPath = "ssh://u551190@u551190.your-storagebox.de:23/./${config.networking.hostName}";
  defaultSourceDirectories = [ defaultHomeDirectory ];
  defaultExcludePatterns = [
    "*.pyc"
    "*cache*"
    "${defaultHomeDirectory}/.cache"
    "${defaultHomeDirectory}/.config/Code"
    "${defaultHomeDirectory}/.config/discord"
    "${defaultHomeDirectory}/.config/GitKraken"
    "${defaultHomeDirectory}/.config/spotify"
    "${defaultHomeDirectory}/.gitkraken"
    "${defaultHomeDirectory}/.local/share/pnpm"
    "${defaultHomeDirectory}/.local/share/Steam"
    "${defaultHomeDirectory}/.local/share/Trash"
    "${defaultHomeDirectory}/.nvm"
    "${defaultHomeDirectory}/.steam-shared"
    "${defaultHomeDirectory}/.steam"
    "${defaultHomeDirectory}/.thumbnails"
    "${defaultHomeDirectory}/.vscode-server"
    "${defaultHomeDirectory}/.vscode"
    "${defaultHomeDirectory}/Downloads"
  ];
in
{
  options.my.backups.borgmatic = with lib; {
    enable = mkEnableOption "shared borgmatic Storage Box backups" // {
      default = true;
    };

    frequency = mkOption {
      type = types.str;
      default = "daily";
      example = "daily";
      description = ''
        How often the user borgmatic timer should run.

        This is passed directly to `systemd.timer` as `OnCalendar`.
      '';
    };

    localPath = mkOption {
      type = types.str;
      default = lib.getExe borg14Package;
      defaultText = literalExpression ''lib.getExe inputs."nixpkgs-borg14".legacyPackages.${pkgs.system}.borgbackup'';
      example = literalExpression ''lib.getExe inputs."nixpkgs-borg14".legacyPackages.${pkgs.system}.borgbackup'';
      description = ''
        Absolute path to the pinned Borg client binary to use locally.

        The default comes from the dedicated `nixpkgs-borg14` flake input so
        regular flake lock updates do not silently change the Borg major/minor
        version used for backups.
      '';
    };

    remotePath = mkOption {
      type = types.str;
      default = "borg-1.4";
      example = "borg-1.4";
      description = ''
        Remote Borg executable name to use over SSH.

        For Hetzner Storage Boxes this is typically `borg-1.4`.
      '';
    };

    sourceDirectories = mkOption {
      type = types.listOf types.str;
      default = defaultSourceDirectories;
      defaultText = literalExpression "[ config.my.identity.homeDirectory ]";
      example = [
        "${config.home.homeDirectory}"
        "/srv/projects"
      ];
      description = ''
        Base directories borgmatic should back up for this device.

        This is intentionally device-scoped rather than repository-scoped so a
        host can define its backup set in one place.
      '';
    };

    extraSourceDirectories = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/srv/projects" ];
      description = ''
        Additional source directories to append to `sourceDirectories`.

        Use this for host-specific additions without replacing the shared base
        list.
      '';
    };

    excludePatterns = mkOption {
      type = types.listOf types.str;
      default = defaultExcludePatterns;
      example = [
        "*.pyc"
        "${config.home.homeDirectory}/.local/share/Steam"
        "${config.home.homeDirectory}/Downloads"
      ];
      description = ''
        Base Borg exclude patterns to use for this device.

        These are written to borgmatic as `exclude_patterns`.
      '';
    };

    extraExcludePatterns = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "${config.home.homeDirectory}/.config/obs-studio" ];
      description = ''
        Additional Borg exclude patterns to append to `excludePatterns`.

        Use this for host-specific additions without replacing the shared base
        list.
      '';
    };

    healthchecksUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://hc-ping.com/01234567-89ab-cdef-0123-456789abcdef";
      description = ''
        Optional Healthchecks ping URL to use for this device.

        When set, borgmatic also enables `send_logs = true` for the
        Healthchecks hook.
      '';
    };

    repositories = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          path = mkOption {
            type = types.str;
            example = "ssh://u551190@u551190.your-storagebox.de:23/./jay-framework";
            description = ''
              Repository URL or path.

              The attribute name is only used locally in Nix; borgmatic uses
              the rendered `label` and `path`. If you want the device hostname
              in the path, interpolate it in Nix with
              `''${config.networking.hostName}` so the generated borgmatic config
              contains a concrete repository location.
            '';
          };

          label = mkOption {
            type = types.str;
            default = name;
            example = "hetzner";
            description = "Short borgmatic label for the repository.";
          };
        };
      }));
      default = {
        hetzner = {
          label = "hetzner";
          path = defaultRepositoryPath;
        };
      };
      example = literalExpression ''
        {
          hetzner = {
            label = "hetzner";
            path = "ssh://u551190@u551190.your-storagebox.de:23/./''${config.networking.hostName}";
          };

          usb = {
            label = "usb";
            path = "/run/media/jay/BACKUP/''${config.networking.hostName}";
          };
        }
      '';
      description = ''
        Named repositories to include in the shared borgmatic configuration.

        All repositories share the same device-level source directories,
        excludes for the primary home directory, local Borg binary, and remote
        Borg path.
      '';
    };
  };

  config = lib.mkIf (config.my.identity.enable && cfg.enable) {
    users.manageLingering = true;
    users.users.${config.my.identity.username}.linger = true;
  };
}
