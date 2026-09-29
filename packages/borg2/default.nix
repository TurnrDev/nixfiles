{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "borgbackup";
  # renovate: datasource=github-release-attachments depName=borgbackup/borg versioning=pep440
  version = "2.0.0b25";

  src = fetchurl {
    url = "https://github.com/borgbackup/borg/releases/download/${finalAttrs.version}/borg-linux-glibc239-x86_64-gh";
    sha256 = "10112ca0cce2d4bde99cf3d93a9f4cd6bda8cd6f099c8fc4057fa5041d375cf4";
  };

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ zlib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/borg2"
    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Deduplicating archiver with compression and authenticated encryption (Borg 2 beta)";
    homepage = "https://www.borgbackup.org/";
    license = lib.licenses.bsd3;
    mainProgram = "borg2";
    platforms = [ "x86_64-linux" ];
  };
})
