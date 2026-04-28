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
      ../../modules/nixos/roles/desktop.nix
      ../../modules/nixos/hardware/bluetooth.nix
      ../../modules/nixos/roles/gaming.nix
    ];

  boot.lanzaboote.enable = lib.mkForce false;
  boot.loader.timeout = lib.mkForce 30;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    theme = ./grub-theme;
    useOSProber = false;
    extraEntries = ''
      menuentry "Windows" {
        insmod part_gpt
        insmod fat
        search --no-floppy --fs-uuid --set=root 842B-04A5
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }

      menuentry "Arch Linux" {
        insmod part_gpt
        insmod fat
        search --no-floppy --fs-uuid --set=root 1A54-B1EE
        chainloader /EFI/GRUB/grubx64.efi
      }
    '';
  };

  fileSystems."/mnt/arch" = {
    device = "/dev/disk/by-uuid/b8be9d02-e091-4f19-99b9-d89ea5e17ee4";
    fsType = "ext4";
    options = [ "nofail" "noauto" "x-systemd.automount" "ro" ];
  };

  fileSystems."/mnt/win" = {
    device = "/dev/disk/by-uuid/9AFC2B85FC2B5AB1";
    fsType = "ntfs3";
    options = [
      "nofail"
      "noauto"
      "x-systemd.automount"
      "ro"
      "uid=${config.my.identity.username}"
      "gid=users"
      "windows_names"
    ];
  };

  fileSystems."/mnt/slow" = {
    device = "/dev/disk/by-uuid/FFF9-F750";
    fsType = "exfat";
    options = [
      "nofail"
      "noauto"
      "x-systemd.automount"
      "uid=${config.my.identity.username}"
      "gid=users"
    ];
  };

  # TEMPORARY SATA ROOT HOUSEKEEPING:
  # jay-desktop currently boots from a small SATA SSD and will eventually move
  # onto the NVMe. Keep Nix's retention tighter here so /nix/store does not
  # slowly crowd out the root filesystem before that migration.
  nix.gc.options = lib.mkForce "--delete-older-than 7d";
  nix.settings = {
    min-free = 10 * 1024 * 1024 * 1024;
    max-free = 20 * 1024 * 1024 * 1024;
  };
  boot.loader.grub.configurationLimit = 10;

  networking.hostName = "jay-desktop";

  # Per-device borgmatic overrides live in the host config. The shared module
  # provides the defaults and translates this block into borgmatic YAML.
  #
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
