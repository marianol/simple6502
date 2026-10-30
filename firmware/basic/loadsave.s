.segment "CODE"
; LOAD and SAVE statements. The work is done by the BIOS, through the jump table
; (BIOS_LOAD and BIOS_SAVE in bios_jumptable.inc). Those are stubs for now (just
; RTS), they are meant for the SD card routines.
; BASIC jumps there instead of calling, so the BIOS routine's RTS returns straight
; to the statement dispatcher.
; @todo when the BIOS routines take a file name, parse it here (the text after the
; keyword, with FRMEVL) and pass it to the BIOS.
SAVE:
        jmp     BIOS_SAVE
LOAD:
        jmp     BIOS_LOAD
