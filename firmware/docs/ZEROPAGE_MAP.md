# Zero page map

This is the map of the whole zero page. It is declared in two files, addresses checked against the ld65 label file:

* `firmware/zeropage.s`: the BIOS, WozMon, Intel HEX and monitor variables, and the range reserved for BASIC (`BASIC_ZP_START`, `BASIC_ZP_END`).
* `firmware/basic/zeropage_basic.s`: the BASIC variables.

WozMon and BASIC never run together, so overlaps with WozMon, monitor and Intel HEX variables would be fine.

## How the zero page is declared

Zero page variables are declared in these files with `.res`, never as `NAME = $xx` in a defines file.

* Each block is anchored with `.org` at a fixed address and its variables follow each other with `.res`. Blocks do not move: programs rely on the addresses (`BIOS_SERIAL_STR` reads `PTR_TX`, WozMon needs `XAML/XAMH`, `STL/STH` and `L/H` adjacent).
* Each block ends with an `.assert` that fails the build if the block grows into the next one. `zeropage.s` checks the BIOS blocks against the range reserved for BASIC, `zeropage_basic.s` checks that the BASIC block ends inside it.
* `basic/msbasic.s` includes `zeropage.s` too. That is how BASIC gets `RAM_SIZE` (its `MEMSIZ` is a name for it) and the reserved range, so the same map is checked in both builds. The linker sees the BIOS bytes twice in the `ZEROPAGE` segment (once per object), which only counts against the 256 byte limit while linking, it is not real RAM use.
* To add a BIOS variable: add it with `.res` at the end of the block it belongs to (or a new block in a free range), then update this table.

Status: `BASIC` = BASIC only, `BIOS` = BIOS only, `SHARED` = shared on purpose, `OVERLAP` = BASIC and BIOS share bytes by accident, `free` = unused.

## Overlaps

None. BASIC's block is $4A-$DD (`BASIC_ZP_START` and `BASIC_ZP_END` in `zeropage.s`). $47-$49 is free below it and $DE-$DF is free above it, before the BIOS `TOCKS` at $E0. `MEMSIZ` at $E3-$E4 is the BIOS `RAM_SIZE`, shared on purpose.

## Map

