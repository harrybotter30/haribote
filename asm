#!/bin/sh -e
base=helloos
as -o ${base}.o ${base}.S
ld -o ${base}.img -T ${base}.lds ${base}.o
