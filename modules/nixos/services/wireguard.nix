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
      description = "SOPS file containing wireguard-home-config.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.wireguard-home-config = {
      inherit (cfg) sopsFile;
      mode = "0400";
    };

    # The profile's AllowedIPs define a split tunnel, so traffic outside the
    # home networks continues to use the normal network connection.
    networking.wg-quick.interfaces.home.configFile =
      config.sops.secrets.wireguard-home-config.path;
  };
}
