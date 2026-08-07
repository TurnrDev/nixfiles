{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  startDockMgr = pkgs.writeShellScript "start-dockmgr" ''
    ${pkgs.systemd}/bin/systemctl --user import-environment \
      HYPRLAND_INSTANCE_SIGNATURE \
      WAYLAND_DISPLAY \
      XDG_RUNTIME_DIR
    exec ${pkgs.systemd}/bin/systemctl --user restart dockmgr.service
  '';
in
{
  config = lib.mkIf osConfig.programs.dockmgr.enable {
    systemd.user.services.dockmgr = {
      Unit = {
        Description = "Watch dock state and apply Hyprland display profiles";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        X-Restart-Triggers = [
          osConfig.programs.dockmgr.package
          osConfig.programs.dockmgr.configFile
        ];
        X-SwitchMethod = "restart";
      };

      Service = {
        Type = "simple";
        ExecStart = "${osConfig.programs.dockmgr.package}/bin/dockmgr watch --config ${osConfig.programs.dockmgr.configFile} --context session";
        Restart = "always";
        RestartPreventExitStatus = "75";
        RestartSec = "3s";
      };
    };

    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("${startDockMgr}")
      end)
    '';
  };
}
