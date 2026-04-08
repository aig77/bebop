_: {
  flake.modules.homeManager.base = _: {
    programs.btop = {
      enable = true;
      settings.theme_background = false;
    };
  };

  flake.modules.homeManager.btopAmd = {pkgs, ...}: {
    programs.btop = {
      package = pkgs.btop.override {rocmSupport = true;};
      settings.shown_boxes = "cpu mem net proc gpu0";
    };
  };

  flake.modules.homeManager.btopNvidia = _: {
    programs.btop.settings = {
      shown_boxes = "cpu mem net proc gpu0";
      nvml_measure_pcie_speeds = true;
    };
  };
}
