#!/bin/sh
set -eu

PPS_GEN="${PPS_GEN:-pps-gen0}"
ENABLE="${ENABLE:-1}"
ENABLE_PATH="/sys/class/pps-gen/${PPS_GEN}/enable"

if [ "$(id -u)" -ne 0 ]; then
	echo "Run as root: sudo $0" >&2
	exit 1
fi

if [ ! -e "${ENABLE_PATH}" ]; then
	echo "${ENABLE_PATH} not found" >&2
	exit 1
fi

case "${ENABLE}" in
	0|1)
		echo "${ENABLE}" >"${ENABLE_PATH}"
		;;
	*)
		echo "ENABLE must be 0 or 1" >&2
		exit 1
		;;
esac

printf 'set %s to %s\n' "${ENABLE_PATH}" "${ENABLE}"
if [ -r "${ENABLE_PATH}" ]; then
	printf '%s=' "${ENABLE_PATH}"
	cat "${ENABLE_PATH}" 2>/dev/null || true
fi
