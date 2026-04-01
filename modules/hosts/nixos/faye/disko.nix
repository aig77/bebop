/*
Disko configuration for faye desktop

FRESH INSTALL WITH NIXOS-ANYWHERE:

1. On TARGET machine:
   - Boot NixOS installer ISO
   - Enable SSH: systemctl start sshd
   - Set password: passwd
   - Get IP: ip a

2. From your machine (generates facter.json, formats disk, installs NixOS):

   nix run github:nix-community/nixos-anywhere -- \
     --flake .#faye \
     --target-host nixos@<ip> \
     --generate-hardware-config nixos-facter ./modules/hosts/nixos/faye/facter.json

   Then commit facter.json, replace hardware.nix import with facter.nix in imports.nix.

WARNING: This will DESTROY ALL DATA on the specified device!
*/
{inputs, ...}: {
  configurations.nixos.faye.module = {
    imports = [inputs.disko.nixosModules.disko];

    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/nvme0n1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = ["fmask=0022" "dmask=0022"];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = ["-f" "-L nixos"];
                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@cache" = {
                      mountpoint = "/var/cache";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
