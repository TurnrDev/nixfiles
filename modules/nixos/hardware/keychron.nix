{ pkgs, ... }:

{
  services.udev = {
    packages = with pkgs; [
      # qmk
      qmk-udev-rules
      # qmk_hid
    ];

  };

  services.xserver.inputClassSections = [
    ''
      Identifier "Keychron V6 Max QWERTY"
      MatchIsKeyboard "on"
      MatchProduct "Keychron.*V6 Max"
      Option "XkbLayout" "gb"
      Option "XkbVariant" ""
    ''
  ];
}
