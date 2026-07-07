{
  pkgs,
  ...
}:

{
  # btop's Intel GPU monitoring needs extra perf capabilities.
  security.wrappers.btop = {
    owner = "root";
    group = "root";
    source = "${pkgs.btop}/bin/btop";
    capabilities = "cap_perfmon+ep";
  };
}
