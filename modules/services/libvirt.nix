_:

{
  flake.modules.nixos.service-libvirt =
    { config, lib, ... }:

    {
      users.users = lib.optionalAttrs (config.my.users ? jay) {
        ${config.my.users.jay.username} = {
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
    };
}
