.segment "CODE"

; LOAD and SAVE stubs. The BIOS has no load/save routine yet (only the
; monitor's Intel HEX L and S commands).
; @todo hook these up once the BIOS provides them.
SAVE:
LOAD:
        rts