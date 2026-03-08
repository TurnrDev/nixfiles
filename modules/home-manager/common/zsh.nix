{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    # python3Packages.pygments
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
      dc = "docker compose";
      dcu = "docker compose up -d --remove-orphans";
      d = "docker";
      dl = "docker logs --tail 1000 --follow";
      de = "docker exec -it";
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
      theme = "fox";
      plugins = ["colorize" "colored-man-pages" "copypath" "cp" "docker" "extract" "fzf" "heroku" "sudo" "git" "zsh-interactive-cd"];
    };
    initContent = ''
      fastfetch

      # https://github.com/zsh-users/zsh-syntax-highlighting/issues/956
      autoload -Uz add-zsh-hook
      add-zsh-hook -Uz precmd _fix_comment_color
      _fix_comment_color() {
        [[ -n ''${ZSH_HIGHLIGHT_STYLES} ]] && ZSH_HIGHLIGHT_STYLES[comment]='fg=magenta,dimmed'
      }

      if [[ -n "$SSH_TTY" ]]; then
        ICON="[%{$fg_bold[red]%} %M%{$reset_color%}%{$fg[cyan]%}]-"
      else
        ICON=""
      fi
      export PROMPT="%{$fg[cyan]%}┌%{$ICON%}%{$fg[cyan]%}[%{$fg_bold[white]%}%D{%d}%{$reset_color%}%{$fg[cyan]%}/%{$fg_bold[white]%}%D{%m}%{$reset_color%}%{$fg[cyan]%}/%{$fg_bold[white]%}%D{%y}%{$reset_color%}%{$fg[cyan]%}]-[%{$fg_bold[white]%}%D{%H}%{$reset_color%}%{$fg[cyan]%}:%{$fg_bold[white]%}%D{%M}%{$reset_color%}%{$fg[cyan]%}:%{$fg_bold[white]%}%D{%S}%{$reset_color%}%{$fg[cyan]%}]-[%{$fg_bold[white]%}%n%{$reset_color%}%{$fg[cyan]%}%{$fg_bold[white]%}%{$reset_color%}%{$fg[cyan]%}]%{$fg[white]%}-%{$fg[cyan]%}(%{$fg_bold[white]%}%~%{$reset_color%}%{$fg[cyan]%})$(git_prompt_info)
└> % %{$reset_color%}";
    '';
  };
}
