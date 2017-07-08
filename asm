#!/bin/sh -e
src=ipl
base=helloos
as -o ${src}.o ${src}.S -al >${src}.lst
ld -o ${base}.img -T ${base}.lds ${src}.o
