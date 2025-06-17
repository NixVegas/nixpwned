{
  nixpkgs,
  pkgsBuildBuild,

  lib,
  callPackage,
  fetchFromGitHub,
  writeText,
  stdenvNoCC,
  symlinkJoin,
  android-tools,
  abootimg,
  rkflashtool,
}:

{
  kernel,
  toplevel,
}:

let
  # Creates a mtdparts definition.
  mkMtdParts =
    mtdpartsType: parts:
    writeText "mtdparts.txt" ''
      CMDLINE: @kernelParams@ mtdparts=${mtdpartsType}:
      ${lib.concatMapStringsSep "\n"
        (p: "${p.name} ${if p.sizeBlocks < 1 then "-" else toString p.sizeBlocks}")
        (
          map (p: {
            name = lib.elemAt p 0;
            sizeBlocks = ((lib.elemAt p 1) * 1024 * 1024) / 512;
          }) parts
        )
      }
    '';

  # Params file.
  params = stdenvNoCC.mkDerivation {
    name = "nixplay-params-${toplevel.name}";

    nativeBuildInputs = [ rkflashtool ];

    phases = [ "installPhase" ];

    mtdParts = mkMtdParts "rk29xxnand" [
      [
        "uboot"
        4
      ]
      [
        "trust"
        4
      ]
      [
        "misc"
        4
      ]
      [
        "resource"
        16
      ]
      [
        "kernel"
        48
      ] # changed from 12
      [
        "boot"
        48
      ] # changed from 12
      [
        "recovery"
        32
      ]
      [
        "backup"
        320
      ]
      [
        "cache"
        320
      ]
      [
        "metadata"
        16
      ]
      [
        "kpanic"
        4
      ]
      [
        "radical_update"
        64
      ]
      [
        "keys"
        16
      ]
      [
        "system"
        1280
      ]
      [
        "userdata"
        0
      ]
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      model=rk3126c
      machine=312x
      kernelParams="$(<${toplevel}/kernel-params) init=/init" substituteAll $mtdParts mtdparts.txt
      rkparameters $model ${lib.versions.majorMinor lib.version} mtdparts.txt > $out/params

      sed -Ei "s/^MACHINE_MODEL:.+/MACHINE_MODEL: $model/g" $out/params
      sed -Ei "s/^MACHINE:.+/MACHINE: $machine/g" $out/params
      sed -Ei 's/^MANUFACTURER:.+/MANUFACTURER: nixpkgs ${lib.version}/g' $out/params

      runHook postInstall
    '';
  };

  # Recovery kernel.
  kernel' = stdenvNoCC.mkDerivation {
    name = "nixplay-kernel-${kernel.name}";

    nativeBuildInputs = [ rkflashtool ];

    phases = [ "installPhase" ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      rkcrc -k ${kernel}/zImage $out/kernel.img

      runHook postInstall
    '';
  };

  # Resource tool for repacking rockchip resource files.
  rsce-go = pkgsBuildBuild.buildGoModule rec {
    pname = "rsce-go";
    version = "2025-06-16";

    src = fetchFromGitHub {
      owner = "numinit";
      repo = "rsce-go";
      rev = "v${version}";
      hash = "sha256-zbukm4+ZyCi6jSwKfcRCxlAROFFdBU6wNeFs78firC4=";
    };

    vendorHash = "sha256-18BpSdvdxjrauXtw7yl5be1hduxzcB/4coLJ9qOhXxU=";
  };

  # What we SHOULD be using.
  boot = stdenvNoCC.mkDerivation {
    name = "nixplay-boot-${toplevel.name}";

    nativeBuildInputs = [
      android-tools
      rsce-go
    ];

    phases = [ "installPhase" ];

    installPhase = ''
      runHook preInstall

      cat ${kernel}/zImage rk-kernel.dtb > zImage+dtb

      rsce-go --pack rk-kernel.dtb
      mv boot-second second.bin

      mkdir -p $out
      mkbootimg \
        --kernel ${kernel}/zImage \
        --base 0x60000000 \
        --kernel_offset 0x408000 \
        --dtb rk-kernel.dtb \
        --second second.bin \
        --ramdisk ${toplevel}/initrd \
        --ramdisk_offset 0x2000000 \
        --pagesize 16384 \
        --cmdline "$(<${toplevel}/kernel-params) init=/init" \
        --output $out/boot.img
        runHook postInstall
    '';
  };

  # Super hacky, takes their boot.img and repacks it.
  boot' = stdenvNoCC.mkDerivation {
    name = "nixplay-boot-${toplevel.name}";

    nativeBuildInputs = [
      android-tools
      abootimg
      rsce-go
    ];

    phases = [ "installPhase" ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp ${./boot.img} boot.img
      abootimg -x boot.img

      sed -Ei 's!^bootsize\s*=\s*.+$!bootsize = 0x3000000!g' bootimg.cfg
      sed -Ei 's!^cmdline\s*=\s*.+$!cmdline = '"$(<${toplevel}/kernel-params)"'!g' bootimg.cfg

      cat bootimg.cfg

      abootimg --create $out/boot.img -f bootimg.cfg -k zImage -r ${toplevel}/initrd -s stage2.img

      runHook postInstall
    '';
  };

  # Will work better (with overlayfs, even) using a NixOS built kernel.
  systemSquashfs = callPackage "${nixpkgs}/nixos/lib/make-squashfs.nix" {
    fileName = "system.img";
    storeContents = [ toplevel ];
    comp = "zstd -Xcompression-level 22";
  };

  # Presently just smashes everything together onto one fs.
  rootfs = callPackage "${nixpkgs}/nixos/lib/make-ext4-fs.nix" {
    storePaths = [ toplevel ];
    volumeLabel = "nixplay";
    compressImage = true;
    populateImageCommands = ''
      ln -s ${toplevel}/init files/init
    '';
  };

  # Rootfs that works with the old kernel.
  rootfs' = rootfs.overrideAttrs (_: {
    MKE2FS_CONFIG = writeText "mke2fs.conf" ''
      [fs_types]
      ext4 = {
        features = ^metadata_csum
      }
    '';
  });

  # System that has the correct partition filename.
  system' = stdenvNoCC.mkDerivation {
    name = "nixplay-system-${toplevel.name}";

    phases = [ "installPhase" ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      ln -s ${systemSquashfs} $out/system.img

      runHook postInstall
    '';
  };

  # Userdata that has the correct partition filename.
  userdata = stdenvNoCC.mkDerivation {
    name = "nixplay-userdata-${toplevel.name}";

    phases = [ "installPhase" ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      ln -s ${rootfs'} $out/userdata.img.zst

      runHook postInstall
    '';
  };
in
symlinkJoin {
  name = "nixplay-${toplevel.name}";
  paths = [
    params
    kernel'
    boot'
    userdata
  ];
  passthru = {
    kernel = kernel';
    system = system';
    boot = boot';
    inherit params userdata;
  };
}
