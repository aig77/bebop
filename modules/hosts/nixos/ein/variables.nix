_: {
  configurations.nixos.ein.module = {
    var = {
      username = "arturo";
      hostname = "ein";
      shell = "zsh";
      monitors = [
        {
          make = "CSOT T3";
          model = "MND508ZB1-1";
          serial = "0";
          width = 2880;
          height = 1920;
          framerate = 120;
          scale = 2.0;
        }
      ];
    };
  };
}
