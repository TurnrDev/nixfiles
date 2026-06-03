{ ... }:

{
  # Allow the Keychron web configurator to access supported keyboards.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0961", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';
}
