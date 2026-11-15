{ inputs, ... }:

{
  flake.modules.nixos.desk-home =
    { config, lib, ... }:
    let
      internal = lib.attrByPath [ "my" "displays" "internal" ] null config;
      display = "desc:Samsung Electric Company LC49G95T H1AK500000";
      externalOutput = x: {
        mode = "5120x1440@59.977";
        position = {
          inherit x;
          y = 0;
        };
        scale = 1.0;
      };
    in
    {
      imports = with inputs.self.modules.nixos; [
        hardware-keyboard-Keychron-v6-max
        hardware-mouse-logitech-mx-master-3s
      ];

      programs.dockmgr.profiles = lib.mkIf (internal != null) [
        {
          name = "Docked Home Office with Inbuilt Display";
          match.and = [
            { displays.connectedAnyOf = [ display ]; }
            {
              usb.allOf = [
                "3434:0961"
                "046d:c548"
              ];
            }
            { lid.closed = false; }
          ];
          outputs = {
            ${internal.identifier} = config.my.displays.internalOutput;
            ${display} = externalOutput internal.width;
          };
        }
        {
          name = "Docked Home Office w/o Inbuilt Display";
          match.and = [
            { displays.connectedAnyOf = [ display ]; }
            {
              usb.allOf = [
                "3434:0961"
                "046d:c548"
              ];
            }
            { lid.closed = true; }
          ];
          outputs = {
            ${internal.identifier} = config.my.displays.internalOutput // {
              disabled = true;
            };
            ${display} = externalOutput 0;
          };
        }
      ];
    };
}
