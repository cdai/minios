
#################
# Macro & Rule
#################

AS 	= nasm
ASINC	= -I include/
ASFLAGS	= -f elf
CC	= gcc
CFLAGS	= -Wall -O
LD 	= ld
# -Ttext org -e entry -s(omit all symbol info)
# -x(discard all local symbols) -M(print memory map)
LDFLAGS = -Ttext 0 -e startup_32 --oformat binary -s -x -M

%.o:	%.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: 	%.asm
	$(AS) $(ASFLAGS) -o $@ $<


#################
# Default
#################

all:	Image


Image:	boot1/bootsect boot2/setup system/system tools/build 	
	tools/build boot1/bootsect boot2/setup system/system > a.bin
	dd if=a.bin of=Image bs=8192 conv=notrunc
	rm -f a.bin
	
tools/build:	tools/build.c
	$(CC) $(CFLAGS) -o $@ $<

# SYSSIZE = system file size
boot1/bootsect:	boot1/bootsect.asm include/var.inc system/system
	(echo -n "SYSSIZE equ ";ls -l system/system | grep system \
		| cut -d " " -f 5 | tr '\012' ' ') > tmp.asm
	cat $< >> tmp.asm
	$(AS) $(ASINC) -o $@ tmp.asm
	rm -f tmp.asm

boot2/setup:	boot2/setup.asm include/var.inc include/pm.inc
	$(AS) $(ASINC) -o $@ $<

system/system:	system/init/head.o system/init/main.o
	$(LD) $(LDFLAGS) \
	system/init/head.o \
	system/init/main.o \
	-o $@ > System.map

system/init/head.o: 	system/init/head.asm include/var.inc include/pm.inc
	$(AS) $(ASFLAGS) $(ASINC) -o $@ $<

system/init/main.o:	system/init/main.c


#################
# Create floppy
#################

disk:
	bximage -q -fd -size=1.44 Image

.PHONY: disk


#################
# Start Vm
#################

start:	Image
	bochs -q -f bochsrc

qemu: 	Image
	qemu-system-x86_64 -m 16M -boot a -fda Image

.PHONY: start qemu


#################
# GitHub
#################

disasm-b1: boot1/bootsect
	ndisasm $< | grep -v "0000 "

disasm-b2: boot2/setup
	ndisasm $< | grep -v "0000 "

disasm-sys: system/system
	objdump -b binary -m i386 -D $<

.PHONY: disasm-b1 disasm-b2 disasm-sys


#################
# GitHub
#################

commit:
	git add .
	git commit -m "$(MSG)"


#################
# Clean
#################

clean:
	rm -f boot1/bootsect boot2/setup system/system tools/build 
	rm -f system/**/*.o
	rm -f a.bin tmp.asm System.map

.PHONY: clean
