{
  ...
}:

{
  imports = [
    ./workstation.nix
  ];

  programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
}
