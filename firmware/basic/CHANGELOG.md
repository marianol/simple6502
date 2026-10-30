# Changelog

All notable changes to this Simple6502 fork of
[mist64/msbasic](https://github.com/mist64/msbasic) are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]
### Changed
- `LOAD` and `SAVE` (`loadsave.s`) jump to the BIOS (`BIOS_LOAD` and `BIOS_SAVE`, BIOS v0.8.0),
  which are stubs for now, instead of having their own `rts`. The binary grew 5 bytes and
  `ref/simple6502_ref.bin` was rebuilt: the only differences were the two `jmp`s and the
  `LOAD` entry in the statement table.
- `header.s` checks at link time that the cold and warm start entries are at
  `BASIC_COLD_START` and `BASIC_WARM_START` (`bios_jumptable.inc`), where the BIOS jumps.
- Moved into the simple6502 repository (`firmware/basic/`). `defines_simple6502.s` and
  `zeropage.s` were renamed `defines_basic.s` and `zeropage_basic.s` (the BIOS has files with
  the old names). `simple6502.cfg` and `bios_jumptable.inc` are now the BIOS copies in
  `firmware/`, and the build scripts find them there. The binary is unchanged (checked with
  `compare_simple6502.sh`).
- Zero page: `BASIC_ZP_START` and the new `BASIC_ZP_END` are defined in the system zero
  page map (`firmware/zeropage.s`), and `MEMSIZ` is now defined as `RAM_SIZE` from that map
  instead of a copy of `$E3`. `zeropage_basic.s` has an `.assert` that the BASIC block ends
  inside the range reserved for it.

### Removed

- Files for all other targets (defines, linker configs, extra, iscntc and
  loadsave files), `make.sh`, `regress.sh` and the `orig/` reference binaries.

### Added

- `SYS address` statement (`poke.s`, keyword in `token.s`). Calls a machine code routine at
  0-65535 and returns on `RTS`, ILLEGAL QUANTITY if out of range. It does not load the CPU
  registers like the CBM does. The token numbers after `CLEAR` moved by one. Tested in the emulator.
- `SOURCE_FILES.md`: files the simple6502 build reads, with a short
  description of each.
- This changelog.

- `compare_simple6502.sh`: builds simple6502 and compares it byte by byte with
  `ref/simple6502_ref.bin`, the binary built before the cleanup.

### Changed

- Startup banner: `### SIMPLE 6502 BASIC ###`, a blank line, then the free memory and
  `(C) 1978 MICROSOFT` on one line. `QT_BYTES_FREE` no longer runs into the copyright text, each
  string (`QT_BASIC`, `QT_BYTES_FREE`, `QT_COPYWRITE`) has its own 0 and its own call in `init.s`.
- Zero page: `Z17`, `Z18` and the old `MEMSIZ` slot removed (nothing used them). The
  variables are now one contiguous block from `BASIC_ZP_START` ($4A), it replaces
  `ZP_START1`-`4` and `ZP_USR`. Everything after those slots moved down. BASIC now ends at
  $DD, no overlap with the BIOS ($DE-$DF stay free). `ZEROPAGE_MAP.md` regenerated. Tested in the emulator.
- Startup: the MEMORY SIZE and TERMINAL WIDTH prompts and the RAM scan are removed.
  `MEMSIZ` is at $E3/$E4 (`MEMSIZ` in the defines), the BIOS `RAM_SIZE`, so BASIC reads the top
  of memory the BIOS POST found. No BIOS change needed. Tested in the emulator, BYTES FREE is correct. The code that wrote
  `Z17`/`Z18`, the width prompt and the credits are commented out in `init.s`.
- Build scripts simplified (no `-D`, no loop). The output is now
  `out/Simple6502-BASIC.bin` (plus `.o` and `.lbl`).
- `USR` has its own 3 byte vector at $4A-$4C (`USR`). It was an alias of
  `GORESTART`, so `USR(x)` ended up at the OK prompt. It now gives ILLEGAL
  QUANTITY until the routine address is POKEd into $4B/$4C (75/76).
  Tested in the emulator. Reference rebuilt.
- Defines: the `CONFIG_` settings are commented out and grouped in one block, with
  a description of each, to document how the source was configured. Nothing
  reads them any more except `CONFIG_NULL`.
- `init.s` commented: the cold start steps and the main labels are documented.
- Easter egg (`WAIT 6502,n`) in `float.s` now sends "MICROSOFT!" to the serial
  terminal instead of writing to PET screen memory at $8000 (the BIOS ROM here).
  The original code is kept as comments. Tested on the emulator. Reference
  rebuilt.
- Zero page: `POSX` and `TXPSV` overrides removed. `POSX` is now at $5B and no
  longer overlaps `STRNG2`; `TXPSV` shares `LINNUM`. Override `.ifdef`s removed
  from `zeropage.s`. Added `ZEROPAGE_MAP.md`. Reference rebuilt.
- `token.s`, `error.s`, `message.s`, `program.s`, `flow1.s`, `flow2.s`, `misc1.s`, `misc2.s`, `poke.s`, `rnd.s`, `array.s`, `trig.s`, `var.s`, `float.s`, `string.s`, `eval.s`, `init.s`, `print.s`, `input.s` and `inline.s`: removed `.ifdef`s for other targets. `CONFIG_NULL` is
  kept on purpose. `ERR_BADDATA` is commented out (needs `CONFIG_FILE`).
- LOAD/SAVE stubs moved from `simple6502_extra.s` to `loadsave.s`.
- `simple6502_extra.s` merged into `extra.s`. `.ifdef KBD` removed from `chrget.s`.
- `misc3.s` removed (KBD only); `msbasic.s` no longer includes it.
- `header.s` now has the entry points: `jmp COLD_START` at $DC00 and
  `jmp RESTART` (warm start) at $DC03. The `.ifdef`s were removed.
- `iscntc.s` holds the Ctrl-C check directly; `simple6502_iscntc.s` and
  `cbm_iscntc.s` removed.
- Reference binary rebuilt for the entry jumps (6 bytes at the start of BASIC)
  and for the backspace fix.
- `defines.s` merged into `defines_simple6502.s`; `msbasic.s` includes it
  directly. Unused defines removed (`CURDVC`, `TISTR`, `Z96`).
- `TODO.txt` renamed to `TODO.md`.
- README rewritten for the Simple6502-only branch.

### Fixed

- Backspace ($08) and DEL ($7F) are handled in `MONRDKEY`: the last character
  is removed from the line buffer and erased on the terminal. `inline.s` is
  unchanged. Tested in the emulator, together with Ctrl-C.
- README typos.

## [0.1.0]

### Added

- Simple6502 build target (`defines_simple6502.s`, `make_simple6502.sh`).
- `simple6502.cfg`: BASIC in its own `BASROM` region ($DC00-$FEFF) for merging
  with the BIOS. `header.s` uses a `BASHEADER` segment for this target.
- BIOS integration through `bios_jumptable.inc` (BIOS v0.6.1 or later):
  `MONCOUT`, blocking `MONRDKEY`, non-blocking `MONRDKEY2` (GET) and a Ctrl-C
  check. LOAD and SAVE are stubs.

### Changed

- `print.s`: the CBM2 `INPUTBUFFER` setup is also used for Simple6502.
- `.gitignore`: ignore `out/`, `out-orig/` and `.DS_Store`.
