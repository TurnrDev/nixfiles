{
  lib,
  stdenv,
  coreutils,
  fetchurl,
  autoPatchelfHook,
  copyDesktopItems,
  jdk21,
  makeDesktopItem,
  makeWrapper,
  unzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "elite-intel";
  version = "1.0.0022";

  src = fetchurl {
    url = "https://github.com/stone-alex/EliteIntel/releases/download/v-${finalAttrs.version}/elite_intel_-${finalAttrs.version}.zip";
    hash = "sha256-3w8ThF8aCiA3pFdoBhzQKpYyWy5lMVqd9aO9+3djeZA=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
    unzip
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    unzip "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -d "$out/bin" "$out/share/elite-intel" "$out/share/pixmaps"
    cp -r . "$out/share/elite-intel"

    unzip -p elite_intel.jar images/elite-logo.png \
      > "$out/share/pixmaps/elite-intel.png"

    makeWrapper ${jdk21}/bin/java "$out/bin/elite-intel" \
      --set _JAVA_AWT_WM_NONREPARENTING "1" \
      --set ELITE_INTEL_DATA_DIR "$out/share/elite-intel" \
      --set-default DISPLAY ":0" \
      --prefix LD_LIBRARY_PATH : "$out/share/elite-intel/native/sherpa-onnx" \
      --run 'runtime_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/elite-intel"' \
      --run '${coreutils}/bin/mkdir -p "$runtime_dir/logs"' \
      --run '${coreutils}/bin/ln -sfn "$ELITE_INTEL_DATA_DIR/credits.md" "$runtime_dir/credits.md"' \
      --run '${coreutils}/bin/ln -sfn "$ELITE_INTEL_DATA_DIR/user-manual.md" "$runtime_dir/user-manual.md"' \
      --run 'cd "$runtime_dir"' \
      --add-flags "-Xmx6g" \
      --add-flags "-Djava.library.path=$out/share/elite-intel/native/sherpa-onnx" \
      --add-flags "-jar $out/share/elite-intel/elite_intel.jar"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "elite-intel";
      desktopName = "Elite Intel";
      comment = "AI companion for Elite Dangerous";
      exec = "elite-intel";
      icon = "elite-intel";
      categories = [
        "Game"
        "Utility"
      ];
    })
  ];

  meta = {
    description = "AI companion and data analyst for Elite Dangerous";
    homepage = "https://github.com/stone-alex/EliteIntel";
    changelog = "https://github.com/stone-alex/EliteIntel/releases/tag/v-${finalAttrs.version}";
    license = lib.licenses.cc-by-nc-sa-40;
    mainProgram = "elite-intel";
    platforms = [ "x86_64-linux" ];
  };
})
