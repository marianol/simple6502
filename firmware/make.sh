#!/usr/bin/env bash

set -o errexit
set -o nounset

if [ $# -eq 0 ]; then
    >&2 echo 'No arguments provided, use -h for help.
    
    '
    exit 1
fi
if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    echo 'Usage: ./make.sh file_name 

This will assemble and link the file "file_name" and put the output in ./out

'
    exit
fi

ldconfig='simple6502.cfg'
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
ld65 -o out/"$filename".bin -C "$ldconfig" out/"$filename".o
echo "Complete.."