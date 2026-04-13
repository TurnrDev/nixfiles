{ config, inputs, lib, pkgs, ... }:

let
  hmBackupCommand = pkgs.writeShellScript "home-manager-backup" ''
    set -eu

    target="$1"
    backup="$target.hm-backup"

    if [ ! -e "$backup" ]; then
      exec mv -- "$target" "$backup"
    fi

    i=1
    while [ -e "$backup.$i" ]; do
      i=$((i + 1))
    done

    exec mv -- "$target" "$backup.$i"
  '';
in {
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/roles/laptop.nix
      ../../modules/nixos/roles/gaming.nix
    ];

  networking.hostName = "jay-framework";

  # Per-device borgmatic overrides live in the host config. The shared module
  # provides the defaults and translates this block into borgmatic YAML.
  #
  # Example additions:
  # my.backups.borgmatic = {
  #   healthchecksUrl = "https://hc-ping.com/01234567-89ab-cdef-0123-456789abcdef";
  #   extraSourceDirectories = [ "/srv/projects" ];
  #   extraExcludePatterns = [ "${config.my.identity.homeDirectory}/.config/obs-studio" ];
  #   repositories.usb = {
  #     label = "usb";
  #     path = "/run/media/jay/BACKUP/${config.networking.hostName}";
  #   };
  # };
  my.backups.borgmatic = {
    frequency = "daily";
    sourceDirectories = [ config.my.identity.homeDirectory ];
    repositories = {
      hetzner.path = "ssh://u551190@u551190.your-storagebox.de:23/./${config.networking.hostName}";
    };
  };

  home-manager = {
    backupCommand = hmBackupCommand;
    extraSpecialArgs = {
      inherit inputs;
      identity = config.my.identity;
    };
    users = lib.mkIf config.my.identity.enable {
      ${config.my.identity.username}.imports = [ ./home.nix ];
    };
  };
}
