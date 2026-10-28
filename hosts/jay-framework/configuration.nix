{
  config,
  lib,
  ...
}:

{
  imports = [
    # Regenerate hardware-configuration.nix with:
    # sudo nixos-generate-config --show-hardware-config --no-filesystems > /etc/nixos/hosts/$(hostname)/hardware-configuration.nix
    ./hardware-configuration.nix
    ./storage.nix
    ../../modules/nixos/roles/laptop.nix
    ../../modules/nixos/roles/gaming.nix
  ];

  networking.hostName = "jay-framework";

  my.wireguard.home = {
    enable = true;
    sopsFile = ../../secrets/hosts/jay-framework.yaml;
    ipv4Address = "10.117.25.241/32";
    ipv6Address = "fd00:7389:538a:05fd::3/64";
  };

  my.displays.internal = {
    width = 2256;
    height = 1504;
    freq = "59.999";
  };

  services.xserver.xkb = {
    layout = "gb";
    variant = "colemak";
  };

  # Framework laptop has an AMD Radeon iGPU; pin the matching stack explicitly.
  services.xserver.videoDrivers = [ "amdgpu" ];
  # Plymouth needs early KMS to show the graphical LUKS prompt.
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [ "kvm" ];
    };
  };

}
