.segment "CODE"


PRSTRING:
        jsr     STRPRT
L297E:
        jsr     CHRGOT

; ----------------------------------------------------------------------------
; "PRINT" STATEMENT
; ----------------------------------------------------------------------------
PRINT:
        beq     CRDO
PRINT2:
        beq     L29DD
        cmp     #TOKEN_TAB
        beq     L29F5
        cmp     #TOKEN_SPC
        clc	; also AppleSoft II
        beq     L29F5
        cmp     #','
; Pre-KIM had no CLC. KIM added the CLC
; here. Post-KIM moved the CLC up...
; (makes no sense on KIM, liveness = 0)
        beq     L29DE
        cmp     #$3B
        beq     L2A0D
        jsr     FRMEVL
        bit     VALTYP
        bmi     PRSTRING
        jsr     FOUT
        jsr     STRLIT
        jsr     STRPRT
        jsr     OUTSP
        bne     L297E ; branch always




L29B9:
        lda     #$00
        sta     INPUTBUFFER,x
        ldx     #<(INPUTBUFFER-1)
        ldy     #>(INPUTBUFFER-1)


CRDO:
        lda     #CRLF_1
        sta     POSX
        jsr     OUTDO
CRDO2:
        lda     #CRLF_2
        jsr     OUTDO

PRINTNULLS:
  .if .def(CONFIG_NULL) || .def(CONFIG_PRINTNULLS)
        txa
        pha
        ldx     Z15
        beq     L29D9
        lda     #$00
L29D3:
        jsr     OUTDO
        dex
        bne     L29D3
L29D9:
        stx     POSX
        pla
        tax
  .else
        eor     #$FF
  .endif
L29DD:
        rts
L29DE:
        lda     POSX
        sec
L29EB:
        sbc     #$0E
        bcs     L29EB
        eor     #$FF
        adc     #$01
        bne     L2A08
L29F5:
        php
        jsr     GTBYTC
        cmp     #')'
        bne     SYNERR4
        plp
        bcc     L2A09
        txa
        sbc     POSX
        bcc     L2A0D
L2A08:
        tax
L2A09:
        inx
L2A0A:
        dex
        bne     L2A13
L2A0D:
        jsr     CHRGET
        jmp     PRINT2
L2A13:
        jsr     OUTSP
        bne     L2A0A

; ----------------------------------------------------------------------------
; PRINT STRING AT (Y,A)
; ----------------------------------------------------------------------------
STROUT:
        jsr     STRLIT

; ----------------------------------------------------------------------------
; PRINT STRING AT (FACMO,FACLO)
; ----------------------------------------------------------------------------
STRPRT:
        jsr     FREFAC
        tax
        ldy     #$00
        inx
L2A22:
        dex
        beq     L29DD
        lda     (INDEX),y
        jsr     OUTDO
        iny
        cmp     #$0D
        bne     L2A22
        jsr     PRINTNULLS
        jmp     L2A22
; ----------------------------------------------------------------------------
OUTSP:
        lda     #$20
        .byte   $2C
OUTQUES:
        lda     #$3F

; ----------------------------------------------------------------------------
; PRINT CHAR FROM (A)
; ----------------------------------------------------------------------------
OUTDO:
        bit     Z14
        bmi     L2A56
        cmp     #$20
        bcc     L2A4E
LCA6A:
        inc     POSX
L2A4E:
        jsr     MONCOUT
L2A56:
        and     #$FF
LE8F2:
        rts

; ----------------------------------------------------------------------------
; ???
; ----------------------------------------------------------------------------
