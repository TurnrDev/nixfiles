{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "code --wait";
    TERMINAL = "ghostty";
  };

  home.packages = with pkgs; [
    bat
    eza
    fastfetch
    fd
    fzf
  ];

  home.file.".oh-my-zsh/custom/plugins/command-time".source =
    inputs."zsh-command-time";

  programs.zsh = {
    enable = true;
    history = {
      extended = true;
      save = 99999999;
      size = 99999999;
    };
    shellAliases = {
      b = "cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --upgrade --show-trace && sudo nix-env --delete-generations 7d";
      d = "docker";
      dc = "docker compose";
      dcu = "docker compose up -d --remove-orphans";
      de = "docker exec -it";
      dl = "docker logs --tail 1000 --follow";
      git-prune = "git fetch --prune && git branch -vv | grep 'gone]' | awk '{print $1}' | xargs -r git branch -D";
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
      custom = "${config.home.homeDirectory}/.oh-my-zsh/custom";
      theme = "robbyrussell";
      plugins = [
        "colored-man-pages"
        "command-time"
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
