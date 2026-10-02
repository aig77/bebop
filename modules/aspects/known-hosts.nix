_: let
  jet = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINSmq/X0XZhH4sODZQ1S6xYwvMCD4wQhFiimyLliZrId";
  knownHosts = {
    programs.ssh.knownHosts.jet = {
      hostNames = ["jet"];
      publicKey = jet;
    };
  };
in {
  flake.modules.nixos.base = knownHosts;
  flake.modules.darwin.base = knownHosts;
}
