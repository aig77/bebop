{
  programs.fastfetch = {
    enable = true;
    settings = {
      schema = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      display = {
        separator = "  │ ";
        color.separator = 245;
      };
      modules = [
        "break"
        {
          type = "title";
          color = {
            user = "cyan";
            at = "white";
            host = "cyan";
          };
        }
        "separator"
        {
          type = "os";
          key = "";
          keyColor = "red";
          format = "{2} {8}";
        }
        {
          type = "kernel";
          key = "";
          keyColor = "red";
          format = "{2}";
        }
        {
          type = "packages";
          key = "󰏖";
          keyColor = "red";
          format = "{1}";
        }
        {
          type = "wm";
          key = "";
          keyColor = "green";
          format = "{1}";
        }
        {
          type = "shell";
          key = "";
          keyColor = "green";
          format = "{1}";
        }
        {
          type = "terminal";
          key = "";
          keyColor = "green";
          format = "{1}";
        }
        {
          type = "cpu";
          key = "";
          keyColor = "blue";
          format = "{1}";
        }
        {
          type = "gpu";
          key = "";
          keyColor = "blue";
          format = "{2}";
          hideType = "integrated";
        }
        {
          type = "memory";
          key = "";
          keyColor = "blue";
          format = "{1} / {2}";
        }
        "break"
        {
          type = "colors";
          symbol = "circle";
        }
      ];
    };
  };
}
