{ pkgs, ... }:

{
  # The NixOS Stylix module supplies the shared scheme, wallpaper, fonts, and
  # cursor to Home Manager. Keep only Home Manager-specific target choices.
  stylix.targets = {
    dank-material-shell.enable = true;
    firefox.profileNames = [ "default" ];
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
