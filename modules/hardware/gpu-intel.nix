_: {
  flake.modules.nixos.hardware-gpu-intel =
    { pkgs, ... }:
    {
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-compute-runtime
          intel-media-driver
          vpl-gpu-rt
        ];
      };

      # btop's Intel GPU monitoring needs extra perf capabilities.
      security.wrappers.btop = {
        owner = "root";
        group = "root";
        source = "${pkgs.btop}/bin/btop";
        capabilities = "cap_perfmon+ep";
      };
    };
}
