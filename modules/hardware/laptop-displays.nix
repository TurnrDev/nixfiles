_:

{
  flake.modules.nixos.hardware-laptop-displays =
    { config, lib, ... }:
    let
      cfg = config.my.displays;
      inherit (cfg) internal;
    in
    {
      options.my.displays = {
        internal = lib.mkOption {
          default = null;
          description = "Laptop panel used by docking profiles and the undocked fallback.";
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                identifier = lib.mkOption {
                  type = lib.types.str;
                  default = "eDP-1";
                };
                width = lib.mkOption { type = lib.types.int; };
                height = lib.mkOption { type = lib.types.int; };
                freq = lib.mkOption { type = lib.types.str; };
              };
            }
          );
        };
        internalOutput = lib.mkOption {
          type = lib.types.attrs;
          readOnly = true;
          description = "Dockmgr output configuration derived from the internal panel.";
          default =
            if internal == null then
              { }
            else
              {
                mode = "${toString internal.width}x${toString internal.height}@${internal.freq}";
                position = {
                  x = 0;
                  y = 0;
                };
                scale = 1.0;
              };
          defaultText = lib.literalExpression "an output derived from my.displays.internal, or {}";
        };
      };

      config.programs.dockmgr.profiles = lib.mkIf (internal != null) (
        lib.mkAfter [
          {
            name = "Undocked";
            outputs.${internal.identifier} = cfg.internalOutput;
            disableUnspecifiedOutputs = false;
          }
        ]
      );
    };
}
