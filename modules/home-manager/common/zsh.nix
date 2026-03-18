{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    fzf
    zoxide
    eza
    bat
    fd
  ];
  programs.zsh = {
    enable = true;
    history = {
      extended = true;
      save = 99999999;
      size = 99999999;
    };
    shellAliases = {
      dc = "docker compose";
      dcu = "docker compose up -d --remove-orphans";
      d = "docker";
      dl = "docker logs --tail 1000 --follow";
      de = "docker exec -it";
      ls = "eza --icons=auto --group-directories-first";
      ll = "eza -lag --icons=auto --group-directories-first";
      la = "eza -a --icons=auto --group-directories-first";
      lt = "eza --tree --level=2 --icons=auto";
      random = "openssl rand -hex 12";
      b = "cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --upgrade --show-trace && sudo nix-env --delete-generations +5";
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
      plugins = [ "git" "sudo" "extract" "fzf" "docker" "colored-man-pages" "copypath" "zsh-interactive-cd" ];
    };
    initContent = ''
      if [[ -o interactive ]]; then
        fastfetch
      fi

      eval "$(zoxide init zsh)"
    '';
  };
}
