{
  alsa-lib,
  buildFHSEnv,
  fetchurl,
  fontconfig,
  freetype,
  icu,
  krb5,
  lib,
  libGL,
  libice,
  libsm,
  libx11,
  libxcursor,
  libxext,
  libxi,
  libxkbcommon,
  libxrandr,
  makeDesktopItem,
  openssl,
  pulseaudio,
  stdenvNoCC,
  udev,
  vulkan-loader,
  wayland,
}:

let
  pname = "sharpemu";
  # renovate: datasource=github-release-attachments depName=sharpemu/sharpemu versioning=loose
  releaseTag = "v0.0.6-mono";
  version = lib.removePrefix "v" releaseTag;
  unwrapped = stdenvNoCC.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://github.com/sharpemu/sharpemu/releases/download/${releaseTag}/sharpemu-${version}-linux-x64.tar.gz";
      sha256 = "dc7edfaa983bb40c6f4022faa2ca2eb4c6f831f8b297f10d2e3c132099137f57";
    };

    sourceRoot = ".";
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/sharpemu
      cp -r . $out/lib/sharpemu/

      runHook postInstall
    '';
  };
  runtimeDependencies = [
    alsa-lib
    fontconfig
    freetype
    icu
    krb5
    libGL
    libice
    libsm
    libx11
    libxcursor
    libxext
    libxi
    libxkbcommon
    libxrandr
    openssl
    pulseaudio
    udev
    vulkan-loader
    wayland
  ];
  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "SharpEmu";
    genericName = "PlayStation 5 Emulator";
    comment = "Experimental PlayStation 5 emulator";
    exec = pname;
    icon = "applications-games";
    categories = [
      "Game"
      "Emulator"
    ];
  };
in
buildFHSEnv {
  inherit pname version;

  targetPkgs = _: runtimeDependencies;
  runScript = "${unwrapped}/lib/sharpemu/SharpEmu";

  extraInstallCommands = ''
    install -Dm444 ${desktopItem}/share/applications/${pname}.desktop \
      $out/share/applications/${pname}.desktop
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Experimental PlayStation 5 emulator";
    homepage = "https://sharpemu.app/";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
  };
}
