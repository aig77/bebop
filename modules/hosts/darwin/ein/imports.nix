{config, ...}: {
  configurations.darwin.ein.module = {
    imports = with config.flake.modules.darwin; [base eyecandy remote-builder];
    remote-builder = {
      host = "jet";
      systems = ["aarch64-linux" "x86_64-linux"];
    };
  };
}
