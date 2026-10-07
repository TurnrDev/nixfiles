{ callPackage }:

let
  # renovate: datasource=github-release-attachments depName=storytold/designcraft versioning=semver
  releaseTag = "v0.2.1";
in
callPackage ../crafting-apps/package.nix {
  pname = "designcraft";
  inherit releaseTag;
  sha256 = "0a66a34192203d5f53d6a38e95c9f556396a12edc1b73f9e66c40b371e100970";
  description = "Native page layout and desktop publishing application";
}
