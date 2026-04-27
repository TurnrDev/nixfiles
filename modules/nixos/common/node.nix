{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nodejs
    vite
    typescript
    typescript-language-server
    eslint
  ];
}
