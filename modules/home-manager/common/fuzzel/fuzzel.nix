{ config, lib, ... }:

{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = lib.mkForce "${config.stylix.fonts.sansSerif.name}:size=18";
        prompt = "󰍉 ";
        placeholder = "Search applications";
        lines = 10;
        width = 42;
        terminal = "foot -e";
        "icons-enabled" = true;
        "use-bold" = true;
        "show-actions" = true;
        "match-mode" = "fzf";
        fields = "name,generic,keywords,categories";
        "horizontal-pad" = 24;
        "vertical-pad" = 18;
        "inner-pad" = 14;
        "line-height" = 28;
        anchor = "top";
        layer = "overlay";
        "y-margin" = 72;
      };
      colors = lib.mkForce {
        background = "${config.lib.stylix.colors.base00}eb";
        text = "${config.lib.stylix.colors.base05}ff";
        prompt = "${config.lib.stylix.colors.base0B}ff";
        placeholder = "${config.lib.stylix.colors.base04}ff";
        input = "${config.lib.stylix.colors.base07}ff";
        match = "${config.lib.stylix.colors.base0D}ff";
        selection = "${config.lib.stylix.colors.base02}ff";
        "selection-text" = "${config.lib.stylix.colors.base07}ff";
        "selection-match" = "${config.lib.stylix.colors.base0B}ff";
        counter = "${config.lib.stylix.colors.base04}ff";
        border = "${config.lib.stylix.colors.base03}ff";
      };
      border = {
        width = 1;
        radius = 22;
        "selection-radius" = 16;
      };
    };
  };
}
