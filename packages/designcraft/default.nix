{ callPackage }:

let
  # renovate: datasource=github-release-attachments depName=storytold/designcraft versioning=semver
  releaseTag = "v0.4.0";
in
callPackage ../crafting-apps/package.nix {
  pname = "designcraft";
  inherit releaseTag;
  sha256 = "4c0b68c0dc62081e455bf8d60dd54f022ff1624359d5e10d06ca2b18d73d4bb3";
  description = "Native page layout and desktop publishing application";
}
