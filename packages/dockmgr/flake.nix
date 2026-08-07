{
  description = "Hyprland dock and display profile manager";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      forSystem =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          package = pkgs.callPackage ./package.nix { };
        in
        {
          inherit package pkgs;
        };
    in
    {
      packages = forAllSystems (system: {
        default = (forSystem system).package;
        dockmgr = (forSystem system).package;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${(forSystem system).package}/bin/dockmgr";
        };
        dockmgr = {
          type = "app";
          program = "${(forSystem system).package}/bin/dockmgr";
        };
      });

      checks = forAllSystems (
        system:
        let
          inherit ((forSystem system).pkgs) lua shellcheck runCommand;
        in
        {
          shell =
            runCommand "dockmgr-shellcheck"
              {
                nativeBuildInputs = [ shellcheck ];
              }
              ''
                shellcheck ${./src/dockmgr.sh}
                touch "$out"
              '';
          lua =
            runCommand "dockmgr-lua-syntax"
              {
                nativeBuildInputs = [ lua ];
              }
              ''
                luac -p ${./src/dockmgr.lua}
                touch "$out"
              '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          inherit ((forSystem system).pkgs)
            jq
            lua
            shellcheck
            mkShell
            ;
        in
        {
          default = mkShell {
            packages = [
              jq
              lua
              shellcheck
            ];
          };
        }
      );

      nixosModules = {
        default = import ./modules/nixos.nix;
      };

      homeManagerModules.default = import ./modules/home-manager.nix;
    };
}
