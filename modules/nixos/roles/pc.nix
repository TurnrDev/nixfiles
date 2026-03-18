# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, ... }:

{
  imports =
    [
      ./default.nix
    ];

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "colemak";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # COLOURS
  stylix.enable = true;
  stylix.base16Scheme = ../../../themes/material-you-teal-dark.yaml;
  stylix.fonts = {
    serif = {
      package = pkgs.noto-fonts;
      name = "Noto Serif";
    };
    sansSerif = {
      package = pkgs.noto-fonts;
      name = "Noto Sans";
    };
    monospace = {
      package = pkgs.nerd-fonts.fira-code;
      name = "FiraCode Nerd Font Mono";
    };
    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
    sizes = {
      applications = 12;
      desktop = 11;
      popups = 12;
      terminal = 12;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jay = {
    isNormalUser = true;
    description = "Jay";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  programs.kdeconnect.enable = true;

  programs.git = {
    enable = true;
    config = {
      user.name = "Jay Turner";
      user.email = "jaynicholasturner@gmail.com";
      init.defaultBranch = "main";
    };
  };
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  programs.foot = {
    enable = true;
    settings = {
      main = {
        shell = "zsh";
        font = "FiraCode Nerd Font Mono";
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vscode
    gitkraken
  ];


  fonts = {
    packages = [
      pkgs.noto-fonts
      pkgs.noto-fonts-color-emoji
      pkgs.nerd-fonts.fira-code
      pkgs.font-awesome
    ];
  };

}
