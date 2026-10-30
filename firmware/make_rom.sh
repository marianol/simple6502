#!/usr/bin/env bash
#
# make_rom.sh - Build the complete 32K ROM image: BIOS + WozMon + MS BASIC.
#
# Usage:   ./make_rom.sh
#
# Assembles BIOS.s and basic/msbasic.s separately and links both objects with
# simple6502.cfg into a single image. Output goes to ./out:
#   simple6502.bin   the ROM image (32768 bytes), burn it with ./burn.sh out/simple6502.bin
#   simple6502.lbl   label file for debugging
#   simple6502.map   link map (segment list)
#
# BASIC is not started by the BIOS yet. From WozMon, type DC00R to cold start it.

set -o errexit
set -o nounset

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit
fi

cd "$(dirname "$0")"
mkdir -p out

name='simple6502'
ldconfig='simple6502.cfg'

echo "Assembling BIOS."
# -I . : the shared files (zeropage.s, bios_jumptable.inc) live in this folder
ca65 --cpu 65C02 -I . -l out/BIOS.lst -o out/BIOS.o BIOS.s
echo "Assembling BASIC."
# -I basic : the BASIC sources. BASIC sets its own CPU (.setcpu "6502") in msbasic.s
ca65 -I . -I basic -o out/BASIC.o basic/msbasic.s
echo "Linking $name using $ldconfig."
ld65 -C "$ldconfig" out/BIOS.o out/BASIC.o -o out/"$name".bin -Ln out/"$name".lbl -m out/"$name".map
echo "Complete: out/$name.bin ($(wc -c < out/"$name".bin | tr -d ' ') bytes)"
