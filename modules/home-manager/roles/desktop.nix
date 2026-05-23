{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ./gaming.nix
    ./workstation.nix
  ];
}
