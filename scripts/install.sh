#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
MODULE_FILE="tgpio-platform.ko"
MODULE_PATH="${ROOT_DIR}/src/${MODULE_FILE}"
MODULE_NAME="tgpio-platform"
KREL=$(uname -r)
DEST_DIR="/lib/modules/${KREL}/extra"
ADDR0="${ADDR0:-0xFE001210}"
ADDR1="${ADDR1:-0xFE001310}"
MMIO_SIZE="${MMIO_SIZE:-0x38}"
USE_SECOND="${USE_SECOND:-1}"
ENABLE_ON_BOOT="${ENABLE_ON_BOOT:-0}"
PPS_GEN="${PPS_GEN:-pps-gen0}"

if [ "$(id -u)" -ne 0 ]; then
	echo "Run as root: sudo $0" >&2
	exit 1
fi

if [ ! -f "${MODULE_PATH}" ]; then
	echo "${MODULE_PATH} not found; run make first" >&2
	exit 1
fi

install -d "${DEST_DIR}"
rm -f "${DEST_DIR}"/tgpio-platform*.ko
install -m 0644 "${MODULE_PATH}" "${DEST_DIR}/${MODULE_FILE}"
depmod "${KREL}"

rm -f /etc/modprobe.d/tgpio-platform*.conf
cat >/etc/modprobe.d/tgpio-platform.conf <<EOF
options ${MODULE_NAME} addr0=${ADDR0} addr1=${ADDR1} mmio_size=${MMIO_SIZE} use_second=${USE_SECOND}
EOF

rm -f /etc/modules-load.d/tgpio-platform*.conf
cat >/etc/modules-load.d/tgpio-platform.conf <<EOF
pps_gen_tio
${MODULE_NAME}
EOF

if [ "${ENABLE_ON_BOOT}" = "1" ]; then
	cat >/etc/systemd/system/tgpio-pps-enable.service <<EOF
[Unit]
Description=Enable Intel TGPIO PPS generator
After=systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'modprobe pps_gen_tio; modprobe ${MODULE_NAME} || modprobe tgpio_platform; echo 1 > /sys/class/pps-gen/${PPS_GEN}/enable'
ExecStop=/bin/sh -c 'test ! -e /sys/class/pps-gen/${PPS_GEN}/enable || echo 0 > /sys/class/pps-gen/${PPS_GEN}/enable'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
	systemctl enable tgpio-pps-enable.service
fi

if lsmod | awk '$1 ~ /^tgpio_platform/ { found = 1 } END { exit !found }'; then
	if [ -e "/sys/class/pps-gen/${PPS_GEN}/enable" ]; then
		echo 0 >"/sys/class/pps-gen/${PPS_GEN}/enable" || true
	fi
	lsmod | awk '$1 ~ /^tgpio_platform/ { print $1 }' |
	while IFS= read -r module; do
		[ -n "${module}" ] || continue
		rmmod "${module}" 2>/dev/null || true
	done
fi

modprobe pps_gen_tio
modprobe "${MODULE_NAME}" || modprobe tgpio_platform

echo "Installed ${MODULE_NAME} for ${KREL}"
echo "Configured addr0=${ADDR0} addr1=${ADDR1} mmio_size=${MMIO_SIZE} use_second=${USE_SECOND}"
if [ "${ENABLE_ON_BOOT}" = "1" ]; then
	echo "Boot enable service installed for ${PPS_GEN}"
fi
echo "Check with: make status"
