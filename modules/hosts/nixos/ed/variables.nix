_: {
  configurations.nixos.ed.role = "server";
  configurations.nixos.ed.module = {
    var = {
      username = "arturo";
      hostname = "ed";
      shell = "zsh";
    };
  };
}
