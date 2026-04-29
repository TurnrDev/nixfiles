# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, lib, pkgs, ... }:

let
  dmsPackages = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system};
  gitkrakenPackage = (import inputs.nixpkgs-gitkraken {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "gitkraken" ];
  }).gitkraken;
  dmsGreeterCacheDir = "/var/lib/dms-greeter";
in
{
  imports =
    [
      ./default.nix
      ../services/dms-home-assistant-monitor.nix
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
      # Reuse the same DMS-managed monitor layout that Hyprland sources at runtime.
      configFiles = [ "${config.my.identity.homeDirectory}/.config/hypr/dms/outputs.conf" ];
      quickshell.package = dmsPackages.quickshell;
      compositor = {
        name = "hyprland";
        customConfig = ''
          env = DMS_RUN_GREETER,1
          source = ${dmsGreeterCacheDir}/outputs.conf

          misc {
              disable_hyprland_logo = true
              disable_splash_rendering = true
          }

          input {
              kb_layout = gb
              kb_variant = colemak
              numlock_by_default = true
          }
        '';
      };
    };
  };
  systemd.services.greetd.preStart = lib.mkAfter ''
    if [ ! -f ${dmsGreeterCacheDir}/outputs.conf ]; then
        : > ${dmsGreeterCacheDir}/outputs.conf
        chown dms-greeter:dms-greeter ${dmsGreeterCacheDir}/outputs.conf
    fi
  '';
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
      extraGroups = [ "networkmanager" "wheel" ];
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
    android-studio
    cameractrls-gtk4
    dbeaver-bin
    gh
    ghostty
    gimp
    gitkrakenPackage
    josm
    nerd-fonts.fira-code
    openscad
    prusa-slicer
    vlc
    vscode
  ];

  fonts = {
    packages = [
      pkgs.font-awesome
    ];
  };
}
