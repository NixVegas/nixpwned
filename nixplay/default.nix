{
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [ ./packaging.nix ];

  environment.systemPackages = with pkgs; [
    htop usbutils uhubctl
  ];

  boot = {
    loader.grub.enable = false;

    consoleLogLevel = 8;

    initrd = {
      kernelModules = [
        "phy-rockchip-emmc"
        "rockchip-nand-controller"
        "dw_mmc-rockchip"
        #"rockchip"
        #"phy-rockchip-pcie"
        #"pcie-rockchip-host"
        #"spi-rockchip-sfc"
        "mtdblock"
        "mmc_block"
        "cmdlinepart"
      ];
      /*postDeviceCommands = ''
        ls -al /dev/mmc* /dev/mtd*
      '';*/
    };

    kernelParams = [
      "console=tty0"
      #"console=uart8250,mmio32,0x20068000"
      "console=ttyS2,115200n8"
      "psci=enable"
      "initrd=0x62000000,0x0080000"
      "maxcpus=1"
      "clk_ignore_unused"
      "panic=3"
      "boot.shell_on_fail"
    ];

    kernelPatches = with lib.kernel; [
      {
        name = "rk312x";
        patch = ./0001-rockchip-prelim-rk3126c-support.patch;
        structuredExtraConfig = {
          ARCH_ROCKCHIP = yes;
          ARM_ROCKCHIP_CPUFREQ = yes;

          CPUFREQ_DT = yes;
          CPU_IDLE = yes;
          CPU_IDLE_GOV_LADDER = yes;
          CPU_IDLE_GOV_MENU = yes;

          SERIAL_CORE = yes;
          SERIAL_CORE_CONSOLE = yes;
          SERIAL_EARLYCON = yes;
          SERIAL_8250 = yes;
          SERIAL_8250_CONSOLE = yes;
          SERIAL_8250_EXTENDED = yes;
          SERIAL_8250_SHARE_IRQ = yes;
          SERIAL_8250_DMA = yes;
          SERIAL_8250_NR_UARTS = freeform (toString 3);
          SERIAL_8250_RUNTIME_UARTS = freeform (toString 3);
          SERIAL_8250_FSL = yes;
          SERIAL_8250_DW = yes;

          FIQ = yes;
          OABI_COMPAT = no;

          ROCKCHIP_MBOX = yes;
          ROCKCHIP_SCR = yes;
          DWMAC_ROCKCHIP = module;
          ROCKCHIP_PHY = module;
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
          RK_FLASH = yes;
          RK_NAND = yes;
          RK_PARTITION = yes;
          CPU_RK3188 = yes;

          SND_SOC_ROCKCHIP = module; # only module
          SND_SOC_RK312X = module;   # only module

          USB20_HOST = yes;
          USB20_OTG = yes;
          MMC_DW_ROCKCHIP = module;
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
          PM_DEVFREQ_EVENT = yes;
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
          HW_RANDOM_ROCKCHIP = module;
          MTD_NAND_ROCKCHIP = module;
          ROCKCHIP_DTPM = yes;
          NVMEM_ROCKCHIP_EFUSE = yes;
          NVMEM_ROCKCHIP_OTP = yes;
          PCIE_ROCKCHIP = yes;
          CRYPTO_DEV_ROCKCHIP = yes;
          CLK_ROCKCHIP = yes;
          CLK_RK312X = yes;

          ARM_ATAG_DTB_COMPAT_CMDLINE_EXTEND = yes;

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

          RTL8XXXU = module;
          RTL8XXXU_UNTESTED = yes;

          MTD_BLOCK = module;
          MTD_CMDLINE_PARTS = module;
          PARTITION_ADVANCED = yes;
          CMDLINE_PARTITION = yes;
          MMC_BLOCK = module; # only module

          SUN8I_DE2_CCU = lib.mkForce module;
        };
      }
    ];

    # wifi
    extraModulePackages = [
      /*(config.boot.kernelPackages.rtl8188eus-aircrack.overrideAttrs (prev: {
        ARCH = "arm";
        CROSS_COMPILE = "armv7l-unknown-linux-gnueabihf-";
        preConfigure = prev.preConfigure or "" + ''
          substituteInPlace Makefile --replace-fail 'CONFIG_RTL8188F = n' 'CONFIG_RTL8188F = y'
        '';
      }))*/
    ];
  };

  hardware = {
    deviceTree = {
      enable = true;
      filter = "rk3126c-*.dtb";
      overlays = [
        {
          name = "nixplay-w10k";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "rockchip,rk3126";
            };
            &uart1 {
              status = "disabled";
            };
            &uart2 {
              status = "okay";
            };
            &{/psci} {
               cpu_off = <0x84000002>;
               cpu_on = <0x84000003>;
               cpu_suspend = <0x84000001>;
            };
            &{/wireless-wlan} {
              WIFI,poweren_gpio = <0x4d 0x14 0x01>;
              /delete-property/ power_ctrl_by_pmu;
              /delete-property/ power_pmu_enable_level;
              /delete-property/ power_pmu_regulator;
              wifi_chip_type = "rtl8188fu";
            };
          '';
        }
      ];
    };
    graphics.enable = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/mmcblk2p15";
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
    getty.autologinUser = "nixos";
    /*kmscon = {
      enable = true;
      hwRender = true;
      autologinUser = "nixos";
    };*/
  };

  programs.sway.enable = true;

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";

  nixpkgs = {
    buildPlatform = "x86_64-linux";
    hostPlatform = lib.recursiveUpdate lib.systems.platforms.armv7l-hf-multiplatform {
      inherit (lib.systems.examples.armv7l-hf-multiplatform) config;
      linux-kernel = {
        preferBuiltin = false;
        extraConfig = "";
      };
      gcc = {
        arch = "armv7ve";
        fpu = "neon-vfpv4";
      };
    };
    overlays = lib.singleton (pkgs: prev: {
      lttng-ust = prev.lttng-ust.overrideAttrs (prevAttrs: rec {
        version = "2.13.9";
        src = pkgs.fetchurl {
          url = "https://lttng.org/files/lttng-ust/${prevAttrs.pname}-${version}.tar.bz2";
          hash = "sha256-KtbWmlSh2STBikqnojPbEE48wzK83SQOGWv3rb7T9xI=";
        };
      });
      colord = prev.colord.overrideAttrs (prevAttrs: {
        env = lib.optionalAttrs pkgs.stdenv.hostPlatform.isAarch32 {
          CFLAGS = "-Wno-incompatible-pointer-types";
        };
      });
      xwayland = prev.xwayland.overrideAttrs (prevAttrs: {
        env = lib.optionalAttrs pkgs.stdenv.hostPlatform.isAarch32 {
          CFLAGS = "-Wno-incompatible-pointer-types";
        };
      });
      llhttp = prev.llhttp.overrideAttrs (prevAttrs: {
        cmakeFlags = prevAttrs.cmakeFlags or [ ] ++ lib.optionals pkgs.stdenv.hostPlatform.isAarch32 [
          "-DCMAKE_C_FLAGS=-flax-vector-conversions"
        ];
      });
      sdl3 = prev.sdl3.override {
        # ibus fails to compile on cross
        ibusSupport = false;
      };
    });
  };
}
