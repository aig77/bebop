/*
Disko configuration for faye desktop

INSTALLATION WITH NIXOS-ANYWHERE:

1. On TARGET machine (192.168.1.x):
  - Boot NixOS installer ISO
  - Check disk device: lsblk
  - Enable SSH and set password:
systemctl start sshd
passwd
- Get IP address:
ip a

2. From your machine:

nix run github:nix-community/nixos-anywhere -- \
  --flake .#faye \
  --target-host nixos@<ip> \
  --generate-hardware-config nixos-generate-config ./hosts/faye/hardware-configuration.nix

3. Done! The system will reboot automatically with your full config applied.
Set root password on first boot:
sudo passwd root

WARNING: This will DESTROY ALL DATA on the specified device!
*/
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # change this
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
                mountOptions = [
                  "fmask=0022"
                  "dmask=0022"
                ];
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
}
