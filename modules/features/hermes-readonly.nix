_: {
  flake.modules.nixos.hermes-readonly = {pkgs, ...}: {
    users.users.hermes = {
      isNormalUser = true;
      createHome = true;
      shell = pkgs.bashInteractive;
      extraGroups = ["systemd-journal" "adm"];
      openssh.authorizedKeys.keyFiles = [../aspects/secrets/hermes.pub];
    };
  };
}
