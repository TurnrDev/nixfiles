{
  lib,
  pkgs,
  repoLib,
  ...
}:

let
  # uv-override # remove-begin; delete packages/uv/default.nix
  uvPatched = pkgs.callPackage ../../../packages/uv { };
  # uv-override # remove-end
  # pip-override # remove-begin
  pipPatched = pkgs.python3Packages.pip.overridePythonAttrs (
    _finalAttrs: _previousAttrs: {
      version = "26.2.2";
      src = pkgs.fetchFromGitHub {
        owner = "pypa";
        repo = "pip";
        tag = "26.2.2";
        hash = "sha256-iH5O1kneYzoHpzbfgrJc/8gVr57CNX3/xpwel4ueNqE=";
      };
    }
  );
  # pip-override # remove-end
in
{
  warnings =
    # uv-override # remove
    lib.optional (lib.versionAtLeast pkgs.uv.version "0.13.4")
      "nixos-unstable now provides uv 0.13.4 or later; remove # uv-override."
    # pip-override # remove
    ++ lib.optional (lib.versionAtLeast pkgs.python3Packages.pip.version "26.2.2") "nixos-unstable now provides pip 26.2.2 or later; remove # pip-override.";

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      bzip2
      curl
      expat
      libffi
      libxcrypt-legacy
      ncurses
      openssl
      readline
      sqlite
      stdenv.cc.cc
      util-linux
      xz
      zlib
      zstd
    ];
  };

  environment.systemPackages = with pkgs; [
    (repoLib.versionAtLeastOrLocal uv "0.13.4" uvPatched) # uv-override # uv
    ruff
    (python3.withPackages (
      ps: with ps; [
        (repoLib.versionAtLeastOrLocal pip "26.2.2" pipPatched) # pip-override # pip
        requests
        virtualenv
      ]
    ))
    gettext
  ];
}
