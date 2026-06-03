{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
  ];

  wayland.windowManager.hyprland.settings = {
    input.kb_variant = "colemak";
    "exec-once" = lib.mkForce [
      "${pkgs.setxkbmap}/bin/setxkbmap -layout gb -variant colemak"
    ];
  };
}
