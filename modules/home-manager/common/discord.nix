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
    discord.vencord.enable = true;
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
        unlockedAvatarZoom.enable = true;
        viewRaw.enable = true;
        voiceDownload.enable = true;
        webScreenShareFixes.enable = true;
        whoReacted.enable = true;
      };
    };
  };

}
