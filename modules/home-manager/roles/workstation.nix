{ pkgs, ... }:

{
  imports = [
    ./default.nix
    ../common/discord.nix
    ../common/firefox.nix
    ../common/hyprland/hyprland.nix
    ../common/kdeconnect.nix
    ../common/spotify.nix
  ];
  
  home.packages = with pkgs; [
    grimblast
  ];
}
