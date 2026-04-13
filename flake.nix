{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # Keep the Borg client/tooling on an explicit 1.4-capable package set even
    # when the rest of the system tracks a newer nixpkgs revision.
    nixpkgs-borg14.url = "github:NixOS/nixpkgs/4e92bbcdb030f3b4782be4751dc08e6b6cb6ccf2";
    # Keep GitKraken on nixpkgs PR #509534 until the update lands upstream.
    nixpkgs-gitkraken.url = "github:NixOS/nixpkgs/pull/509534/head";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord.url = "github:FlameFlag/nixcord";
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugins = {
      url = "git+https://github.com/AvengeMedia/dms-plugins";
      flake = false;
    };
    dms-plugins-taylan = {
      url = "git+https://github.com/TaylanTatli/dms-plugins";
      flake = false;
    };
    dms-plugin-hass = {
      url = "git+https://github.com/xxyangyoulin/dms-plugin-hass";
      flake = false;
    };
    dms-plugin-docker-manager = {
      url = "git+https://github.com/LuckShiba/DmsDockerManager";
      flake = false;
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.jay-framework = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/jay-framework/configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
