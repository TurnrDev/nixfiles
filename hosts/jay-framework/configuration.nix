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

  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [ "kvm" ];
    };
  };

}
