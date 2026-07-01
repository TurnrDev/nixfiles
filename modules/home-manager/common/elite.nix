{ pkgs, inputs, ... }:

let

in
{
  home.packages = [
    pkgs.edmarketconnector
  ];
}
