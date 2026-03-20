_: {
  configurations.nixos.ed.module = {config, ...}: {
    home-manager.users.${config.var.username} = {
      home.stateVersion = "25.05";
    };
  };
}
