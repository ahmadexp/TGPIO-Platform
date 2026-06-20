// SPDX-License-Identifier: BSD-2-Clause
/*
 * Platform-device module for Intel Time-Aware GPIO / Timed I/O PPS.
 * Copyright (c) 2026 Ahmad Byagowi
 */

#include <linux/ioport.h>
#include <linux/module.h>
#include <linux/platform_device.h>

#define TGPIO_DRIVER_NAME "intel-pps-gen-tio"
#define TGPIO_MAX_DEVICES 2

static unsigned long addr0 = 0xFE001210;
static unsigned long addr1 = 0xFE001310;
static unsigned int mmio_size = 0x38;
static bool use_second = true;

module_param(addr0, ulong, 0444);
MODULE_PARM_DESC(addr0, "MMIO base for the first TGPIO/TIO block");

module_param(addr1, ulong, 0444);
MODULE_PARM_DESC(addr1, "MMIO base for the second TGPIO/TIO block");

module_param(mmio_size, uint, 0444);
MODULE_PARM_DESC(mmio_size, "MMIO resource size for each block, default 0x38");

module_param(use_second, bool, 0444);
MODULE_PARM_DESC(use_second, "Register the second TGPIO/TIO block");

static struct platform_device *pdevs[TGPIO_MAX_DEVICES];

static int tgpio_register_device(unsigned int index, unsigned long addr)
{
	struct resource res = {
		.start = addr,
		.end = addr + mmio_size - 1,
		.flags = IORESOURCE_MEM,
	};

	if (!addr)
		return -EINVAL;

	if (addr + mmio_size - 1 < addr)
		return -EOVERFLOW;

	pdevs[index] = platform_device_register_resndata(NULL,
							 TGPIO_DRIVER_NAME,
							 index, &res, 1,
							 NULL, 0);
	if (IS_ERR(pdevs[index]))
		return PTR_ERR(pdevs[index]);

	pr_info("registered %s.%u at %pa-%pa\n", TGPIO_DRIVER_NAME, index,
		&res.start, &res.end);
	return 0;
}

static int __init tgpio_platform_init(void)
{
	int ret;

	if (!mmio_size)
		return -EINVAL;

	ret = request_module("pps_gen_tio");
	if (ret)
		pr_warn("request_module(pps_gen_tio) returned %d\n", ret);

	ret = tgpio_register_device(0, addr0);
	if (ret)
		return ret;

	if (use_second) {
		ret = tgpio_register_device(1, addr1);
		if (ret)
			goto unregister_first;
	}

	return 0;

unregister_first:
	platform_device_unregister(pdevs[0]);
	pdevs[0] = NULL;
	return ret;
}

static void __exit tgpio_platform_exit(void)
{
	unsigned int i;

	for (i = ARRAY_SIZE(pdevs); i > 0; i--) {
		if (pdevs[i - 1])
			platform_device_unregister(pdevs[i - 1]);
	}
}

module_init(tgpio_platform_init);
module_exit(tgpio_platform_exit);

MODULE_AUTHOR("Ahmad Byagowi");
MODULE_DESCRIPTION("Static platform-device module for Intel pps_gen_tio");
MODULE_LICENSE("Dual BSD/GPL");
