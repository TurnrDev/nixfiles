{
  appimageTools,
  fetchurl,
  lib,
  libnotify,
  libsecret,
}:

let
  pname = "greenlight";
  # renovate: datasource=github-release-attachments depName=unknownskl/greenlight versioning=semver
  releaseTag = "v2.4.2";
  version = lib.removePrefix "v" releaseTag;
  src = fetchurl {
    url = "https://github.com/unknownskl/greenlight/releases/download/${releaseTag}/Greenlight-${version}.AppImage";
    sha256 = "1ceb56c4b3b348480565f784083e3a4222ad782dd9cb9a0aa8934df070331777";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = _: [
    libnotify
    libsecret
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/greenlight-desktop.desktop \
      $out/share/applications/greenlight-desktop.desktop
    substituteInPlace $out/share/applications/greenlight-desktop.desktop \
      --replace-fail "Exec=AppRun" "Exec=greenlight"
    cp -r ${appimageContents}/usr/share/icons $out/share/
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Xbox and xCloud streaming client";
    homepage = "https://github.com/unknownskl/greenlight";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
  };
}
