# Changelog

All notable changes to the simple6502 BIOS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.0]

### Added

- `X` monitor command, like the PET monitor: exit to BASIC. It warm starts BASIC if it has
  been started since reset, and cold starts it if not (a warm start needs what the cold start
  sets up, otherwise it would jump through uninitialized zero page vectors).
- `BASIC_STARTED` ($EC) in the zero page map: cleared by the BIOS reset, set by BASIC's cold
  start.
- BASIC: `MONITOR` statement (jumps to WozMon through `BIOS_MONITOR`) and the `READY.`
  prompt instead of `OK`. See `basic/CHANGELOG.md`.

## [0.8.0]

### Added

- Jump table slots 8 to 11: `BIOS_BASIC_COLD` ($8018) and `BIOS_BASIC_WARM` ($801B) jump
  to BASIC's cold and warm start (`BASIC_COLD_START` $DC00 and `BASIC_WARM_START` $DC03 in
  `bios_jumptable.inc`). `BIOS_LOAD` ($801E) and `BIOS_SAVE` ($8021) call the new
  `bios_load` and `bios_save` routines, which are stubs (just `RTS`) for now. Slots 0 to 7 did
  not move.
- The jump table is checked at link time against `bios_jumptable.inc`, so a slot that is
  added to one and not the other fails the build. BASIC's `header.s` has the same check for
  its two entry points.
- MS BASIC source in `basic/`, imported from the `clean_simple6502` branch of
  [marianol/msbasic](https://github.com/marianol/msbasic) (commit `e2b02db`). It uses the
  BIOS through the jump table (`BIOS_SERIAL_OUT`, `BIOS_SERIAL_POLL`) and reads the top of
  memory from the BIOS `RAM_SIZE`. It builds into the ROM at $DC00.
- `make_rom.sh`: builds the full 32K ROM (BIOS + WozMon + BASIC) into `out/simple6502.bin`.
- `zeropage.s`: the zero page map. It replaces the zero page equates that were in
  `defines_simple6502.s`. Variables are declared with `.res` in fixed-address blocks, and
  `.assert` checks fail the build if a block grows into another one or into the range
  reserved for BASIC ($4A-$DD).
- `docs/ZEROPAGE_MAP.md`: the map of the whole zero page (BIOS and BASIC).

### Removed

- `board_test.s` and its build files in `out/`.

### Changed

- The jump table moved from `BIOS.s` to its own file, `bios_header.s`, included by `BIOS.s`.
- BASIC's `LOAD` and `SAVE` statements now jump to `BIOS_LOAD` and `BIOS_SAVE` instead of
  having their own empty stubs. The BASIC binary grew 5 bytes and its reference binary was
  rebuilt (the only differences were the new glue and the `LOAD` entry in its statement table).
- The user program tools moved to their own folder, `userprog/`, so they build
  independently of the ROM: `userprg.s`, `make_usr.sh`, `simple6502_RAM-Only.cfg` and
  `SPI_prg.txt`. `make_usr.sh` runs from any directory, writes to `userprog/out/` (ignored
  by git, the old `out/userprg.*` files were removed) and finds `bios_jumptable.inc` in the
  folder or in `BIOS_INC` (default `..`). The program binary is unchanged.
- `simple6502.cfg` now also has the `BASROM` region ($DC00-$FEFF) for BASIC, and the
  `ROM` region ends at $DBFF. All segments are optional, so the same file links the BIOS
  alone, BASIC alone or both.
- `defines_simple6502.s` only has hardware definitions now, the zero page variables moved
  to `zeropage.s`. The BIOS code was byte-identical to 0.7.0 after this change (checked).
- `bios_jumptable.inc` is the only copy; BASIC uses it from here.

## [0.7.0]

### Added

- VIA1 support (external I/O card at $7F20):
  - `via_init` detects the VIA by writing/reading two patterns to DDRB, and if
    present configures Timer 1 as a free-running ~10ms periodic interrupt and
    enables it. Sets the `VIA_PRESENT` flag (and carry) when found.
  - The IRQ handler now services VIA1 Timer 1: it checks the IFR, clears the
    flag by reading T1C-L, and increments the 3-byte `TOCKS` jiffy counter.
  - On boot, when the VIA is detected, a line is printed under the BIOS banner:
    `## VIA1 on $7F20`.
- VIA helper constants (ACR/IER/IFR masks, Timer 1 10ms reload) and a
  `VIA_PRESENT` zero-page flag.

### Notes

- VIA Timer 1 interrupts are not yet delivered by the simple6502 emulator, so
  the TOCKS tick can only be fully verified on real hardware for now. VIA
  detection and the boot banner are verified in the emulator.

## [0.6.1]

### Fixed

- The Zero Page and Stack (Page 1) checkerboard POST test is now actually run
  in the reset vector. It was described in the 0.5.0 comments and changelog but
  never wired in, which left `post_fail` unreachable. A mismatch now jumps to
  the `post_fail` data-bus fault beacon as intended. `post_fail` was moved to
  just before `post` so the four checks reach it with direct branches.
- Verified in the emulator: normal boot is unchanged, and a deliberately
  broken stack compare hangs in `post_fail` before the stack pointer is set up.

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
