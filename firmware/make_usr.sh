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
ca65 -vvv --cpu 65C02 -o ./out/"$filename".o "$1"
echo "Linking $filename using $ldconfig memory configuration."
ld65 -C "$ldconfig" out/"$filename".o -o out/"$filename".bin
echo "Complete.."
xxd -u -g 1  ./out/"$filename".bin
