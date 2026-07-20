{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ../common/dockmgr.nix
    ../common/dms/laptop-monitors.nix
    ./gaming.nix
    ./workstation.nix
  ];

  programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
}
