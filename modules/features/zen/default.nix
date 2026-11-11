_: {
  flake.modules.homeManager.zen = {
    inputs,
    config,
    pkgs,
    lib,
    ...
  }: let
    zenPkg = config.programs.zen-browser.package;
    realZen = "${zenPkg}/bin/${zenPkg.meta.mainProgram}";
  in {
    imports = [inputs.zen-browser.homeModules.beta];

    stylix.targets.zen-browser.enable = false;

    # Strips the strange binary path name. If the zen-sync feature is imported,
    # its launcher is in PATH and takes over the lifecycle.
    home.packages = [
      (pkgs.writeShellScriptBin "zen" ''
        if command -v zen-sync-run >/dev/null 2>&1; then
          exec zen-sync-run "$@"
        fi

        exec ${realZen} "$@"
      '')
    ];

    programs.zen-browser = {
      enable = true;

      policies = {
        AutofillAddressEnabled = true; # allow address autofill
        AutofillCreditCardEnabled = false; # never save card numbers
        DisableAppUpdate = true; # nix manages updates, not the browser
        DisableFeedbackCommands = false; # remove "Submit Feedback" menu entries
        DisableFirefoxStudies = true; # opt out of Mozilla experiments
        DisablePocket = true; # remove Pocket integration
        DisableTelemetry = true; # no usage data sent to Mozilla
        DontCheckDefaultBrowser = true; # suppress "set as default" prompt
        NoDefaultBookmarks = true; # start with no Mozilla-provided bookmarks
        OfferToSaveLogins = false; # bitwarden handles passwords

        EnableTrackingProtection = {
          Value = true; # enable Enhanced Tracking Protection
          Locked = true; # prevent user from disabling it
          Cryptomining = true; # block cryptominer scripts
          Fingerprinting = true; # block fingerprinting scripts
        };

        SanitizeOnShutdown = {
          FormData = true; # clear form history on exit
          Cache = true; # clear disk cache on exit
        };

        Preferences = {
          "browser.aboutConfig.showWarning" = false; # skip the about:config warning page
          "browser.contentblocking.category" = "strict"; # use strict ETP level
          "browser.tabs.warnOnClose" = false; # no "close multiple tabs?" dialog
          "browser.tabs.hoverPreview.enabled" = true; # show tab thumbnail on hover

          "privacy.resistFingerprinting" = true; # randomize browser fingerprint
          "privacy.resistFingerprinting.randomization.canvas.use_siphash" = true; # stronger canvas noise algorithm
          "privacy.resistFingerprinting.randomization.daily_reset.enabled" = true; # rotate fingerprint daily
          "privacy.resistFingerprinting.randomization.daily_reset.private.enabled" = true; # also rotate in private windows
          "privacy.resistFingerprinting.block_mozAddonManager" = true; # hide extension list from pages
          "privacy.spoof_english" = 1; # send en-US Accept-Language regardless of system locale

          "privacy.firstparty.isolate" = true; # partition cookies/storage per top-level domain
          "network.cookie.cookieBehavior" = 5; # reject third-party cookies (dFPI mode)
          "dom.battery.enabled" = false; # hide battery status API

          "gfx.webrender.all" = true; # force GPU-accelerated WebRender compositor
          "network.http.http3.enabled" = true; # enable QUIC/HTTP3
          "network.socket.ip_addr_any.disabled" = true; # prevent binding to 0.0.0.0 (WebRTC leak mitigation)
        };
      };

      profiles.default = {
        # No official docs for zen.* prefs. Source of truth:
        # All prefs:     https://github.com/zen-browser/desktop/tree/main/prefs/zen
        # Nix HM module: https://github.com/0xc000022070/zen-browser-flake
        settings = {
          "zen.workspaces.continue-where-left-off" = true; # reopen last active workspace on launch
          "zen.workspaces.natural-scroll" = true; # trackpad-direction workspace switching
          "zen.view.compact.hide-tabbar" = true; # hide tab bar in compact mode
          "zen.view.compact.hide-toolbar" = false; # keep toolbar visible in compact mode
          "zen.view.compact.enable-at-startup" = true; # start in compact mode
          "zen.view.compact.animate-sidebar" = true; # slide sidebar in/out instead of jumping
          "zen.view.sidebar-expanded" = true; # start with sidebar expanded
          "zen.view.use-single-toolbar" = false; # keep nav bar and tab bar separate
          "zen.welcome-screen.seen" = true; # skip the first-launch welcome screen
          "zen.urlbar.behavior" = "float"; # URL bar floats over page rather than docking
          "zen.theme.content-element-separation" = 0; # remove padding/border-radius around content pane
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # enable userChrome.css and userContent.css
          "browser.urlbar.suggest.openpage" = false; # suppress "switch to tab" suggestions in URL bar
        };

        extensions.packages = with inputs.firefox-addons.packages.${pkgs.system}; [
          bitwarden
          darkreader
          stylus
          ublock-origin
        ];

        # Mod UUIDs from https://zen-browser.app/mods
        mods = [
          "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
        ];

        search = {
          force = true;
          default = "Brave";
          engines = {
            "Brave" = {
              urls = [
                {
                  template = "https://search.brave.com/search?q={searchTerms}";
                  params = [
                    {
                      name = "query";
                      value = "searchTerms";
                    }
                  ];
                }
              ];
              icon = "https://styles.redditmedia.com/t5_h6drn/styles/communityIcon_qrrthyodef771.png";
              definedAliases = ["@brave"];
            };
            "NixOS Packages" = {
              urls = [{template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";}];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@pkg"];
            };
            "NixOS Options" = {
              urls = [{template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";}];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@opt"];
            };
            "Home Manager Options" = {
              urls = [{template = "https://home-manager-options.extranix.com/?query={searchTerms}";}];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@hm"];
            };
          };
        };

        # Spaces, pins, containers, and open tabs are runtime state owned by
        # R2 through zen-sync. Do not declare them here: the zen-browser
        # module would rewrite zen-sessions.jsonlz4 at activation and fight
        # the synced session.
      };
    };

    # Added due to this Darwin specific issue
    # https://github.com/0xc000022070/zen-browser-flake/issues/285
    home.activation.zenUnlockProfilesIni = lib.mkIf pkgs.stdenv.isDarwin (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        profilesIni="$HOME/Library/Application Support/Zen/profiles.ini"
        if [ -L "$profilesIni" ]; then
          src="$(readlink "$profilesIni")"
          rm "$profilesIni"
          cp "$src" "$profilesIni"
          chmod 644 "$profilesIni"
        fi
      ''
    );
  };
}
