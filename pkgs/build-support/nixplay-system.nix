{
  nixpkgs,

  lib,
  callPackage,
  writeText,
  stdenvNoCC,
  symlinkJoin,
  android-tools,
  rkflashtool,
}:

{
  kernel,
  toplevel
}:

let
  mkMtdParts = baseCmdline: mtdpartsType: parts:
    writeText "mtdparts.txt" ''
      CMDLINE: ${lib.concatStringsSep " " baseCmdline} @kernelParams@ mtdparts=${mtdpartsType}:
      ${
        lib.concatMapStringsSep
          "\n"
          (p: "${p.name} ${if p.sizeBlocks < 1 then "-" else toString p.sizeBlocks}")
          (map (p: { name = lib.elemAt p 0; sizeBlocks = ((lib.elemAt p 1) * 1024 * 1024) / 512; }) parts)
      }
    '';

  params = stdenvNoCC.mkDerivation {
    name = "nixplay-params-${toplevel.name}";

    nativeBuildInputs = [ rkflashtool ];

    phases = [ "installPhase" ];

    mtdParts = mkMtdParts [ "console=ttyFIQ0" "initrd=0x62000000,0x0080000" ] "rk29xxnand" [
      ["uboot" 4]
      ["trust" 4]
      ["misc" 4]
      ["resource" 16]
      ["kernel" 48]   # changed from 12
      ["boot" 48]     # changed from 12
      ["recovery" 32]
      ["backup" 320]
      ["cache" 320]
      ["metadata" 16]
      ["kpanic" 4]
      ["radical_update" 64]
      ["keys" 16]
      ["system" 1280]
      ["userdata" 0]
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      model=rk3126c
      machine=312x
      kernelParams="$(<${toplevel}/kernel-params)" substituteAll $mtdParts mtdparts.txt
      rkparameters $model ${lib.versions.majorMinor lib.version} mtdparts.txt > $out/params

      sed -Ei "s/^MACHINE_MODEL:.+/MACHINE_MODEL: $model/g" $out/params
      sed -Ei "s/^MACHINE:.+/MACHINE: $machine/g" $out/params
      sed -Ei 's/^MANUFACTURER:.+/MANUFACTURER: nixpkgs ${lib.version}/g' $out/params

      rkparametersblock $out/params $out/params.bin

      runHook postInstall
    '';
  };

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

  boot = stdenvNoCC.mkDerivation {
    name = "nixplay-boot-${toplevel.name}";

    nativeBuildInputs = [ android-tools ];

    phases = [ "installPhase" ];

    installPhase = ''
      runHook preInstall

      cat ${kernel}/zImage ${kernel}/dtbs/rk3128-evb.dtb > zImage+dtb

      mkdir -p $out
      mkbootimg \
        --kernel zImage+dtb \
        --ramdisk ${toplevel}/initrd \
        --pagesize 16384 \
        --cmdline "$(<${toplevel}/kernel-params)" \
        --output $out/boot.img
      runHook postInstall
    '';
  };

  system = callPackage "${nixpkgs}/nixos/lib/make-squashfs.nix" {
    fileName = "system.img";
    storeContents = [ toplevel ];
    comp = "zstd -Xcompression-level 22";
  };

  system' = stdenvNoCC.mkDerivation {
    name = "nixplay-system-${toplevel.name}";

    phases = [ "installPhase" ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      ln -s ${system} $out/system.img

      runHook postInstall
    '';
  };
in
symlinkJoin {
  name = "nixplay-system-${toplevel.name}";
  paths = [ params kernel' boot system' ];
  passthru = {
    kernel = kernel';
    system = system';
    inherit params boot;
  };
}
