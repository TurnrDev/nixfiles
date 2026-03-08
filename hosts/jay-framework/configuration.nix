{ config, inputs, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/roles/laptop.nix
    ];

  networking.hostName = "jay-framework";

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.jay.imports = [ ./home.nix ];
  };
}
