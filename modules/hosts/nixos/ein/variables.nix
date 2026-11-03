_: {
  configurations.nixos.ein.module = {
    var = {
      username = "arturo";
      hostname = "ein";
      shell = "zsh";
      monitors = [
        {
          model = "MND508ZB1-1";
          width = 2880;
          height = 1920;
          framerate = 120;
        }
      ];
    };
  };
}
