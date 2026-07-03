{ inputs, ... }:

{
  imports = [
    ./default.nix
    inputs.stylix.homeModules.stylix
    ../common/default-apps.nix
    ../common/discord.nix
    ../common/firefox.nix
    ../common/go-hass-agent.nix
    ../common/hyprland/hyprland.nix
    ../common/kdeconnect.nix
    ../common/spotify.nix
  ];

  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
  };
}
