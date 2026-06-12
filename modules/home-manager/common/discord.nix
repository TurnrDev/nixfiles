{
  identity,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  my.backups.borgmatic.moduleExcludePatterns = lib.mkAfter [
    "${identity.homeDirectory}/.config/discord"
  ];

  programs.nixcord = {
    enable = true;
    config = {
      plugins = {
        alwaysTrust.enable = true;
        clearUrls.enable = true;
        copyFileContents.enable = true;
        customRpc.enable = true;
        forceOwnerCrown.enable = true;
        imageZoom.enable = true;
        memberCount.enable = true;
        messageLinkEmbeds.enable = true;
        messageLogger.enable = true;
        noF1.enable = true;
        permissionsViewer.enable = true;
        pinDms.enable = true;
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

  wayland.windowManager.hyprland.settings = {
    "exec-once" = lib.mkAfter [
      "[workspace 9 silent] uwsm app -- discord"
    ];

    windowrule = lib.mkAfter [
      {
        name = "workspace-discord";
        "match:initial_class" = "^([dD]iscord)$";
        workspace = "9";
      }
    ];
  };
}
