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
          inherit ((forSystem system).pkgs)
            bats
            jq
            lua
            shellcheck
            runCommand
            ;
          validModule = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              ./modules/nixos.nix
              {
                system.stateVersion = "26.11";
                programs.dockmgr = {
                  enable = true;
                  profiles = [
                    {
                      name = "Laptop";
                      match = null;
                      outputs.eDP-1 = { };
                    }
                  ];
                };
              }
            ];
          };
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
          shell-tests =
            runCommand "dockmgr-shell-tests"
              {
                nativeBuildInputs = [
                  bats
                  jq
                ];
                DOCKMGR_SOURCE = ./src/dockmgr.sh;
              }
              ''
                bats ${./tests/dockmgr.bats}
                touch "$out"
              '';
          lua-tests =
            runCommand "dockmgr-lua-tests"
              {
                nativeBuildInputs = [
                  jq
                  lua
                ];
              }
              ''
                lua ${./tests/dockmgr_test.lua} ${./src/dockmgr.lua} ${jq}/bin/jq
                touch "$out"
              '';
          nixos-module = runCommand "dockmgr-nixos-module" { } ''
            test -e ${validModule.config.programs.dockmgr.configFile}
            touch "$out"
          '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          inherit ((forSystem system).pkgs)
            jq
            bats
            lua
            shellcheck
            mkShell
            ;
        in
        {
          default = mkShell {
            packages = [
              jq
              bats
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
