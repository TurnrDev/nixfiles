{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/roles/desktop.nix
    ../../modules/home-manager/hardware/amd.nix
  ];

  my.dankMaterialShell.monitors.configurations = [
    {
      name = "Default";

      outputs = {
        "DP-2" = {
          mode = "5120x1440@240";

          position = {
            x = 0;
            y = 0;
          };

          scale = 1.0;
        };
      };
    }
  ];

}
