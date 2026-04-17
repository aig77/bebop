_: {
  flake.modules.homeManager.gui = {
    pkgs,
    lib,
    var,
    ...
  }: let
    inherit (pkgs.stdenv) isDarwin;
    ghosttyPkg =
      if isDarwin
      then null
      else pkgs.ghostty;
    hasPkg = ghosttyPkg != null;
  in
    lib.mkIf (var.terminal == "ghostty") {
      programs.ghostty = {
        enable = true;
        package = ghosttyPkg;

        installBatSyntax = hasPkg;
        installVimSyntax = hasPkg;

        settings = {
          window-padding-x = 24;
          window-padding-y = 16;
          window-padding-balance = true;
          shell-integration-features = "ssh-env,ssh-terminfo";
          background-opacity =
            if isDarwin
            then 1.0
            else 0.9;
        };
      };
    };
}
