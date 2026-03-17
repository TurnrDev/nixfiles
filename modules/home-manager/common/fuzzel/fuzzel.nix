{ config, pkgs, lib, ... }:

{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = lib.mkForce "${config.stylix.fonts.sansSerif.name}:size=25";
        lines = 8;
        line-height = 30;
        width = 20;
        terminal = "foot";
      };
    };
  };
}
