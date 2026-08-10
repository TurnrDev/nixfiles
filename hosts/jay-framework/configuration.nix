{
  config,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/roles/laptop.nix
    ../../modules/nixos/roles/gaming.nix
  ];

  networking.hostName = "jay-framework";

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
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Per-device borgmatic overrides live in the host config. The shared module
  # provides the defaults and translates this block into borgmatic YAML.
  #
  my.backups.borgmatic = {
    frequency = "daily";
    sourceDirectories = [ config.my.identity.homeDirectory ];
    healthchecksUrl = "https://healthchecks.home.turnr.net/ping/66bb872c-5ff0-4398-ba0c-7db7f3f7b731";
    repositories = {
      hetzner.path = "ssh://u551190@u551190.your-storagebox.de:23/./${config.networking.hostName}";
    };
  };

  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [ "kvm" ];
    };
  };

}
