{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    eslint
    nodejs
    typescript
    typescript-language-server
    vite
  ];
}
