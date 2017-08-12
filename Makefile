.PHONY: all clean distclean install realclean run default img ipl10.bin
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
ASRCS = ipl10.S asmhead.S
CSRCS = bootpack.c startup.c
PSRCS = $(ASRCS:.S=.s)
OBJS = $(ASRCS:.S=.o) $(CSRCS:.c=.o)
LISTS = $(SRCS:.S=.lst)
TMPS = bootpack.hrb asmhead.bin

all: $(IMAGE) $(SYS)

$(IMAGE): $(OBJS) haribote.lds
	$(LD) $(LDFLAGS) -T haribote.lds -o $(IMAGE) ipl10.o

$(SYS): $(OBJS) asmhead.lds hrb.lds
	$(LD) $(LDFLAGS) -T asmhead.lds -o asmhead.bin asmhead.o
	$(LD) $(LDFLAGS) -T hrb.lds -o bootpack.hrb bootpack.o
	cat asmhead.bin bootpack.hrb >$@
	$(RM) bootpack.hrb asmhead.bin

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

ipl10.bin: $(OBJS)
