_: {
  configurations.nixos.ein.module = {
    var = {
      username = "arturo";
      hostname = "ein";
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
