.PHONY: all clean distclean install realclean run default img ipl10.bin
%.o: %.S
	$(CC) -E $(CFLAGS) $(CPPFLAGS) $< -o $*.s
	$(AS) $(ASFLAGS)  $*.s -o $@ >$*.lst

QEMU = qemu-system-i386
ASFLAGS = -al
CFLAGS = -fno-pic
LDFLAGS =
QFLAGS = -drive if=floppy,format=raw,file=$(IMAGE) -m 64
FD = /dev/fd0
IMAGE = haribote.img
SYS = haribote.sys
ASRCS = ipl10.S asmhead.S
CSRCS = bootpack.c
PSRCS = $(ASRCS:.S=.s)
OBJS = $(ASRCS:.S=.o) $(CSRCS:.c=.o)
LISTS = $(SRCS:.S=.lst)

all: $(IMAGE) $(SYS)

$(IMAGE): $(OBJS) haribote.lds
	$(LD) $(LDFLAGS) -T haribote.lds -o $(IMAGE) ipl10.o

$(SYS): $(OBJS) asmhead.lds
	$(LD) $(LDFLAGS) -T asmhead.lds -o $(SYS) haribote.o bootpack.o

$(OBJS): Makefile

run: $(IMAGE)
	$(QEMU) $(QFLAGS)

install: $(IMAGE)
	dd $(IMAGE) $(FD)

clean:
	$(RM) $(PSRCS) $(OBJS) $(LISTS) *~

realclean distclean: clean
	$(RM) $(IMAGE) $(SYS)

# compatible targets

default: all

img: $(IMAGE)

ipl10.bin: $(OBJS)
