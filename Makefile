.PHONY: all clean distclean install realclean run default img
%.o: %.S
	$(CC) -E $(CFLAGS) $(CPPFLAGS) $< -o $*.s
	$(AS) $(ASFLAGS)  $*.s -o $@ >$*.lst

QEMU = qemu-system-i386
ASFLAGS = -al
CFLAGS = -fno-pic -Os -Wall
LDFLAGS =
QFLAGS = -drive if=floppy,format=raw,file=$(IMAGE) -m 64
FD = /dev/fd0
IMAGE = haribote.img
SYS = haribote.sys
ASRCS = ipl10.S asmhead.S naskfunc.S
CSRCS = bootpack.c dsctbl.c graphic.c startup.c tinylib.c
PSRCS = $(ASRCS:.S=.s)
OBJS = $(ASRCS:.S=.o) $(CSRCS:.c=.o)
LISTS = $(ASRCS:.S=.lst)
TMPS = boot.o file.o ipl10.bin font.o font.bin bootpack.hrb asmhead.bin

all: $(IMAGE)

$(IMAGE): ipl10.o $(SYS) ipl10.lds
	$(LD) $(LDFLAGS) -T ipl10.lds -o ipl10.bin ipl10.o
	objcopy -Ibinary -Bi386 -Oelf32-i386 ipl10.bin boot.o
	objcopy -Ibinary -Bi386 -Oelf32-i386 $(SYS) file.o
	support/makelds >haribote.lds
	$(LD) $(LDFLAGS) -T haribote.lds -o $(IMAGE)
	$(RM) boot.o file.o ipl10.bin

$(SYS): $(OBJS) hankaku.txt asmhead.lds hrb.lds support/makefont
	$(LD) $(LDFLAGS) -T asmhead.lds -o asmhead.bin asmhead.o
	support/makefont hankaku.txt >font.bin
	objcopy -Ibinary -Bi386 -Oelf32-i386 font.bin font.o
	$(LD) $(LDFLAGS) -T hrb.lds -o bootpack.hrb bootpack.o dsctbl.o graphic.o naskfunc.o tinylib.o
	cat asmhead.bin bootpack.hrb >$@
	$(RM) font.o font.bin bootpack.hrb asmhead.bin

$(OBJS): Makefile

run: $(IMAGE)
	$(QEMU) $(QFLAGS)

install: $(IMAGE)
	dd $(IMAGE) $(FD)

clean:
	$(RM) $(PSRCS) $(OBJS) $(LISTS) $(TMPS) *~

realclean distclean: clean
	$(RM) $(IMAGE) $(SYS)

# compatible targets

default: all

img: $(IMAGE)
