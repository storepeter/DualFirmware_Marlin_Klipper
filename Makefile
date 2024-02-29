# Copyright (C) StorePeter January 2024 license:  https://en.wikipedia.org/wiki/Beerware
# Add Klipper as secondary firmware on 3D-printer with ATmega2560, 
# requires ISP programmer f.ex. USBasp
#
# - backup current firmware from ATmega2560
# - get, compile and install dualboot bootloader
# - get, patch, configure, and compile Klipper
# - restore the backup firmware as Primary Firmware
# - install the klipper firmware as Secondary Firmware

TTY       := $(wildcard /dev/serial/by-id/usb-*)
BAUD      := 250000
DUAL_BASE := 0x34000
DUALTOOL  := avr-dualboot/dualtool.sh
RELOCATE  += EXTRA_CFLAGS="-mrelax -fno-jump-tables -DDUALBOOT_BASE=$(DUAL_BASE)"
RELOCATE  += EXTRA_LDFLAGS="-mrelax -fno-jump-tables -Wl,--section-start=.text=$(DUAL_BASE)"
avr-dualboot.git:= https://github.com/StorePeter/avr-dualboot
klipper.git     := https://github.com/Klipper3d/klipper.git
KLIPPER_PYTHON  := ~klipper/klippy-env/bin/python3

.PHONY: avr-dualboot klipper %.patch

default: $(DUALTOOL)
	$<

src: avr-dualboot.src klipper.src

compile: avr-dualboot/dualboot.elf klipper/out/klipper.elf
	avr-size $^

%.src: | %
# I would have thought (order only) only would get us here if % did not exist
# until I under stand this, let bash handle it
	echo "$$@=$@: | $$<=$<"
	if [ ! -d  $(basename $@) ]; then \
		git clone $($(basename $@).git); \
		if [ -f Patches/$(basename $@).gitHEAD ]; then \
			git -C $(basename $@) checkout $$(cat Patches/$(basename $@).gitHEAD) < Patches/$(basename $@).patch; \
		fi; \
		if [ -f Patches/$(basename $@).patch ]; then \
			patch -d $(basename $@) -p1 < Patches/$(basename $@).patch; \
		fi; \
	else \
		echo "Source $(basename $@) exist"; \
	fi

$(DUALTOOL): avr-dualboot.src

avr-dualboot.compile avr-dualboot/dualboot.elf: avr-dualboot.src
	if [ ! -d avr-dualboot/optiboot ]; then $(MAKE) -C avr-dualboot clone; fi
	$(MAKE) -C avr-dualboot dualboot.elf

klipper.config:
	$(MAKE) -C klipper menuconfig
	cp klipper.config klipper.config 

klipper.compile klipper/out/klipper.elf: klipper.src
	@if [ ! -f klipper.config ]; then echo "  Please configure Klipper by typing:  $(MAKE) klipper.config"; false; fi
	cp klipper.config klipper/.config
	$(MAKE) -C klipper $(VERBOSE) clean
	$(MAKE) -C klipper $(VERBOSE) $(RELOCATE)

klipper.check: klipper/out/klipper.elf
	$(DUALTOOL) -1 -e $^

klipper.flash: backup klipper/out/klipper.elf
	$(DUALTOOL) -1 -e -w $^

flash: backup klipper/out/klipper.elf
	avr-size       klipper/out/klipper.elf
	$(MAKE) restore
	$(DUALTOOL) -w klipper/out/klipper.elf

klipper.test:
	$(KLIPPER_PYTHON) klipper/klippy/console.py -v $(TTY)

%.diff:
	cd $(basename $@); git diff --diff-filter=M

%.patch:
	mkdir -p Patches
	git -C $(basename $@) remote get-url origin > Patches/$(@:patch=url)
	git -C $(basename $@) rev-parse --short HEAD > Patches/$(@:patch=gitHEAD)
	git -C $(basename $@) diff --diff-filter=M > Patches/$@

Patches: klipper.patch avr-dualboot.patch

commit: Patches
	git commit -a

%.clean:
	$(MAKE) -C $(basename $@) clean

clean: avr-dualboot.clean  klipper.clean

dist-clean:
	rm -rf  avr-dualboot klipper

dualboot.flash backup restore cu:
	$(MAKE) -C avr-dualboot TTY=$(TTY) CU_BAUD=$(BAUD) $@
