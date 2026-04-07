let
  mainMod = "SUPER";
in
rec {
  inherit mainMod;

  altMod = "${mainMod} ALT";
  mainShift = "${mainMod} SHIFT";
  mainCtrl = "${mainMod} CTRL";
  mainShiftCtrl = "${mainMod} SHIFT CTRL";
  ctrlAlt = "CTRL ALT";
  ctrlShift = "CTRL SHIFT";

  mkBind =
    {
      mods ? "",
      key,
      description,
      dispatcher,
      params ? "",
      includeEmptyParam ? true,
    }:
    let
      prefix = builtins.concatStringsSep ", " [
        mods
        key
        description
        dispatcher
      ];
    in
    if params == "" then
      if includeEmptyParam then "${prefix}," else prefix
    else
      "${prefix}, ${params}";
}
