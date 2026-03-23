_: {
  flake.modules.homeManager.swaync = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors.withHashtag;
    font = config.stylix.fonts.sansSerif.name;
  in {
    home.packages = [pkgs.libnotify];

    services.swaync = {
      enable = true;

      settings = {
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        control-center-layer = "top";
        layer-shell = true;
        cssPriority = "application";
        control-center-margin-top = 10;
        control-center-margin-bottom = 10;
        control-center-margin-right = 10;
        control-center-margin-left = 0;
        notification-icon-size = 48;
        timeout = 5;
        timeout-low = 2;
        timeout-critical = 0;
        fit-to-screen = false;
        control-center-width = 420;
        control-center-height = 600;
        notification-window-width = 400;
        keyboard-shortcuts = true;
        image-visibility = "when-available";
        transition-time = 200;
        hide-on-clear = false;
        hide-on-action = true;
        widgets = ["title" "volume" "dnd" "notifications"];
        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear All";
          };
          volume = {
            label = "󰕾";
            show-per-app = false;
          };
          dnd = {
            text = "Do Not Disturb";
          };
        };
      };

      style = ''
        * {
          font-family: "${font}";
          font-size: 13px;
          transition: none;
        }

        .notification-row {
          outline: none;
          margin: 0;
          padding: 0;
        }

        .notification-row:hover {
          background: transparent;
        }

        .notification {
          border-radius: 12px;
          margin: 6px 0;
          padding: 0;
          box-shadow: none;
        }

        .notification-content {
          background: ${colors.base01};
          border: 1px solid ${colors.base03};
          border-radius: 12px;
          padding: 12px;
        }

        .notification-default-action {
          background: transparent;
          border: none;
          border-radius: 12px;
          padding: 0;
          margin: 0;
          color: ${colors.base05};
        }

        .notification-default-action:hover {
          background: ${colors.base02};
        }

        .close-button {
          background: transparent;
          border: none;
          border-radius: 50%;
          color: ${colors.base04};
          min-width: 24px;
          min-height: 24px;
          margin: 4px;
        }

        .close-button:hover {
          background: ${colors.base08};
          color: ${colors.base00};
        }

        .notification-action {
          background: ${colors.base02};
          border: 1px solid ${colors.base03};
          border-radius: 8px;
          color: ${colors.base05};
          padding: 4px 12px;
          margin: 4px;
        }

        .notification-action:hover {
          background: ${colors.base03};
        }

        .summary {
          color: ${colors.base05};
          font-weight: bold;
          font-size: 14px;
        }

        .body {
          color: ${colors.base04};
          font-size: 12px;
        }

        .app-name {
          color: ${colors.base0D};
          font-size: 11px;
        }

        .time {
          color: ${colors.base03};
          font-size: 11px;
        }

        .control-center {
          background: ${colors.base00};
          border: 1px solid ${colors.base03};
          border-radius: 16px;
          padding: 8px;
        }

        .control-center-list {
          background: transparent;
        }

        .control-center-list-placeholder {
          color: ${colors.base03};
          font-size: 14px;
        }

        .widget-title {
          margin: 4px 8px 8px 8px;
        }

        .widget-title > label {
          color: ${colors.base05};
          font-size: 15px;
          font-weight: bold;
        }

        .widget-title > button {
          color: ${colors.base05};
          background: ${colors.base02};
          border: none;
          border-radius: 8px;
          padding: 4px 12px;
          font-size: 12px;
        }

        .widget-title > button:hover {
          background: ${colors.base03};
        }

        .widget-dnd {
          margin: 4px 8px;
        }

        .widget-dnd > label {
          color: ${colors.base05};
          font-size: 13px;
        }

        .widget-dnd > switch {
          border-radius: 100px;
          background: ${colors.base02};
          border: 1px solid ${colors.base03};
        }

        .widget-dnd > switch:checked {
          background: ${colors.base0D};
          border-color: ${colors.base0D};
        }

        .widget-volume {
          margin: 4px 8px;
        }

        .widget-volume > box > label {
          color: ${colors.base0D};
          font-size: 16px;
          min-width: 24px;
        }

        .widget-volume scale {
          padding: 0 8px;
        }

        .widget-volume scale trough {
          background: ${colors.base02};
          border-radius: 100px;
          min-height: 6px;
          border: none;
        }

        .widget-volume scale trough highlight {
          background: ${colors.base0D};
          border-radius: 100px;
          min-height: 6px;
        }

        .widget-volume scale slider {
          background: ${colors.base05};
          border-radius: 50%;
          min-width: 18px;
          min-height: 18px;
          border: 2px solid ${colors.base0D};
          box-shadow: none;
        }

        .widget-volume scale slider:hover {
          background: ${colors.base0D};
        }

        .widget-dnd > switch slider {
          background: ${colors.base05};
          border-radius: 100px;
          min-width: 20px;
          min-height: 20px;
        }
      '';
    };
  };
}
