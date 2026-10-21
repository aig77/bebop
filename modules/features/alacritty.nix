_: {
  flake.modules.homeManager.alacritty = {lib, ...}: {
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
