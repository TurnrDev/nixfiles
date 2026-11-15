_:

{
  flake.modules.homeManager.program-elite-dangerous =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.edmarketconnector
      ];
    };
}
