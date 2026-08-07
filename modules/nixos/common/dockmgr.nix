{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    all
    imap0
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.my.dockmgr;
  stringListType = types.listOf types.str;
  dockMgr = pkgs.callPackage ../../../packages/dockmgr/dockmgr.nix { };

  validateTypedStringListAttrs =
    allowedKeys: value:
    builtins.isAttrs value
    && value != { }
    && all (key: builtins.elem key allowedKeys) (builtins.attrNames value)
    && all (key: builtins.isList value.${key} && all builtins.isString value.${key}) (
      builtins.attrNames value
    );

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

  phaseHooksType = types.submodule {
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

  hooksType = types.submodule {
    options = {
      session = mkOption {
        type = phaseHooksType;
        default = { };
      };
      greeter = mkOption {
        type = phaseHooksType;
        default = { };
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
      disabled = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  profileType = types.submodule {
    options = {
      id = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional stable dockmgr profile ID.";
      };
      name = mkOption { type = types.str; };
      match = mkOption {
        type = types.nullOr matchExpressionType;
        default = null;
        description = "Activation expression supporting and, or, not, usb, displays, and lid.";
      };
      hooks = mkOption {
        type = hooksType;
        default = { };
      };
      outputs = mkOption {
        type = types.attrsOf outputType;
        default = { };
      };
      disableUnspecifiedOutputs = mkOption {
        type = types.bool;
        default = true;
        description = "Disable connected outputs not listed in this profile.";
      };
    };
  };

  profileNames = map (profile: profile.name) cfg.profiles;

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
      fallback = profile.match == null;
    }
  ) cfg.profiles;
in
{
  options.my.dockmgr = {
    enable = mkEnableOption "dockmgr display profile manager";
    package = mkOption {
      type = types.package;
      readOnly = true;
    };
    configFile = mkOption {
      type = types.path;
      readOnly = true;
    };
    luaModule = mkOption {
      type = types.path;
      readOnly = true;
    };
    profiles = mkOption {
      type = types.listOf profileType;
      default = [ ];
      description = "Hyprland display profiles selected from dock, display, and lid state.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.length profileNames == lib.length (lib.unique profileNames);
        message = "dockmgr profile names must be unique.";
      }
      {
        assertion = builtins.any (profile: profile.match == null) cfg.profiles;
        message = "dockmgr requires a fallback profile with match = null.";
      }
    ];

    my.dockmgr = {
      package = dockMgr;
      luaModule = dockMgr.luaModule;
      configFile = pkgs.writeText "dockmgr-config.json" (
        builtins.toJSON {
          version = 2;
          profiles = resolvedProfiles;
        }
      );
    };

    environment = {
      systemPackages = [
        dockMgr
        pkgs.nwg-displays
      ];
      etc."dockmgr/config.json".source = config.my.dockmgr.configFile;
    };
  };
}
