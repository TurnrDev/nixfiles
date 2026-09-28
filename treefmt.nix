{
  projectRootFile = "flake.nix";

  programs = {
    actionlint.enable = true;

    deadnix = {
      enable = true;
      priority = 0;
    };
    statix = {
      enable = true;
      priority = 1;
    };
    nixfmt = {
      enable = true;
      priority = 2;
    };

    ruff-check = {
      enable = true;
      priority = 0;
    };
    ruff-format = {
      enable = true;
      priority = 1;
    };

    shfmt = {
      enable = true;
      priority = 0;
    };
    shellcheck = {
      enable = true;
      priority = 1;
    };

    stylua.enable = true;
  };
}
