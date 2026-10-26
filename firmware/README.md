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

## Status

**Version 0.3.0** — tested and working on board rev 1.6 and in the simple6502 emulator.

See [CHANGELOG.md](CHANGELOG.md) for the full version history.
