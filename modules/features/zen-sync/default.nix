_: {
  flake.modules.homeManager.zen-sync = {
    config,
    inputs,
    lib,
    pkgs,
    ...
  }: let
    mainProgram = config.programs.zen-browser.package.meta.mainProgram;
    realZen = "${config.programs.zen-browser.package}/bin/${mainProgram}";

    zenSync = pkgs.stdenv.mkDerivation {
      pname = "zen-sync";
      version = "unstable-2026-11-11";

      src = pkgs.fetchFromGitHub {
        owner = "enisbu";
        repo = "zen-sync";
        rev = "11133819d6d4e558d7bcc45ce25ac8e328d36b98";
        hash = "sha256-MrWe97S18GIG1bZOpVXkTr9xXvzVg8F1bqEES3IAUJw=";
      };

      nativeBuildInputs = [pkgs.makeWrapper];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/zen-sync $out/bin
        install -m755 zen-sync $out/lib/zen-sync/zen-sync
        install -m644 merge.py cloud.py $out/lib/zen-sync/
        patchShebangs $out/lib/zen-sync

        makeWrapper $out/lib/zen-sync/zen-sync $out/bin/zen-sync \
          --prefix PATH : ${lib.makeBinPath [pkgs.coreutils pkgs.python3 pkgs.age pkgs.procps]} \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.lz4]}

        runHook postInstall
      '';
    };

    metaHelper = pkgs.writeShellScriptBin "zen-sync-meta" ''
      set -euo pipefail

      export PATH="${lib.makeBinPath [pkgs.age pkgs.coreutils pkgs.python3]}:$PATH"

      # shellcheck source=/dev/null
      source "''${XDG_CONFIG_HOME:-$HOME/.config}/zen-sync/config"

      export R2_ACCOUNT_ID R2_ACCESS_KEY R2_SECRET_KEY R2_BUCKET AGE_MODE
      export AGE_KEY_PATH="''${AGE_KEY_PATH:-}"
      export ZEN_SYNC_LIB="${zenSync}/lib/zen-sync"

      exec ${pkgs.python3}/bin/python3 ${./zen-sync-meta.py}
    '';

    launcher = pkgs.writeShellScriptBin "zen-sync-run" ''
      export PATH="${lib.makeBinPath [
        pkgs.coreutils
        pkgs.findutils
        pkgs.libnotify
        pkgs.lsof
        pkgs.procps
        pkgs.python3
        pkgs.util-linux
        zenSync
      ]}:$PATH"

      REAL_ZEN="${realZen}"
      PROC_NAME="${mainProgram}"
      ZEN_SYNC_BIN="${zenSync}/bin/zen-sync"
      META_BIN="${metaHelper}/bin/zen-sync-meta"

      ${builtins.readFile ./zen-sync-run.sh}
    '';

    menu = pkgs.writeShellScriptBin "zen-sync-menu" ''
      export PATH="${lib.makeBinPath [
        pkgs.coreutils
        pkgs.fuzzel
        pkgs.gnused
        pkgs.libnotify
        pkgs.procps
        pkgs.util-linux
        zenSync
        launcher
      ]}:$PATH"

      PROC_NAME="${mainProgram}"

      ${builtins.readFile ./zen-sync-menu.sh}
    '';
  in {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    config = {
      # zen-sync is intentionally HM-only. The NixOS sops module does not know
      # about these keys, so the feature can be imported and removed without
      # touching a host's system configuration.
      sops = {
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        defaultSopsFile = ../../aspects/secrets/secrets.yaml;
        defaultSopsFormat = "yaml";

        secrets = {
          "zen-sync/r2-account-id" = {
            mode = "0400";
          };
          "zen-sync/r2-access-key" = {
            mode = "0400";
          };
          "zen-sync/r2-secret-key" = {
            mode = "0400";
          };
          "zen-sync/r2-bucket" = {
            mode = "0400";
          };
          "zen-sync/age-key" = {
            mode = "0400";
          };
        };

        templates."zen-sync-config" = {
          path = "${config.xdg.configHome}/zen-sync/config";
          mode = "0400";
          content = ''
            MODE="r2"
            R2_ACCOUNT_ID="${config.sops.placeholder."zen-sync/r2-account-id"}"
            R2_ACCESS_KEY="${config.sops.placeholder."zen-sync/r2-access-key"}"
            R2_SECRET_KEY="${config.sops.placeholder."zen-sync/r2-secret-key"}"
            R2_BUCKET="${config.sops.placeholder."zen-sync/r2-bucket"}"
            AGE_MODE="keyfile"
            AGE_KEY_PATH="${config.sops.secrets."zen-sync/age-key".path}"
            LOCAL_PROFILE="$HOME/.config/zen/default"
          '';
        };
      };

      home.packages = [
        zenSync
        launcher
        menu
        pkgs.fuzzel
      ];

      # Home Manager sops reads this key as the user. Keep it private.
      home.activation.zenSyncAgeKeyMode = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
          chmod 600 "$HOME/.config/sops/age/keys.txt" 2>/dev/null || true
        fi
      '';

      # The stock desktop entry launches zen-beta directly, bypassing the
      # lifecycle wrapper. Override it in the user data directory.
      xdg.desktopEntries."zen-beta" = {
        name = "Zen Browser";
        genericName = "Web Browser";
        exec = "${launcher}/bin/zen-sync-run %U";
        icon = "zen-browser";
        categories = ["Network" "WebBrowser"];
        mimeType = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "application/vnd.mozilla.xul+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
        startupNotify = true;
        settings.StartupWMClass = "zen-beta";
        actions = {
          "new-private-window" = {
            name = "New Private Window";
            exec = "${launcher}/bin/zen-sync-run --private-window %U";
          };
          "new-window" = {
            name = "New Window";
            exec = "${launcher}/bin/zen-sync-run --new-window %U";
          };
        };
      };

      systemd.user.services.zen-sync-flush = {
        Unit.Description = "Retry Zen session sync";
        Service = {
          Type = "oneshot";
          ExecStart = "${launcher}/bin/zen-sync-run --flush";
        };
      };

      systemd.user.timers.zen-sync-flush = {
        Unit.Description = "Retry Zen session sync every 15 minutes";
        Timer = {
          OnCalendar = "*:0/15";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
