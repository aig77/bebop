# Runs unpatched foreign binaries (upstream tarballs, GitHub release assets,
# anything a tool downloads for itself) by shimming the dynamic loader path.
# Nothing here is needed for nix-built packages.
#
# The list is deliberately short. nixpkgs already appends its own default set
# (zlib, zstd, cc, curl, openssl, attr, libssh, bzip2, libxml2, acl, libsodium,
# util-linux, xz, systemd) automatically, because list options concatenate. So
# what follows is only the delta for GUI and editor tooling, not a re-listing.
#
# When something still fails, do not guess. The error names the library:
#
#   error while loading shared libraries: libfoo.so.1: cannot open shared object file
#
# Find the provider and add just that package:
#
#   nix run github:nix-community/nix-index-database -- lib/libfoo.so.1 --top-level
#
# A full 120-entry community list exists at wiki.nixos.org/wiki/Nix-ld. It is a
# stopgap for people running Unity, Steam, AppImages, SDL and GTK2 titles, and
# it costs a multi-gigabyte buildEnv in every login shell. Do not paste it.
_: {
  flake.modules.nixos.nix-ld = {pkgs, ...}: {
    programs.nix-ld = {
      enable = true;

      # Only what editor and GUI tooling dlopens at runtime.
      libraries = with pkgs; [
        # Display stack, for XWayland and foreign GL/Vulkan apps.
        libGL
        vulkan-loader
        libgbm
        libdrm
        libxkbcommon
        libva

        # Font and theme resolution for unpatched GUI apps.
        fontconfig
        freetype
        glib

        # Audio, for tools that grab or play media.
        pipewire
        alsa-lib
        libpulseaudio

        # Bundled browser engines, as shipped by many prebuilt app bundles.
        nss
        nspr

        # Session bus lookups from unpatched clients.
        dbus
      ];
    };
  };
}
