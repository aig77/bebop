_: {
  flake.modules.nixos.base = {
    config,
    pkgs,
    ...
  }: {
    programs.${config.var.shell}.enable = true;
    users.users.${config.var.username} = {
      isNormalUser = true;
      initialPassword = "password";
      extraGroups = ["wheel" "networkmanager"];
      shell = pkgs.${config.var.shell};
      openssh.authorizedKeys.keyFiles = [./secrets/ssh.pub];
    };
    users.users.root.openssh.authorizedKeys.keyFiles = [
      ./secrets/ssh.pub
      ./secrets/builder.pub
    ];
  };
}
