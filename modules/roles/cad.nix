{ ... }:

{
  flake.modules.nixos.role-cad =
    {
      pkgs,
      ...
    }:

    {
      environment.systemPackages = with pkgs; [
        openscad
        prusa-slicer
      ];
    };
}
