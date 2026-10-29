{ lib, pkgs, ... }:

let
  secretService = pkgs.writeTextDir "share/dbus-1/services/org.freedesktop.secrets.service" ''
    [D-BUS Service]
    Name=org.freedesktop.secrets
    Exec=${lib.getExe' pkgs.kdePackages.kwallet "ksecretd"}
  '';

  # NixOS imports packaged user units from lib/systemd/user, while KWallet
  # installs this unit in share/systemd/user.
  pamSystemd = pkgs.runCommand "kwallet-pam-systemd" { } ''
    mkdir -p $out/lib/systemd/user
    ln -s ${pkgs.kdePackages.kwallet-pam}/share/systemd/user/plasma-kwallet-pam.service \
      $out/lib/systemd/user/plasma-kwallet-pam.service
  '';
in
{
  services.dbus.packages = [
    pkgs.kdePackages.kwallet
    secretService
  ];

  xdg.portal.config = {
    common."org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
    hyprland."org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
  };

  # greetd delegates authentication and session setup to the login PAM stack.
  # Its own custom rules disable automatic module generation, so attaching this
  # to greetd would never emit pam_kwallet5.  Put it on login instead, where it
  # receives the password from Dux's graphical login flow.
  security.pam.services.login.kwallet = {
    enable = true;
    forceRun = true;
  };

  systemd.packages = [ pamSystemd ];
  systemd.user.services.plasma-kwallet-pam = {
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
  };

  environment.systemPackages = [ pkgs.kdePackages.kwalletmanager ];
}
