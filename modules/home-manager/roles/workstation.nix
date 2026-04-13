{ identity, inputs, lib, pkgs, ... }:

{
  imports = [
    ./default.nix
    inputs.nixcord.homeModules.nixcord
    ../common/firefox.nix
    ../common/hyprland/hyprland.nix
    ../common/kdeconnect.nix
    ../common/spotify.nix
  ];

  my.backups.borgmatic.moduleExcludePatterns = lib.mkAfter [
    "${identity.homeDirectory}/.config/discord"
  ];
  
  home.packages = with pkgs; [
    grimblast
    dotnetCorePackages.dotnet_9.sdk # For Godot-Mono VSCode-Extension CSharp
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

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default = {
      userSettings = {
        "dotnetAcquisitionExtension.existingDotnetPath" = [
          {
            "extensionId" = "ms-dotnettools.csharp";
            "path" = "${pkgs.dotnet-sdk_9}/bin";
          }
          {
            "extensionId" = "ms-dotnettools.csdevkit";
            "path" = "${pkgs.dotnet-sdk_9}/bin";
          }
          {
            "extensionId" = "woberg.godot-dotnet-tools";
            "path" = "${pkgs.dotnet-sdk_8}/bin"; # Godot-Mono uses DotNet8 version.
          }
        ];
        "godotTools.lsp.serverPort" = 6005; # port should match your Godot configuration
      };
      extensions = with pkgs.vscode-extensions; [
        geequlim.godot-tools # For Godot GDScript support
        woberg.godot-dotnet-tools # For Godot C# support
        ms-dotnettools.csdevkit
        ms-dotnettools.csharp
        ms-dotnettools.vscode-dotnet-runtime
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        { name = "godot-files";
          publisher = "alfish";
          version = "0.1.6";
          sha256 = "sha256-FFtl1QXSa4nGKFUJh5f3R7AV7hZg59Qs5vBZHgSUCUw=";
        }
      ];
    };
  };
}
