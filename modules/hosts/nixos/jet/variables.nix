_: {
  configurations.nixos.jet.role = "server";
  configurations.nixos.jet.module = {
    var = {
      username = "arturo";
      hostname = "jet";
      shell = "zsh";
    };
  };
}
