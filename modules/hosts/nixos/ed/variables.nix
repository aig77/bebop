_: {
  configurations.nixos.ed.role = "server";
  configurations.nixos.ed.module = {
    var = {
      username = "arturo";
      hostname = "ed";
      shell = "zsh";
      network = {
        subnet = "192.168.68.0/24";
        hosts = {
          jet = "192.168.68.100";
          ed = "192.168.68.101";
        };
      };
    };
  };
}