| Bytes | Size | BASIC | BIOS | Status | Notes |
| ----- | ---- | ----- | ---- | ------ | ----- |
| $00 | 1 |  | ZP_START | BIOS | fault beacon scratch (post_fail only) |
| $01-$23 | 35 |  |  | free |  |
| $24-$25 | 2 |  | XAML/XAMH | BIOS | WozMon |
| $26-$27 | 2 |  | STL/STH | BIOS | WozMon |
| $28-$29 | 2 |  | L/H | BIOS | WozMon |
| $2A | 1 |  | YSAV | BIOS | WozMon |
| $2B | 1 |  | MODE | BIOS | WozMon |
| $2C-$2F | 4 |  |  | free |  |
| $30-$31 | 2 |  | IHEX_ADDR | BIOS | Intel HEX |
| $32 | 1 |  | IHEX_LEN | BIOS | Intel HEX |
| $33 | 1 |  | IHEX_TYPE | BIOS | Intel HEX |
| $34 | 1 |  | IHEX_SUM | BIOS | Intel HEX |
| $35 | 1 |  | IHEX_TMP | BIOS | Intel HEX |
| $36-$3F | 10 |  |  | free |  |
| $40-$41 | 2 |  | PC_REG_H/L | BIOS | monitor register print |
| $42 | 1 |  | SP_REG | BIOS | monitor register print |
| $43 | 1 |  | A_REG | BIOS | monitor register print |
| $44 | 1 |  | X_REG | BIOS | monitor register print |
| $45 | 1 |  | Y_REG | BIOS | monitor register print |
| $46 | 1 |  | SR_REG | BIOS | monitor register print |
| $47-$49 | 3 |  |  | free |  |
| $4A-$4C | 3 | USR |  | BASIC | `USR(x)` vector, a `JMP`. Set to IQERR at startup. POKE USR+1 (low) and USR+2 (high) to set the routine address |
| $4D-$4F | 3 | GORESTART |  | BASIC |  |
| $50-$52 | 3 | GOSTROUT |  | BASIC |  |
| $53-$54 | 2 | GOAYINT |  | BASIC |  |
| $55-$56 | 2 | GOGIVEAYF |  | BASIC |  |
| $57 | 1 | Z15 |  | BASIC | null count after CR; unused in this build |
| $58 | 1 | POSX |  | BASIC | cursor column |
| $59-$5A | 2 | LINNUM / TXPSV |  | BASIC | TXPSV (INPUT/READ text pointer save) shares LINNUM |
| $5B | 1 | CHARAC |  | BASIC |  |
| $5C | 1 | ENDCHR |  | BASIC |  |
| $5D | 1 | EOLPNTR |  | BASIC |  |
| $5E | 1 | DIMFLG |  | BASIC |  |
| $5F-$60 | 2 | VALTYP |  | BASIC |  |
| $61 | 1 | DATAFLG |  | BASIC |  |
| $62 | 1 | SUBFLG |  | BASIC |  |
| $63 | 1 | INPUTFLG |  | BASIC |  |
| $64 | 1 | CPRMASK |  | BASIC |  |
| $65 | 1 | Z14 |  | BASIC | output suppress flag (Ctrl-O) |
| $66 | 1 | TEMPPT |  | BASIC |  |
| $67-$68 | 2 | LASTPT |  | BASIC |  |
| $69-$71 | 9 | TEMPST |  | BASIC |  |
| $72-$73 | 2 | INDEX |  | BASIC |  |
| $74-$75 | 2 | DEST |  | BASIC |  |
| $76-$7A | 5 | RESULT |  | BASIC |  |
| $7B-$7C | 2 | TXTTAB |  | BASIC |  |
| $7D-$7E | 2 | VARTAB |  | BASIC |  |
| $7F-$80 | 2 | ARYTAB |  | BASIC |  |
| $81-$82 | 2 | STREND |  | BASIC |  |
| $83-$84 | 2 | FRETOP |  | BASIC |  |
| $85-$86 | 2 | FRESPC |  | BASIC |  |
| $87-$88 | 2 | CURLIN |  | BASIC |  |
| $89-$8A | 2 | OLDLIN |  | BASIC |  |
| $8B-$8C | 2 | OLDTEXT |  | BASIC |  |
| $8D-$8E | 2 | Z8C |  | BASIC | line number of the DATA statement being read |
| $8F-$90 | 2 | DATPTR |  | BASIC |  |
| $91-$92 | 2 | INPTR |  | BASIC |  |
| $93-$94 | 2 | VARNAM |  | BASIC |  |
| $95-$96 | 2 | VARPNT |  | BASIC |  |
| $97-$98 | 2 | FORPNT |  | BASIC |  |
| $99-$9A | 2 | LASTOP |  | BASIC |  |
| $9B | 1 | CPRTYP |  | BASIC |  |
| $9C-$9D | 2 | FNCNAM / TEMP3 |  | BASIC |  |
| $9E-$A0 | 3 | DSCPTR |  | BASIC |  |
| $A1-$A2 | 2 | DSCLEN |  | BASIC | JMPADRS = DSCLEN+1 (3 bytes): a `JMP` used to call the functions (`eval.s` stores the address in JMPADRS+1/+2). Overlaps Z52 and ARGEXTENSION on purpose |
| $A3 | 1 | Z52 |  | BASIC | scratch for garbage collection and LEFT$/RIGHT$/MID$ |
| $A4 | 1 | ARGEXTENSION |  | BASIC |  |
| $A5 | 1 | TEMP1 |  | BASIC |  |
| $A6-$A7 | 2 | HIGHDS |  | BASIC |  |
| $A8-$A9 | 2 | HIGHTR |  | BASIC |  |
| $AA | 1 | TEMP2 |  | BASIC |  |
| $AB | 1 | INDX / TMPEXP |  | BASIC |  |
| $AC | 1 | EXPON |  | BASIC |  |
| $AD | 1 | LOWTR / LOWTRX |  | BASIC | LOWTR+1 is EXPSGN |
| $AE | 1 | EXPSGN |  | BASIC |  |
| $AF-$B3 | 5 | FAC |  | BASIC |  |
| $B4 | 1 | FACSIGN |  | BASIC |  |
| $B5 | 1 | SERLEN |  | BASIC |  |
| $B6 | 1 | SHIFTSIGNEXT |  | BASIC |  |
| $B7-$BB | 5 | ARG |  | BASIC |  |
| $BC | 1 | ARGSIGN |  | BASIC |  |
| $BD-$BE | 2 | STRNG1 |  | BASIC | SGNCPR = STRNG1, FACEXTENSION = STRNG1+1 |
| $BF-$C0 | 2 | STRNG2 |  | BASIC |  |
| $C1-$D8 | 24 | CHRGET code |  | BASIC | CHRGOT=$C7, CHRGOT2=$CE, TXTPTR=$C8-$C9 |
| $D9-$DD | 5 | RNDSEED |  | BASIC | part of the CHRGET block (RND writes the seed here) |
| $DE-$DF | 2 |  |  | free |  |
| $E0-$E2 | 3 |  | TOCKS | BIOS | jiffy clock |
| $E3-$E4 | 2 | MEMSIZ | RAM_SIZE ($E3-$E4) | SHARED | top of memory, first address that is not RAM. The BIOS POST writes it (its RAM_SIZE), BASIC reads it. Shared on purpose |
| $E5 | 1 |  | PTR_RD_RX_BUF | BIOS |  |
| $E6 | 1 |  | PTR_WR_RX_BUF | BIOS |  |
| $E7-$E8 | 2 |  | PTR_TX | BIOS | string pointer |
| $E9-$EA | 2 |  | POST_PTR | BIOS | POST RAM walk |
| $EB | 1 |  | VIA_PRESENT | BIOS | non-zero if VIA1 was detected and initialized |
| $EC | 1 | BASIC_STARTED | BASIC_STARTED | SHARED | non-zero once BASIC has been cold started. The BIOS reset clears it, BASIC's cold start sets it. The monitor `X` command warm starts BASIC only if it is set. |
| $ED-$FF | 19 |  |  | free |  |

