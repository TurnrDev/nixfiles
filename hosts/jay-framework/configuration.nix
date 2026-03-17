{ config, inputs, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/roles/laptop.nix
      ../../modules/nixos/roles/gaming.nix
    ];

  networking.hostName = "jay-framework";

  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    users.jay.imports = [ ./home.nix ];
  };
}
