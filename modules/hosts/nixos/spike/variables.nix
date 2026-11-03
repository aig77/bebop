_: {
  configurations.nixos.spike.module = {
    var = {
      username = "arturo";
      hostname = "spike";
      shell = "zsh";
      monitors = [
        {
          make = "Microstep";
          model = "MPG321UX OLED";
          serial = "0x01010101";
          width = 3840;
          height = 2160;
          framerate = 240;
          scale = 1.3;
        }
      ];
    };
  };
}
