{
  lib,
  fetchFromGitHub,
  buildGoModule,
  nodejs,
  npmHooks,
  fetchNpmDeps,
}:
buildGoModule (finalAttrs: {
  pname = "go-hass-agent";
  version = "14.11.0";

  src = fetchFromGitHub {
    owner = "joshuar";
    repo = "go-hass-agent";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mC/Y1z2kudBZOEQU5S17ROx3iHPpDGGSkUJe7MMb/iE=";
  };

  vendorHash = "sha256-Xz7u8SSlxlDB5HbKMbm1xVYrtp1/zy2yBgoWS3NcTew=";

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-LwOVVVGWufQ+Q3jiv0H9lf7zg3R9fXvvAlLiUWqtmZs=";
  };

  overrideModAttrs = oldAttrs: {
    nativeBuildInputs = lib.filter (drv: drv != npmHooks.npmConfigHook) oldAttrs.nativeBuildInputs;
    preBuild = "";
  };

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
  ];

  preBuild = ''
    npm run build:js
    npm run build:css
  '';

  ldflags = [
    "-s"
    "-w"
    "-X github.com/joshuar/go-hass-agent/config.AppVersion=v${finalAttrs.version}"
  ];

  meta = {
    description = "Home Assistant native app for desktop/laptop devices";
    mainProgram = "go-hass-agent";
    homepage = "https://github.com/joshuar/go-hass-agent";
    changelog = "https://github.com/joshuar/go-hass-agent/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
