# simple6502 Firmware

This is a BIOS for the simple6502 SBC.

## Requirements

- [x] Serial (ACIA): routines to initialize and manage the serial port.
- [ ] VIA helper routines to interface with a 6522 for I/O
- [x] Memory Monitor: WozMon, why innovate?
- [ ] BASIC: will start with MS Basic from 1976 to be period correct. As a bonus I will have Woz and Gates code in the same ROM
- [ ] Some LOAD/SAVE feature to put binaries in memory though serial/SD for testing. Maybe as an update to WozMon??
- [ ] SPI Interface with VIA (in IO Card)
- [ ] SD Card using SPI

Will come up with some other stuff with 32K I have space for stuff.

## Status

**Version 0.1.0:**

- Tested and working in board rev 1.6
- Features:
  - Wozmon
  - Serial IO Routines
