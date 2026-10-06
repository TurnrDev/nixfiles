{
  identity,
  lib,
  pkgs,
  ...
}:

let
  esDeSettingsDirectory = "${identity.homeDirectory}/ES-DE/settings";
  esDeSettingsFile = "${esDeSettingsDirectory}/es_settings.xml";
  initialEsDeSettings = pkgs.writeText "es-de-settings.xml" ''
    <?xml version="1.0"?>
    <string name="ROMDirectory" value="/srv/nfs/games/roms/" />
  '';
in
{
  home.file."ES-DE/custom_systems/es_find_rules.xml".text = ''
    <?xml version="1.0"?>
    <!-- This is the ES-DE find rules configuration file for Linux. -->
    <ruleList>
      <core name="RETROARCH">
        <rule type="corepath">
          <entry>${pkgs.retroarch-full}/lib/retroarch/cores/</entry>
        </rule>
      </core>
    </ruleList>
  '';

  # ES-DE owns this file and updates it from the UI. Seed it when absent, or
  # update only the declarative ROM path while leaving every other setting
  # mutable.
  home.activation.configureEsDeRomDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_directory=${lib.escapeShellArg esDeSettingsDirectory}
    settings_file=${lib.escapeShellArg esDeSettingsFile}

    run mkdir -p "$settings_directory"

    if [[ ! -e "$settings_file" ]]; then
      run install -m 600 ${initialEsDeSettings} "$settings_file"
    elif grep -q '<string name="ROMDirectory"' "$settings_file"; then
      run sed -i \
        's#<string name="ROMDirectory" value="[^"]*" */>#<string name="ROMDirectory" value="/srv/nfs/games/roms/" />#' \
        "$settings_file"
    else
      run sed -i \
        '$a<string name="ROMDirectory" value="/srv/nfs/games/roms/" />' \
        "$settings_file"
    fi
  '';
}
