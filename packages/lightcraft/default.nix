{ callPackage }:

let
  # renovate: datasource=github-release-attachments depName=storytold/lightcraft versioning=semver
  releaseTag = "v0.2.1";
in
callPackage ../crafting-apps/package.nix {
  pname = "lightcraft";
  inherit releaseTag;
  sha256 = "543f91c96e4081e86065ec8fb3d62447b08bfd6ae0da22df50fc27a55bb9777d";
  description = "Native photo library and raw developer";
}
