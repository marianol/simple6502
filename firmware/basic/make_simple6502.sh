#!/bin/sh
# Assembles and links the Simple6502 BASIC on its own, without the BIOS. Output (.o, .bin
# and .lbl) goes to basic/out/. The BIOS area of the image is left empty (zeros).
# To build the complete ROM (BIOS + BASIC) use ../make_rom.sh.
#
# -I ..  finds the files BASIC shares with the BIOS: zeropage.s and bios_jumptable.inc.
# ../simple6502.cfg is the linker config for the whole ROM.
cd "$(dirname "$0")" || exit 1
NAME=Simple6502-BASIC
mkdir -p out &&
ca65 -I .. msbasic.s -o out/$NAME.o &&
ld65 -C ../simple6502.cfg out/$NAME.o -o out/$NAME.bin -Ln out/$NAME.lbl
