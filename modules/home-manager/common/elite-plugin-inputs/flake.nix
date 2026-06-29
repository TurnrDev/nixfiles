{
  inputs.edmc-discord-presence = {
    url = "git+https://github.com/elite-kode/edmc-discord-presence?submodules=1";
    flake = false;
  };

  outputs =
    { self, ... }@inputs:
    {
      sources = builtins.removeAttrs inputs [ "self" ];
    };
}
