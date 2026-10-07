{ callPackage }:

let
  # renovate: datasource=github-release-attachments depName=storytold/printcraft versioning=semver
  releaseTag = "v0.2.1";
in
callPackage ../crafting-apps/package.nix {
  pname = "printcraft";
  inherit releaseTag;
  sha256 = "73b2977330d73716971237f68f89cba6ad52cbfb563ad0ab6d9ad18f44d45192";
  description = "Native PDF viewer and editor";
}
