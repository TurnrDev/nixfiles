{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/roles/laptop.nix
    ../../modules/nixos/hardware/intel-arc.nix
  ];

  networking.hostName = "jay-mopo";

  my.identity.email = lib.mkForce "jay.turner@mopo.co";

  stylix.base16Scheme = ../../modules/home-manager/common/stylix/themes/mopo.yaml;

  services.xserver.xkb = {
    layout = "gb";
    variant = "colemak";
  };

  # jay-mopo uses a Meteor Lake Intel iGPU. Use the generic modesetting stack
  # with Mesa plus Intel's current media/compute userspace drivers.
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      vpl-gpu-rt
    ];
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

}
