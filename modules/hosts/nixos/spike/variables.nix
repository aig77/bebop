_: {
  configurations.nixos.spike.module = {
    var = {
      username = "arturo";
      hostname = "spike";
      shell = "zsh";
      terminal = "ghostty";
      browser = "zen";
      fileManager = "thunar";
      git = {
        name = "Arturo";
        email = "29128253+aig77@users.noreply.github.com";
      };
    };
  };
}
