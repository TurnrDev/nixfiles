{ pkgs, ... }:

{
  # The NixOS Stylix module supplies the shared scheme, wallpaper, fonts, and
  # cursor to Home Manager. Keep only Home Manager-specific target choices.
  stylix.targets = {
    qt.enable = false;

    # Rofi is not enabled on any host, and this Stylix target still uses
    # Home Manager's deprecated `programs.rofi.font` option.
    rofi.enable = false;
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
