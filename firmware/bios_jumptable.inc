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
