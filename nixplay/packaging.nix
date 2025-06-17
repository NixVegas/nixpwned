{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib.options) mkOption;
  inherit (lib) types;

  system = pkgs.nixplaySystem {
    inherit (config.system.build) toplevel kernel;
  };
in
{
  options = {
    system.build.nixplay = {
      params = mkOption {
        description = "The Nixplay parameters image";
        type = types.package;
        default = system.params;
        readOnly = true;
      };
      kernel = mkOption {
        description = "The Nixplay kernel image";
        type = types.package;
        default = system.kernel;
        readOnly = true;
      };
      boot = mkOption {
        description = "The Nixplay boot image";
        type = types.package;
        default = system.boot;
        readOnly = true;
      };
      system = mkOption {
        description = "The Nixplay system image";
        type = types.package;
        default = system.system;
        readOnly = true;
      };
      all = mkOption {
        description = "All Nixplay images";
        type = types.package;
        default = system;
        readOnly = true;
      };
    };
  };
}
