{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/roles/desktop.nix
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-2,5120x1440@240,0x0,1"
    ];
  };

}
