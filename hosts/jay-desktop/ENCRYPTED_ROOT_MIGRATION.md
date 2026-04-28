# jay-desktop Encrypted Root Migration

This host config now expects the Intel SATA SSD to use:

- `/boot`: FAT32 EFI partition with GPT partition label `nixos-efi`
- `cryptroot`: LUKS2 volume opened from GPT partition label `nixos-crypt`
- Btrfs subvolumes: `@`, `@nix`, `@home`, `@log`, `@swap`
- swap file: `/swap/swapfile`, created inside the encrypted Btrfs volume

Do this from NixOS installer media, not from the running installed system.

## Safety Checks

Before partitioning, identify the target disk by model and serial:

```sh
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL,UUID,MOUNTPOINTS
```

The target disk is the Intel SATA SSD:

```text
MODEL:  INTEL SSDMCEAW120A4
SERIAL: CVDA448302SP120P
SIZE:   111.8G
```

Do not partition the Samsung Windows SSD or the WD_BLACK NVMe.

## Installer Layout Commands

Replace `/dev/sdX` with the Intel SATA SSD path after confirming the safety
checks above.

```sh
sudo swapoff --all

sudo parted /dev/sdX -- mklabel gpt
sudo parted /dev/sdX -- mkpart ESP fat32 1MiB 1025MiB
sudo parted /dev/sdX -- set 1 esp on
sudo parted /dev/sdX -- name 1 nixos-efi
sudo parted /dev/sdX -- mkpart nixos-crypt 1025MiB 100%
sudo parted /dev/sdX -- name 2 nixos-crypt

sudo mkfs.fat -F 32 -n NIXBOOT /dev/sdX1

sudo cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/nixos-crypt
sudo cryptsetup open /dev/disk/by-partlabel/nixos-crypt cryptroot

sudo mkfs.btrfs -L nixos-root /dev/mapper/cryptroot
sudo mount /dev/mapper/cryptroot /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@log
sudo btrfs subvolume create /mnt/@swap
sudo chattr +C /mnt/@swap
sudo umount /mnt

sudo mount -o subvol=@,compress=zstd,noatime /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/{boot,nix,home,var/log,swap}
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix
sudo mount -o subvol=@home,compress=zstd,noatime /dev/mapper/cryptroot /mnt/home
sudo mount -o subvol=@log,compress=zstd,noatime /dev/mapper/cryptroot /mnt/var/log
sudo mount -o subvol=@swap,noatime,compress=no /dev/mapper/cryptroot /mnt/swap
sudo mount /dev/disk/by-partlabel/nixos-efi /mnt/boot
```

Restore `/home`, `/etc/nixos`, and any non-reproducible local state before
installing. Then install from this flake:

```sh
sudo nixos-install --flake /mnt/etc/nixos#jay-desktop
```

## Post-Boot Checks

After rebooting into the installed system:

```sh
findmnt -no SOURCE,FSTYPE /
lsblk -f
swapon --show
cat /proc/cmdline
```

Expected results:

- `/` is mounted from `/dev/mapper/cryptroot` as `btrfs`
- the SATA system partition is `crypto_LUKS`
- swap is `/swap/swapfile`, not the old plain swap partition
- boot prompts for the LUKS passphrase
