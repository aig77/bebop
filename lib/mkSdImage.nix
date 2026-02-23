{inputs, ...}: {
  mkSdImage = {
    hostname,
    system ? "aarch64-linux",
    extraModules ? [],
  }:
    (inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs hostname;};
      modules =
        [
          "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          {
            nixpkgs.config = {
              allowUnfree = true;
              allowBroken = true;
            };
          }
          ../hosts/nixos/${hostname}/configuration.nix
        ]
        ++ extraModules;
    })
    .config
    .system
    .build
    .sdImage;
}
