{ ... }:

{
  flake.modules.nixos.service-kdeconnect =
    { ... }:
    {
      programs.kdeconnect.enable = true;
    };

  flake.modules.homeManager.service-kdeconnect =
    { pkgs, ... }:

    {
      services.kdeconnect = {
        enable = true;
        package = pkgs.kdePackages.kdeconnect-kde;
      };
    };
}
