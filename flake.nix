# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./core.nix
        (inputs.import-tree.filter (path: builtins.baseNameOf path != "example.nix") ./modules)
      ];
    };

  inputs = {
    AquaticOS = {
      url = "git+https://git.aquaticservers.com/aqua/AquaticOS";
      inputs = {
        flake-file.follows = "flake-file";
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs";
        nixpkgs-master.follows = "nixpkgs-master";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        nur.follows = "nur";
      };
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dockmgr = {
      url = "path:./packages/dockmgr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux = {
      url = "github:duxlabs-dev/dux-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-emoji-launcher = {
      url = "github:devnullvoid/dms-emoji-launcher";
      flake = false;
    };
    dux-greeter = {
      url = "github:duxlabs-dev/dux-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-plugin-docker-manager = {
      url = "github:LuckShiba/DmsDockerManager";
      flake = false;
    };
    dux-plugin-hass = {
      url = "github:xxyangyoulin/dms-plugin-hass";
      flake = false;
    };
    dux-plugins = {
      url = "github:duxlabs-dev/dux-plugins";
      flake = false;
    };
    dux-screenshot = {
      url = "github:JDKamalakar/DMS-Screenshot";
      flake = false;
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    kytyps5 = {
      url = "github:KytyPS5/KytyPS5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    multiverse.url = "github:fzakaria/nixpkgs-multiverse";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixcord.url = "github:4evy/nixcord";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/nur";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zsh-command-time = {
      url = "github:popstas/zsh-command-time";
      flake = false;
    };
  };
}
