{ inputs, ... }:

{
  flake.modules.nixos.desk-azelphur-workbench =
    { config, lib, ... }:
    let
      internal = lib.attrByPath [ "my" "displays" "internal" ] null config;
      display = "desc:Samsung Electric Company LC49G95T H1AK500000";
    in
    {
      imports = with inputs.self.modules.nixos; [
        hardware-mouse-logitech-mx-master-3s
      ];

      programs.dockmgr.profiles = lib.mkIf (internal != null) [
        {
          name = "Azelphur Workbench";
          match.and = [
            { displays.connectedAnyOf = [ display ]; }
            { usb.noneOf = [ "046d:c548" ]; }
          ];
          outputs = {
            ${internal.identifier} = config.my.displays.internalOutput // {
              disabled = true;
            };
            ${display} = {
              mode = "5120x1440@59.977";
              position = {
                x = 0;
                y = 0;
              };
              scale = 1.0;
            };
          };
        }
      ];
    };
}
