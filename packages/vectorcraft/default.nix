{ callPackage }:

let
  # renovate: datasource=github-release-attachments depName=storytold/vectorcraft versioning=semver
  releaseTag = "v0.4.0";
in
callPackage ../crafting-apps/package.nix {
  pname = "vectorcraft";
  inherit releaseTag;
  sha256 = "9bc79a38f605689552ea2afdc6d476c6be780f8c71c740ce12a128f0ebbd5837";
  description = "Native vector graphics and illustration editor";
}
