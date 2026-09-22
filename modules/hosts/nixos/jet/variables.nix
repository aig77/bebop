_: {
  configurations.nixos.jet.role = "server";
  configurations.nixos.jet.module = {
    var = {
      username = "arturo";
      hostname = "jet";
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
