{ lib }:

let
  # Select the latest Multiverse package version in [lower, upper).
  # Returns null when the locked Multiverse input has no matching version.
  versionBetween = multiverse: package: lower: upper:
    let
      versions = builtins.filter (
        version: lib.versionAtLeast version lower && lib.versionOlder version upper
      ) (multiverse.versionsOf package);
    in
    if versions == [ ] then null else lib.last versions;
in
{
  inherit versionBetween;

  # Prefer a qualifying Multiverse package; otherwise retain the local fallback.
  multiverseVersionBetweenOrLocal = multiverse: package: lower: upper: local:
    let
      version = versionBetween multiverse package lower upper;
    in
    if version == null then local else multiverse.version package version;

  # Prefer the upstream package once it reaches minimumVersion; otherwise use
  # the local override. This keeps a local security patch inactive once fixed.
  versionAtLeastOrLocal = upstream: minimumVersion: local:
    if lib.versionAtLeast upstream.version minimumVersion then upstream else local;
}
