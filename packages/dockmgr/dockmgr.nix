{
  bash,
  coreutils,
  gawk,
  gnugrep,
  hyprland,
  jq,
  libnotify,
  symlinkJoin,
  systemd,
  util-linux,
  writeShellApplication,
}:

let
  script = builtins.readFile ./dockmgr;
  version = builtins.head (builtins.elemAt (builtins.split ''DOCKMGR_VERSION="([^"]+)"'' script) 1);
  executable = writeShellApplication {
    name = "dockmgr";
    runtimeInputs = [
      bash
      coreutils
      gawk
      gnugrep
      hyprland
      jq
      libnotify
      systemd
      util-linux
    ];
    text = script;
  };
in
(symlinkJoin {
  name = "dockmgr-${version}";
  paths = [ executable ];
  postBuild = ''
    mkdir -p "$out/share/dockmgr"
    ln -s ${./dockmgr.lua} "$out/share/dockmgr/dockmgr.lua"
  '';
}).overrideAttrs
  (
    finalAttrs: previousAttrs: {
      pname = "dockmgr";
      inherit version;
      name = "dockmgr-${version}";
      passthru = (previousAttrs.passthru or { }) // {
        luaModule = "${finalAttrs.finalPackage}/share/dockmgr/dockmgr.lua";
      };
    }
  )
