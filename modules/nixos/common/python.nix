{ pkgs, ... }:

{
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
    uv
    ruff
    (python3.withPackages (
      ps: with ps; [
        requests
        virtualenv
      ]
    ))
  ];
}
