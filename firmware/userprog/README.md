# User programs

A scratchpad to write programs for the simple6502 that run from RAM. `make_usr.sh`
assembles one and generates an Intel HEX file that the monitor loads with `L`. It is
independent of the ROM build and may become its own repo.

## Use

```sh
./make_usr.sh              # builds userprg.s
./make_usr.sh other.s      # builds another source
```

Output goes to `out/` (ignored by git): `.o`, `.lst`, `.lbl`, `.bin` and `.hex`. The script
prints the binary and the `.hex` at the end.

To run it on the board or in the emulator:

1. In the monitor type `L`, then paste the `.hex` file. Each record carries its own
   address, and a bad record stops the load with `CKSUM ERR`.
2. Type `0300 R` to run it. An `RTS` returns to the monitor.

## Files

- `userprg.s`: the scratchpad program (VIA test, bit-banged SPI, SD card init).
- `simple6502_RAM-Only.cfg`: linker config. The program goes in the `USR_PROGRAM`
  segment, which starts at $0300 (WozMon's input buffer is at $0200).
- `SPI_prg.txt`: notes from an SPI test session (marked v0.6.1): a hex dump of the
  assembled program from $0300 and its linker labels.

## Load address

The default is $0300. `LOADADDR=0x0400 ./make_usr.sh` changes the address in the `.hex`,
but the program is linked for the address in the cfg (`RAM` start), so change both together.

## Calling the BIOS

Programs call the BIOS through the jump table (`BIOS_SERIAL_OUT` and the others), never
through internal addresses, so they keep working when the BIOS is rebuilt:

```asm
.include "bios_jumptable.inc"
        lda #'A'
        jsr BIOS_SERIAL_OUT
```

`make_usr.sh` looks for `bios_jumptable.inc` in this folder first, then in the folder
named by `BIOS_INC` (default `..`, the firmware folder). To use this folder on its own,
copy `bios_jumptable.inc` here, or run with `BIOS_INC=/path/to/firmware`.

## Zero page

This folder does not use the BIOS zero page map. Check `../docs/ZEROPAGE_MAP.md` before
using zero page locations: the BIOS, WozMon and the monitor use $00-$46 and $E0-$EB, and
BASIC uses $4A-$DD (WozMon and BASIC never run together with a program of yours).

## Requirements

`ca65` and `ld65` (cc65), `srec_cat` (srecord) and `xxd`.
