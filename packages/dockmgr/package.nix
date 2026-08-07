{
  bash,
  coreutils,
  gawk,
  hyprland,
  jq,
  lib,
  libnotify,
  makeWrapper,
  shellcheck,
  stdenvNoCC,
  util-linux,
}:

let
  version = builtins.head (
    builtins.elemAt (builtins.split ''DOCKMGR_VERSION="([^"]+)"'' (builtins.readFile ./src/dockmgr.sh)) 1
  );
  runtimeInputs = [
    bash
    coreutils
    gawk
    hyprland
    jq
    libnotify
    util-linux
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dockmgr";
  inherit version;
  src = ./src;

  nativeBuildInputs = [
    makeWrapper
    shellcheck
  ];

  doCheck = true;

  installPhase = ''
    install -Dm755 dockmgr.sh "$out/libexec/dockmgr"
    install -Dm444 dockmgr.lua "$out/share/dockmgr/dockmgr.lua"
    makeWrapper "$out/libexec/dockmgr" "$out/bin/dockmgr" \
      --set DOCKMGR_LUA_MODULE "$out/share/dockmgr/dockmgr.lua" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}
  '';

  checkPhase = ''
    runHook preCheck
    bash -n dockmgr.sh
    shellcheck dockmgr.sh
    runHook postCheck
  '';

  meta = {
    description = "Hyprland dock and display profile manager";
    mainProgram = "dockmgr";
  };
})
