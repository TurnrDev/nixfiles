{
  ...
}:

{
  imports = [
    ./workstation.nix
  ];

  programs.dank-material-shell.plugins.networkStatus.enable = true;

  programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
}
