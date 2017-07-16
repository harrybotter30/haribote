.PHONY: all clean distclean install realclean run asm default img ipl.bin
%.o: %.S
	$(CC) -E $(CFLAGS) $(CPPFLAGS) $< -o $*.s
	$(AS) $(ASFLAGS)  $*.s -o $@ >$*.lst

QEMU = qemu-system-i386
ASFLAGS = -al
LDFLAGS = -T haribote.lds
QFLAGS = -drive if=floppy,format=raw,file=$(IMAGE) -m 64
FD = /dev/fd0
IMAGE = haribote.img
SRCS = ipl.S
PSRCS = $(SRCS:.S=.s)
OBJS = $(SRCS:.S=.o)
LISTS = $(SRCS:.S=.lst)

all: $(IMAGE)

$(IMAGE): $(OBJS)
	$(LD) $(LDFLAGS) -o $(IMAGE) $(OBJS)

$(OBJS): Makefile

run: $(IMAGE)
	$(QEMU) $(QFLAGS)

install: $(IMAGE)
	dd $(IMAGE) $(FD)

clean:
	$(RM) $(PSRCS) $(OBJS) $(LISTS) *~

realclean distclean: clean
	$(RM) $(IMAGE)

# compatible targets

default: all

img: $(IMAGE)

asm ipl.bin: $(OBJS)
