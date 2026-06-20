#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo "Run as root: sudo $0" >&2
	exit 1
fi

for enable in /sys/class/pps-gen/*/enable; do
	[ -e "${enable}" ] || continue
	echo 0 >"${enable}" || true
done

lsmod | awk '$1 ~ /^tgpio_platform/ { print $1 }' |
while IFS= read -r module; do
	[ -n "${module}" ] || continue
	rmmod "${module}" 2>/dev/null || true
done
