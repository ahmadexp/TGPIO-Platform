# TGPIO Platform

Author: Ahmad Byagowi

Linux kernel module for systems with the Intel Time-Aware GPIO (Timed I/O hardware related to PTM), works with the upstream `pps_gen_tio` driver.

The module registers static `intel-pps-gen-tio` platform devices. The real PPS
logic remains in the stock kernel driver.

## Quick Start

Build and test-load with the default Intel static addresses:

```sh
make
make load
make status
```

Targets that load, install, unload, enable, or disable the module invoke
`sudo` internally.

Show available targets:

```sh
make help
```

If `/sys/class/pps-gen/pps-gen0` appears, enable PPS output:

```sh
echo 1 | sudo tee /sys/class/pps-gen/pps-gen0/enable
```

Or:

```sh
make enable
```

Stop PPS output:

```sh
echo 0 | sudo tee /sys/class/pps-gen/pps-gen0/enable
```

Or:

```sh
make disable
```

Unload the module:

```sh
make unload
```

## Persistent Install

Install for the running kernel:

```sh
make
make install
```

Install and enable `pps-gen0` automatically at boot:

```sh
make install ENABLE_ON_BOOT=1
```

Remove the persistent install:

```sh
make uninstall
```

## Address Sets

Defaults:

```text
addr0=0xFE001210
addr1=0xFE001310
mmio_size=0x38
use_second=1
```

Override at load time:

```sh
make load ADDR0=0xF6801210 ADDR1=0xF6801310
```

Override at install time:

```sh
make install ADDR0=0xF6801210 ADDR1=0xF6801310
```

Single TGPIO block:

```sh
make load USE_SECOND=0
```

## Requirements

- Linux kernel with `CONFIG_PPS_GENERATOR_TIO=m` or `=y`
- Matching kernel headers for the running kernel
- Known-good MMIO addresses for the target platform
- Root privileges to load/install kernel modules

Check kernel support:

```sh
modinfo pps_gen_tio
zgrep CONFIG_PPS_GENERATOR_TIO /proc/config.gz 2>/dev/null || grep CONFIG_PPS_GENERATOR_TIO /boot/config-$(uname -r)
```

## Known working setup

The following is a known working setup with confirmed results:

ASUS ProArt Z890-CREATOR WIFI with the BIOS version 3202

link: https://www.asus.com/us/motherboards-components/motherboards/proart/proart-z890-creator-wifi/

with out of the box Ubuntu Ubuntu 26.04 LTS (comes with default 7.0.0-22-generic)

## Safety

This module maps and exposes MMIO resources. Wrong addresses can write to the
wrong hardware registers. Use only address sets confirmed for your platform.

See [docs/background.md](docs/background.md) for why this exists.
See [docs/troubleshooting.md](docs/troubleshooting.md) for common checks.

## License

BSD 2-Clause. Use, modify, redistribute, and commercialize it freely, while
retaining Ahmad Byagowi's copyright notice and license terms.
