
#################
# Macro & Rule
#################

AS 	= nasm
ASINC	= -I include/
CC	= gcc
LD 	= ld

ASFLAGS	= -f elf -g
CFLAGS	= -Wall -O -g -I include/

# -Ttext org -e entry 
# -s(omit all symbol info) -S(omit debug info)
# -x(discard all local symbols) -M(print memory map)
LDFLAGS = -Ttext 0 -e startup_32 --oformat binary -s -S -x -M

# -Ttext org -e entry -M(print memory map)
LDFLAGS2= -Ttext 0 -e startup_32

AR 	= ar
ARFLAGS = rcs

OBJS 	= system/init/head.o system/kernel/proc.o system/kernel/syscall.o system/fs/read_write.o system/init/main.o system/lib/lib.a
LIBS 	= system/lib/write.o

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

system/system:	$(OBJS)
	$(LD) $(LDFLAGS) \
	$(OBJS) \
	-o $@ > System.map
	$(LD) $(LDFLAGS2) \
	$(OBJS) \
	-o system/system-gdb

system/init/head.o: 	system/init/head.asm include/var.inc include/pm.inc
	$(AS) $(ASFLAGS) $(ASINC) -o $@ $<

system/lib/lib.a: 	$(LIBS)
	$(AR) $(ARFLAGS) $@ $<


#################
# Disassemble
#################

# sed /q: match to that line then QUIT
# append "cc -MM" output to the end
dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp.make
	$(CC) $(CFLAGS) -MM system/**/*.c >> tmp.make
	cp -f tmp.make Makefile
	rm -f tmp.make

.PHONY: dep


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
# Disassemble
#################

disasm-b1: boot1/bootsect
	ndisasm $< | grep -v "0000 "

disasm-b2: boot2/setup
	ndisasm $< | grep -v "0000 "

disasm-sys: system/system
	objdump -b binary -m i386 -D $<

.PHONY: disasm-b1 disasm-b2 disasm-sys


#################
# GDB Debugger
#################

gdb: 	system/system
	@gdb system/system-gdb


#################
# GitHub
#################

# -s means short output format
# @cmd disable echo
commit:
	@git status -s
	@git add .
	@git commit -m "$(MSG)"


#################
# Clean
#################

clean:
	rm -f boot1/bootsect boot2/setup system/system system/system-gdb tools/build 
	rm -f $(OBJS)
	rm -f a.bin tmp.asm System.map

.PHONY: clean


### Dependencies
read_write.o: system/fs/read_write.c include/type.h
main.o: system/init/main.c include/proc.h include/type.h include/head.h
proc.o: system/kernel/proc.c include/proc.h include/type.h include/head.h \
  include/mm.h include/system.h include/io.h include/syscall.h
write.o: system/lib/write.c include/type.h
