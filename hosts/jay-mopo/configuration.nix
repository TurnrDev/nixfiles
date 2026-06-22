{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

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
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/roles/laptop.nix
  ];

  networking.hostName = "jay-mopo";

  my.identity.email = lib.mkForce "jay.turner@mopo.co";

  services.displayManager.dms-greeter.compositor.customConfig = lib.mkForce ''
    env = DMS_RUN_GREETER,1
    source = /var/lib/dms-greeter/outputs.conf

    misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
    }

    input {
        kb_layout = gb
        kb_variant = colemak
        numlock_by_default = true
    }

  '';

  services.xserver.xkb = {
    layout = "gb";
    variant = "colemak";
  };

  # Per-device borgmatic overrides live in the host config. The shared module
  # provides the defaults and translates this block into borgmatic YAML.
  #
  my.backups.borgmatic.enable = false;
#   my.backups.borgmatic = {
#     frequency = "daily";
#     sourceDirectories = [ config.my.identity.homeDirectory ];
#     healthchecksUrl = "https://healthchecks.home.turnr.dev/ping/66bb872c-5ff0-4398-ba0c-7db7f3f7b731";
#     repositories = {
#       hetzner.path = "ssh://u551190@u551190.your-storagebox.de:23/./${config.networking.hostName}";
#     };
#   };

  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [ "kvm" ];
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
