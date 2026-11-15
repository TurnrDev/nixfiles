_:

{
  flake.modules.nixos.role-python-development =
    {
      pkgs,
      ...
    }:

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
            pip
            requests
            virtualenv
          ]
        ))
        gettext
      ];
    };

  flake.modules.homeManager.role-python-development = {
    # `uv tool install` places executables in ~/.local/bin by default.
    home.sessionPath = [ "$HOME/.local/bin" ];
  };
}
