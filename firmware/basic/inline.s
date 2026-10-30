.segment "CODE"


; ----------------------------------------------------------------------------
; READ A LINE, AND STRIP OFF SIGN BITS
; ----------------------------------------------------------------------------
INLIN:

        ldx     #$00
INLIN2:
        jsr     GETLN
        cmp     #$0D
        beq     L2453
        sta     INPUTBUFFER,x
        inx
        bne     INLIN2
L244C:
L2453:
        jmp     L29B9

GETLN:
        jsr     MONRDKEY
        cmp     #$0F
        bne     L2465
        pha
        lda     Z14
        eor     #$FF
        sta     Z14
        pla
L2465:
        rts
