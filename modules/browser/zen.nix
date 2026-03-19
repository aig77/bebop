_: {
  flake.modules.homeManager.gui = {
    pkgs,
    inputs,
    config,
    var,
    ...
  }: {
    imports = [inputs.zen-browser.homeModules.beta];

    programs.zen-browser = {
      enable = true;

      policies = {
        AutofillAddressEnabled = true;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        SanitizeOnShutdown = {
          FormData = true;
          Cache = true;
        };

        Preferences = {
          "browser.aboutConfig.showWarning" = false;
          "browser.contentblocking.category" = "strict";
          "browser.tabs.warnOnClose" = false;
          "browser.tabs.hoverPreview.enabled" = true;

          "privacy.resistFingerprinting" = true;
          "privacy.resistFingerprinting.randomization.canvas.use_siphash" = true;
          "privacy.resistFingerprinting.randomization.daily_reset.enabled" = true;
          "privacy.resistFingerprinting.randomization.daily_reset.private.enabled" = true;
          "privacy.resistFingerprinting.block_mozAddonManager" = true;
          "privacy.spoof_english" = 1;

          "privacy.firstparty.isolate" = true;
          "network.cookie.cookieBehavior" = 5;
          "dom.battery.enabled" = false;

          "gfx.webrender.all" = true;
          "network.http.http3.enabled" = true;
          "network.socket.ip_addr_any.disabled" = true;
        };
      };

      profiles.${var.username} = {
        extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          bitwarden
          darkreader
          ublock-origin
        ];

        settings = {
          "zen.workspaces.continue-where-left-off" = true;
          "zen.workspaces.natural-scroll" = true;
          "zen.view.compact.hide-tabbar" = true;
          "zen.view.compact.hide-toolbar" = true;
          "zen.view.sidebar-expanded" = false;
          "zen.view.use-single-toolbar" = false;
          "zen.view.compact.animate-sidebar" = true;
          "zen.welcome-screen.seen" = true;
          "zen.urlbar.behavior" = "float";
        };

        containersForce = true;
        containers = {
          Personal = {
            color = "green";
            icon = "fingerprint";
            id = 1;
          };
        };

        spacesForce = true;
        spaces = {
          "Space" = {
            id = "c6de089c-410d-4206-961d-ab11f988d40a";
            position = 1000;
          };
        };

        pinsForce = true;
        pins = let
          inherit (config.programs.zen-browser.profiles.${var.username}) containers;
        in {
          "GitHub" = {
            id = "d472f2f7-836e-4bd5-8144-6555137d4704";
            container = containers.Personal.id;
            url = "https://github.com";
            position = 100;
            isEssential = true;
          };
          "Vim Cheat Sheet" = {
            id = "0d8f97b9-86ae-4563-8082-18b1aec0570d";
            container = containers.Personal.id;
            url = "https://vim.rtorr.com";
            position = 102;
            isEssential = true;
          };
          "Tmux Cheat Sheet" = {
            id = "32f6fd7e-9bdc-4bb4-8244-4114f27a57df";
            container = containers.Personal.id;
            url = "https://tmuxcheatsheet.com/";
            position = 103;
            isEssential = true;
          };
        };

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
            "My NixOS" = {
              urls = [
                {
                  template = "https://mynixos.com/search?q={searchTerms}";
                  params = [
                    {
                      name = "query";
                      value = "searchTerms";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@nx"];
            };
          };
        };
      };
    };

    stylix.targets.zen-browser.profileNames = ["${var.username}"];
  };
}
