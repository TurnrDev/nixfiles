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

  edmcoverlay2 = pkgs.stdenv.mkDerivation {
    pname = "edmcoverlay2";
    version = "unstable";
    src = inputs.edmcoverlay2;

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    buildInputs = [
      pkgs.gtk4
      pkgs.gtk4-layer-shell
      pkgs.python3Packages.pygobject3
      pkgs.libx11
      pkgs.libxcomposite
      pkgs.libxext
      pkgs.libxfixes
    ];

    buildPhase = ''
      runHook preBuild
      make
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/edmcoverlay"
      cp -r . "$out/edmcoverlay"

      chmod +x "$out/edmcoverlay/overlay"

      mv "$out/edmcoverlay/Wayland/main.py" "$out/edmcoverlay/Wayland/main.py.real"
      makeWrapper ${pkgs.python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python "$out/edmcoverlay/Wayland/main.py" \
        --add-flags "$out/edmcoverlay/Wayland/main.py.real" \
        --prefix GI_TYPELIB_PATH : "${pkgs.lib.makeSearchPath "lib/girepository-1.0" [
          pkgs.gtk4
          pkgs.gtk4-layer-shell
        ]}" \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [
          pkgs.gtk4
          pkgs.gtk4-layer-shell
        ]}" \
        --prefix XDG_DATA_DIRS : "${pkgs.gtk4}/share:${pkgs.gtk4-layer-shell}/share"

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

  home.file.".local/share/EDMarketConnector/plugins/edmcoverlay".source =
    "${edmcoverlay2}/edmcoverlay";
}
