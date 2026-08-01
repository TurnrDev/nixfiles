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
    ../../modules/home-manager/hardware/amd.nix
  ];

  my.dankMaterialShell.monitors.internalDisplay = {
    width = 2256;
    height = 1504;
    freq = "59.999";
  };
}
