#!/usr/bin/env bash
#
# make_usr.sh - Assemble a user program that runs from RAM and generate the
#               Intel HEX file to load it with the monitor's L command.
#
# Usage:   ./make_usr.sh [file.s]
#   file.s  Source to build (default: userprg.s)
#
# Output goes to ./out (next to this script): .o, .lst, .lbl, .bin and .hex.
# Paste the .hex into the terminal after typing L in the monitor.
#
# This folder does not depend on the ROM build. The only thing it needs from the
# BIOS is the jump table include (bios_jumptable.inc). It looks for it here
# first, then in the folder named by BIOS_INC (default: .., the firmware folder).
# If you move this folder to its own repo, copy bios_jumptable.inc next to this
# script, or run with BIOS_INC=/path/to/firmware.
#
# LOADADDR is where the program is loaded (default 0x0300, the RAM start in
# simple6502_RAM-Only.cfg). The program must be linked for that address.

set -o errexit
set -o nounset

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
    exit
fi

cd "$(dirname "$0")"

ldconfig='simple6502_RAM-Only.cfg'
bios_inc="${BIOS_INC:-..}"
loadaddr="${LOADADDR:-0x0300}"
dir="out"
if [[ ! -e "$dir" ]]; then
    mkdir "$dir"
elif [[ ! -d "$dir" ]]; then
    echo "$dir already exists but is not a directory" 1>&2
    exit 1
fi

file=$(basename -- "${1:-userprg.s}")
filename="${file%.*}"

echo "Compiling $filename."
ca65 -vvv --cpu 65C02 -I . -I "$bios_inc" -l ./out/"$filename".lst -o ./out/"$filename".o "$file"
echo "Linking $filename using $ldconfig memory configuration."
ld65 -C "$ldconfig" out/"$filename".o -o out/"$filename".bin -Ln out/"$filename".lbl
echo "Generating Intel HEX at offset $loadaddr."
# -address-length=2 forces 16-bit addresses and suppresses the type 04
# extended-linear-address record, keeping the file to plain 00/01 records
# that the BIOS loader understands.
srec_cat out/"$filename".bin -binary -offset "$loadaddr" -o out/"$filename".hex -intel -address-length=2
echo "Complete.."
echo "--- binary ---"
xxd -u -g 1  ./out/"$filename".bin
echo "--- Intel HEX (paste into WozMon after 'L') ---"
cat ./out/"$filename".hex
