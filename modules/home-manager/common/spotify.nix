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
     "exec-once" = lib.mkAfter [
       "[workspace 9 silent] uwsm app -- spotify"
     ];

     windowrule = lib.mkAfter [
     {
       name = "workspace-spotify";
       "match:initial_class" = "^([sS]potify)$";
        workspace = "9";
     }
   ];
  };
}
