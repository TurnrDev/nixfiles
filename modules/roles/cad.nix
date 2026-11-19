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

      services.syncthing.settings.folders = {
        "3D Printing" = {
          path = "${config.my.users.jay.homeDirectory}/3D Printing/";
          devices = config.my.syncthing.personalDeviceList ++ config.my.syncthing.workDeviceList;
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
        "PrusaSlicer" = {
          path = "${config.my.users.jay.homeDirectory}/.config/PrusaSlicer/";
          devices = config.my.syncthing.personalDeviceList ++ config.my.syncthing.workDeviceList;
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
      };
    };
}
