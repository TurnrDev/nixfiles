{ inputs, pkgs, ... }:

{
  imports = [
    ./default.nix
    inputs.nixcord.homeModules.nixcord
    ../common/firefox.nix
    ../common/hyprland/hyprland.nix
    ../common/kdeconnect.nix
    ../common/spotify.nix
  ];

  home.packages = with pkgs; [
    grimblast
  ];

  programs.nixcord = {
    enable = true;  # enable Nixcord. Also installs discord package
    config = {
      # frameless = true; # set some Vencord options
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
