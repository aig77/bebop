_: {
  flake.modules.nixos.forgejo = {
    config,
    pkgs,
    lib,
    ...
  }: let
    subdomain = "git";
    domain = config.sops.placeholder."cloudflare/service-domain";
    stateDir = config.services.forgejo.stateDir;
    customDir = config.services.forgejo.customDir;
    configPath = "${customDir}/conf/app.ini";
    forgejo = config.services.forgejo.package;
    catppuccinTheme = pkgs.fetchzip {
      url = "https://git.bros.ninja/mike/neptune-forgejo/archive/v0.6.0.tar.gz";
      hash = "sha256-8Hf8uML7X7r1h3L18CKI2LL2wVHBN466tI4lE6I0COI=";
    };
    mauveIcon = pkgs.fetchurl {
      url = "https://files.svgcdn.io/catppuccin/forgejo.svg";
      hash = "sha256-Pn6UEVQF5KQzyIa++lxivJyfEhOG3yJ5ZOXXFV+sFZU=";
    };
    mauveBranding =
      pkgs.runCommand "forgejo-mauve-branding" {
        nativeBuildInputs = [pkgs.imagemagick];
      } ''
        mkdir -p $out
        sed -e 's/#f5a97f/#cba6f7/g' -e 's/#ed8796/#b4befe/g' ${mauveIcon} > $out/logo.svg
        cp $out/logo.svg $out/favicon.svg
        magick -background none $out/logo.svg -resize 512x512 $out/logo.png
        magick -background none $out/logo.svg -resize 180x180 $out/favicon.png
        magick -background none $out/logo.svg -resize 180x180 $out/apple-touch-icon.png
      '';
    catppuccinAccents = [
      "rosewater"
      "flamingo"
      "pink"
      "mauve"
      "red"
      "maroon"
      "peach"
      "yellow"
      "green"
      "teal"
      "sky"
      "sapphire"
      "blue"
      "lavender"
    ];
    catppuccinFlavors = ["latte" "frappe" "macchiato" "mocha"];
    catppuccinThemes =
      lib.concatStringsSep ","
      (["forgejo-auto" "forgejo-light" "forgejo-dark"]
        ++ map (a: "catppuccin-${a}-auto") catppuccinAccents
        ++ lib.concatMap (f: map (a: "catppuccin-${f}-${a}") catppuccinAccents) catppuccinFlavors);
  in {
    var.services.forgejo = {
      inherit subdomain;
      port = config.ports.forgejo;
      public = true;
      auth = false;
      backup = {
        paths = [
          "/var/lib/backups/forgejo.sql"
          "${stateDir}/repositories"
          "${stateDir}/data"
          customDir
        ];
        prepareCommand = ''
          mkdir -p /var/lib/backups
          ${pkgs.util-linux}/bin/runuser -u postgres -- ${pkgs.postgresql}/bin/pg_dump ${config.services.forgejo.database.name} > /var/lib/backups/forgejo.sql
        '';
      };
      monitor = {
        enable = true;
        type = "http";
        path = "/api/healthz";
        conditions = [
          "[STATUS] == 200"
          "[BODY].status == pass"
        ];
      };
      homepage = {
        enable = true;
        icon = "si:forgejo";
      };
    };

    sops = {
      secrets = {
        "cloudflare/service-domain" = {};
        "forgejo/bootstrap-admin-email" = {};
        "forgejo/smtp-password" = {};
        "forgejo/runner-token" = {};
      };

      templates = {
        "forgejo.env" = {
          mode = "0444";
          content = ''
            FORGEJO_ADMIN_EMAIL=${config.sops.placeholder."forgejo/bootstrap-admin-email"}
          '';
        };

        "forgejo-runner.env" = {
          mode = "0400";
          content = ''
            TOKEN=${config.sops.placeholder."forgejo/runner-token"}
          '';
        };

        "forgejo-domain".content = "${subdomain}.${domain}";
        "forgejo-root-url".content = "https://${subdomain}.${domain}/";
        "forgejo-mailer-from".content = "forgejo@resend.${domain}";
      };
    };

    services.forgejo = {
      enable = true;
      database.type = "postgres";
      lfs.enable = true;
      settings = {
        server = {
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = config.ports.forgejo;
          DISABLE_SSH = true;
          INSTALL_LOCK = true;
          RUN_MODE = "prod";
        };
        service = {
          DISABLE_REGISTRATION = false;
          REGISTER_EMAIL_CONFIRM = true;
          REGISTER_MANUAL_CONFIRM = true;
          ENABLE_CAPTCHA = true;
          ENABLE_NOTIFY_MAIL = true;
          REQUIRE_SIGNIN_VIEW = false;
        };
        mailer = {
          ENABLED = true;
          PROTOCOL = "smtps";
          SMTP_ADDR = "smtp.resend.com";
          SMTP_PORT = 465;
          USER = "resend";
        };
        session = {
          COOKIE_SECURE = true;
          COOKIE_SAMESITE = "lax";
        };
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };
        ui = {
          DEFAULT_THEME = "catppuccin-mauve-auto";
          THEMES = catppuccinThemes;
        };
      };
      secrets = {
        server = {
          DOMAIN = config.sops.templates."forgejo-domain".path;
          ROOT_URL = config.sops.templates."forgejo-root-url".path;
        };
        mailer = {
          PASSWD = config.sops.secrets."forgejo/smtp-password".path;
          FROM = config.sops.templates."forgejo-mailer-from".path;
        };
      };
    };

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.default = {
        enable = true;
        name = config.var.hostname;
        url = "http://127.0.0.1:${toString config.ports.forgejo}";
        tokenFile = config.sops.templates."forgejo-runner.env".path;
        labels = [
          "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
          "ubuntu-24.04:docker://catthehacker/ubuntu:act-24.04"
          "ubuntu-22.04:docker://catthehacker/ubuntu:act-22.04"
        ];
        settings = {
          container.options = "--memory=1g --cpus=2";
        };
      };
    };

    systemd.services.forgejo.preStart = lib.mkAfter ''
      mkdir -p ${customDir}/public/assets/css
      install -m 0644 ${catppuccinTheme}/public/assets/css/theme-catppuccin-*.css ${customDir}/public/assets/css/

      mkdir -p ${customDir}/public/assets/img
      install -m 0644 \
        ${mauveBranding}/logo.svg \
        ${mauveBranding}/logo.png \
        ${mauveBranding}/favicon.svg \
        ${mauveBranding}/favicon.png \
        ${mauveBranding}/apple-touch-icon.png \
        ${customDir}/public/assets/img/

      set -a
      . ${config.sops.templates."forgejo.env".path}
      set +a
      if ! ${forgejo}/bin/forgejo admin user list --config ${configPath} | ${pkgs.gnugrep}/bin/grep -qw ${config.var.username}; then
        ${forgejo}/bin/forgejo admin user create \
          --config ${configPath} \
          --username ${config.var.username} \
          --email "$FORGEJO_ADMIN_EMAIL" \
          --admin \
          --random-password \
          --must-change-password
      fi
    '';
  };
}
