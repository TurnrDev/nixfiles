{ callPackage }:

let
  # renovate: datasource=github-release-attachments depName=storytold/filmcraft versioning=semver
  releaseTag = "v0.2.1";
in
callPackage ../crafting-apps/package.nix {
  pname = "filmcraft";
  inherit releaseTag;
  sha256 = "dff27e644bcb06b3d4c1f667b8fd544bd15ee4b446c8aee61706712f212887af";
  description = "Native non-linear video editor";
  withAlsa = true;
}
