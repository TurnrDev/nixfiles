{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    prismlauncher
  ];

  services.syncthing.settings.folders."PrismLauncher" = {
    path = "${config.my.identity.homeDirectory}/.local/share/PrismLauncher/";
    devices = config.my.syncthing.personalDeviceList;
    versioning = {
      type = "simple";
      params.keep = "10";
    };
  };
}
