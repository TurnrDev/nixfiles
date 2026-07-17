{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.my.dankMaterialShell.monitors;
  internal = cfg.internalDisplay;
  homeOfficeDisplay = "desc:Samsung Electric Company LC49G95T H1AK500000";
  homeOfficeMode = "5120x1440@59.977";

  internalMode =
    "${toString internal.width}x${toString internal.height}@${internal.freq}";

  scaledWidth = scale: builtins.floor (internal.width * scale);

  generatedInternalOutput = {
    mode = internalMode;
    position = { x = 0; y = 0; };
    scale = 1.0;
    disabled = false;
  };

  externalOutput = internalScale: {
    mode = homeOfficeMode;
    position = {
      x = scaledWidth internalScale;
      y = 0;
    };
    scale = 1.0;
  };

  standardProfiles = [
    {
      name = "Docked Home Office with Inbuilt Display";
      match = {
        and = [
          { displays.connectedAnyOf = [ homeOfficeDisplay ]; }
          { usb.allOf = [ "3434:0961" "046d:c548" ]; }
          { lid.closed = false; }
        ];
      };
      outputs = {
        ${internal.identifier} = cfg.internalOutput;
        ${homeOfficeDisplay} = externalOutput 1.0;
      };
    }

    {
      name = "Docked Home Office w/o Inbuilt Display";
      match = {
        and = [
          { displays.connectedAnyOf = [ homeOfficeDisplay ]; }
          { usb.allOf = [ "3434:0961" "046d:c548" ]; }
          { lid.closed = true; }
        ];
      };
      outputs = {
        ${internal.identifier} = cfg.internalOutput // { disabled = true; };
        ${homeOfficeDisplay} = externalOutput 0.0;
      };
    }

    {
      name = "Alfie Office";
      match = {
        and = [
          { displays.connectedAnyOf = [ homeOfficeDisplay ]; }
          { usb.noneOf = [ "046d:c548" ]; }
        ];
      };
      outputs = {
        ${internal.identifier} = cfg.internalOutput // { disabled = true; };
        ${homeOfficeDisplay} = externalOutput 0.0;
      };
    }

    {
      name = "Undocked";
      outputs = {
        ${internal.identifier} = cfg.internalOutput;
      };
    }
  ];
in
{
  options.my.dankMaterialShell.monitors.internalDisplay = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        identifier = mkOption {
          type = types.str;
          default = "eDP-1";
          description = "The laptop's internal display identifier.";
        };
        width = mkOption { type = types.int; };
        height = mkOption { type = types.int; };
        freq = mkOption { type = types.str; };
      };
    });
    default = null;
    description = "Specification used by the standard laptop monitor profiles.";
  };

  options.my.dankMaterialShell.monitors.internalOutput = mkOption {
    type = types.attrs;
    readOnly = true;
    description = "Generated output configuration for the internal display.";
  };

  config = mkIf (internal != null) {
    my.dankMaterialShell.monitors = {
      internalOutput = generatedInternalOutput;
      configurations = standardProfiles;
    };
  };
}
