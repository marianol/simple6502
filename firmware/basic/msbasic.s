.debuginfo +

.setcpu "6502"
.macpack longbranch

; Definitions, constants and macros
.include "defines_basic.s"
.include "macros.s"
; The system zero page map (../zeropage.s), shared with the BIOS build. It gives
; BASIC the RAM_SIZE variable and the range reserved for BASIC.
.include "zeropage.s"
; The BASIC variables, checked against that range.
.include "zeropage_basic.s"

; The code block
.include "header.s"
.include "token.s"
.include "error.s"
.include "message.s"
.include "memory.s"
.include "program.s"
.include "flow1.s"
.include "loadsave.s"
.include "flow2.s"
.include "misc1.s"
.include "print.s"
.include "input.s"
.include "eval.s"
.include "var.s"
.include "array.s"
.include "misc2.s"
.include "string.s"
.include "poke.s"
.include "float.s"
.include "chrget.s"
.include "rnd.s"
.include "trig.s"
.include "init.s"
.include "extra.s"
