
#################
# Macro & Rule
#################

AS 		= nasm
ASFLAGS = -f elf
CC		= gcc
CFLAGS	= -Wall -O
LD 		= ld
# -Ttext org -e entry -s(omit all symbol info)
# -x(discard all local symbols) -M(print memory map)
LDFLAGS = -Ttext 0 -e main --oformat binary -s -x -M

%.o:	%.c
	$(CC) $(CFLAGS) -o $@ $<

%.o: 	%.asm
	$(AS) $(ASFLAGS) -o $@ $<

#################
# 	Default
#################

all:	Image

#.PHONY : Image disk start clean

Image:	boot1/bootsect boot2/setup system/system tools/build 	
	tools/build boot1/bootsect boot2/setup system/system > a.bin
	dd if=a.bin of=Image bs=8192 conv=notrunc
	rm -f a.bin
	
tools/build:	tools/build.c
	$(CC) $(CFLAGS) -o $@ $<

# SYSSIZE= number of clicks (16 bytes) to be loaded
boot1/bootsect:	boot1/bootsect.asm system/system
	(echo -n "SYSSIZE equ (";ls -l system/system | grep system \
		| cut -d " " -f 5 | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.asm
	cat $< >> tmp.asm
	$(AS) -o $@ tmp.asm
	rm -f tmp.asm

boot2/setup:	boot2/setup.asm
	$(AS) -o $@ $<

system/system:	system/init/main.o system/init/myprint.o
	$(LD) $(LDFLAGS) \
	system/init/main.o \
	system/init/myprint.o \
	-o $@ > System.map

system/init/main.o:	system/init/main.c

system/init/myprint.o: system/init/myprint.asm


#################
# Create floppy
#################

disk:
	bximage -q -fd -size=1.44 Image


#################
# Start Bochs
#################

start:	Image
	bochs -q -f bochsrc


#################
# 	GitHub
#################


#################
# 	Clean
#################

clean:
	rm -f boot1/bootsect boot2/setup system/system tools/build 
	rm -f a.bin tmp.asm System.map