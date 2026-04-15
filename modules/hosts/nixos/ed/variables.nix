_: {
  configurations.nixos.ed.module = {
    var = {
      username = "arturo";
      hostname = "ed";
      shell = "zsh";
      headless = true;
    };
  };
}
