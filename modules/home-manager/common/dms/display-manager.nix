{ config, lib, pkgs, ... }:

let
  inherit (lib) all imap0 mkOption types;

  cfg = config.my.dankMaterialShell.monitors;

  stringListType = types.listOf types.str;

  validateTypedStringListAttrs =
    allowedKeys: value:
    builtins.isAttrs value
    && value != { }
    && all (key: builtins.elem key allowedKeys) (builtins.attrNames value)
    && all (key: builtins.isList value.${key} && all builtins.isString value.${key}) (builtins.attrNames value);

  validateLidClause =
    value:
    builtins.isAttrs value
    && (builtins.attrNames value) == [ "closed" ]
    && builtins.isBool value.closed;

  validateMatchExpression =
    value:
    builtins.isAttrs value
    && value != { }
    && all (
      key:
      let
        current = value.${key};
      in
      if key == "and" || key == "or" then
        builtins.isList current && all validateMatchExpression current
      else if key == "not" then
        validateMatchExpression current
      else if key == "usb" then
        validateTypedStringListAttrs [ "anyOf" "allOf" "noneOf" ] current
      else if key == "displays" then
        validateTypedStringListAttrs [ "connectedAnyOf" "connectedAllOf" "connectedNoneOf" ] current
      else if key == "lid" then
        validateLidClause current
      else
        false
    ) (builtins.attrNames value);

  matchExpressionType = types.addCheck types.attrs validateMatchExpression;

  hooksType = types.submodule {
    options = {
      preUp = mkOption {
        type = stringListType;
        default = [ ];
      };

      postUp = mkOption {
        type = stringListType;
        default = [ ];
      };

      preDown = mkOption {
        type = stringListType;
        default = [ ];
      };

      postDown = mkOption {
        type = stringListType;
        default = [ ];
      };
    };
  };

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

      match = mkOption {
        type = types.nullOr matchExpressionType;
        default = null;
        description = ''
          Profile activation expression for dock state matching.

          Supported expression keys are `and`, `or`, `not`, `usb`, `displays`, and `lid`.
        '';
      };

      hooks = mkOption {
        type = hooksType;
        default = { };
      };

      outputs = mkOption {
        type = types.attrsOf outputType;
        default = { };
      };
    };
  };

  profileNames = map (profile: profile.name) cfg.configurations;

  matchSpecificity =
    expr:
    if expr == null then
      0
    else
      builtins.foldl' (
        total: key:
        let
          value = expr.${key};
        in
        total
        + (
          if key == "and" || key == "or" then
            builtins.foldl' (sum: item: sum + matchSpecificity item) 0 value
          else if key == "not" then
            matchSpecificity value
          else if key == "usb" || key == "displays" then
            builtins.foldl' (sum: clause: sum + builtins.length value.${clause}) 0 (builtins.attrNames value)
          else if key == "lid" then
            1
          else
            0
        )
      ) 0 (builtins.attrNames expr);

  resolvedProfiles = imap0 (
    index: profile:
    let
      profileWithoutId = profile // {
        id = null;
      };
      hash = builtins.substring 0 8 (builtins.hashString "sha256" (builtins.toJSON profileWithoutId));
    in
    profile
    // {
      id = if profile.id != null then profile.id else "profile_${profile.name}_${hash}";
      order = index;
      specificity = matchSpecificity profile.match;
    }
  ) cfg.configurations;

  dmsConfigurations = map (profile: {
    inherit (profile) id name outputs;
  }) resolvedProfiles;

  dockmgrConfigurations = map (profile: {
    inherit (profile) id name match hooks order specificity;
    fallback = profile.match == null;
  }) resolvedProfiles;
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

            match = null;

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
      configurations = dmsConfigurations;
    };

    xdg.configFile."dockmgr/config.json".text = builtins.toJSON {
      version = 1;
      profiles = dockmgrConfigurations;
    };

    home.packages = [
      pkgs.jq
      pkgs.nwg-displays
    ];
  };
}
