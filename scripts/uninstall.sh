#!/bin/sh
set -eu

KREL=$(uname -r)
DEST_DIR="/lib/modules/${KREL}/extra"

if [ "$(id -u)" -ne 0 ]; then
	echo "Run as root: sudo $0" >&2
	exit 1
fi

if command -v systemctl >/dev/null 2>&1; then
	systemctl disable --now tgpio-pps-enable.service 2>/dev/null || true
	rm -f /etc/systemd/system/tgpio-pps-enable.service
	systemctl daemon-reload
fi

lsmod | awk '$1 ~ /^tgpio_platform/ { print $1 }' |
while IFS= read -r module; do
	[ -n "${module}" ] || continue
	rmmod "${module}" 2>/dev/null || true
done
rm -f /etc/modprobe.d/tgpio-platform*.conf
rm -f /etc/modules-load.d/tgpio-platform*.conf
rm -f "${DEST_DIR}"/tgpio-platform*.ko
depmod "${KREL}"

echo "Uninstalled TGPIO platform module for ${KREL}"
