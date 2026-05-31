{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    eza
    fastfetch
    fd
    fzf
  ];

  programs.zsh = {
    enable = true;
    history = {
      extended = true;
      save = 99999999;
      size = 99999999;
    };
    shellAliases = {
      b = "cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --show-trace";
      d = "docker";
      dc = "docker compose";
      dcu = "docker compose up -d --remove-orphans";
      de = "docker exec -it";
      dl = "docker logs --tail 1000 --follow";
      la = "eza -a --icons=auto --group-directories-first";
      ll = "eza -lag --icons=auto --group-directories-first";
      ls = "eza --icons=auto --group-directories-first";
      lt = "eza --tree --level=2 --icons=auto";
      random = "openssl rand -hex 12";
    };
    enableCompletion = true;
    autosuggestion = {
      enable = true;
    };
    syntaxHighlighting = {
      enable = true;
    };
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "colored-man-pages"
        "copypath"
        "docker"
        "extract"
        "fzf"
        "git"
        "sudo"
        "zsh-interactive-cd"
      ];
    };
    initContent = ''
      if [[ -o interactive ]]; then
        fastfetch
      fi

      dhc() {
        docker inspect --format "{{json .State.Health }}" $1 | jq
      }
    '';
  };

  programs.ghostty = {
    enable = true;
    package = null;
    systemd.enable = false;
    enableZshIntegration = true;
    settings.command = "${pkgs.zsh}/bin/zsh";
  };
}
