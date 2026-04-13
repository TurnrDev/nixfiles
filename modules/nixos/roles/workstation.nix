# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, lib, pkgs, ... }:

let
  dmsPackages = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports =
    [
      ./default.nix
    ];

  my.backups.borgmatic.extraExcludePatterns = lib.mkAfter [
    "${config.my.identity.homeDirectory}/.config/Code"
    "${config.my.identity.homeDirectory}/.config/GitKraken"
    "${config.my.identity.homeDirectory}/.gitkraken"
    "${config.my.identity.homeDirectory}/.vscode"
    "${config.my.identity.homeDirectory}/.vscode-server"
  ];

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = false;
  # Use Hyprland's built-in UWSM session and let DMS remember whichever
  # session was chosen last, while still defaulting system-side to UWSM.
  services.displayManager = {
    defaultSession = "hyprland-uwsm";
    dms-greeter = {
      enable = true;
      package = dmsPackages.default;
      configHome = config.my.identity.homeDirectory;
      quickshell.package = dmsPackages.quickshell;
      compositor = {
        name = "hyprland";
        customConfig = ''
          env = DMS_RUN_GREETER,1

          misc {
              disable_hyprland_logo = true
              disable_splash_rendering = true
          }

          input {
              kb_layout = gb
              kb_variant = colemak
          }
        '';
      };
    };
  };
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "colemak";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Define workstation-specific groups and packages for the shared user.
  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      packages = with pkgs; [];
    };
  };

  programs.kdeconnect.enable = true;

  programs.git = {
    enable = true;
    config = {
      core.excludesFile = "/etc/gitignore";
      init.defaultBranch = "main";
    };
  };

  environment.etc."gitignore".text = ''
    .codex
  '';

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
    nerd-fonts.fira-code
    prusa-slicer
  ];


  fonts = {
    packages = [
      pkgs.font-awesome
    ];
  };

  virtualisation.docker.enable = true;
}
