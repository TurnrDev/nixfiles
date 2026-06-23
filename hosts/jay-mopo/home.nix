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

  programs.dank-material-shell.settings.customThemeFile = lib.mkForce
    "/etc/nixos/modules/home-manager/common/dms/themes/mopo.json";

  wayland.windowManager.hyprland.settings = {
    input.kb_variant = "colemak";
    "exec-once" = lib.mkForce [
      "${pkgs.setxkbmap}/bin/setxkbmap -layout gb -variant colemak"
    ];
  };
}
