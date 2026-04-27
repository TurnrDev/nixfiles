{ config, inputs, lib, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/roles/desktop.nix
  ];
}
