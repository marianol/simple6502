#!/usr/bin/env bash
#
# run_tests.sh - Build the BIOS and run the sim65 tests in this folder.
#
# Usage:   ./run_tests.sh [name ...]
#   name   Run only name_test.s (for example "via_ports"). Default: every *_test.s here.
#
# Environment:
#   TEST_ROM=file   Use this 32K ROM image instead of building the BIOS (to test a ROM you built
#                   some other way, or one you patched on purpose to see a test fail).
#
# Each test is assembled with ca65, linked with test_ram.cfg and run in sim65 with the ROM at $8000.
# The BIOS is built in a temporary folder, nothing in out/ is touched. Exit code: 0 = all passed.

set -o nounset

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
fi

here="$(cd "$(dirname "$0")" && pwd)"
fw="$(dirname "$here")"
max_cycles=5000000      # a routine that never returns is stopped here (sim65 exits with 126)
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for tool in ca65 ld65 sim65; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Error: $tool not found (install cc65)." >&2; exit 2; }
done

file_size() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1"; }

# The sim65 image: 12 byte header, then memory from $0300 up to $FFEF with the test at $0300 and the
# ROM at $8000. sim65 keeps $FFF0 and up for itself, so the last 16 bytes of the ROM (the end of WozMon
# and the vectors) are not loaded, no test needs them.
# Header: "sim65", format 2, 65C02, C stack pointer at $F0, load address $0300, start address $0300.
make_image() {  # test.bin rom.bin out.img
    local size
    size="$(file_size "$1")"
    if [ "$size" -gt $((0x8000 - 0x0300)) ]; then
        echo "test program is too big ($size bytes)" >&2
        return 1
    fi
    {
        printf 'sim65\002\001\360\000\003\000\003'
        cat "$1"
        head -c $((0x8000 - 0x0300 - size)) /dev/zero
        head -c $((0xFFF0 - 0x8000)) "$2"
    } > "$3"
}

if [ -n "${TEST_ROM-}" ]; then
    rom="$TEST_ROM"
    [ -f "$rom" ] || { echo "Error: TEST_ROM '$rom' not found." >&2; exit 2; }
    echo "Using the ROM image $rom"
else
    rom="$tmp/rom.bin"
    echo "Building the BIOS..."
    ca65 --cpu 65C02 -I "$fw" -o "$tmp/BIOS.o" "$fw/BIOS.s" &&
    ld65 -C "$fw/simple6502.cfg" "$tmp/BIOS.o" -o "$rom" || { echo "BIOS build failed." >&2; exit 2; }
fi
if [ "$(file_size "$rom")" -ne 32768 ]; then
    echo "Error: the ROM image must be 32768 bytes." >&2
    exit 2
fi

tests=()
if [ $# -eq 0 ]; then
    for f in "$here"/*_test.s; do [ -f "$f" ] && tests+=("$f"); done
else
    for n in "$@"; do tests+=("$here/${n%_test}_test.s"); done
fi
[ ${#tests[@]} -gt 0 ] || { echo "No tests found." >&2; exit 2; }

passed=0
failed=0
for src in "${tests[@]}"; do
    [ -f "$src" ] || { echo "FAIL $(basename "$src" .s): no such test"; failed=$((failed + 1)); continue; }
    name="$(basename "$src" .s)"

    # every check number must be used once, or the line printed for a failure would be wrong
    dup="$(grep -ohE '^[[:space:]]+(FAIL|CC|CS|KEPT|AKEPT|MEM)[[:space:]]+[0-9]+' "$src" | awk '{print $2}' | sort -n | uniq -d | tr '\n' ' ')"
    if [ -n "$dup" ]; then
        echo "FAIL $name: check number(s) used more than once: $dup"
        failed=$((failed + 1))
        continue
    fi

    if ! ca65 --cpu 65C02 -I "$fw" -I "$here" -o "$tmp/$name.o" "$src" ||
       ! ld65 -C "$here/test_ram.cfg" "$tmp/$name.o" -o "$tmp/$name.bin"; then
        echo "FAIL $name: does not build"
        failed=$((failed + 1))
        continue
    fi
    make_image "$tmp/$name.bin" "$rom" "$tmp/$name.img" || { failed=$((failed + 1)); continue; }

    out="$(sim65 -x "$max_cycles" "$tmp/$name.img" 2>&1)"
    rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "PASS $name"
        passed=$((passed + 1))
    elif [ "$rc" -eq 126 ]; then
        echo "FAIL $name: did not finish within $max_cycles cycles, a routine may be stuck"
        failed=$((failed + 1))
    else
        line="$(grep -nE "^[[:space:]]+(FAIL|CC|CS|KEPT|AKEPT|MEM)[[:space:]]+$rc([[:space:]]|,|\$)" "$src" | head -1)"
        if [ -n "$line" ]; then
            echo "FAIL $name: check $rc, line ${line%%:*}:${line#*:}"
        else
            echo "FAIL $name: exit code $rc ${out:+($out)}"
        fi
        failed=$((failed + 1))
    fi
done

echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
