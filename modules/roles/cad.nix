_:

{
  flake.modules.nixos.role-cad =
    {
      config,
      pkgs,
      ...
    }:

    {
      environment.systemPackages = with pkgs; [
        openscad
        prusa-slicer
      ];

      services.syncthing.settings.folders."PrusaSlicer" = {
        path = "${config.my.users.jay.homeDirectory}/.config/PrusaSlicer/";
        devices = config.my.syncthing.personalDeviceList ++ config.my.syncthing.workDeviceList;
        versioning = {
          type = "simple";
          params.keep = "10";
        };
      };
    };
}
