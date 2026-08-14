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
    ./google-drive.nix
  ];

  programs.borgmatic.enable = false;

}
