{
  config,
  lib,
  pkgs,
  ...
}:

let
  secretName = "obojima-glyph";
  fontDirectory = "${config.my.identity.homeDirectory}/.local/share/fonts/Obojima Glyph";
  fontPath = "${fontDirectory}/ObojimaGlyphs-Regular.ttf";
in
{
  sops.secrets.${secretName} = {
    sopsFile = ../../../secrets/obojima-glyph.ttf.json;
    format = "binary";
    owner = config.my.identity.username;
    group = "users";
    mode = "0444";
    restartUnits = [ "install-obojima-glyph-font.service" ];
  };

  systemd.services.install-obojima-glyph-font = {
    description = "Install the Obojima Glyph font for ${config.my.identity.username}";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };

    script = ''
      install -d -m 0755 -o ${lib.escapeShellArg config.my.identity.username} -g users \
        ${lib.escapeShellArg fontDirectory}
      install -m 0644 -o ${lib.escapeShellArg config.my.identity.username} -g users \
        ${lib.escapeShellArg config.sops.secrets.${secretName}.path} \
        ${lib.escapeShellArg fontPath}
      ${pkgs.fontconfig}/bin/fc-cache -f ${lib.escapeShellArg fontDirectory}
    '';
  };
}
