
#################
# Macro & Rule
#################

AS 	= nasm
ASINC	= -I include/
CC	= gcc
LD 	= ld

ASFLAGS	= -f elf -g
# -fomit-frame-pointer is for embedded asm
CFLAGS	= -Wall -O -g -I include/

# -Ttext org -e entry 
# -s(omit all symbol info) -S(omit debug info)
# -x(discard all local symbols) -M(print memory map)
LDFLAGS = -Ttext 0 -e startup_32 --oformat binary -s -S -x -M

# -Ttext org -e entry -M(print memory map)
LDFLAGS2= -Ttext 0 -e startup_32 -x

AR 	= ar
ARFLAGS = rcs

OBJS 	= system/init/head.o system/kernel/proc.o system/kernel/syscall.o system/kernel/traps.o system/mm/page.o system/fs/read_write.o system/init/main.o system/lib/lib.a
LIBS 	= system/lib/write.o system/lib/fork.o

%.o:	%.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: 	%.asm
	$(AS) $(ASFLAGS) -o $@ $<

FORMAT 	= \033[31;1m
RESET 	= \033[0m

#################
# Default
#################

all:	clean Image


Image:	boot1/bootsect boot2/setup system/system tools/build 	
	@echo -e "$(FORMAT)[Copy bootsect,setup,system to Image]$(RESET)"
	tools/build boot1/bootsect boot2/setup system/system > a.bin
	dd if=a.bin of=Image bs=8192 conv=notrunc
	rm -f a.bin
	
tools/build:	tools/build.c
	$(CC) $(CFLAGS) -o $@ $<

# SYSSIZE = system file size
boot1/bootsect:	boot1/bootsect.asm include/var.inc system/system
	@echo -e "$(FORMAT)[Compile bootloader1 - bootsect]$(RESET)"
	(echo -n "SYSSIZE equ ";ls -l system/system | grep system \
		| cut -d " " -f 5 | tr '\012' ' ') > tmp.asm
	cat $< >> tmp.asm
	$(AS) $(ASINC) -o $@ tmp.asm
	rm -f tmp.asm

boot2/setup:	boot2/setup.asm include/var.inc include/pm.inc
	@echo -e "$(FORMAT)[Compile bootloader2 - setup]$(RESET)"
	$(AS) $(ASINC) -o $@ $<

system/system:	$(OBJS)
	@echo -e "$(FORMAT)[Link system kernel]$(RESET)"
	$(LD) $(LDFLAGS) \
	$(OBJS) \
	-o $@ > System.map
	@echo -e "$(FORMAT)[Link system kernel with debug info]$(RESET)"
	$(LD) $(LDFLAGS2) \
	$(OBJS) \
	-o system/system-gdb

system/init/head.o: 	system/init/head.asm include/var.inc include/pm.inc
	$(AS) $(ASFLAGS) $(ASINC) -o $@ $<

system/lib/lib.a: 	$(LIBS)
	$(AR) $(ARFLAGS) $@ $(LIBS)


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
# Start & Debug
#################

start:	Image
	@bochs -q -f bochsrc

qemu: 	Image
	@qemu-system-x86_64 -m 16M -boot a -fda Image

gdb: 	Image system/system-gdb
	@nohup ./bochs -q -f bochsrc-gdb > /dev/null &
	@sleep 2
	@gdb system/system-gdb

# match .text until blank line, then filter out .text and *fill*...
sysmap: System.map
	@sed -n '/^.text/,/^$$/p' System.map | egrep -v "^.text|^ .text|^ \*"
	@sed -n '/^.data /,/^$$/p' System.map | egrep -v "^.data|^ .data|^ \*"

.PHONY: start qemu gdb


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
# GitHub
#################

# -s means short output format
commit:
	@git status -s
	@git add .
	@git commit -m "$(MSG)"


#################
# Clean
#################

clean:
	@echo -e "$(FORMAT)[Clean temporary files]$(RESET)"
	rm -f boot1/bootsect boot2/setup system/system system/system-gdb tools/build 
	rm -f $(OBJS) $(LIBS)
	rm -f a.bin tmp.asm System.map

.PHONY: clean


### Dependencies
read_write.o: system/fs/read_write.c include/type.h
main.o: system/init/main.c include/proc.h include/type.h include/head.h \
  include/system.h include/proto.h
proc.o: system/kernel/proc.c include/proc.h include/type.h include/head.h \
  include/mm.h include/system.h include/io.h include/syscall.h
traps.o: system/kernel/traps.c include/system.h include/head.h \
  include/type.h
fork.o: system/lib/fork.c include/proto.h include/type.h
write.o: system/lib/write.c include/proto.h include/type.h
