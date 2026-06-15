{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ./gaming.nix
    ./workstation.nix
  ];

  wayland.windowManager.hyprland.settings.source = [
    "~/.config/hypr/dms/outputs.conf"
  ];

  # programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
}
