{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-gitsquid.url = "github:TurnrDev/nixpkgs?ref=gitsquid";
    # Historical Nixpkgs package sets, evaluated only when a version is selected.
    # Keep `nixpkgs` as the real base input: flake inputs that follow it require
    # the normal nixpkgs lib and legacyPackages interface.
    multiverse.url = "github:fzakaria/nixpkgs-multiverse";
    dockmgr = {
      url = "path:./packages/dockmgr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord.url = "github:4evy/nixcord";
    dux = {
      url = "github:duxlabs-dev/dux-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-greeter = {
      url = "github:duxlabs-dev/dux-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-files = {
      url = "github:duxlabs-dev/dux-files";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-plugins = {
      url = "github:duxlabs-dev/dux-plugins";
      flake = false;
    };
    dux-screenshot = {
      url = "github:JDKamalakar/DMS-Screenshot";
      flake = false;
    };
    dux-plugin-hass = {
      url = "github:xxyangyoulin/dms-plugin-hass";
      flake = false;
    };
    dux-plugin-docker-manager = {
      url = "github:LuckShiba/DmsDockerManager";
      flake = false;
    };
    dux-emoji-launcher = {
      url = "github:devnullvoid/dms-emoji-launcher";
      flake = false;
    };
    dux-plugin-tailscale = {
      url = "github:cglavin50/dms-tailscale";
      flake = false;
    };
    zsh-command-time = {
      url = "github:popstas/zsh-command-time";
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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      repoLib = import ./lib { inherit (nixpkgs) lib; };
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      mkHost =
        hostDirectory:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs repoLib;
            homeModule = hostDirectory + "/home.nix";
          };
          modules = [
            (hostDirectory + "/configuration.nix")
            inputs.stylix.nixosModules.stylix
            inputs.home-manager.nixosModules.default
            ./modules/nixos/common/home-manager.nix
          ];
        };
    in
    {
      formatter.${system} = treefmtEval.config.build.wrapper;

      checks.${system}.formatting = treefmtEval.config.build.check self;

      nixosConfigurations = {
        jay-framework = mkHost ./hosts/jay-framework;
        jay-desktop = mkHost ./hosts/jay-desktop;
        jay-mopo = mkHost ./hosts/jay-mopo;

        # Compatibility alias so plain `nixos-rebuild` works on hosts named "nixos".
        # nixos = mkHost ./hosts/<newhost>;
      };
    };
}
