_: {
  flake.modules.nixos.grafana-dashboards-loki = {pkgs, ...}: let
    loki = {
      type = "loki";
      uid = "loki";
    };

    dashboard = {
      uid = "sadlil-loki-apps-dashboard";
      title = "Logs";
      tags = ["loki" "logs"];
      timezone = "browser";
      schemaVersion = 39;
      version = 1;
      refresh = "";
      editable = true;
      graphTooltip = 0;
      time = {
        from = "now-3h";
        to = "now";
      };
      annotations.list = [];
      links = [];
      templating.list = [
        {
          name = "host";
          label = "Host";
          type = "query";
          datasource = loki;
          query = "label_values(hostname)";
          refresh = 1;
          includeAll = true;
          multi = true;
          allValue = ".*";
          current = {};
          hide = 0;
        }
        {
          name = "unit";
          label = "Unit";
          type = "query";
          datasource = loki;
          query = "label_values({job=\"journal\", hostname=~\"$host\"}, unit)";
          refresh = 1;
          includeAll = true;
          multi = true;
          allValue = ".*";
          current = {};
          hide = 0;
        }
        {
          name = "search";
          label = "Search";
          type = "textbox";
          query = "";
          current = {};
          hide = 0;
        }
      ];
      panels = [
        {
          id = 1;
          type = "logs";
          title = "Journal logs";
          datasource = loki;
          gridPos = {
            h = 16;
            w = 24;
            x = 0;
            y = 0;
          };
          targets = [
            {
              refId = "A";
              datasource = loki;
              expr = "{job=\"journal\", hostname=~\"$host\", unit=~\"$unit\"} |= \"$search\"";
            }
          ];
          options = {
            showTime = true;
            showLabels = true;
            showCommonLabels = false;
            wrapLogMessage = true;
            prettifyLogMessage = false;
            enableLogDetails = true;
            dedupStrategy = "none";
            sortOrder = "Descending";
          };
          fieldConfig = {
            defaults = {};
            overrides = [];
          };
        }
        {
          id = 2;
          type = "timeseries";
          title = "Log volume";
          datasource = loki;
          gridPos = {
            h = 8;
            w = 24;
            x = 0;
            y = 16;
          };
          targets = [
            {
              refId = "A";
              datasource = loki;
              expr = "sum by (hostname, unit) (count_over_time({job=\"journal\", hostname=~\"$host\", unit=~\"$unit\"} |= \"$search\" [$__interval]))";
              legendFormat = "{{hostname}} {{unit}}";
            }
          ];
          fieldConfig = {
            defaults = {
              unit = "short";
            };
            overrides = [];
          };
          options = {
            legend = {
              displayMode = "list";
              placement = "bottom";
              showLegend = true;
            };
            tooltip = {
              mode = "multi";
              sort = "none";
            };
          };
        }
        {
          id = 3;
          type = "logs";
          title = "Errors";
          datasource = loki;
          gridPos = {
            h = 12;
            w = 24;
            x = 0;
            y = 24;
          };
          targets = [
            {
              refId = "A";
              datasource = loki;
              expr = "{job=\"journal\", hostname=~\"$host\", unit=~\"$unit\"} |~ \"(?i)error|fail|fatal|panic|critical\"";
            }
          ];
          options = {
            showTime = true;
            showLabels = true;
            showCommonLabels = false;
            wrapLogMessage = true;
            prettifyLogMessage = false;
            enableLogDetails = true;
            dedupStrategy = "none";
            sortOrder = "Descending";
          };
          fieldConfig = {
            defaults = {};
            overrides = [];
          };
        }
      ];
    };
  in {
    observability.grafanaDashboards."loki.json".source =
      (pkgs.formats.json {}).generate "loki-dashboard.json" dashboard;
  };
}
