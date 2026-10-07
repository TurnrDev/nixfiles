{ callPackage }:

let
  # renovate: datasource=github-release-attachments depName=storytold/effectcraft versioning=semver
  releaseTag = "v0.4.0";
in
callPackage ../crafting-apps/package.nix {
  pname = "effectcraft";
  inherit releaseTag;
  sha256 = "3b7b616ba837910e812e53cff1776c56159fe9644ef8dc47a45759bd7ab7679a";
  description = "Native motion graphics and visual effects compositor";
  withAlsa = true;
}
