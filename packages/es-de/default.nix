{
  appimageTools,
  fetchurl,
}:

let
  pname = "es-de";
  version = "3.4.1";
  src = fetchurl {
    url = "https://gitlab.com/api/v4/projects/es-de%2Femulationstation-de/packages/generic/ES-DE_Stable/${version}/ES-DE_x64.AppImage";
    sha256 = "3c61a44d738d55163daa58ede70720b425a0df62460c04dc23dd3ca586723581";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/org.es_de.frontend.desktop \
      $out/share/applications/org.es_de.frontend.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share/
  '';

  passthru.updateScript = ./update.sh;

  meta.mainProgram = pname;
}
