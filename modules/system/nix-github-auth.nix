{ inputs, ... }:

{
  flake.modules.nixos.system-nix-github-auth =
    { config, pkgs, ... }:
    {
      # Multiple consumers may import this module; configure the include once.
      key = "system-nix-github-auth";

      imports = [ inputs.sops-nix.nixosModules.sops ];

      environment.systemPackages = [ pkgs.gh ];

      sops.secrets.github-token = {
        sopsFile = ../../secrets/shared.yaml;
        owner = "root";
        group = "root";
        mode = "0400";
      };

      sops.templates."github-access-token.conf" = {
        path = "/etc/nix/github-access-token.conf";
        content = ''
          access-tokens = github.com=${config.sops.placeholder.github-token}
        '';
        owner = "root";
        group = "root";
        mode = "0400";
        restartUnits = [ "nix-daemon.service" ];
      };

      # Only SOPS placeholders enter the store; the token is rendered at runtime.
      nix.extraOptions = ''
        !include /etc/nix/github-access-token.conf
      '';
    };
}
