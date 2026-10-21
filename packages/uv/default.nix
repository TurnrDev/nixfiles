{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  rust-jemalloc-sys,
  installShellFiles,
  buildPackages,
  versionCheckHook,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "uv";
  version = "0.13.4";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "uv";
    tag = finalAttrs.version;
    hash = "sha256-US3SjwhWE3v4/i46YuBon2GA6PupC4Z0NRUqcV9CPLM=";
  };
  cargoHash = "sha256-9L47CTlkOVYfGuzE4e7e2FYAI192pAsipzzScF7B1j4=";

  buildInputs = [ rust-jemalloc-sys ];
  nativeBuildInputs = [ installShellFiles ];
  cargoBuildFlags = [
    "--package"
    "uv"
  ];

  doCheck = false;
  postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
    in
    ''
      installShellCompletion --cmd uv \
        --bash <(${emulator} $out/bin/uv generate-shell-completion bash) \
        --fish <(${emulator} $out/bin/uv generate-shell-completion fish) \
        --zsh <(${emulator} $out/bin/uv generate-shell-completion zsh)
    ''
  );

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Extremely fast Python package installer and resolver, written in Rust";
    homepage = "https://github.com/astral-sh/uv";
    changelog = "https://github.com/astral-sh/uv/blob/${finalAttrs.version}/CHANGELOG.md";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "uv";
    broken = stdenv.buildPlatform.is32bit;
  };
})
