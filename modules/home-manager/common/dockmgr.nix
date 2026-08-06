{
  lib,
  osConfig,
  ...
}:

{
  config = lib.mkIf osConfig.my.dockmgr.enable {
    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("${osConfig.my.dockmgr.package}/bin/dockmgr watch --config ${osConfig.my.dockmgr.configFile} --context session")
      end)
    '';
  };
}
