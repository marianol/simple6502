.segment "BASHEADER"	; avoid clash with BIOS HEADER segment

; Startup Vectors at the top of Basic ROM
; for the SIMPLE6502 this will be $DC00

jmp     COLD_START      ; $DC00 cold start
jmp     RESTART         ; $DC03 warm start

