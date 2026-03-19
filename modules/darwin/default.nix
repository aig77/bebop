_: {
  flake.modules.darwin.base = {
    config,
    pkgs,
    ...
  }: {
    nix.enable = false;
    nixpkgs.hostPlatform = "aarch64-darwin";

    system = {
      stateVersion = 5;
      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToControl = true;
      };
      defaults = {
        controlcenter.BatteryShowPercentage = true;
        dock = {
          autohide = true;
          orientation = "bottom";
        };
        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          CreateDesktop = false;
          FXRemoveOldTrashItems = true;
        };
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
      };
    };

    environment = {
      shells = with pkgs; [fish zsh];
      systemPackages = with pkgs; [coreutils];
      systemPath = ["/usr/local/bin"];
      pathsToLink = ["/Applications"];
    };

    programs.${config.var.shell}.enable = true;

    users.users.${config.var.username} = {
      home = "/Users/${config.var.username}";
      shell = pkgs.${config.var.shell};
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "zap";
      };
      extraConfig = ''
        cask_args appdir: "~/Applications"
      '';
    };

    sops = {
      defaultSopsFile = ../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "${config.users.users.${config.var.username}.home}/.config/sops/age/keys.txt";
      secrets = {
        git-email = {};
        openweather-api-key = {};
        weatherapi-key = {};
      };
    };
  };
}
