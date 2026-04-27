{ pkgs, ... }:

let
  jdk = pkgs.jdk;
in
{
  programs.java = {
    enable = true;
    package = jdk;
  };

  environment.systemPackages = with pkgs; [
    gradle
  ];

  environment.sessionVariables = {
    JAVA_HOME = "${jdk}";
  };
}
