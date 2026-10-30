.segment "BASHEADER"	; avoid clash with BIOS HEADER segment
; Startup Vectors at the top of Basic ROM
; for the SIMPLE6502 this will be $DC00
; The BIOS jump table jumps to these two addresses (BIOS_BASIC_COLD and
; BIOS_BASIC_WARM), so they must stay at BASIC_COLD_START and BASIC_WARM_START
; (bios_jumptable.inc). The linker checks it.
.assert * = BASIC_COLD_START, lderror, "BASIC cold start entry is not at BASIC_COLD_START (bios_jumptable.inc)"
jmp     COLD_START      ; $DC00 cold start
.assert * = BASIC_WARM_START, lderror, "BASIC warm start entry is not at BASIC_WARM_START (bios_jumptable.inc)"
jmp     RESTART         ; $DC03 warm start
