{ inputs, ... }:

{
  imports = [
    ./default.nix
    ../common/default-apps.nix
    ../common/discord.nix
    inputs.dockmgr.homeManagerModules.default
    ../common/firefox.nix
    ../common/go-hass-agent.nix
    ../common/hyprland/hyprland.nix
    ../common/kdeconnect.nix
    ../common/spotify.nix
    ../common/stylix.nix
  ];

  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
  };
}
