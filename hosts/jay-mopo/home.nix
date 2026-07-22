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
    ./google-drive.nix
  ];

  my.dankMaterialShell.monitors.internalDisplay = {
    width = 2880;
    height = 1800;
    freq = "90.001";
  };

  my.dankMaterialShell.monitors.configurations = lib.mkBefore [
    {
      name = "Docked Work";

      match = {
        and = [
          {
            displays.connectedAllOf = [
              "DP-5"
              "DP-7"
            ];
          }
          {
            usb.allOf = [
              "258a:003a"
              "05e3:0625"
              "05e3:0610"
              "05e3:0608"
            ];
          }
        ];
      };

      outputs = {
        ${config.my.dankMaterialShell.monitors.internalDisplay.identifier} =
          config.my.dankMaterialShell.monitors.internalOutput // {
            scale = 1.5;
          };

        "DP-5" = {
          mode = "1920x1200@59.950";
          position = { x = 1920; y = 0; };
          scale = 1.0;
        };

        "DP-7" = {
          mode = "1920x1200@59.950";
          position = { x = 3840; y = 0; };
          scale = 1.0;
        };
      };
    }
  ];

  programs.dank-material-shell.settings.customThemeFile =
    lib.mkForce "/etc/nixos/modules/home-manager/common/dms/themes/mopo.json";
}
