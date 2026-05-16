{ identity, inputs, lib, ... }:

{
   imports = [
     inputs.spicetify-nix.homeManagerModules.spicetify
   ];

   my.backups.borgmatic.moduleExcludePatterns = lib.mkAfter [
     "${identity.homeDirectory}/.config/spotify"
   ];

   programs.spicetify = {
     enable = true;
   };

   wayland.windowManager.hyprland.settings = {
     on = lib.mkAfter [
       {
         _args = [
           "hyprland.start"
           (lib.generators.mkLuaInline ''
             function()
               hl.exec_cmd("[workspace 9 silent] uwsm app -- spotify")
             end
           '')
         ];
       }
     ];

     window_rule = lib.mkAfter [
     {
       name = "workspace-spotify";
       match.initial_class = "^([sS]potify)$";
        workspace = "9";
     }
   ];
  };
}
