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
      name = "Docked Work";

      outputs = {
        "eDP-1" = {
          mode = "2880x1800@90.001";

          scale = 1.5;
          disabled = false;
        };

        "DP-5" = {
          mode = "1920x1200@59.950";

          position = {
            x = 1920;
            y = 0;
          };

          scale = 1.0;
        };

        "DP-7" = {
          mode = "1920x1200@59.950";

          position = {
            x = 3840;
            y = 0;
          };

          scale = 1.0;
        };
      };
    }
    {
      name = "Docked Home Office with Inbuilt Display";

      outputs = {
        "eDP-1" = {
          mode = "2880x1800@90.001";

          scale = 1.0;
          disabled = false;
        };

        "desc:Samsung Electric Company LC49G95T H1AK500000" = {
          mode = "preferred";

          position = {
            x = 2880;
            y = 0;
          };

          scale = 1.0;
        };
      };
    }

    {
      name = "Docked Home Office w/o Inbuilt Display";

      outputs = {
        "eDP-1" = {
          mode = "2880x1800@90.001";

          scale = 1.0;
          disabled = true;
        };
        
        "desc:Samsung Electric Company LC49G95T H1AK500000" = {
          mode = "preferred";

          position = {
            x = 2880;
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
          mode = "2880x1800@90.001";

          scale = 1.0;
          disabled = false;
        };
      };
    }
  ];

  programs.dank-material-shell.settings.customThemeFile = lib.mkForce "/etc/nixos/modules/home-manager/common/dms/themes/mopo.json";

}
