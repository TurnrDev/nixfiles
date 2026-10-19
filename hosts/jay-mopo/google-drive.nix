{ osConfig, pkgs, ... }:

let
  rcloneConfig = osConfig.sops.secrets."rclone-gdrive-config".path;
  runtimeConfig = "%t/rclone-gdrive/rclone.conf";
in
{
  home.packages = [ pkgs.rclone ];

  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "Mount Google Drive at ~/GDrive";
      After = [
        "network-online.target"
      ];
      AssertPathExists = [ rcloneConfig ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "notify";
      RuntimeDirectory = "rclone-gdrive";
      RuntimeDirectoryMode = "0700";
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p %h/GDrive"
        "${pkgs.coreutils}/bin/install -m 0600 ${rcloneConfig} ${runtimeConfig}"
      ];
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.rclone}/bin/rclone mount gdrive: %h/GDrive"
        "--config ${runtimeConfig}"
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
