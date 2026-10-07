{
  alsa-lib,
  autoPatchelfHook,
  dbus,
  fetchurl,
  lib,
  libGL,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  makeWrapper,
  pname,
  releaseTag,
  sha256,
  stdenv,
  stdenvNoCC,
  vulkan-loader,
  wayland,
  withAlsa ? false,
  xdg-utils,
  description,
}:

let
  version = lib.removePrefix "v" releaseTag;
  runtimeLibraries = [
    dbus
    libGL
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    stdenv.cc.cc.lib
    vulkan-loader
    wayland
  ]
  ++ lib.optional withAlsa alsa-lib;
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/storytold/${pname}/releases/download/${releaseTag}/${pname}-${version}-linux-x86_64.tar.gz";
    inherit sha256;
  };

  sourceRoot = "${pname}-${version}-linux-x86_64";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = runtimeLibraries;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R bin share $out/

    runHook postInstall
  '';

  postFixup = ''
    for program in $out/bin/${pname} $out/bin/${pname}-cli; do
      wrapProgram "$program" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}" \
        --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}"
    done
  '';

  meta = {
    inherit description;
    homepage = "https://getartcraft.com/apps/${pname}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
