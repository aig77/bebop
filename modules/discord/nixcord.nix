_: {
  flake.modules.homeManager.gui = {pkgs, ...}: {
    home.packages = [pkgs.discord];
  };
}
# _: {
#   flake.modules.homeManager.gui = {inputs, ...}: {
#     imports = [inputs.nixcord.homeModules.nixcord];
#
#     programs.nixcord = {
#       enable = true;
#       config = {
#         frameless = true;
#         plugins = {
#           alwaysAnimate.enable = true;
#           betterFolders.enable = true;
#           fakeNitro.enable = true;
#           imageZoom.enable = true;
#           readAllNotificationsButton.enable = true;
#         };
#       };
#     };
#   };
# }
