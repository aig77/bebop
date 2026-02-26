{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [inputs.zen-browser.homeModules.default];

  programs.zen-browser = {
    enable = true;
    suppressXdgMigrationWarning = true;

    profiles.${config.var.username} = {
      isDefault = true;
      extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
        bitwarden
        darkreader
        ublock-origin
      ];
    };

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

      DNSOverHTTPS = {
        Enabled = true;
        Value = "increased";
        ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
      };

      Preferences = {
        "browser.contentblocking.category" = {Value = "strict";};
        "dom.security.https_only_mode" = {Value = true;};
      };

      SearchEngines = {
        Default = "Brave";
        PreventInstalls = false;
        Remove = ["Google" "Bing" "Yahoo"];
        Add = [
          {
            Name = "Brave";
            Method = "GET";
            URLTemplate = "https://search.brave.com/search?q={searchTerms}";
          }
        ];
      };
    };
  };

  stylix.targets.zen-browser.profileNames = ["${config.var.username}"];
}
