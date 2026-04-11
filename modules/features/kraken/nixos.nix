_: {
  flake.modules.nixos.kraken = {pkgs, ...}: let
    gif = pkgs.fetchurl {
      url = "https://media.gifdb.com/faye-valentine-498-x-371-gif-dt6ema7osqh9fqwo.gif";
      hash = "sha256-mFIsx1WqMya/TLm26vrpzwQk1sCI5tw3MBCu41cA+LU=";
    };
  in {
    environment.systemPackages = [pkgs.liquidctl];

    services.udev.packages = [pkgs.liquidctl];

    systemd.services.kraken-lcd = {
      description = "Set NZXT Kraken LCD display";
      wantedBy = ["multi-user.target"];
      after = ["systemd-udev-settle.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "kraken-lcd-set" ''
          ${pkgs.liquidctl}/bin/liquidctl --match kraken initialize
          ${pkgs.liquidctl}/bin/liquidctl --match kraken set lcd screen gif ${gif}
          ${pkgs.liquidctl}/bin/liquidctl --match kraken set lcd screen orientation 270
        '';
      };
    };
  };
}
