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
    ../../modules/nixos/roles/desktop.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/hardware/logitech-g512.nix
    ../../modules/nixos/hardware/logitech-mx-master-3s.nix
    ../../modules/nixos/roles/gaming.nix
  ];

  boot.lanzaboote.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce true;
#   boot.loader.timeout = lib.mkForce 30;
#   boot.loader.systemd-boot.enable = lib.mkForce false;
#   boot.loader.grub = {
#     enable = true;
#     efiSupport = true;
#     device = "nodev";
#     theme = ./grub-theme;
#     useOSProber = false;
#     extraEntries = ''
#       menuentry "Windows" {
#         insmod part_gpt
#         insmod fat
#         search --no-floppy --fs-uuid --set=root 842B-04A5
#         chainloader /EFI/Microsoft/Boot/bootmgfw.efi
#       }
#     '';
#   };
#
#   fileSystems."/mnt/win" = {
#     device = "/dev/disk/by-uuid/9AFC2B85FC2B5AB1";
#     fsType = "ntfs3";
#     options = [
#       "nofail"
#       "noauto"
#       "x-systemd.automount"
#       "ro"
#       "uid=${config.my.identity.username}"
#       "gid=users"
#       "windows_names"
#     ];
#   };

#   fileSystems."/mnt/slow" = {
#     device = "/dev/disk/by-label/slow";
#     fsType = "ext4";
#     options = [
#       "nofail"
#       "noauto"
#       "x-systemd.automount"
#     ];
#   };

  networking.hostName = "jay-desktop";

  # Per-device borgmatic overrides live in the host config. The shared module
  # provides the defaults and translates this block into borgmatic YAML.
  #
  my.backups.borgmatic = {
    frequency = "daily";
    sourceDirectories = [ config.my.identity.homeDirectory ];
    healthchecksUrl = "https://healthchecks.home.turnr.dev/ping/3864da02-bd3e-4f8f-9685-825959aa6cf9";
    repositories = {
      hetzner.path = "ssh://u551190@u551190.your-storagebox.de:23/./arch";
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
