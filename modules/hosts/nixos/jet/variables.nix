_: {
  configurations.nixos.jet.role = "server";
  configurations.nixos.jet.module = {config, ...}: {
    var = {
      username = "arturo";
      hostname = "jet";
      shell = "zsh";
      network.hosts = {
        jet = "192.168.68.100";
        ed = "192.168.68.101";
      };
    };

    hetzner-storagebox = {
      enable = false;
      host = "uXXXXXX.your-storagebox.de";
      user = "uXXXXXX";
      identityFile = config.sops.secrets."hetzner-storagebox/ssh-key".path;
      knownHostsFile = config.sops.secrets."hetzner-storagebox/known-hosts".path;
      gid = config.users.groups.media.gid;
      umask = "002";
    };

    sops.secrets."hetzner-storagebox/ssh-key" = {};
    sops.secrets."hetzner-storagebox/known-hosts" = {};
  };
}
