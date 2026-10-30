#!/bin/sh
# Builds simple6502 BASIC on its own and compares the result byte by byte with the reference
# binary in ref/. Use it to check that cleanup changes did not alter the output.
# Exit code: 0 = identical, 1 = different or build failed.
cd "$(dirname "$0")" || exit 1
REF=ref/simple6502_ref.bin
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
ca65 -I .. msbasic.s -o "$TMP/Simple6502-BASIC.o" &&
ld65 -C ../simple6502.cfg "$TMP/Simple6502-BASIC.o" -o "$TMP/Simple6502-BASIC.bin" || {
	echo "BUILD FAILED"
	exit 1
}
echo "BUILD OK"
if cmp "$REF" "$TMP/Simple6502-BASIC.bin"; then
	echo "COMPARE OK: identical to $REF ($(wc -c < "$REF" | tr -d ' ') bytes)"
else
	echo "COMPARE FAILED: output differs from $REF"
	exit 1
fi
