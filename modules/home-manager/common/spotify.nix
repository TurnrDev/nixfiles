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
}
