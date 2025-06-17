{
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./packaging.nix ];

  environment.systemPackages = with pkgs; [
    htop
  ];

  boot = {
    loader.grub.enable = false;

    consoleLogLevel = 7;

    kernelPatches = with lib.kernel; [
      {
        name = "no-ntfs";
        patch = null;
        extraStructuredConfig = {
          NTFS3_FS = no;
        };
      }
      {
        name = "rk312x";
        patch = null;
        extraStructuredConfig = {
          CLK_RK312X = yes;
        };
      }
    ];
  };

  fileSystems = {
    # TODO fix, broken af.
    "/" = {
      device = "/dev/disk/by-partlabel/userdata";
    };
  };

  networking = {
    wireless = {
      enable = true;
    };
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";

  nixpkgs = {
    buildPlatform = "x86_64-linux";
    hostPlatform = lib.recursiveUpdate lib.systems.examples.armv7l-hf-multiplatform {
      gcc = {
        arch = "armv7ve";
        fpu = "neon-vfpv4";
      };
    };
  };
}
