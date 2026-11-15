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
    # The Marketplace expressions are regenerated daily. Renovate updates this
    # lock-file input, keeping VS Code extensions independent of nixpkgs.
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    # Historical Nixpkgs package sets, evaluated only when a version is selected.
    # Keep `nixpkgs` as the real base input: flake inputs that follow it require
    # the normal nixpkgs lib and legacyPackages interface.
    multiverse.url = "github:fzakaria/nixpkgs-multiverse";
    kytyps5 = {
      url = "github:KytyPS5/KytyPS5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dockmgr = {
      url = "path:./packages/dockmgr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/nur";
  };
}
