#!/bin/sh
set -eu

echo "== modules =="
lsmod | grep -E '^(tgpio_platform|pps_gen_tio|pps_gen_core|pps_core)' || true

echo
echo "== platform devices =="
find /sys/bus/platform/devices -maxdepth 1 -name 'intel-pps-gen-tio*' -print 2>/dev/null || true

echo
echo "== pps generators =="
if [ ! -d /sys/class/pps-gen ]; then
	echo "/sys/class/pps-gen is missing"
	exit 0
fi

found=0
for dev in /sys/class/pps-gen/*; do
	[ -e "${dev}" ] || continue
	found=1
	echo "-- ${dev}"
	for attr in name system time enable; do
		if [ -e "${dev}/${attr}" ]; then
			printf '%s=' "${attr}"
			cat "${dev}/${attr}" 2>/dev/null || true
		fi
	done
done

if [ "${found}" -eq 0 ]; then
	echo "no pps-gen devices found"
fi
