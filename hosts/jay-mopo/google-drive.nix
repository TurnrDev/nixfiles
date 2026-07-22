{ config, pkgs, ... }:

let
  rcloneConfig = config.sops.secrets."rclone-gdrive-config".path;
in
{
  home.packages = [ pkgs.rclone ];

  sops.secrets."rclone-gdrive-config" = {
    sopsFile = ../../secrets/hosts/jay-mopo.yaml;
    mode = "0400";
  };

  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "Mount Google Drive at ~/GDrive";
      After = [ "sops-nix.service" "network-online.target" ];
      Requires = [ "sops-nix.service" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/GDrive";
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.rclone}/bin/rclone mount gdrive: %h/GDrive"
        "--config ${rcloneConfig}"
        "--vfs-cache-mode writes"
        "--dir-cache-time 1m"
        "--poll-interval 1m"
      ];
      ExecStop = "${pkgs.fuse}/bin/fusermount -u %h/GDrive";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 20;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
