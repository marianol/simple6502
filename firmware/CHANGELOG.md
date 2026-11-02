# Changelog

All notable changes to the simple6502 BIOS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.1]

### Changed

- `via_report` is now `via1_report`, it only reports VIA1. Comments in `BIOS.s`, `bios_jumptable.inc` and
  `defines_simple6502.s` were made more concise, and the equates in `bios_jumptable.inc` are aligned.

### Fixed

- Typos in comments (`interrumpt`, `chech`, `caanot`, `doen`, `Thats`).

### Added

- `test/`: tests of the BIOS routines that run in sim65, cc65's simulator. `test/run_tests.sh` builds the
  BIOS in a temporary folder and runs every `*_test.s`, printing the line of the check that failed.
  `test/test.inc` has the helpers and `test/via_ports_test.s` tests the four VIA port routines through the
  jump table of the real ROM (55 checks). See `test/README.md`.

## [0.11.0]

### Added

- Four public VIA port routines, jump table slots 13 to 16: `BIOS_VIA_CONFIG` ($8027, check VIA X),
  `BIOS_VIA_SET_DDR` ($802A), `BIOS_VIA_READ` ($802D) and `BIOS_VIA_WRITE` ($8030). One convention for
  all four: X = VIA index (0 = VIA1), Y = port (0 = A, 1 = B), A = DDR pattern or data. Carry is the
  result, clear = done and set = failed. They fail, and do nothing, if the VIA was not found at boot
  (its `MACHINE_CONFIG` bit), if the index is not a VIA the BIOS knows, or if the port is not 0 or 1.
  A, X and Y come back unchanged (A holds the value for `BIOS_VIA_READ`), other flags are not defined.
- `VIA_COUNT` in `defines_simple6502.s`: how many VIAs the port routines know. Only VIA1 for now, so
  index 1 and up fail until VIA2 has an address.

### Changed

- `via_init` returns carry clear when it finds the VIA and set when it does not (it was the other way
  round), like the VIA port routines. The reset ignores it.
- These replace the internal port helpers added in 0.10.2 (`via_init_ports`, `via_write_a`,
  `via_write_b`, `via_read_a`, `via_read_b`). Those were never in the jump table. The presence check
  is part of the new routines.

### Tested

- In sim65 (where $7F20-$7F23 are plain memory, so a write can be read back), with a program that calls
  the four routines through the jump table of the real ROM image: 55 checks pass. They cover carry on
  success and failure, A/X/Y preserved, the right register address hit for each port, failures writing
  nothing (bad port, bad index, VIA not found, a VIA2 bit alone), and the stack balanced. Two deliberate
  breakages of the ROM are caught: the port A write moved to port B's address fails the register check,
  and a "found" reported with carry set fails the first check.
- Not run on the emulator or the board.

## [0.10.2]

### Added

- VIA1 port helper routines in the BIOS: `via_init_ports` (A = $00 sets both data direction
  registers, $01 only DDRA, $02 only DDRB; X = DDRA mask, Y = DDRB mask; carry set if A is not a
  valid mode, nothing else changes), `via_write_a` and `via_write_b` (write A to the port),
  `via_read_a` and `via_read_b` (read the port into A). They are not in the jump table yet, so only
  BIOS code can call them.

### Changed

- BASIC: `ENTROPY` in `basic/defines_basic.s` now points at `BIOS_GET_TOCKS`, the planned source for the `RND`
  seed. It is not wired into `RND` yet (there is a todo in the file), and the BASIC binary is unchanged.

### Fixed

- Typos in comments in `BIOS.s`, `wozmon_sbc.s`, `defines_simple6502.s` and `userprog/userprg.s`, including the part
  number in the WozMon header (`MC60B50` is `MC68B50`) and the `ACIA_TDRE` comment. The label of the serial
  transmit loop is `poll_acia` (it was `pool_acia`), it polls the ACIA status.

### Tested

- Assembled, and the opcodes, register addresses and branch targets of the new routines were
  checked in the listing. Not run: nothing calls them yet.

## [0.10.1]

### Changed

- Removed `VIA_PRESENT`: it was the same information as `BIOS_CFG_VIA1` in `MACHINE_CONFIG`.
  `via_report` now reads the config byte. That moved the variables after it down by 1:
  `BASIC_STARTED` is at $E9 and `MACHINE_CONFIG` at $EA (`BIOS_MACHINE_CONFIG` follows, rebuild
  programs that use the symbol).

### Tested

- In the emulator: with the VIA the banner has the VIA line and `$E9`-`$EA` read 00 03; with no VIA at
  $7F20 the banner has no VIA line, the ROM still boots to the monitor and `$E9`-`$EA` read 00 01.

