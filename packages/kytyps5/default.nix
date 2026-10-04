{
  alsa-lib,
  autoPatchelfHook,
  brotli,
  copyDesktopItems,
  dbus,
  fetchurl,
  fontconfig,
  freetype,
  glib,
  krb5,
  lib,
  libdrm,
  libglvnd,
  libx11,
  libxcb,
  libxcursor,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxtst,
  makeDesktopItem,
  makeWrapper,
  pulseaudio,
  stdenv,
  stdenvNoCC,
  udev,
  vulkan-loader,
  wayland,
  xcbutil,
  xcbutilcursor,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  zlib,
  zstd,
}:

let
  pname = "kytyps5";
  # renovate: datasource=github-release-attachments depName=KytyPS5/KytyPS5 versioning=loose
  releaseTag = "KytyPS5-2026-10-03-db17585";
  version = lib.removePrefix "KytyPS5-" releaseTag;
  runtimeDependencies = [
    alsa-lib
    brotli
    dbus
    fontconfig
    freetype
    glib
    krb5
    libdrm
    libglvnd
    libx11
    libxcb
    libxcursor
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxtst
    pulseaudio
    udev
    vulkan-loader
    wayland
    xcbutil
    xcbutilcursor
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
    zlib
    zstd
  ];
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/KytyPS5/KytyPS5/releases/download/${releaseTag}/${releaseTag}-Linux-x86_64.tar.gz";
    sha256 = "ed28cbd8677818757d9f108cde9be795ff46f169827f745fd899989745357808";
  };

  sourceRoot = ".";
  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = runtimeDependencies ++ [ stdenv.cc.cc.lib ];

  # Optional SDL/OpenGL ES and Steam integrations are loaded dynamically.
  autoPatchelfIgnoreMissingDeps = [
    "libGLES_CM.so.1"
    "libsteam_api.so"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kytyps5 $out/bin
    cp -r . $out/lib/kytyps5/

    makeWrapper $out/lib/kytyps5/launcher $out/bin/kytyps5 \
      --set QT_PLUGIN_PATH $out/lib/kytyps5/plugins \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies}
    makeWrapper $out/lib/kytyps5/kyty_emulator $out/bin/kyty-emulator \
      --set QT_PLUGIN_PATH $out/lib/kytyps5/plugins \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      desktopName = "KytyPS5";
      genericName = "PlayStation 5 Emulator";
      comment = "Experimental PlayStation 5 emulator";
      exec = pname;
      icon = "applications-games";
      categories = [
        "Game"
        "Emulator"
      ];
    })
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Experimental PlayStation 5 emulator";
    homepage = "https://github.com/KytyPS5/KytyPS5";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
  };
}
