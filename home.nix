{ config, inputs, pkgs, ... }:

{
  imports = [
    inputs.nixcord.homeModules.nixcord
    ./modules/home-manager/common/fuzzel/fuzzel.nix
    ./modules/home-manager/common/hyprland/hyprland.nix
    ./modules/home-manager/common/hyprlock/hyprlock.nix
    ./modules/home-manager/common/waybar/waybar.nix
    ./modules/home-manager/common/zsh.nix

  ];

  programs.nixcord = {
    enable = true;  # enable Nixcord. Also installs discord package
    config = {
      enabledThemes = [
        "stylix.theme.css"
      ];
    #   frameless = true; # set some Vencord options
      plugins = {
        alwaysTrust.enable = true;
        ClearURLs.enable = true;  
        copyFileContents.enable = true;
        CustomRPC.enable = true;
        forceOwnerCrown.enable = true;
        imageZoom.enable = true;
        memberCount.enable = true;
        messageLinkEmbeds.enable = true;
        messageLogger.enable = true;
        noF1.enable = true;
        permissionsViewer.enable = true;
        PinDMs.enable = true;
        previewMessage.enable = true;
        serverInfo.enable = true;
        showHiddenChannels.enable = true;
        unlockedAvatarZoom.enable = true;
        viewRaw.enable = true;
        voiceDownload.enable = true;
        webScreenShareFixes.enable = true;
        whoReacted.enable = true;
      };
    };
  };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "jay";
  home.homeDirectory = "/home/jay";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
