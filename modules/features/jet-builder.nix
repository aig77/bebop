_: {
  flake.modules.nixos.jet-builder = {
    nix.settings = {
      builders-use-substitutes = true;
      buildMachines = [
        {
          hostName = "jet";
          system = "aarch64-linux";
          sshUser = "root";
          maxJobs = 2;
          protocol = "ssh-ng";
        }
        {
          hostName = "jet";
          system = "x86_64-linux";
          sshUser = "root";
          maxJobs = 2;
          protocol = "ssh-ng";
        }
      ];
    };
  };
}
