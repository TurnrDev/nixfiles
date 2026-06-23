{ pkgs, inputs, ... }:

let

  edmcDiscordPresence = pkgs.stdenvNoCC.mkDerivation {
    pname = "edmc-discord-presence";
    version = "unstable";
    src = inputs.edmc-discord-presence;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -r "$src" "$out/DiscordPresence"

      runHook postInstall
    '';
  };
in
{
  home.packages = [
    pkgs.edmarketconnector
  ];

  home.file.".local/share/EDMarketConnector/plugins/DiscordPresence".source =
    "${edmcDiscordPresence}/DiscordPresence";

  wayland.windowManager.hyprland.settings.windowrule = [
    {
      name = "float-edmarketconnector";
      "match:initial_class" = "^(Edmarketconnector)$";

      float = "on";
      opacity = "0.8";
    }
  ];
}
