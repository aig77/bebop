{config, ...}: {
  configurations.darwin.spike.module = {
    imports = with config.flake.modules.darwin; [base];
  };
}
