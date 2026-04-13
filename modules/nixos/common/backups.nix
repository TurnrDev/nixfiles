{ config, inputs, lib, pkgs, ... }:

let
  # These options are the per-device interface. The Home Manager module reads
  # them from osConfig and renders a single shared borgmatic configuration file.
  cfg = config.my.backups.borgmatic;
  borg14Package = inputs."nixpkgs-borg14".legacyPackages.${pkgs.system}.borgbackup;
  defaultHomeDirectory = config.my.identity.homeDirectory;
  defaultRepositoryPath = "ssh://u551190@u551190.your-storagebox.de:23/./{hostname}";
in
{
  options.my.backups.borgmatic = with lib; {
    enable = mkEnableOption "shared borgmatic Storage Box backups" // {
      default = true;
    };

    frequency = mkOption {
      type = types.str;
      default = "hourly";
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
      default = [ defaultHomeDirectory ];
      defaultText = literalExpression "[ config.my.identity.homeDirectory ]";
      example = [
        "/home/jay"
        "/srv/projects"
      ];
      description = ''
        Directories borgmatic should back up for this device.

        This is intentionally device-scoped rather than repository-scoped so a
        host can define its backup set in one place.
      '';
    };

    excludePatterns = mkOption {
      type = types.listOf types.str;
      default = [
        "${defaultHomeDirectory}/.cache"
        "${defaultHomeDirectory}/Downloads"
        "${defaultHomeDirectory}/.local/share/Trash"
      ];
      example = [
        "/home/jay/.cache"
        "/home/jay/Downloads"
        "/home/jay/VirtualMachines"
      ];
      description = ''
        Borg exclude patterns to use for this device.

        These are written to borgmatic as `exclude_patterns`.
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
            example = "ssh://u551190@u551190.your-storagebox.de:23/./{hostname}";
            description = ''
              Repository URL or path.

              The attribute name is only used locally in Nix; borgmatic uses
              the rendered `label` and `path`.
            '';
          };

          label = mkOption {
            type = types.str;
            default = name;
            example = "storagebox";
            description = "Short borgmatic label for the repository.";
          };
        };
      }));
      default = {
        storagebox = {
          label = "storagebox";
          path = defaultRepositoryPath;
        };
      };
      example = literalExpression ''
        {
          storagebox = {
            label = "storagebox";
            path = "ssh://u551190@u551190.your-storagebox.de:23/./{hostname}";
          };

          usb = {
            label = "usb";
            path = "/run/media/jay/BACKUP/{hostname}";
          };
        }
      '';
      description = ''
        Named repositories to include in the shared borgmatic configuration.

        All repositories share the same device-level source directories,
        excludes, local Borg binary, and remote Borg path.
      '';
    };
  };

  config = lib.mkIf (config.my.identity.enable && cfg.enable) {
    users.manageLingering = true;
    users.users.${config.my.identity.username}.linger = true;
  };
}
