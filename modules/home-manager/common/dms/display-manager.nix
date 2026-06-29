{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;

  cfg = config.my.dankMaterialShell.monitors;

  positionType = types.submodule {
    options = {
      x = mkOption {
        type = types.int;
        default = 0;
      };

      y = mkOption {
        type = types.int;
        default = 0;
      };
    };
  };

  outputType = types.submodule {
    options = {
      mode = mkOption {
        type = types.str;
        default = "preferred";
      };

      position = mkOption {
        type = positionType;
        default = { };
      };

      scale = mkOption {
        type = types.float;
        default = 1.0;
      };

      transform = mkOption {
        type = types.str;
        default = "Normal";
      };

      vrr = mkOption {
        type = types.bool;
        default = false;
      };

      disabled = mkOption {
        type = types.bool;
        default = false;
      };

      hyprland = mkOption {
        type = types.attrs;
        default = { };
      };
    };
  };

  profileType = types.submodule {
    options = {
      id = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional DMS profile ID. If null, generated from profile name and profile contents.";
      };

      name = mkOption {
        type = types.str;
      };

      outputs = mkOption {
        type = types.attrsOf outputType;
        default = { };
      };
    };
  };

  profileNames = map (profile: profile.name) cfg.configurations;

  generatedConfigurations = map (
    profile:
    let
      profileWithoutId = profile // {
        id = null;
      };
      hash = builtins.substring 0 8 (builtins.hashString "sha256" (builtins.toJSON profileWithoutId));
    in
    profile
    // {
      id = if profile.id != null then profile.id else "profile_${profile.name}_${hash}";
    }
  ) cfg.configurations;
in
{
  options.my.dankMaterialShell.monitors = {
    version = mkOption {
      type = types.int;
      default = 1;
    };

    configurations = mkOption {
      type = types.listOf profileType;
      default = [ ];

      description = ''
        DankMaterialShell monitor profiles.

        Example:

        ```nix
        my.dankMaterialShell.monitors.configurations = [
          {
            name = "Docked";

            outputs = {
              "desc:Samsung Electric Company LC49G95T H1AK500000" = {
                mode = "5120x1440@59.977";

                position = {
                  x = 0;
                  y = 0;
                };

                scale = 1.0;
              };
            };
          }

          {
            name = "Undocked";

            outputs = {
              "eDP-1" = {
                mode = "2256x1504@59.999";
                scale = 1.3333333333333333;
              };
            };
          }
        ];
        ```

        Profile IDs are optional and will be generated automatically if omitted.

        Profile names must be unique.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.length profileNames == lib.length (lib.unique profileNames);
        message = "DMS monitor profile names must be unique.";
      }
    ];

    xdg.configFile."DankMaterialShell/monitors.json".text = builtins.toJSON {
      version = cfg.version;
      configurations = generatedConfigurations;
    };
    
    home.packages = [
      pkgs.nwg-displays
    ];
  };
}