## [0.10.0]

### Added

- `BIOS_GET_TOCKS` (jump table slot 12, $8024): reads the 24-bit TOCKS clock as a consistent value,
  A = low byte, X = middle, Y = high. The interrupt can increment TOCKS between two reads of its
  bytes, which makes a program reading $E0-$E2 itself see a value off by 256 ticks. The routine masks
  interrupts for the three loads and restores the caller's I flag.
- Machine configuration byte, `MACHINE_CONFIG` ($EB, `BIOS_MACHINE_CONFIG` in `bios_jumptable.inc`):
  one bit per peripheral, set when the BIOS found and initialized it. Bit 0 `BIOS_CFG_SERIAL`
  (set by `serial_init`), bit 1 `BIOS_CFG_VIA1` (set by `via_init` when it finds the VIA, cleared
  if not), bit 2 `BIOS_CFG_VIA2` reserved. The reset clears the byte. The linker checks that the
  address in `zeropage.s` and in the include agree.

### Changed

- `init_serial` is now `serial_init`. The ROM identification string at the start of the BIOS is
  `BIOS-simple6502-v<version>` (it was `simple6502 BIOS Ver: <version>`). The reset also clears
  `RAM_SIZE` before the POST sets it.
- The POST's RAM walk pointer is a scratch local to `post`, no longer declared in `zeropage.s`
  (a value only one routine uses, which it initializes itself, is not declared). That moved the
  variables after it down by 2: `VIA_PRESENT` is at $E9, `BASIC_STARTED` at $EA and
  `MACHINE_CONFIG` at $EB (`BIOS_MACHINE_CONFIG` follows). `docs/ZEROPAGE_MAP.md` now says that zero
  page that is not declared is scratch, free for programs to use.
- The TOCKS jiffy clock is verified in the emulator, which now delivers VIA interrupts.
  This replaces the note in 0.7.0 that said it could not be tested. With the tick running:
  `TOCKS` counts up during the monitor, an Intel HEX `L` load, a loaded program, `S` save,
  BASIC (a `FOR` loop, Ctrl-C, `MONITOR` and `X`) and keyboard input, and none of them is
  disturbed by the interrupt. Measured against the emulator's cycle counter, one tick is
  about 18,500 cycles, which is 10 ms (18,432) within the 1% the measurement can resolve.
- Removed the "STUB" block in `post` that said the timer was still to do. `via_init` starts it.
- `irq_handler` now saves A, X and Y on entry (`pha`, `phx`, `phy`) and restores them before the
  `RTI`, so the sources that will be added to it can use any register. Before, it only saved A
  because it only used A. Checked with a program that keeps known values in A, X and Y in a loop
  while the tick fires: it stays intact with the real handler, and with a test handler that
  trashes X and Y but saves them. It breaks with the same test handler without the X/Y save.

### Fixed

- `via_init` clears TOCKS before it looks for the VIA. Before, TOCKS was only cleared when a VIA was
  found, so without the I/O card it kept what the memory tests left in zero page ($AA) and never ran.
  It now reads 0.

### Tested

- After the zero page change (emulator, with the VIA): the ROM reaches the monitor and prints the new banner,
  `RAM_SIZE` is $7F00 (the POST RAM walk works with its scratch pointer), `VIA_PRESENT`, `BASIC_STARTED` and
  `MACHINE_CONFIG` read 01, 00 and 03 at their new addresses, and `X`, `MONITOR`, `X` start BASIC, return to
  the monitor and warm start BASIC without the banner.
- In the emulator, with the VIA: a program that calls `BIOS_GET_TOCKS` 6000 times while the tick runs
  never sees the clock go backwards, sees the carry from the low to the middle byte (the clock is
  set to $0000FE first) and gets A, X and Y in the right order; the I flag is kept when it is set
  and when it is clear. The config byte is $03 and BASIC still starts.
- Without a VIA at $7F20: the ROM boots to the monitor, no VIA banner line, TOCKS reads 0, the config
  byte is $01, and BASIC still starts.
- The atomic read is by construction (interrupts masked), sampling cannot show it. For a program that
  reads the three bytes itself, a bad value needs a tick to land in the ~6 cycles between its first and
  last read (about 1 in 3000 reads) and that tick to carry out of the low byte (1 in 256), so about
  1 in 800,000 reads. It is rare, but the value then jumps by about 2.5 seconds.

### Not verified

- On the board. The emulator reloads the timer with N cycles, a real 6522 takes N+2, so the
  `-2` in `VIA_T1_10MS` can only be confirmed with a scope. The I/O card's /IRQ line reaching
  the CPU is also untested.

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
