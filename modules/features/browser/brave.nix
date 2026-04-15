{
  flake.modules.homeManager.gui = {pkgs, ...}: {
    programs.chromium = {
      enable = false;
      package = pkgs.brave;
      extensions = [
        {id = "nngceckbapebfimnlniiiahkandclblb";} # bitwarden
        {id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";} # dark reader
      ];
    };
  };
}
