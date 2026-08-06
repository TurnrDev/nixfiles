{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/roles/desktop.nix
    ../../modules/home-manager/hardware/amd.nix
  ];

}
