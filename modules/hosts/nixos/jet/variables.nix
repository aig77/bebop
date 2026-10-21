_: {
  configurations.nixos.jet.role = "server";
  configurations.nixos.jet.module = _: {
    var = {
      username = "arturo";
      hostname = "jet";
      shell = "zsh";
    };
  };
}
