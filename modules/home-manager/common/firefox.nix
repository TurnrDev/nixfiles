{ config, pkgs, ... }:

{
  programs.firefox = {
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    enable = true;
    nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];
  };

  stylix.targets.firefox.profileNames = [ "default" ];
}
