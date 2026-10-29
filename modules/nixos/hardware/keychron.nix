{ pkgs, ... }:

{
  services.udev = {
    packages = with pkgs; [
      # qmk
      qmk-udev-rules
      # qmk_hid
    ];

  };

  # Allow the Keychron web configurator to access supported keyboards.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0961", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="d031", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

}
