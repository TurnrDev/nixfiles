{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    filterAttrs
    literalExpression
    mapAttrs
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;
  cfg = config.services.monitorctl;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
  yaml = pkgs.formats.yaml { };

  instanceConfig =
    name: instance:
    yaml.generate "monitorctl-${name}.yaml" {
      inherit (instance) connector profile;
      host = instance.bindAddress;
      port = instance.port;
      profile_dir = "${instance.package}/lib/monitorctl/profiles";
      feature_overrides = instance.featureOverrides;
      include_unknown_features = instance.includeUnknownFeatures;
      mqtt = {
        inherit (instance.mqtt)
          host
          port
          tls
          ;
        enabled = instance.mqtt.enable;
        discovery_prefix = instance.mqtt.discoveryPrefix;
        node_id = instance.mqtt.nodeId;
        device_name = instance.mqtt.deviceName;
      };
      toggle_between = instance.toggleBetween;
      fast_poll_interval = instance.fastPollInterval;
      slow_poll_interval = instance.slowPollInterval;
      log_level = instance.logLevel;
    };
in
{
  options.services.monitorctl = {
    enable = mkEnableOption "per-monitor monitor-switch services";

    instances = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, ... }: {
            options = {
              enable = mkEnableOption "this monitor instance" // {
                default = true;
              };

              package = mkOption {
                type = types.package;
                default = pkgs.callPackage ../../../packages/monitor-switch { };
                defaultText = literalExpression "pkgs.callPackage ../../../packages/monitor-switch { }";
                description = "Pinned upstream monitor-switch package used by this instance.";
              };

              connector = mkOption {
                type = types.str;
                description = ''
                  Glob for the physical DRM connector, for example
                  `/sys/class/drm/card*-HDMI-A-3`. monitor-switch follows that
                  connector's `ddc` symlink on each recovery rather than pinning an
                  I²C bus number; the selected profile is then matched to its EDID.
                '';
              };

              profile = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Optional upstream profile name to force; null selects by EDID.";
              };

              featureOverrides = mkOption {
                type = types.attrs;
                default = { };
                description = "Local monitor-switch feature overrides, merged after the selected profile.";
              };

              toggleBetween = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Input option IDs cycled by the upstream toggle endpoint.";
              };

              includeUnknownFeatures = mkOption {
                type = types.bool;
                default = false;
                description = "Expose VCP features for which upstream has no metadata.";
              };

              bindAddress = mkOption {
                type = types.str;
                default = "127.0.0.1";
                description = "HTTP bind address. The upstream API has no authentication.";
              };

              port = mkOption {
                type = types.port;
                default = 8765;
                description = "Loopback HTTP port for this independent instance.";
              };

              fastPollInterval = mkOption {
                type = types.float;
                default = 15.0;
              };
              slowPollInterval = mkOption {
                type = types.float;
                default = 300.0;
              };
              logLevel = mkOption {
                type = types.str;
                default = "INFO";
              };

              mqtt = {
                enable = mkEnableOption "Home Assistant MQTT discovery for this monitor";
                host = mkOption {
                  type = types.str;
                  description = "MQTT broker host or address.";
                };
                port = mkOption {
                  type = types.port;
                  default = 1883;
                };
                tls = mkOption {
                  type = types.bool;
                  default = false;
                };
                discoveryPrefix = mkOption {
                  type = types.str;
                  default = "homeassistant";
                };
                nodeId = mkOption {
                  type = types.str;
                  default = "monitorctl_${name}";
                  description = "Stable MQTT node ID; it scopes topics, HA unique IDs, and the HA device.";
                };
                deviceName = mkOption {
                  type = types.str;
                  default = name;
                };
                credentialsFile = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = ''
                    Root-readable EnvironmentFile containing MONITORCTL_MQTT_USERNAME
                    and MONITORCTL_MQTT_PASSWORD. It is read by systemd and never put
                    in the Nix store.
                  '';
                };
              };
            };
          }
        )
      );
      description = "Independently supervised physical-monitor instances.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = enabledInstances != { };
        message = "services.monitorctl.enable requires at least one enabled instance.";
      }
      {
        assertion = lib.all (instance: !instance.mqtt.enable || instance.mqtt.credentialsFile != null) (
          lib.attrValues enabledInstances
        );
        message = "Each MQTT-enabled monitorctl instance needs mqtt.credentialsFile.";
      }
      {
        assertion =
          (lib.length (lib.unique (map (instance: instance.port) (lib.attrValues enabledInstances))))
          == (lib.length (lib.attrValues enabledInstances));
        message = "Enabled monitorctl instances must use different HTTP ports.";
      }
      {
        assertion =
          (lib.length (
            lib.unique (
              map (instance: instance.mqtt.nodeId) (
                lib.attrValues (filterAttrs (_: instance: instance.mqtt.enable) enabledInstances)
              )
            )
          ))
          == (lib.length (lib.attrValues (filterAttrs (_: instance: instance.mqtt.enable) enabledInstances)));
        message = "MQTT-enabled monitorctl instances must use distinct mqtt.nodeId values.";
      }
    ];

    hardware.i2c.enable = true;
    boot.kernelModules = [ "i2c-dev" ];

    systemd.services = lib.mapAttrs' (
      name: instance:
      lib.nameValuePair "monitorctl-${name}" {
        description = "monitor-switch DDC/CI controller (${name})";
        documentation = [ "https://github.com/DimpiM/monitor-switch" ];
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        startLimitIntervalSec = 0;

        serviceConfig = {
          Type = "simple";
          DynamicUser = true;
          SupplementaryGroups = [ "i2c" ];
          WorkingDirectory = "${instance.package}/lib/monitorctl";
          Environment = [
            "MONITORCTL_CONFIG=${instanceConfig name instance}"
            "PYTHONUNBUFFERED=1"
            "XDG_CACHE_HOME=/var/cache/monitorctl-${name}"
          ];
          EnvironmentFile = optional (instance.mqtt.credentialsFile != null) instance.mqtt.credentialsFile;
          CacheDirectory = "monitorctl-${name}";
          ExecStart = "${instance.package}/bin/monitorctl";
          Restart = "always";
          RestartSec = "5s";

          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];
          DeviceAllow = [ "char-i2c rw" ];
        };
      }
    ) enabledInstances;
  };
}
