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

  # programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
}
