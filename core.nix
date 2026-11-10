{ inputs, lib, ... }:
{
  flake-file.inputs.AquaticOS = {
    url = "git+https://git.aquaticservers.com/aqua/AquaticOS";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.nixpkgs-master.follows = "nixpkgs-master";
    inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    inputs.flake-file.follows = "flake-file";
    inputs.flake-parts.follows = "flake-parts";
    inputs.home-manager.follows = "home-manager";
    inputs.import-tree.follows = "import-tree";
    inputs.nur.follows = "nur";
  };

  flake-file.outputs = lib.mkForce ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./core.nix (inputs.import-tree ./modules) ];
    }
  '';

  imports = [ (inputs.import-tree "${inputs.AquaticOS}/modules") ];
}