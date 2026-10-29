{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  python3,
  ddcutil,
}:

let
  python = python3.withPackages (
    ps: with ps; [
      flask
      waitress
      pyyaml
      paho-mqtt
    ]
  );
in
stdenvNoCC.mkDerivation (_finalAttrs: {
  pname = "monitor-switch";
  version = "0.1.0-unstable-2026-08-08";

  src = fetchFromGitHub {
    owner = "DimpiM";
    repo = "monitor-switch";
    rev = "8d80e7f9ff3854555958aaab46bf1a543539845c";
    hash = "sha256-flZ3eU6qJALZbY6ow4xiKUcbYxgehWi4KCO2po2DJtI=";
  };

  sourceRoot = "source/service";
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm644 run.py "$out/lib/monitorctl/run.py"
    cp -r monitorctl profiles "$out/lib/monitorctl/"

    makeWrapper ${python}/bin/python "$out/bin/monitorctl" \
      --add-flags "$out/lib/monitorctl/run.py" \
      --prefix PATH : ${lib.makeBinPath [ ddcutil ]} \
      --prefix PYTHONPATH : "$out/lib/monitorctl"
    makeWrapper ${python}/bin/python "$out/bin/monitorctl-cli" \
      --add-flags "-m monitorctl" \
      --prefix PATH : ${lib.makeBinPath [ ddcutil ]} \
      --prefix PYTHONPATH : "$out/lib/monitorctl"

    runHook postInstall
  '';

  meta = {
    description = "DDC/CI monitor control via HTTP, MQTT and Home Assistant discovery";
    homepage = "https://github.com/DimpiM/monitor-switch";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "monitorctl";
  };
})
