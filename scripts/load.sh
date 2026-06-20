#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
MODULE="${ROOT_DIR}/src/tgpio-platform.ko"
ADDR0="${ADDR0:-0xFE001210}"
ADDR1="${ADDR1:-0xFE001310}"
MMIO_SIZE="${MMIO_SIZE:-0x38}"
USE_SECOND="${USE_SECOND:-1}"

tgpio_module_loaded()
{
	lsmod | awk '$1 ~ /^tgpio_platform/ { found = 1 } END { exit !found }'
}

tgpio_devices_exist()
{
	find /sys/bus/platform/devices -maxdepth 1 -name 'intel-pps-gen-tio*' 2>/dev/null |
		grep -q .
}

show_status_and_exit()
{
	"${SCRIPT_DIR}/status.sh"
	exit 0
}

if [ "$(id -u)" -ne 0 ]; then
	echo "Run as root: sudo $0" >&2
	exit 1
fi

if [ ! -f "${MODULE}" ]; then
	echo "${MODULE} not found; run make first" >&2
	exit 1
fi

if tgpio_module_loaded; then
	echo "TGPIO platform module is already loaded"
	show_status_and_exit
fi

if tgpio_devices_exist; then
	echo "TGPIO platform devices are already registered"
	show_status_and_exit
fi

modprobe pps_gen_tio
if ! output=$(insmod "${MODULE}" addr0="${ADDR0}" addr1="${ADDR1}" mmio_size="${MMIO_SIZE}" use_second="${USE_SECOND}" 2>&1); then
	if printf '%s\n' "${output}" | grep -q 'File exists' && tgpio_devices_exist; then
		printf '%s\n' "${output}" >&2
		echo "TGPIO platform devices are already registered"
		show_status_and_exit
	fi

	if ! modprobe tgpio_platform addr0="${ADDR0}" addr1="${ADDR1}" mmio_size="${MMIO_SIZE}" use_second="${USE_SECOND}"; then
		printf '%s\n' "${output}" >&2
		exit 1
	fi
fi

"${SCRIPT_DIR}/status.sh"
