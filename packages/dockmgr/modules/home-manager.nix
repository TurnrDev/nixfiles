{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  statePath = "${config.xdg.stateHome}/dockmgr/active-profile";
  luaModule = "${osConfig.programs.dockmgr.package}/share/dockmgr/dockmgr.lua";
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
        Environment = [ "DOCKMGR_STATE_PATH=${statePath}" ];
        Restart = "always";
        RestartPreventExitStatus = "75";
        RestartSec = "3s";
      };
    };

    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      -- Restore the last profile synchronously as this configuration is parsed.
      -- Unlike invoking dockmgr through a start/reload event, this prevents
      -- Hyprland from visibly modesetting an output to its preferred mode first.
      dofile("${luaModule}").restore(
        "${statePath}",
        "${osConfig.programs.dockmgr.configFile}",
        "${lib.getExe pkgs.jq}"
      )

      hl.on("hyprland.start", function()
        hl.exec_cmd("${startDockMgr}")
      end)
    '';
  };
}
