{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
  ];

  my.dankMaterialShell.monitors.configurations = [
    {
      name = "Docked Home Office with Inbuilt Display";

      # match = {
      #   and = [
      #     {
      #       displays.connectedAnyOf = [
      #         "desc:Samsung Electric Company LC49G95T H1AK500000" 
      #         "desc:Samsung Electric Company LC49G95T"
      #          ];
      #     }
      #     {
      #       usb.anyOf = [
      #         "3434:0961"
      #         "046d:c548"
      #       ];
      #     }
      #     {
      #       lid.closed = false;
      #     }
      #   ];
      # };

      outputs = {
        "eDP-1" = {
          mode = "2256x1504@59.999";

          scale = 1.0;
          disabled = false;
        };

        "desc:Samsung Electric Company LC49G95T H1AK500000" = {
          mode = "preferred";

          position = {
            x = 2256;
            y = 0;
          };

          scale = 1.0;
        };
      };
    }

    {
      name = "Docked Home Office w/o Inbuilt Display";

      # match = {
      #   and = [
      #     {
      #       displays.connectedAnyOf = [
      #         "desc:Samsung Electric Company LC49G95T H1AK500000" 
      #         "desc:Samsung Electric Company LC49G95T"
      #          ];
      #     }
      #     {
      #       usb.anyOf = [
      #         "3434:0961"
      #         "046d:c548"
      #       ];
      #     }
      #     {
      #       lid.closed = true;
      #     }
      #   ];
      # };

      outputs = {
        "eDP-1" = {
          mode = "2256x1504@59.999";

          scale = 1.0;
          disabled = true;
        };
        
        "desc:Samsung Electric Company LC49G95T H1AK500000" = {
          mode = "preferred";

          position = {
            x = 2256;
            y = 0;
          };

          scale = 1.0;
        };
        
        "desc:Samsung Electric Company LC49G95T" = {
          mode = "preferred";

          position = {
            x = 2256;
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

          scale = 1.0;
          disabled = false;
        };
      };
    }
  ];

}
