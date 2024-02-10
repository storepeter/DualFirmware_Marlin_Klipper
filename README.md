# DualFirmware Marlin Klipper

You can read more about this on my BLOG

	http://storepeter.dk/3d-printer/avr-dualboot-bootloader

The 3D-printer is running some kind of Marlin, on an ATmega2560,
which we  might not even have the source code for.

We like to keep the installed firmware, but would also like to install
klipper as secondary on the MCU.

This can be done by installing avr-dualboot as bootloader
and install a physical switch on to the 3D-printer
to control if it will boot into Marlin or Klipper.

Here is what we need to do:

- get the sources from Github for avr-dualboot and klipper
- backup current firmware from ATmega2560
- compile and install dualboot bootloader
- restore the backup firmware as Primary Firmware
- configure, and compile Klipper
- install the klipper firmware as Secondary Firmware

### Get the sources from Github for avr-dualboot and klipper

You can download and patch the sources with the necessary changes using
this command

	$ make src

### Backup current firmware from ATmega2560

Connect your favorite ISP tool,
I use cheap USBasp-clones from China which were running very old firmware.
see avr-dualboot/README.USBasp if this applies to you too.

First we should backup the Firmware currently on the MCU

	$ make backup

A full backup of the current firmware including bootloader
but not fuse settings is created, check it out, for me it was:

	$ ls avr-dualboot/Preserved_Firmware/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0
```
   4096 Jan 29 16:32 eeprom.bin
   9740 Jan 29 16:32 eeprom.hex
 261406 Jan 29 16:32 flash.bin
 620900 Jan 29 16:32 flash.hex
 108572 Jan 29 16:32 orig-app.bin
 305392 Jan 29 16:32 orig-app.hex
```

### Compile and install dualboot bootloader

Defaults is for a bootloader on an ATmega2560 16 Mhz,
see Makefile for further details.

To compile a new DualBoot bootloader

	$ make dualboot.elf

To flash that to the device

	$ make dualboot.flash

To access the new bootloader I have written a small tool:

	$ ./dualtool.sh  -h

```
Usage: dualtool.sh [option] [primary_firmware.elf] [secondary_firmware.elf]
    <nofile>       prints current firmware-map
    -1 -2          as default jump to primary or secondary firmware
    file.elf       firmware (primary and/or secondary) to load
    file.hex       primary firmware can be in hex format
    -w             program device with given .elf fiiles
    -e             erase device
    -E eeprom.hex  program EEPROM        
    -c usbasp      use usbasp as ISP
    -b baud
    -p mcu
    -v             verbose
check for trampolines,handle vector_table, suggest DUAL_BASE
```

Without options it will show a map of the flash on the MCU

	$dualtool.sh 

```
# MCU=atmega2560 FLASH=262144 VECT_BASE=0x3fb00 VECT_SZ=256 BOOT_BASE=0x3fc00 BOOT_SZ=1024
# This Device is runing DualBoot based on optiboot 8.3
# no update to vector block required
 0x00000 - 0x3fb00 1st void 
 0x3fb00 - 0x3fc00 irq vector table... 256 bytes
 0x3fc00 - 0x40000 DualBoot bootloader 1024 bytes

```

Check new bootloader by downloading primary.elf and secondary.elf

	$ make flash

You can check what is on MCU using

	$ ./dualtool.sh
```
# This Device is runing DualBoot based on optiboot 8.3
# no update to vector block required
 0x00000 - 0x30000 1st flashed with primary 
 0x30000 - 0x3fb00 2nd flashed with secondary DEFAULT
 0x3fb00 - 0x3fc00 irq vector table... 256 bytes
 0x3fc00 - 0x40000 DualBoot bootloader 1024 bytes
# Keep primary firmware, not erasing
# Keep secondary firmware, not erasing
```

### Restore the backup firmware as Primary Firmware

To restore the original Firmware, with the newly install DualBoot bootloader

	$ make restore

Now we should have system that works as before, with the difference that it now has a bootloader

### Configure, and compile Klipper

	$ make klipper.config
	$ nake klipper.compile

### Install the klipper firmware as Secondary Firmware

	$ make klipper.flash

### DONE

You can check what is on the MCU using

	$ ./dualtool.sh

If you have used kiauh to install klipper with the username klipper, you should be
able to test that klipper is running on the MCU using this

	$ make klipper.test


Best Regards

StorePeter
