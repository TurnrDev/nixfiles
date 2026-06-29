{
  inputs.zsh-command-time = {
    url = "git+https://github.com/popstas/zsh-command-time";
    flake = false;
  };

  outputs =
    { self, ... }@inputs:
    {
      sources = builtins.removeAttrs inputs [ "self" ];
    };
}
