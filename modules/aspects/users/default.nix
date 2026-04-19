_: {
  flake.modules.nixos.base = {
    config,
    pkgs,
    ...
  }: {
    environment.shells = with pkgs; [fish zsh];
    programs.${config.var.shell}.enable = true;
    users.users.${config.var.username} = {
      isNormalUser = true;
      initialPassword = "password";
      extraGroups = ["wheel" "networkmanager"];
      shell = pkgs.${config.var.shell};
    };
  };
}
