{ lib, ... }:

{
  # Workstations hold the configuration checkout and perform builds/deployments.
  # Appliance hosts use Git but do not carry the checkout itself.
  home.activation.linkNixosRepository = lib.hm.dag.entryAfter [ "createReposDirectory" ] ''
    run ln -sfnT /etc/nixos "$HOME/Repos/nixos"
  '';
}
