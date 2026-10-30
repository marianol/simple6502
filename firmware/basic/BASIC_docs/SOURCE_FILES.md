# Files read by the simple6502 build

Build: `ca65 msbasic.s` (see `make_simple6502.sh`).
List generated with `ca65 msbasic.s --create-dep`.

Descriptions are inferred from a quick scan of each file.

## Top level and configuration

| File | What it does |
| ---- | ------------ |
| msbasic.s | Main file. Includes `defines_basic.s`, the zero page files and all the others in link order. |
| defines_basic.s | All target definitions: `CONFIG_*` flags, `INPUTBUFFER`, floating point sizes, `CR`/`LF`, `MONCOUT`. Includes `../bios_jumptable.inc`. |
| ../bios_jumptable.inc | The Simple6502 BIOS jump table (`BIOS_*` addresses), shared with the BIOS. |
| macros.s | Macros for tokens, keyword tables, error messages and high-bit strings. |
| ../zeropage.s | The system zero page map (shared with the BIOS): `RAM_SIZE` and the range reserved for BASIC. |
| zeropage_basic.s | The BASIC zero page variables. |
| header.s | Entry points at the start of BASIC ROM: `jmp COLD_START` at $DC00 and `jmp RESTART` (warm start) at $DC03. |

## Interpreter core

| File | What it does |
| ---- | ------------ |
| token.s | Keyword table, token numbers and the statement and function vectors. |
| error.s | Error code table and error message strings. |
| message.s | Global messages: "ERROR", "IN", "READY.", "BREAK". |
| memory.s | Stack frame search and memory management (shared by all BASIC versions). |
| program.s | Error handling, program entry and line editing, tokenizer (`CRUNCH`), detokenizer (`LIST`). |
| flow1.s | `FOR`/`NEXT`, statement dispatcher (`NEWSTT`), `RESTORE`, `STOP`/`END`. |
| flow2.s | `RUN`, `GOSUB`/`RETURN`, `GOTO`, `DATA`, `IF`, `REM`, `ON`. |
| misc1.s | Line number parsing (`LINGET`), `LET` and string assignment. |
| misc2.s | `FRE`, `POS`, `DEF FN` and integer-to-float helpers. |
| chrget.s | `CHRGET` and `CHRGOT` text scanner (copied to zero page at startup). |
| init.s | Cold start: memory sizing, banner and zero page setup. Sets `BASIC_STARTED` at the end. |

## Expressions, variables and math

| File | What it does |
| ---- | ------------ |
| eval.s | Expression evaluator and operators. |
| var.s | Variable lookup and creation (`PTRGET`). |
| array.s | Arrays: `DIM`, element addressing and integer conversion. |
| string.s | String functions and string space management (including garbage collection). |
| float.s | Floating point routines. Includes the CBM2 "WAIT 6502" Easter egg. |
| trig.s | `SIN`, `COS`, `TAN`, `ATN`. |
| rnd.s | `RND` and the random number seed. |
| poke.s | `PEEK`, `POKE`, `WAIT` and related argument parsing, and `SYS` (added). |

## Input and output

| File | What it does |
| ---- | ------------ |
| print.s | `PRINT`, `TAB`, `SPC`, number and string output, character out (`OUTDO`). |
| input.s | `INPUT`, `READ`, `GET` and input conversion errors. |
| inline.s | Line input (`INLIN`) from the console. |
| iscntc.s | Ctrl-C check using `BIOS_SERIAL_POLL`. Any other key is discarded. Falls into `STOP`. |
| extra.s | `MONRDKEY` (blocking, echoes, handles backspace), `MONRDKEY2` (non-blocking, for GET) and the `MONITOR` statement, in the `EXTRA` segment. |
| loadsave.s | The `LOAD` and `SAVE` statements. Each one jumps to the BIOS (`BIOS_LOAD`, `BIOS_SAVE`), which are stubs for now. |

## Build files (not read by the assembler)

| File | What it does |
| ---- | ------------ |
| ../simple6502.cfg | ld65 linker config and memory map, for the whole ROM. |
| make_simple6502.sh | Assembles and links BASIC on its own into `out/Simple6502-BASIC.bin` (plus `.o` and `.lbl`). The full ROM is built by `../make_rom.sh`. |
| compare_simple6502.sh | Builds the target and compares it byte by byte with `ref/simple6502_ref.bin`. |
| ref/simple6502_ref.bin | Reference binary. Rebuilt after adding the entry jumps in `header.s`. |
