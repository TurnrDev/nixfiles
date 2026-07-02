{ config, lib, ... }:

{
  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [
        "libvirtd"
        "kvm"
      ];
    };
  };

  programs.virt-manager.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;
}
