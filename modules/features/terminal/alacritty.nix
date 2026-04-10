_: {
  flake.modules.homeManager.base = {lib, var, ...}: lib.mkIf (var.terminal == "alacritty") {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          padding = {
            x = 24;
            y = 16;
          };
          opacity = lib.mkForce 0.9;
        };
      };
    };
  };
}
