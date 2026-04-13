_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    programs.claude-code = {
      enable = true;
      plugins = [
        # update with claude plugin update caveman
        (pkgs.fetchFromGitHub {
          owner = "JuliusBrussee";
          repo = "caveman";
          rev = "63e797cd753b";
          hash = "sha256-pHPMQGr9/ufsUODmqHm2T6sCOaeOOJl4baX4OeeYp6k=";
        })
      ];
      skills.new-project = ./skills/new-project.md;
    };
  };
}
