{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.josm;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  scalarToString = value: if builtins.isBool value then lib.boolToString value else toString value;
  isMapList = value: builtins.isList value && value != [ ] && builtins.isAttrs (builtins.head value);

  scalarSettings = lib.filterAttrs (_: value: !builtins.isList value) cfg.settings;
  listSettings = lib.filterAttrs (_: value: builtins.isList value && !isMapList value) cfg.settings;
  mapSettings = lib.filterAttrs (_: value: isMapList value) cfg.settings;

  xml = pkgs.formats.xml { };
  preferences = xml.generate "josm-preferences.xml" {
    preferences = {
      "@xmlns" = "http://josm.openstreetmap.de/preferences-1.0";
      "@version" = "1";

      tag = lib.mapAttrsToList (key: value: {
        "@key" = key;
        "@value" = scalarToString value;
      }) scalarSettings;

      list = lib.mapAttrsToList (key: values: {
        "@key" = key;
        entry = map (value: { "@value" = scalarToString value; }) values;
      }) (listSettings // { plugins = cfg.plugins; });

      maps = lib.mapAttrsToList (key: maps: {
        "@key" = key;
        map = map (attrs: {
          tag = lib.mapAttrsToList (mapKey: value: {
            "@key" = mapKey;
            "@value" = scalarToString value;
          }) attrs;
        }) maps;
      }) mapSettings;
    };
  };
in
{
  options.programs.josm = {
    enable = mkEnableOption "JOSM, with declarative preferences and plugins";

    package = mkOption {
      type = types.package;
      default = pkgs.josm.override {
        jre = pkgs.jre.override { enableJavaFX = true; };
      };
      defaultText = lib.literalExpression ''
        pkgs.josm.override {
          jre = pkgs.jre.override { enableJavaFX = true; };
        }
      '';
      description = "JOSM package to run.";
    };

    plugins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Flake-locked JOSM plugins to install and enable.";
    };

    settings = mkOption {
      # `types.oneOf` cannot reliably merge JOSM's two list shapes (a list of
      # scalar entries versus a list of maps), so classification happens in
      # the serializer above.
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        JOSM preferences. Scalar values become tags, lists become JOSM lists,
        and lists of attribute sets become JOSM maps.
      '';
    };
  };

  config = mkMerge [
    {
      programs.josm = {
        enable = true;

        plugins = [
          "AddrInterpolation"
          "ColorPlugin"
          "FixAddresses"
          "KartaView"
          "MapRoulette"
          "Mapillary"
          "MicrosoftStreetside"
          "PicLayer"
          "Review.Changes"
          "RoadSigns"
          "ShapeTools"
          "alignways"
          "apache-commons"
          "apache-http"
          "auto_tools"
          "buildings_tools"
          "centernode"
          "continuosDownload"
          "contourmerge"
          "ejml"
          "fhrsPlugin"
          "flatlaf"
          "geotools"
          "http2"
          "imagery_offset_db"
          "jackson"
          "javafx"
          "jaxb"
          "jna"
          "jts"
          "libphonenumber"
          "log4j"
          "opendata"
          "osm-obj-info"
          "pdfimport"
          "phonenumber"
          "rasterfilters"
          "reverter"
          "shrinkwrap"
          "tageditor"
          "terracer"
          "todo"
          "turnlanes-tagging"
          "turnrestrictions"
          "undelete"
          "utilsplugin2"
        ];

        settings = {
          "alignways.majorver" = 2;
          "buildings_tool.shape" = "RECTANGLE";
          "dialog.dynamic.buttons" = true;
          "draw.rawgps.colormode" = 0;
          "draw.rawgps.lines" = 2;
          expert = true;
          "geoimage.docked" = false;
          "geoimage.visible" = true;
          "imagery.layers.addedIds" = [
            "Bing"
            "Mapbox"
          ];
          "imagery.layers.default" = [
            "Bing"
            "EsriWorldImagery"
            "EsriWorldImageryClarity"
            "Mapbox"
            "standard"
            "OSMUK-Cadastral-Parcels"
          ];
          "iodb.modify.toolbar" = false;
          "iso.dates" = true;
          laf = "com.formdev.flatlaf.FlatDarculaLaf";
          language = "en_GB";
          "mappaint.renderer-class-name" = "org.openstreetmap.josm.data.osm.visitor.paint.StyledMapRenderer";
          "mappaint.style.entries" = [
            {
              active = true;
              title = "JOSM default (MapCSS)";
              ptoken = "standard";
              url = "resource://styles/standard/elemstyles.mapcss";
            }
            {
              active = false;
              title = "Lane and road attributes";
              url = "https://josm.openstreetmap.de/josmfile?page=Styles/Lane_and_Road_Attributes&zip=1";
            }
          ];
          "mappaint.style.known-defaults" = [ "resource://styles/standard/elemstyles.mapcss" ];
          "message.imagery.nagPanel.https://clarity.maptiles.arcgis.com/arcgis/rest/services/World_Imagery/MapServer/tile/{zoom}/{y}/{x}" =
            false;
          "message.imagery.nagPanel.https://www.bing.com/maps/" = false;
          "message.imagery.nagPanel.https://{switch:a,b,c,d}.tiles.mapbox.com/v4/mapbox.satellite/{zoom}/{x}/{y}.jpg?access_token={apikey}" =
            false;
          "osm-server.upload-strategy" = "singlerequest";
          "piclayer.autoloadcal" = "yes";
          "pluginmanager.time-based-update.policy" = "never";
          "pluginmanager.version-based-update.policy" = "never";
          "plugins.terracer.handle_relation" = false;
          "proxy.policy" = "no-proxy";
          "relation.editor.generic.lastrole" = "forward";
          "remotecontrol.enabled" = true;
          "remotecontrol.permission.authorization" = true;
          "reviewPlugin/icon.minimized" = true;
          "reviewPlugin/icon.visible" = false;
          "sidetoolbar.hidden.org.openstreetmap.josm.plugins.piclayer.actions.transform.MovePictureAction" =
            false;
          "streetside-main.visible" = false;
          "streetside-viewer.visible" = false;
          toolbar = [
            "open"
            "save"
            "download"
            "upload"
            "|"
            "undo"
            "redo"
            "|"
            "dialogs/search(searchExpression=)"
            "preference"
            "|"
            "splitway"
            "combineway"
            "wayflip"
            "|"
            "imagery-offset"
            "|"
            "tagginggroup_Highways/Streets"
            "tagginggroup_Highways/Ways"
            "tagginggroup_Highways/Waypoints"
            "tagginggroup_Highways/Barriers"
            "|"
            "tagginggroup_Transport/Car"
            "tagginggroup_Transport/Public Transport"
            "|"
            "tagginggroup_Facilities/Tourism"
            "tagginggroup_Facilities/Food+Drinks"
            "|"
            "imagery_Bing aerial imagery"
            "imagery_OSMUK Cadastral Parcels"
            "getoffset"
            "|"
            "tagginggroup_Annotation"
            "turnlanes-tagging"
          ];
          "turnrestrictions.visible" = true;
          "upload.source.obtainautomatically" = true;
          "utilsplugin2.customurl" = "https://www.openstreetmap.org/{#type}/{#id}/history";
          "validator.visible" = true;
        };
      };
    }

    (mkIf cfg.enable {
      assertions = [
        {
          assertion = !(cfg.settings ? plugins);
          message = "Use programs.josm.plugins instead of programs.josm.settings.plugins.";
        }
      ];

      home.packages = [ cfg.package ];

      xdg.configFile."JOSM/preferences.xml".source = preferences;

      xdg.dataFile = lib.listToAttrs (
        map (plugin: {
          name = "JOSM/plugins/${plugin}.jar";
          value.source = inputs.josm-plugin-sources.sources."josm-plugin-${plugin}";
        }) cfg.plugins
      );
    })
  ];
}
