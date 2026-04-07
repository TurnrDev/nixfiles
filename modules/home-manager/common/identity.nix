{ identity, ... }:

{
  home.username = identity.username;
  home.homeDirectory = identity.homeDirectory;
}
