_: {
  configurations.nixos.spike.module = {
    var = {
      username = "arturo";
      hostname = "spike";
      shell = "zsh";
      monitors = [
        {
          model = "MPG321UX OLED";
          width = 3840;
          height = 2160;
          framerate = 240;
          scale = 1.3;
        }
      ];
    };
  };
}
