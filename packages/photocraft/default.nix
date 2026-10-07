{ callPackage }:

let
  # renovate: datasource=github-release-attachments depName=storytold/photocraft versioning=semver
  releaseTag = "v0.3.0";
in
callPackage ../crafting-apps/package.nix {
  pname = "photocraft";
  inherit releaseTag;
  sha256 = "e8f3af6afae53a8a4d6eb13abfbccf74b8ffc2143e487047d724e5683d5cff3d";
  description = "Native image editor with layered PSD support";
}
