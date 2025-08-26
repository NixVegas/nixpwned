# nixpwned

Getting NixOS to run on the [nixplay](https://nixplaysucks.com).

Status: We have Linux 6.12 booting!

- Serial works!
- Display kind of works with the old device tree (but graphics are corrupt)
- Device tree needs forward porting
- CPU dies if we use more than one core

![](/img/boot.jpg)

## Hardware

Tested against the Nixplay W10K or [Apolosign](https://www.amazon.com/ApoloSign-Digital-1920x1080-Auto-Rotate-Instantly/dp/B0CQCMQRWX) frames.

Note that the Apolosign has better hardware, including a newer PCB and better flash chip. They're all RK3126C based, though.

### Nixplay W10K

![](/img/w10k.jpg)

![](/img/graphics.jpg)

### Apolosign 10.1 inch ("powered by Nixplay")

![](/img/apolosign.jpg)

### Existing software

These run Android 5 (!!!) which is truly ancient.

## Development

Run `nix develop`.

- Reset into MaskROM mode. On some Nixplay devices this is, bogglingly, holding the externally facing reset button and plugging USB in.
- Run lsusb and you should see the Rockchip MaskROM device.

## Serial

One of [these](https://www.amazon.com/PCBite-4xSP10-Digital-Probes/dp/B08W3RM861) works great for finding the pins (thanks @MatthewCroughan for finding the pins)

Use 3.3v logic levels, [here's an adapter](https://www.amazon.com/Modules-Converter-Supports-Switching-Optional/dp/B0D76GPH4V)

## Building

`nix build .#nixosConfigurations.nixplay.config.system.build.nixplay.all -L`

Many things will be broken. This is released mostly as-is.

## Flashing

- BACK UP YOUR PARAMS AND PARTITIONS FIRST!
- `rkflashtool P < result/params`
- `rkflashtool w boot < result/boot.img`
- `rkflashtool w userdata < <(zstdcat result/userdata.img.zst)`
