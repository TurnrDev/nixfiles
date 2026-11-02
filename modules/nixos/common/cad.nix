{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    openscad
    prusa-slicer
  ];
}
