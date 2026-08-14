{
  config,
  inputs,
  lib,
  pkgs,
  homeModule,
  ...
}:

let
  backupCommand = pkgs.writeShellScript "home-manager-backup" ''
    set -eu

    target="$1"
    backup="$target.hm-backup"

    if [ ! -e "$backup" ]; then
      exec mv -- "$target" "$backup"
    fi

    i=1
    while [ -e "$backup.$i" ]; do
      i=$((i + 1))
    done

    exec mv -- "$target" "$backup.$i"
  '';
in
{
  users.manageLingering = true;
  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username}.linger = true;
  };

  home-manager = {
    inherit backupCommand;
    extraSpecialArgs = {
      inherit inputs;
      identity = config.my.identity;
    };
    users = lib.mkIf config.my.identity.enable {
      ${config.my.identity.username}.imports = [ homeModule ];
    };
  };
}
