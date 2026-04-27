{ pkgs, ... }:

{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      zstd
      openssl
      curl
      bzip2
      xz
      libffi
      sqlite
      readline
      ncurses
      expat
      util-linux
      libxcrypt-legacy
    ];
  };

  environment.systemPackages = with pkgs; [
    uv
    ruff
    (python3.withPackages (ps: with ps; [
      requests
      virtualenv
    ]))
  ];
}
