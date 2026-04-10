_: {
  flake.modules.homeManager.krabby = {
    lib,
    pkgs,
    ...
  }: let
    fetchCommand = "${pkgs.krabby}/bin/krabby name umbreon -s --no-title | ${pkgs.fastfetch}/bin/fastfetch --file-raw -";
  in {
    programs = {
      fish = {
        shellAliases = {
          fetch = fetchCommand;
          fastfetch = fetchCommand;
          neofetch = fetchCommand;
        };
        interactiveShellInit = ''
          function fish_greeting
            ${fetchCommand}
          end
        '';
      };

      zsh = {
        shellAliases = {
          fetch = fetchCommand;
          fastfetch = fetchCommand;
          neofetch = fetchCommand;
        };
        initContent = lib.mkBefore ''
          ${fetchCommand}
        '';
      };
    };
  };
}
