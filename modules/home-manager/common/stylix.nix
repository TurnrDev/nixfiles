{
  lib,
  pkgs,
  ...
}:

{
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "dark";
    base16Scheme = lib.mkDefault ./stylix/themes/trainerdex.yaml;
    image = ./stylix/wallpapers/geometric-dual-monitor.png;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.source-serif;
        name = "Source Serif 4";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        desktop = 11;
        popups = 11;
        terminal = 12;
      };
    };

    targets = {
      dank-material-shell.enable = true;
      firefox.profileNames = [ "default" ];
    };
  };

  home.pointerCursor.enable = true;

  home.packages = [ pkgs.papirus-icon-theme ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };
}
