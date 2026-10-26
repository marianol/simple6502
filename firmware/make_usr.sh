#!/usr/bin/env bash

ldconfig='simple6502_RAM-Only.cfg'
dir="out"
if [[ ! -e "$dir" ]]; then
    mkdir $dir
elif [[ ! -d "$dir" ]]; then
    echo "$dir already exists but is not a directory" 1>&2
    exit 1
fi

file=$(basename -- "$1")
ext="${file##*.}"
filename="${file%.*}"

echo "Compiling $filename."
ca65 -vvv --cpu 65C02 -l ./out/"$filename".lst -o ./out/"$filename".o "$1"
echo "Linking $filename using $ldconfig memory configuration."
ld65 -C "$ldconfig" out/"$filename".o -o out/"$filename".bin -Ln out/"$filename".lbl
# Load address for RAM-resident user programs (matches simple6502_RAM-Only.cfg RAM start)
loadaddr="0x0300"
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
