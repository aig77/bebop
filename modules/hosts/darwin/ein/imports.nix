{config, ...}: {
  configurations.darwin.ein.module = {
    imports = with config.flake.modules.darwin; [base eyecandy];
  };
}
