# OBOJIMA GLYPH
# by 1985 Games Inc © 2026.
# V.1.0
# _____________________________________________________________________________
# This font is free for PERSONAL USE ONLY.
# IT IS NOT AVAILABLE FOR COMMERCIAL USE!
# _____________________________________________________________________________
# info@1985games.com
# www.1985games.com
# www.obojima.com
{
  config,
  lib,
  pkgs,
  ...
}:

let
  secretName = "obojima-glyph";
  # Fontconfig applications (including GIMP and LibreOffice) list this as
  # “Obojima Glyphs_update_glyphfont”, not the filename or directory name.
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
      # Run as the desktop user so fc-cache updates the cache GIMP reads.
      User = config.my.identity.username;
    };

    script = ''
      install -d -m 0755 ${lib.escapeShellArg fontDirectory}
      install -m 0644 \
        ${lib.escapeShellArg config.sops.secrets.${secretName}.path} \
        ${lib.escapeShellArg fontPath}
      ${pkgs.fontconfig}/bin/fc-cache -f ${lib.escapeShellArg fontDirectory}
    '';
  };
}
