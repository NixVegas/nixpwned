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

    consoleLogLevel = 8;

    initrd.compressor = "gzip";

    kernelParams = [
      "panic=3"
      "console=ttyFIQ0,115200n8"
      "boot.shell_on_fail"
      "initrd=0x62000000,0x0080000"
    ];

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
    "/" = {
      device = "/dev/mmcblk0p15";
      fsType = "ext4";
      autoResize = true;
    };
  };

  networking = {
    useDHCP = true;
    wireless = {
      enable = true;
      userControlled = {
        enable = true;
      };
      networks = {
        # your network here
      };
    };
    firewall = {
      allowedTCPPorts = [ 22 ];
    };
    hostName = "nixplay";
  };

  services = {
    openssh.enable = true;
    nscd = {
      # Fails to start with this kernel
      enable = false;
    };
    udev = {
      # Fails to start with this kernel (Android doesn't use it...)
      enable = false;
    };
    getty = {
      autologinUser = "nixos";
    };
  };

  # since we disable nscd
  system.nssModules = lib.mkForce [ ];

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };

  security.sudo.wheelNeedsPassword = false;

  # This is already in the kernel command line (still doesn't seem to solve it)
  systemd.units."serial-getty@ttyFIQ0".enable = false;

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
