{
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./core.nix
        (inputs.import-tree ./modules)
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
