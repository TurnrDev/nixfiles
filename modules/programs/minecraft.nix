_:

{
  flake.modules.nixos.program-minecraft =
    { config, pkgs, ... }:

    {
      environment.systemPackages = with pkgs; [
        prismlauncher
      ];

      services.syncthing.settings.folders."PrismLauncher" = {
        path = "${config.my.users.jay.homeDirectory}/.local/share/PrismLauncher/";
        devices = config.my.syncthing.personalDeviceList;
        versioning = {
          type = "simple";
          params.keep = "10";
        };
      };
    };
}
