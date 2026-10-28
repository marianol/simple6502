# simple6502 Firmware

This is a BIOS for the simple6502 SBC.

## Requirements

- [x] Serial (ACIA): routines to initialize and manage the serial port.
- [x] Memory Monitor: WozMon, why innovate?
- [x] LOAD/SAVE over serial using Intel HEX (SD card support to come later)
- [ ] BASIC: will start with MS Basic from 1976 to be period correct. As a bonus I will have Woz and Gates code in the same ROM
- [ ] SPI Interface with VIA (in IO Card)
- [ ] SD Card using SPI
- [ ] VIA helper routines to interface with a 6522 for I/O

Will come up with some other stuff with 32K I have space for stuff.

## BIOS Jump Table (ABI)

Like a C64 KERNAL, the BIOS exposes its routines through a fixed-address jump
table at the start of ROM ($8000). Each entry is a 3-byte `JMP`, so external
programs call stable addresses that do not change when the BIOS is rebuilt.

The table is **append-only**: new routines are added at the end, existing slots
never move. Include `bios_jumptable.inc` in your program and call the `BIOS_*`
symbols instead of hardcoding addresses.

| Addr  | Symbol            | Routine                                         |
|-------|-------------------|-------------------------------------------------|
| $8000 | `BIOS_COLD_START` | Cold start / reset                              |
| $8003 | `BIOS_MONITOR`    | Enter WozMon                                     |
| $8006 | `BIOS_SERIAL_OUT` | Transmit A over serial                          |
| $8009 | `BIOS_SERIAL_IN`  | Receive a byte (carry set if data in A)         |
| $800C | `BIOS_SERIAL_STR` | Transmit null-terminated string at `PTR_TX`     |
| $800F | `BIOS_SERIAL_HEX` | Transmit A as two ASCII hex digits              |
| $8012 | `BIOS_OUT_CRLF`   | Transmit CR + LF                                |
| $8015 | `BIOS_SERIAL_POLL` | Receive a byte, no echo (carry set if data in A) |

```asm
.include "bios_jumptable.inc"
        lda #'A'
        jsr BIOS_SERIAL_OUT
```

## Monitor Commands

WozMon's single-letter commands are decoded by `cmd_dispatch` in the BIOS, so
they can also be reused from other code. In addition to WozMon's examine/store
syntax:

- `R` - run the program at the last examined address (returns to the monitor on `RTS`).
- `L` - load an Intel HEX stream from the serial terminal. Each record is stored at
  the address carried in the record itself. 
  Each record's checksum is verified; a bad record aborts with `CKSUM ERR`. 
  The EOF record (`:00000001FF`) ends the load with `OK`.
- `S` - save a memory range as an Intel HEX stream. Use WozMon's block syntax to
  set the range first, e.g. `0300.0314 S` dumps $0300 through $0314 inclusive as
  16-byte data records followed by an EOF record.

### Building loadable programs

`make_usr.sh` assembles a user program with the RAM-only layout and also emits an
Intel HEX file (via `srec_cat`) alongside the binary. Paste that `.hex` into the
terminal after the `L` command to load it. The load address comes from the
`-offset` in `make_usr.sh` (default $0300).

### Burning the ROM

`burn.sh` flashes a ROM image to an Atmel AT28C256 (32K EEPROM) using
[minipro](https://gitlab.com/DavidGriffith/minipro) with a TL866/T48/T56
programmer. It defaults to `out/BIOS.bin` and checks the image is exactly
32768 bytes before writing; minipro erases and verifies automatically.

```sh
./make.sh BIOS.s   # build out/BIOS.bin
./burn.sh          # burn it to the EEPROM
```

## Status

**Version 0.6.0** — tested and working on board rev 1.6 and in the simple6502 emulator.

See [CHANGELOG.md](CHANGELOG.md) for the full version history.
