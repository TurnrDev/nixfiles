{
  config,
  lib,
  ...
}:

let
  cfg = config.my.wireguard.home;
in
{
  options.my.wireguard.home = {
    enable = lib.mkEnableOption "the home WireGuard VPN";

    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "SOPS file containing wireguard-home-private-key and wireguard-home-preshared-key.";
    };

    ipv4Address = lib.mkOption {
      type = lib.types.str;
      description = "IPv4 address, including prefix length, assigned to this WireGuard client.";
    };

    ipv6Address = lib.mkOption {
      type = lib.types.str;
      description = "IPv6 address, including prefix length, assigned to this WireGuard client.";
    };

    peerPublicKey = lib.mkOption {
      type = lib.types.str;
      default = "pwjlHY5YO2DBi4mJSj3QIjpiXOjojNzv6AS/mk8YTG0=";
      description = "Public key of the home WireGuard peer.";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "wireguard.home.turnr.net:51820";
      description = "Host and port of the home WireGuard peer.";
    };

    allowedIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "10.117.24.0/23"
        "10.117.26.1/32"
      ];
      description = "Home networks that should route through WireGuard.";
    };

    mtu = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1420;
      description = "WireGuard interface MTU.";
    };

    persistentKeepalive = lib.mkOption {
      type = lib.types.ints.positive;
      default = 25;
      description = "WireGuard persistent keepalive interval in seconds.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      wireguard-home-private-key = {
        inherit (cfg) sopsFile;
        mode = "0400";
      };
      wireguard-home-preshared-key = {
        inherit (cfg) sopsFile;
        mode = "0400";
      };
    };

    # NixOS's NetworkManager module substitutes this root-only runtime file
    # into the declarative profile. No decrypted key is placed in the Nix
    # store or a persistent NetworkManager profile.
    sops.templates.wireguard-home-networkmanager-env = {
      content = ''
        WIREGUARD_HOME_PRIVATE_KEY=${config.sops.placeholder.wireguard-home-private-key}
        WIREGUARD_HOME_PRESHARED_KEY=${config.sops.placeholder.wireguard-home-preshared-key}
      '';
      mode = "0400";
      restartUnits = [ "NetworkManager-ensure-profiles.service" ];
    };

    networking.networkmanager.ensureProfiles = {
      environmentFiles = [ config.sops.templates.wireguard-home-networkmanager-env.path ];
      profiles.home = {
        connection = {
          id = "home";
          type = "wireguard";
          interface-name = "home";
          autoconnect = true;
        };

        wireguard = {
          inherit (cfg) mtu;
          peer-routes = true;
          private-key = "$WIREGUARD_HOME_PRIVATE_KEY";
          private-key-flags = 0;
        };

        "wireguard-peer.${cfg.peerPublicKey}" = {
          allowed-ips = lib.concatStringsSep ";" cfg.allowedIPs;
          inherit (cfg) endpoint;
          persistent-keepalive = cfg.persistentKeepalive;
          preshared-key = "$WIREGUARD_HOME_PRESHARED_KEY";
          preshared-key-flags = 0;
        };

        ipv4 = {
          method = "manual";
          address1 = cfg.ipv4Address;
          never-default = true;
          route-metric = 2000;
        };

        ipv6 = {
          method = "manual";
          address1 = cfg.ipv6Address;
          never-default = true;
          route-metric = 2000;
        };
      };
    };
  };
}
