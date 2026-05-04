{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    prismlauncher
  ];

  services.syncthing.settings.folders."PrismLauncher" = {
    path = "${config.my.identity.homeDirectory}/.local/share/PrismLauncher/";
    devices = [ "home-server" "jay-framework" "jay-desktop" ];
    versioning = {
      type = "simple";
      params.keep = "10";
    };
  };
}
