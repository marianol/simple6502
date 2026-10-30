
## Simple6502 Build ToDo's

- [x] Figure out what each source in SOURCE_FILES.md does.
- [x] Create a reference binary and a script that can compile and check against it as I am cleaning up in the source
- [x] see opportunities for file consolidation
- [x] the `CONFIG_*` flags in the defines are not read by any source now. They are commented out in one block as documentation of how it was configured. Only `CONFIG_NULL` is still used
- [x] the `-D simple6502` in the build scripts is not needed any more (the build works without it)
- [x] clean up souces for .ifdef(s) that refer to other architectures.
  - Only the `CONFIG_NULL` / `CONFIG_PRINTNULLS` conditionals are left on purpose (token.s, flow1.s, print.s, init.s). To enable NULL uncomment `CONFIG_NULL` and `NULL_MAX` in the defines.
- [ ] update init.s once the cleanup is done:
  - [x] `MEMSIZ` is at $E3/$E4, the BIOS `RAM_SIZE`. BASIC reads the top of memory from it, the RAM scan and the `MEMORY SIZE?` prompt are gone. The BIOS needs no change. Tested in the emulator, the BYTES FREE is correct
  - [x] `TERMINAL WIDTH?` prompt removed, the code that wrote `Z17` and `Z18` is commented out
  - [x] freed the unused zero page slots (`Z17`, `Z18`, old `MEMSIZ`) and made the variables one contiguous block from `BASIC_ZP_START`
  - [x] `WIDTH` and `WIDTH2` in the defines are not used now, see comments in defines_simple6502
  - [ ] the credits (`PR_WRITTEN_BY`, typing A at the memory prompt) are commented out, add them back somewhere if wanted
  - [x] new startup banner (`QT_BASIC`, `QT_BYTES_FREE`, `QT_COPYWRITE`), each string is printed by its own call now. Tested in the emulator
  - [ ] `DSCLEN` is set to 3 twice in the cold start, remove one (changes the binary, rebuild the reference)
- [x] zero page: `BASIC_ZP_START` lowered to $4A, BASIC ends at $DD. No overlap with the BIOS, $DE-$DF stay free as spare
- [x] `USR` has its own vector at $4A-$4C (it was an alias of `GORESTART`)
- [x] TEST `USR` in the emulator, works:
  - `PRINT USR(0)` should give `?ILLEGAL QUANTITY ERROR`
  - load a routine ending in `RTS` (for example at $0300), then `POKE 75,0 : POKE 76,3 : X=USR(5)` should run it and return to the OK prompt
- [x] TEST `SYS` in the emulator, works:
  - `SYS 65536` and `SYS -1` should give `?ILLEGAL QUANTITY ERROR`
  - load a routine ending in `RTS` should run it and return to the OK prompt
  - check that `LIST` shows `SYS` and that the other keywords still work (the token numbers after `CLEAR` moved by one)
- [ ] `LOAD` and `SAVE` are stubs (`loadsave.s`), hook them to the BIOS

### Nice to have
- [ ] `SYS` could load/store the A, X, Y and P registers like the C=64 does (from/to fixed locations)
- [ ] `ENTROPY` in the defines is unused now. Use the timer for the `RND` seed or remove it. Now RND function gets its initial random seed from a hardcoded, fixed sequence of bytes stored in the ROM and passed to ZP in init.s

### From original source

* convert messy init code into completely different
  files without ifdefs (not much in common!)
* move all machine specific code into separate files
* rename all labels that point to RTS to RTSn
* look for all " $", i.e. (zeropage) constants, replace them
  with symbols
* convert platform ifdefs in generic files into feature ifdefs or macros

