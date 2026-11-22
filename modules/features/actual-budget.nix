{config, ...}: {
  fleet.services.actual-budget = {
    module = config.flake.modules.nixos.actual-budget;
    category = "Productivity";
    backup.paths = ["/var/lib/actual"];
    monitor = {
      enable = true;
      http = {};
    };
    homepage = {
      enable = true;
      title = "Actual Budget";
      icon = "di:actual-budget";
    };
  };

  flake.modules.nixos.actual-budget = {config, ...}: {
    services.actual = {
      enable = true;
      settings = {
        port = config.ports.actual-budget;
        hostname = "127.0.0.1";
      };
    };
  };
}
