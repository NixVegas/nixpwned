# nixpwned

Getting NixOS to run on the [nixplay](https://nixplaysucks.com).

Status:

- Serial works!
- Display kind of works with the old device tree (but graphics are corrupt)
- Device tree needs forward porting

## Development

Run `nix develop` and follow instructions in the shell hook.

- Reset into MaskROM mode. On some Nixplay devices this is, bogglingly, holding the externally facing reset button and plugging USB in.
- Run lsusb and you should see the Rockchip MaskROM device.

## Serial

One of [these](https://www.amazon.com/PCBite-4xSP10-Digital-Probes/dp/B08W3RM861) works great for finding the pins (thanks @MatthewCrougha for finding the pins)

Use 3.3v logic levels, [here's an adapter](https://www.amazon.com/Modules-Converter-Supports-Switching-Optional/dp/B0D76GPH4V)

## Building

`nix build .#nixosConfigurations.nixplay.config.system.build.nixplay.all -L`

Many things will be broken. This is released mostly as-is.

## Flashing

- BACK UP YOUR PARAMS AND PARTITIONS FIRST!
- `rkflashtool P < result/params`
- `rkflashtool w boot < result/boot.img`
- `rkflashtool w userdata < <(zstdcat result/userdata.img.zst)`
