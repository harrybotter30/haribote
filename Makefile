.PHONY: all clean distclean install realclean run default img ipl10.bin
%.o: %.S
	$(CC) -E $(CFLAGS) $(CPPFLAGS) $< -o $*.s
	$(AS) $(ASFLAGS)  $*.s -o $@ >$*.lst

QEMU = qemu-system-i386
ASFLAGS = -al
LDFLAGS =
QFLAGS = -drive if=floppy,format=raw,file=$(IMAGE) -m 64
FD = /dev/fd0
IMAGE = haribote.img
SYS = haribote.sys
SRCS = ipl10.S haribote.S
PSRCS = $(SRCS:.S=.s)
OBJS = $(SRCS:.S=.o)
LISTS = $(SRCS:.S=.lst)

all: $(IMAGE) $(SYS)

$(IMAGE): $(OBJS) haribote.lds
	$(LD) $(LDFLAGS) -T haribote.lds -o $(IMAGE) ipl10.o

$(SYS): $(OBJS) binary.lds
	$(LD) $(LDFLAGS) -T binary.lds -o $(SYS) haribote.o

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
