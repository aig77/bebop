{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    grub2-themes.url = "github:vinceliuice/grub2-themes";
    hyprland.url = "github:hyprwm/Hyprland/";
    niri.url = "github:sodiboo/niri-flake";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    stylix.url = "github:danth/stylix";

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.git-hooks-nix.flakeModule
      ];

      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

      perSystem = {pkgs, ...}: {
        devShells.default = import ./shell.nix {inherit pkgs;};
        formatter = pkgs.alejandra;
        pre-commit = import ./lib/pre-commit.nix;
      };

      flake = let
        builders = import ./lib/builders.nix {inherit inputs;};
      in {
        nixosConfigurations = {
          faye = builders.mkNixos {
            hostname = "faye";
            system = "x86_64-linux";
            overlays = [inputs.niri.overlays.niri];
            extraModules = [
              inputs.disko.nixosModules.disko
              inputs.home-manager.nixosModules.home-manager
              inputs.stylix.nixosModules.stylix
            ];
          };
          ed = builders.mkNixos {
            hostname = "ed";
            system = "aarch64-linux";
          };
        };

        packages.aarch64-linux = {
          ed-sdimage = builders.mkSdImage {
            hostname = "ed";
            extraModules = [
              inputs.sops-nix.nixosModules.sops
            ];
          };
        };

        darwinConfigurations = {
          ein = builders.mkDarwin {hostname = "ein";};
          spike = builders.mkDarwin {hostname = "spike";};
        };
      };
    };
}
