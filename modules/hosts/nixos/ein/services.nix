_: {
  configurations.nixos.ein.module = {
    serviceRegistry.syncserver = {
      host = "jet";
      port = 4060;
      servePort = 4060;
      category = "Infrastructure";
    };

    serviceRegistry.searx = {
      host = "jet";
      port = 4020;
      servePort = 4020;
      category = "Productivity";
    };
  };
}
