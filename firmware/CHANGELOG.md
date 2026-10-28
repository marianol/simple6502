# Changelog

All notable changes to the simple6502 BIOS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0]

### Added

- `serial_poll`: non-blocking, non-echoing serial read. Returns the byte in A
  with carry set if one was waiting, or carry clear if not. Preserves X and Y.
  Exposed as jump table slot 7 (`BIOS_SERIAL_POLL`, $8015) for programs that
  poll the keyboard and do their own echoing (BASIC GET / Ctrl-C check, games,
  editors).

### Changed

- `serial_in` now calls `serial_poll` and then echoes. Behavior is unchanged
  (slot 3, `BIOS_SERIAL_IN`).

## [0.5.0]

### Added

- Power-On Self Test (POST):
  - Zero Page and Stack (Page 1) checkerboard test ($55/$AA), run in the reset
    vector before the stack is used, so Page 1 can be tested without clobbering
    a live return address.
  - RAM walk from $0200 upward; the detected top of RAM (first non-RAM address)
    is stored in the `RAM_SIZE` zero-page variable. The walk stops at the I/O
    boundary ($7F00) so it never writes into hardware registers.
  - `post_fail` fault beacon: on a ZP/stack failure (before serial is up and
    with no onboard indicator in rev 1.6), it drives a ~1 kHz pattern on data
    bit D0 by repeatedly writing to a Zero Page location, observable with a
    scope or logic probe. Placeholder until a real indicator is designed.
- Reserved `TOCKS` as a 3-byte jiffy counter ($E0-$E2) and `POST_PTR`
  ($E9-$EA) in the zero-page map. The VIA Timer 1 tick that drives TOCKS is
  left as a stub until the VIA routines are implemented.

## [0.4.0]

### Added

- Fixed-address BIOS jump table at the start of ROM ($8000), exposing stable
  entry points for external programs (cold start, monitor, and the serial
  routines). The table is append-only so addresses never change across BIOS
  rebuilds.
- `bios_jumptable.inc` with public `BIOS_*` address equates for programs to
  include instead of hardcoding BIOS addresses.
- `burn.sh` to flash a ROM image to an AT28C256 EEPROM via minipro.

### Changed

- `userprg.s` now calls BIOS routines through the jump table include rather
  than hardcoded (and stale) addresses.

## [0.3.0]

### Added

- Intel HEX `LOAD` (`L`) and `SAVE` (`S`) commands over serial.
  - `L` reads an Intel HEX stream and stores each record at the address carried
    in the record itself (no manual deposit address needed). Each record's
    checksum is verified; a bad record aborts with `CKSUM ERR`, and the EOF
    record ends the load with `OK`.
  - `S` dumps a memory range as 16-byte Intel HEX data records plus an EOF
    record, using WozMon's block syntax to set the range (e.g. `0300.0314 S`).
- `cmd_dispatch` BIOS routine that decodes the `R`/`L`/`S` monitor commands, so
  they can be reused from other code.
- `make_usr.sh` now emits an Intel HEX file (via `srec_cat`) alongside the
  binary for easy paste-loading with `L`.

### Changed

- WozMon's inline per-letter command compares were replaced by a single call to
  `cmd_dispatch` in the BIOS. This frees space in the tight MONITOR segment and
  keeps the command logic reusable.

### Tested

- Verified end-to-end on board rev 1.6 and in the simple6502 emulator: load,
  run, checksum-error detection, and save round-trip.

## [0.1.0]

### Added

- Initial BIOS for the simple6502 SBC.
- Serial (ACIA) routines: init, polled transmit/receive, string and hex output.
- WozMon memory monitor adapted to the MC68B50 ACIA, with an `R` command to run
  a program and return to the monitor on `RTS`.

[0.3.0]: https://github.com/marianol/simple6502
[0.1.0]: https://github.com/marianol/simple6502
