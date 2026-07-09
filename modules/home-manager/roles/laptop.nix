{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ../common/dockmgr.nix
    ./gaming.nix
    ./workstation.nix
  ];

  programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
  programs.dank-material-shell.plugins.tailscale.enable = true;
}
