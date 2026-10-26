#!/usr/bin/env bash
#
# burn.sh - Flash a BIOS binary to an Atmel AT28C256 EEPROM using minipro
#           (TL866 / T48 / T56 series programmer).
#
# Usage:   ./burn.sh [file]
#   file   Optional path to the ROM image. Defaults to ./out/BIOS.bin
#
# The AT28C256 is a 32K x 8 (32768 byte) EEPROM, which maps to the
# simple6502 ROM space $8000-$FFFF. The image must be exactly 32768 bytes.

set -o errexit
set -o nounset
set -o pipefail

device='AT28C256'            # minipro device name (DIP-28 package)
default_file='out/BIOS.bin'  # default image if none given
rom_size=32768               # AT28C256 capacity in bytes

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    cat <<'EOF'
Usage: ./burn.sh [file]

Flash a ROM image to an AT28C256 EEPROM with minipro.

  file   ROM image to burn (default: out/BIOS.bin)

The image must be exactly 32768 bytes. minipro verifies the write
automatically after programming.

Examples:
  ./burn.sh                 # burn out/BIOS.bin
  ./burn.sh out/board_test.bin
EOF
    exit
fi

file="${1-$default_file}"

# --- sanity checks -------------------------------------------------------
if ! command -v minipro >/dev/null 2>&1; then
    echo "Error: minipro not found on PATH. Install it (e.g. 'brew install minipro')." >&2
    exit 1
fi

if [[ ! -f "$file" ]]; then
    echo "Error: ROM image '$file' not found." >&2
    echo "Build it first (e.g. ./make.sh BIOS.s) or pass a path." >&2
    exit 1
fi

# Portable file size (BSD stat on macOS, GNU stat on Linux)
actual_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
if [[ "$actual_size" -ne "$rom_size" ]]; then
    echo "Error: '$file' is $actual_size bytes, expected $rom_size for $device." >&2
    echo "The AT28C256 is a 32K EEPROM; the image size must match exactly." >&2
    exit 1
fi

# --- burn ----------------------------------------------------------------
echo "Burning '$file' ($actual_size bytes) to $device..."
# -p: part   -w: write image   minipro erases and verifies by default.
minipro -p "$device" -w "$file"
echo "Done. $device programmed and verified."
