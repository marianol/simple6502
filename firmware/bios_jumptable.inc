; simple6502 BIOS - Public Jump Table (ABI)
;
; Fixed entry-point addresses for the BIOS routines. External programs that run
; on the simple6502 (user programs, loaders, future BASIC, etc.) should call
; these addresses rather than the BIOS's internal labels, which move whenever
; the BIOS is rebuilt.
;
; The table lives at the start of ROM ($8000); each entry is a 3-byte JMP.
;
; CONTRACT: the table is APPEND-ONLY. Addresses here are frozen. New routines
; are added at the end (next free slot). Never insert or reorder.
;
; Usage from an assembly program:
;     .include "bios_jumptable.inc"
;     lda #'A'
;     jsr BIOS_SERIAL_OUT

BIOS_JUMPTABLE = $8000              ; base address of the table

BIOS_COLD_START = BIOS_JUMPTABLE + 0*3   ; $8000 cold start / reset
BIOS_MONITOR    = BIOS_JUMPTABLE + 1*3   ; $8003 enter WozMon
BIOS_SERIAL_OUT = BIOS_JUMPTABLE + 2*3   ; $8006 transmit A over serial
BIOS_SERIAL_IN  = BIOS_JUMPTABLE + 3*3   ; $8009 receive byte (carry set if data in A)
BIOS_SERIAL_STR = BIOS_JUMPTABLE + 4*3   ; $800C transmit null-terminated string @ PTR_TX
BIOS_SERIAL_HEX = BIOS_JUMPTABLE + 5*3   ; $800F transmit A as two ASCII hex digits
BIOS_OUT_CRLF   = BIOS_JUMPTABLE + 6*3   ; $8012 transmit CR + LF
BIOS_SERIAL_POLL = BIOS_JUMPTABLE + 7*3  ; $8015 receive byte, no echo (carry set if data in A)
BIOS_BASIC_COLD = BIOS_JUMPTABLE + 8*3   ; $8018 cold start MS BASIC (new program, memory cleared)
BIOS_BASIC_WARM = BIOS_JUMPTABLE + 9*3   ; $801B warm start MS BASIC (keeps the program and variables)
BIOS_LOAD       = BIOS_JUMPTABLE + 10*3  ; $801E BASIC LOAD (stub for now, just RTS)
BIOS_SAVE       = BIOS_JUMPTABLE + 11*3  ; $8021 BASIC SAVE (stub for now, just RTS)

; MS BASIC's own entry points, the two JMPs at the start of its ROM region
; (basic/header.s, BASROM at $DC00 in simple6502.cfg). The jump table slots above
; go there. basic/header.s checks at link time that BASIC really starts at these.
BASIC_COLD_START = $DC00            ; cold start
BASIC_WARM_START = $DC03            ; warm start (RESTART)
