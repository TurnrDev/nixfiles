{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    hyprlock
  ];
  stylix.targets.hyprlock.enable = true;
  programs.hyprlock.enable = true;
  wayland.windowManager.hyprland.settings = {
    bindd = [
      "$mainMod, L, Lock Session, exec, loginctl lock-session"
    ];
  };
}
