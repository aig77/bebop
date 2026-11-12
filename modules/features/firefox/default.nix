_: {
  flake.modules.homeManager.firefox = {
    inputs,
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    sync = osConfig.serviceRegistry.syncserver;
    searx = osConfig.serviceRegistry.searx;
    syncPort =
      if sync.servePort != null
      then sync.servePort
      else sync.port;
    searxPort =
      if searx.servePort != null
      then searx.servePort
      else searx.port;
    tailnet = osConfig.net.tailnet;
  in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        configPath = ".mozilla/firefox";

        policies = {
          ExtensionSettings."{2adf0361-e6d8-4b74-b3bc-3f450e8ebb69}" = {
            installation_mode = "normal_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/file/3989617/catppuccin_mocha_blue_git-2.0.xpi";
          };
          AutofillAddressEnabled = true; # allow address autofill
          AutofillCreditCardEnabled = false; # never save card numbers
          DisableAppUpdate = true; # nix manages updates, not the browser
          DisableFeedbackCommands = true; # remove "Submit Feedback" menu entries
          DisableFirefoxStudies = true; # opt out of Mozilla experiments
          DisablePocket = true; # remove Pocket integration
          DisableTelemetry = true; # no usage data sent to Mozilla
          DontCheckDefaultBrowser = true; # suppress "set as default" prompt
          NoDefaultBookmarks = true; # start with no Mozilla-provided bookmarks
          OfferToSaveLogins = false; # bitwarden handles passwords
          PasswordManagerEnabled = false; # never store passwords in Firefox

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

            # Keep passwords and form data out of the browser.
            "signon.rememberSignons" = false;
            "signon.autofillForms" = false;

            # Firefox Sync must not fight the declarative profile.
            "services.sync.engine.prefs" = false;
            "services.sync.engine.addons" = false;
            "services.sync.engine.passwords" = false;
            "services.sync.engine.addresses" = false;
            "services.sync.engine.creditcards" = false;
            "services.sync.engine.forms" = false;

            # Disable AI chat and smart tab groups.
            "browser.ml.chat.enabled" = false;
            "browser.ml.chat.menu" = false;
            "browser.ml.chat.sidebar" = false;
            "browser.ml.chat.shortcuts" = false;
            "browser.ml.chat.page" = false;
            "browser.ml.chat.page.footerBadge" = false;
            "browser.ml.chat.page.menuBadge" = false;
            "browser.ml.linkPreview.enabled" = false;
            "browser.tabs.groups.smart.enabled" = false;
            "browser.tabs.groups.smart.userEnabled" = false;
            "browser.tabs.groups.smart.optin" = false;
            "browser.shopping.experience2023.enabled" = false; # Review Checker

            # Remove sponsored and recommendation surfaces.
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;
            "browser.newtabpage.activity-stream.showWeather" = false;
            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
            "browser.messaging-system.whatsNewPanel.enabled" = false;
            "browser.aboutwelcome.enabled" = false;
            "browser.urlbar.quicksuggest.enabled" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
            "browser.urlbar.suggest.trending" = false;
            "browser.urlbar.suggest.recentsearches" = false;
            "browser.urlbar.suggest.searches" = false;
            "browser.search.suggest.enabled" = false;
            "browser.search.suggest.enabled.private" = false;
            "browser.urlbar.showSearchSuggestionsFirst" = false;

            # Mozilla telemetry and crash reporting.
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "app.normandy.enabled" = false;
            "app.shield.optoutstudies.enabled" = false;
            "breakpad.reportURL" = "";
            "browser.crashReports.unsubmittedCheck.enabled" = false;
            "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
            "browser.tabs.crashReporting.sendReport" = false;

            # Mozilla lookups and promos.
            "browser.region.network.url" = "";
            "browser.region.update.enabled" = false;
            "browser.search.update" = false;
            "browser.topsites.contile.enabled" = false;
            "browser.vpn_promo.enabled" = false;
            "browser.promo.focus.enabled" = false;
            "extensions.update.enabled" = false;
            "extensions.htmlaboutaddons.recommendations.enabled" = false;

            # Network callbacks and prefetching.
            "network.captive-portal-service.enabled" = false;
            "network.connectivity-service.enabled" = false;
            "network.trr.mode" = 5;
            "network.dns.disablePrefetch" = true;
            "network.prefetch-next" = false;
            "network.predictor.enabled" = false;
            "network.http.speculative-parallel-limit" = 0;
            "browser.safebrowsing.downloads.remote.enabled" = false;

            # Tracking and leak protection.
            "privacy.globalprivacycontrol.enabled" = true;
            "privacy.donottrackheader.enabled" = true;
            "privacy.trackingprotection.emailtracking.enabled" = true;
            "beacon.enabled" = false;
            "browser.send_pings" = false;
            "media.peerconnection.ice.default_address_only" = true;
            "media.peerconnection.ice.no_host" = true;
            "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;

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

          SearchEngines = {
            Remove = [
              "Bing"
              "Google"
              "Mojeek"
              "Qwant"
              "Perplexity"
            ];

            Add = [
              {
                Name = "Brave";
                URLTemplate = "https://search.brave.com/search?q={searchTerms}";
                IconURL = "https://search.brave.com/favicon.ico";
                Alias = "@brave";
              }
              {
                Name = "SearXNG";
                URLTemplate = "https://${searx.host}.${tailnet}:${toString searxPort}/search?q={searchTerms}";
                IconURL = "https://${searx.host}.${tailnet}:${toString searxPort}/favicon.ico";
                Alias = "@searx";
              }
              {
                Name = "NixOS Packages";
                URLTemplate = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
                IconURL = "https://search.nixos.org/favicon.ico";
                Alias = "@pkg";
              }
              {
                Name = "NixOS Options";
                URLTemplate = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
                IconURL = "https://search.nixos.org/favicon.ico";
                Alias = "@opt";
              }
              {
                Name = "Home Manager Options";
                URLTemplate = "https://home-manager-options.extranix.com/?query={searchTerms}";
                IconURL = "https://home-manager-options.extranix.com/favicon.ico";
                Alias = "@hm";
              }
            ];
          };
        };

        profiles.default = {
          id = 0;
          name = "default";
          isDefault = true;

          settings = {
            "browser.urlbar.suggest.openpage" = false; # suppress "switch to tab" suggestions in URL bar
            "browser.startup.page" = 3; # restore the previous session on launch
            "browser.startup.homepage" = "about:blank"; # no Firefox home page
            "browser.newtabpage.enabled" = false; # blank new tabs
            "browser.uidensity" = 1; # compact toolbar density
            "extensions.autoDisableScopes" = 0; # keep profile extensions enabled
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # enable userChrome.css
            "extensions.activeThemeID" = "{2adf0361-e6d8-4b74-b3bc-3f450e8ebb69}"; # Catppuccin Mocha - Blue

            "identity.sync.tokenserver.uri" = "https://${sync.host}.${tailnet}:${toString syncPort}/1.0/sync/1.5";

            "services.sync.engine.tabs" = true;
            "services.sync.engine.bookmarks" = true;
            "services.sync.engine.history" = true;
            "services.sync.engine.prefs" = false;
            "services.sync.engine.addons" = false;
            "services.sync.engine.passwords" = false;
            "services.sync.engine.addresses" = false;
            "services.sync.engine.creditcards" = false;
            "services.sync.engine.forms" = false;
          };

          userChrome = ''
            /* sharp tabs and URL/search bar */
            .tabbrowser-tab .tab-background,
            .tabbrowser-tab .tab-content,
            #urlbar,
            #urlbar-background,
            #searchbar {
              border-radius: 0 !important;
            }
          '';

          extensions.force = true;
          extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
            bitwarden
            darkreader
            stylus
            ublock-origin
          ];
        };
      };

      stylix.targets.firefox = {
        enable = true;
        profileNames = ["default"];
      };
    };
}
