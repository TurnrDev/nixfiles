{ config, inputs, pkgs, ... }:

{
  imports = [
    ./default.nix
    inputs.nixcord.homeModules.nixcord
    ../common/firefox.nix
    ../common/fuzzel/fuzzel.nix
    ../common/hyprland/hyprland.nix
    ../common/hypridle.nix
    ../common/hyprlock/hyprlock.nix
    ../common/kdeconnect.nix
    ../common/quickshell/quickshell.nix
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
}
