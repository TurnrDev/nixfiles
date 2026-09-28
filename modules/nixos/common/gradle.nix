{ pkgs, ... }:

{
  programs.java = {
    enable = true;
    package = pkgs.jdk;
  };

  environment.systemPackages = with pkgs; [
    gradle
  ];

  environment.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk}";
  };
}
