; simple6502 BIOS header: the jump table (public ABI)
;
; Fixed-address entry points so external programs can call BIOS routines at
; stable addresses that never change as the BIOS internals grow.
;
; The table lives at the very start of ROM ($8000) and each entry is a 3-byte
; JMP. CONTRACT: entries are APPEND-ONLY. Never insert, reorder, or remove a
; slot - that would shift every entry below it and break existing binaries.
; Add new routines to the end only.
;
; Slot  Address  Routine
; ----  -------  ----------------------------------------------------------
;  0    $8000    J_COLD_START  - cold start / reset entry
;  1    $8003    J_MONITOR     - enter WozMon monitor
;  2    $8006    J_SERIAL_OUT  - transmit A over serial
;  3    $8009    J_SERIAL_IN   - receive a byte (carry set if data)
;  4    $800C    J_SERIAL_STR  - transmit null-terminated string @ PTR_TX
;  5    $800F    J_SERIAL_HEX  - transmit A as two ASCII hex digits
;  6    $8012    J_OUT_CRLF    - transmit CR+LF
;  7    $8015    J_SERIAL_POLL - receive a byte, no echo (carry set if data)
;  8    $8018    J_BASIC_COLD  - cold start MS BASIC (new program, memory cleared)
;  9    $801B    J_BASIC_WARM  - warm start MS BASIC (keeps the program and variables)
; 10    $801E    J_LOAD        - BASIC LOAD (stub for now, just RTS)
; 11    $8021    J_SAVE        - BASIC SAVE (stub for now, just RTS)
;
; The equates for these addresses live in bios_jumptable.inc for programs to
; include. The .asserts at the end of this file stop the build if the two get
; out of sync, so when you append an entry here also add its equate there.
;
; Included by BIOS.s. The routines the entries jump to are in BIOS.s and
; wozmon_sbc.s. BIOS.s includes bios_jumptable.inc before this file.

.segment "HEADER"
J_COLD_START:  jmp reset            ; slot 0  $8000
J_MONITOR:     jmp WOZMON           ; slot 1  $8003
J_SERIAL_OUT:  jmp serial_out       ; slot 2  $8006
J_SERIAL_IN:   jmp serial_in        ; slot 3  $8009
J_SERIAL_STR:  jmp serial_out_str   ; slot 4  $800C
J_SERIAL_HEX:  jmp serial_out_hex   ; slot 5  $800F
J_OUT_CRLF:    jmp out_crlf         ; slot 6  $8012
J_SERIAL_POLL: jmp serial_poll      ; slot 7  $8015
J_BASIC_COLD:  jmp BASIC_COLD_START ; slot 8  $8018  BASIC's own entry, $DC00
J_BASIC_WARM:  jmp BASIC_WARM_START ; slot 9  $801B  BASIC's own entry, $DC03
J_LOAD:        jmp bios_load        ; slot 10 $801E
J_SAVE:        jmp bios_save        ; slot 11 $8021

; Keep MONITOR as an alias for existing code that referenced it.
MONITOR = J_MONITOR

; The table must match bios_jumptable.inc. The table is in a relocatable segment,
; so the linker checks these once it has placed HEADER at $8000.
.assert J_COLD_START  = BIOS_COLD_START,  lderror, "jump table slot 0 does not match bios_jumptable.inc"
.assert J_MONITOR     = BIOS_MONITOR,     lderror, "jump table slot 1 does not match bios_jumptable.inc"
.assert J_SERIAL_OUT  = BIOS_SERIAL_OUT,  lderror, "jump table slot 2 does not match bios_jumptable.inc"
.assert J_SERIAL_IN   = BIOS_SERIAL_IN,   lderror, "jump table slot 3 does not match bios_jumptable.inc"
.assert J_SERIAL_STR  = BIOS_SERIAL_STR,  lderror, "jump table slot 4 does not match bios_jumptable.inc"
.assert J_SERIAL_HEX  = BIOS_SERIAL_HEX,  lderror, "jump table slot 5 does not match bios_jumptable.inc"
.assert J_OUT_CRLF    = BIOS_OUT_CRLF,    lderror, "jump table slot 6 does not match bios_jumptable.inc"
.assert J_SERIAL_POLL = BIOS_SERIAL_POLL, lderror, "jump table slot 7 does not match bios_jumptable.inc"
.assert J_BASIC_COLD  = BIOS_BASIC_COLD,  lderror, "jump table slot 8 does not match bios_jumptable.inc"
.assert J_BASIC_WARM  = BIOS_BASIC_WARM,  lderror, "jump table slot 9 does not match bios_jumptable.inc"
.assert J_LOAD        = BIOS_LOAD,        lderror, "jump table slot 10 does not match bios_jumptable.inc"
.assert J_SAVE        = BIOS_SAVE,        lderror, "jump table slot 11 does not match bios_jumptable.inc"