## What the Zxx variables do

These have no descriptive name in the MS BASIC source. Descriptions come from reading the code that uses them.

| Name | Address | Size | Purpose | Used in this build |
| ---- | ------- | ---- | ------- | ------------------ |
| Z14 | $65 | 1 | Output suppress flag. `OUTDO` checks bit 7 and skips printing when it is set. Ctrl-O typed at a line prompt toggles it (`inline.s`). It is cleared at `ERROR`, `RESTART` and `INPUT` (`lsr Z14`), and by a break/STOP (`stx Z14`). Set up at startup by `init.s`. | Yes |
| Z15 | $57 | 1 | Number of NUL characters to send after a carriage return. Set by the `NULL` statement and at startup, read by `CRDO` in `print.s`. | No. Only assembled with `CONFIG_NULL` or `CONFIG_PRINTNULLS`, neither is defined, so nothing reads or writes it. Kept so NULL can be switched on |
| Z8C | $8D | 2 | Line number of the `DATA` statement `READ` is working in. `FINDATA` in `input.s` stores it; the syntax error path for bad data puts it in `CURLIN` so the error is reported against the `DATA` line. | Yes |
| Z52 | $A3 | 1 | Scratch byte used in `string.s` in two unrelated places. In garbage collection it keeps the offset from a variable entry to its string descriptor (0 for an array element, 2 for a simple variable, taken from `DSCLEN`). In `SUBSTRING_SETUP` (`LEFT$`, `RIGHT$`, `MID$`) it holds the high byte of the return address while the parameters are popped off the stack. | Yes |

`Z17` (terminal width) and `Z18` (last comma print zone) were removed. Nothing read them with `CONFIG_NO_CR` on, and the code in `init.s` that wrote them is commented out. `WIDTH` and `WIDTH2` in the defines are not used now either.

## Totals

* BASIC uses 150 bytes ($4A-$DD in one block, plus MEMSIZ at $E3-$E4, shared with the BIOS RAM_SIZE).
* BIOS uses 35 bytes.
* 73 bytes are free in both.
* `BASIC_ZP_START` = $4A (in `zeropage.s`). The variables in `zeropage_basic.s` follow each other from there.
* `STACK_TOP` ($FA) is a stack page offset, not a zero page address.
