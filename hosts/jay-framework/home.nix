{ config, inputs, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
  ];
}
