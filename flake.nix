{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
    zsh-command-time = {
      url = "git+https://github.com/popstas/zsh-command-time";
      flake = false;
    };
    edmc-discord-presence = {
      url = "git+https://github.com/elite-kode/edmc-discord-presence?submodules=1";
      flake = false;
    };
    edmcoverlay2 = {
      url = "git+https://github.com/pan-mroku/edmcoverlay2";
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

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      mkHost =
        hostPath:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            hostPath
            inputs.home-manager.nixosModules.default
          ];
        };
    in
    {
      nixosConfigurations = {
        jay-framework = mkHost ./hosts/jay-framework/configuration.nix;
        jay-desktop = mkHost ./hosts/jay-desktop/configuration.nix;
        jay-mopo = mkHost ./hosts/jay-mopo/configuration.nix;

        # Compatibility alias so plain `nixos-rebuild` works on hosts named "nixos".
        # nixos = mkHost ./hosts/<newhost>/configuration.nix;
      };
    };
}
