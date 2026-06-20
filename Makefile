KDIR ?= /lib/modules/$(shell uname -r)/build
SRC_DIR := $(CURDIR)/src
SUDO ?= sudo

ADDR0 ?= 0xFE001210
ADDR1 ?= 0xFE001310
MMIO_SIZE ?= 0x38
USE_SECOND ?= 1
ENABLE_ON_BOOT ?= 0
PPS_GEN ?= pps-gen0

.PHONY: all clean help load unload enable disable status install uninstall

help:
	@echo "Targets:"
	@echo "  make                 Build tgpio-platform.ko"
	@echo "  make load            Build and load with static TGPIO resources"
	@echo "  make enable          Enable /sys/class/pps-gen/$(PPS_GEN)"
	@echo "  make disable         Disable /sys/class/pps-gen/$(PPS_GEN)"
	@echo "  make status          Show module and pps-gen status"
	@echo "  make install         Install persistently for the running kernel"
	@echo "  make uninstall       Remove persistent install"
	@echo
	@echo "Common overrides:"
	@echo "  ADDR0=$(ADDR0)"
	@echo "  ADDR1=$(ADDR1)"
	@echo "  MMIO_SIZE=$(MMIO_SIZE)"
	@echo "  USE_SECOND=$(USE_SECOND)"
	@echo "  ENABLE_ON_BOOT=$(ENABLE_ON_BOOT)"
	@echo "  PPS_GEN=$(PPS_GEN)"

all:
	$(MAKE) -C $(KDIR) M=$(SRC_DIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(SRC_DIR) clean

load: all
	$(SUDO) ADDR0="$(ADDR0)" ADDR1="$(ADDR1)" MMIO_SIZE="$(MMIO_SIZE)" USE_SECOND="$(USE_SECOND)" ./scripts/load.sh

unload:
	$(SUDO) PPS_GEN="$(PPS_GEN)" ./scripts/unload.sh

enable:
	$(SUDO) PPS_GEN="$(PPS_GEN)" ENABLE=1 ./scripts/set-enable.sh

disable:
	$(SUDO) PPS_GEN="$(PPS_GEN)" ENABLE=0 ./scripts/set-enable.sh

status:
	./scripts/status.sh

install: all
	$(SUDO) ADDR0="$(ADDR0)" ADDR1="$(ADDR1)" MMIO_SIZE="$(MMIO_SIZE)" USE_SECOND="$(USE_SECOND)" ENABLE_ON_BOOT="$(ENABLE_ON_BOOT)" PPS_GEN="$(PPS_GEN)" ./scripts/install.sh

uninstall:
	$(SUDO) ./scripts/uninstall.sh
