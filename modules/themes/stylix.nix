{ inputs, ... }:

{
  flake.modules.nixos.theme-stylix =
    { lib, pkgs, ... }:

    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      # System-wide Stylix complements the Home Manager configuration: it owns
      # TTY, boot, display-manager, GTK/Qt, and font integration where those
      # targets are configured at the NixOS layer.
      stylix = {
        enable = true;
        autoEnable = true;
        # Dolphin's Qt/Kvantum integration remains unreliable outside Plasma.
        # Leave Qt to its native styling rather than mixing incompatible palettes.
        targets.qt.enable = false;
        polarity = "dark";
        base16Scheme = lib.mkDefault ./themes/trainerdex.yaml;
        image = ./wallpapers/geometric-dual-monitor.png;

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
      };
    };

  flake.modules.homeManager.theme-stylix =
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
    };
}
