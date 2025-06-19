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

    initrd = {
      kernelModules = [ "mmc_block" ];
      postDeviceCommands = ''
        ls -al /dev >&2
      '';
    };

    kernelParams = [
      "earlycon=uart8250,mmio32,0x20068000"
      "initrd=0x62000000,0x0080000"
      "console=tty0"
      "console=ttyS0,115200n8"
      "boot.shell_on_fail"
      "panic=3"
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
          ARCH_ROCKCHIP = yes;
          ARM_ROCKCHIP_CPUFREQ = yes;

          SERIAL_CORE = yes;
          SERIAL_CORE_CONSOLE = yes;
          SERIAL_EARLYCON = yes;
          SERIAL_8250 = yes;
          SERIAL_8250_CONSOLE = yes;
          SERIAL_8250_DMA = yes;
          SERIAL_8250_NR_UARTS = freeform (toString 1);
          SERIAL_8250_RUNTIME_UARTS = freeform (toString 1);
          SERIAL_8250_FSL = yes;
          SERIAL_8250_DW = yes;

          FIQ = yes;

          ROCKCHIP_MBOX = yes;
          ROCKCHIP_SCR = yes;
          DWMAC_ROCKCHIP = yes;
          ROCKCHIP_PHY = yes;
          WL_ROCKCHIP = yes;
          ROCKCHIP_REMOTECTL = yes;
          ROCKCHIP_REMOTECTL_PWM = yes;
          SPI_ROCKCHIP = yes;
          PINCTRL_ROCKCHIP = yes;
          ROCKCHIP_IODOMAIN = yes;
          ROCKCHIP_THERMAL = yes;
          RK_VIRTUAL_THERMAL = yes;
          RK3368_THERMAL = yes;
          DRM_ROCKCHIP = yes;
          ROCKCHIP_CDN_DP = yes;
          ROCKCHIP_DW_HDMI = yes;
          ROCKCHIP_DW_MIPI_DSI = yes;
          ROCKCHIP_ANALOGIX_DP = yes;
          ROCKCHIP_INNO_HDMI = yes;
          ROCKCHIP_LVDS = yes;
          DRM_PANEL = yes;
          LCD_GENERAL = yes;
          ROCKCHIP_RGA = yes;
          ROCKCHIP_RGA2 = yes;
          RK_VCODEC = yes;

          RK_CONSOLE_THREAD = yes;
          CPU_RK3188 = yes;

          SND_SOC_ROCKCHIP = module;
          SND_SOC_RK312X = module;

          USB20_HOST = yes;
          USB20_OTG = yes;
          MMC_DW_ROCKCHIP = yes;
          ROCKCHIP_TIMER = yes;
          ROCKCHIP_IOMMU = yes;
          ROCKCHIP_CPUINFO = yes;
          ROCKCHIP_IPA = yes;
          ROCKCHIP_OPP = yes;
          ROCKCHIP_GRF = yes;
          ROCKCHIP_PM_DOMAINS = yes;
          ROCKCHIP_PVTM = yes;
          ROCKCHIP_SUSPEND_MODE = yes;
          PM_DEVFREQ = yes;
          ARM_ROCKCHIP_DMC_DEVFREQ = yes;
          DEVFREQ_EVENT_ROCKCHIP_DFI = yes;
          DEVFREQ_EVENT_ROCKCHIP_NOCP = yes;
          PWM_ROCKCHIP = yes;
          PHY_ROCKCHIP_USB = yes;
          PHY_ROCKCHIP_INNO_USB = yes;
          PHY_ROCKCHIP_EMMC = yes;
          PHY_ROCKCHIP_DP = yes;
          PHY_ROCKCHIP_INNO_MIPI_DPHY = yes;
          PHY_ROCKCHIP_INNO_HDMI_PHY = yes;
          PHY_ROCKCHIP_TYPEC = yes;
          GPIO_ROCKCHIP = yes;
          ROCKCHIP_EFUSE = yes;
          ROCKCHIP_SIP = yes;
          HW_RANDOM_ROCKCHIP = yes;
          MTD_NAND_ROCKCHIP = yes;
          ROCKCHIP_DTPM = yes;
          NVMEM_ROCKCHIP_EFUSE = yes;
          NVMEM_ROCKCHIP_OTP = yes;
          PCIE_ROCKCHIP = yes;
          CRYPTO_DEV_ROCKCHIP = yes;
          CLK_ROCKCHIP = yes;
          CLK_RK312X = yes;

          DRM_DW_HDMI = yes;
          DW_HDMI_I2S_AUDIO = yes;
          MALI400 = yes;
          MALI_DT = yes;
          MALI_DEVFREQ = yes;
          MALI_BIFROST = yes;
          MALI_MIDGARD = yes;
          MALI_EXPERT = yes;
          MALI_PLATFORM_THIRDPARTY = yes;
          MALI_PLATFORM_THIRDPARTY_NAME = freeform "rk";
          MALI_DEBUG = yes;
          MALI_FENCE_DEBUG = yes;

          MTD_BLOCK = yes;
          MTD_CMDLINE_PARTS = yes;
          MMC_BLOCK = module;
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

  hardware = {
    graphics.enable = true;
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
    kmscon = {
      enable = true;
      hwRender = true;
      autologinUser = "nixos";
    };
  };
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };

  security.sudo.wheelNeedsPassword = false;

  # This is already in the kernel command line (still doesn't seem to solve it)
  #systemd.units."serial-getty@ttyFIQ0".enable = false;

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
