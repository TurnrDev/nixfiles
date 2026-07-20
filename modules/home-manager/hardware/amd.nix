{
  lib,
  pkgs,
  ...
}:

{
  programs.btop.package = lib.mkForce pkgs.btop-rocm;
}
