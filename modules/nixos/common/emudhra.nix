{
  lib,
  pkgs,
  repoLib,
  ...
}:

{
  # certificate-blacklist # remove-begin
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];
  # certificate-blacklist # remove-end

  warnings =
    # certificate-blacklist # remove
    lib.optional (lib.versionAtLeast pkgs.cacert.version "3.131.1") ''
      nixos-unstable now includes CA data 3.131.1 or later. Review the eMudhra
      incident response, then remove security.pki.caCertificateBlacklist if the
      upstream CA bundle covers the required distrusts.
    ''
    # mozilla-ca-override # remove
    ++ lib.optional (lib.versionAtLeast pkgs.emudhraUpstreamMozillaCA.version "20261020") "nixos-unstable now provides Mozilla::CA 20261020 or later; remove # mozilla-ca-override.";

  nixpkgs.overlays = [
    (_final: prev: {
      # mozilla-ca-override # remove-begin
      emudhraUpstreamMozillaCA = prev.perlPackages.MozillaCA;

      perlPackages = prev.perlPackages.overrideScope (
        _perlFinal: perlPrev: {
          MozillaCA = repoLib.versionAtLeastOrLocal perlPrev.MozillaCA "20261020" (
            perlPrev.MozillaCA.overrideAttrs (
              _finalAttrs: _previousAttrs: {
                name = "Mozilla-CA-20261020";
                version = "20261020";
                src = prev.fetchurl {
                  url = "mirror://cpan/authors/id/L/LW/LWP/Mozilla-CA-20261020.tar.gz";
                  hash = "sha256-Gu7ZekYzieWC4IXoLeA64L/6501Gz47kxRE0HlUIwh0=";
                };
                postPatch = "";
              }
            )
          );
        }
      );
      # mozilla-ca-override # remove-end
    })
  ];
}
