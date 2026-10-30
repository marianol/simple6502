; Simple6502 console input, built on BIOS_SERIAL_POLL (bios_jumptable.inc).
;
; BIOS_SERIAL_POLL is non-blocking and does not echo: it returns the byte in A
; with carry set, or carry clear if nothing was received. X and Y are preserved.
.segment "EXTRA"

; MONRDKEY: blocking read with echo, used by GETLN (line input).
; BASIC's INLIN does not echo typed characters itself, so we do it here.
; Returns the char in A.
;
; Backspace ($08) and DEL ($7F) are handled here so INLIN stays untouched.
; INLIN2 keeps the buffer index in X and calls GETLN -> MONRDKEY, so X is the
; number of characters typed so far. On backspace we decrement X (the next key
; will overwrite the removed character), erase it on the terminal (BS, space,
; BS) and wait for the next key. At the start of the line it is ignored.
; NOTE: this relies on X being the buffer index when called from INLIN2.
MONRDKEY:
@wait:
        jsr     BIOS_SERIAL_POLL
        bcc     @wait
        cmp     #$08            ; backspace
        beq     @backspace
        cmp     #$7F            ; DEL (sent by some terminals for backspace)
        beq     @backspace
        jsr     BIOS_SERIAL_OUT ; echo (preserves A)
        rts
@backspace:
        txa
        beq     @wait           ; start of line, nothing to delete
        dex
        lda     #$08
        jsr     BIOS_SERIAL_OUT
        lda     #' '
        jsr     BIOS_SERIAL_OUT
        lda     #$08
        jsr     BIOS_SERIAL_OUT
        jmp     @wait

; MONRDKEY2: non-blocking read without echo, used by GET.
; Returns the char in A, or 0 if no key is waiting.
MONRDKEY2:
        jsr     BIOS_SERIAL_POLL
        bcs     @got
        lda     #$00
@got:
        rts


