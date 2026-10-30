.segment "INIT"

; ============================================================================
; COLD START
;
; Entry point when BASIC is started (the BIOS jumps here through the vector at
; the start of BASIC ROM, see header.s). It sets up the zero page, copies CHRGET
; into RAM, takes the top of memory from the BIOS, prints the banner and the
; free memory, and ends by jumping to RESTART (the "OK" prompt).
; ============================================================================

; ----------------------------------------------------------------------------
; Credits (removed). They were shown by typing "A" at the MEMORY SIZE prompt,
; which no longer exists. Kept commented out with QT_WRITTEN_BY.
; ----------------------------------------------------------------------------
;PR_WRITTEN_BY:
;      lda     #<QT_WRITTEN_BY
;      ldy     #>QT_WRITTEN_BY
;      jsr     STROUT

; ----------------------------------------------------------------------------
; COLD_START
; Step 1: stack and zero page vectors
; ----------------------------------------------------------------------------
COLD_START:
        ldx     #$FF
        stx     CURLIN+1                ; $FF in the high byte = direct mode
        ldx     #$FB
        txs                             ; stack pointer
        lda     #<COLD_START
        ldy     #>COLD_START
        sta     GORESTART+1             ; GORESTART: JMP to COLD_START for now
        sty     GORESTART+2
        sta     GOSTROUT+1              ; GOSTROUT: JMP to COLD_START for now
        sty     GOSTROUT+2
        lda     #<AYINT
        ldy     #>AYINT
        sta     GOAYINT                 ; GOAYINT: vector to AYINT (float to integer)
        sty     GOAYINT+1
        lda     #<GIVAYF
        ldy     #>GIVAYF
        sta     GOGIVEAYF               ; GOGIVEAYF: vector to GIVAYF (integer to float)
        sty     GOGIVEAYF+1
        lda     #$4C                    ; $4C = JMP opcode
        sta     GORESTART
        sta     GOSTROUT
        sta     JMPADRS                 ; JMP opcode of the function call trampoline (eval.s)
        sta     USR                     ; CHANGED: USR is its own vector now (zeropage_basic.s).
        lda     #<IQERR                 ; JMP IQERR until the user sets the address, so
        ldy     #>IQERR                 ; USR(x) gives ILLEGAL QUANTITY
        sta     USR+1
        sty     USR+2
; Terminal width is not used (CONFIG_NO_CR). Z17 and Z18 were removed from zeropage_basic.s.
;        lda     #WIDTH
;        sta     Z17                     ; default terminal width (see ZEROPAGE_MAP.md)
;        lda     #WIDTH2
;        sta     Z18                     ; default last print zone


; ----------------------------------------------------------------------------
; Step 2: copy CHRGET into RAM (zero page)
;
; GENERIC_CHRGET in ROM (chrget.s) is the text scanner. It modifies its own
; code (the TXTPTR operand), so it must run from RAM. It is copied to CHRGET
; in zero page, together with the random number seed.
;
; All non-CONFIG_SMALL versions of BASIC have
; the same bug here: While the number of bytes
; to be copied is correct for CONFIG_SMALL,
; it is one byte short on non-CONFIG_SMALL:
; It seems the "ldx" value below has been
; hardcoded. So on these configurations,
; the last byte of GENERIC_RNDSEED, which
; is 5 bytes instead of 4, does not get copied -
; which is nothing major, because it is just
; the least significant 8 bits of the mantissa
; of the random number seed.
; ----------------------------------------------------------------------------
        ldx     #GENERIC_CHRGET_END-GENERIC_CHRGET-1 ; XXX
L4098:                                  ; copy loop, X counts down to 0
        lda     GENERIC_CHRGET-1,x
        sta     CHRGET-1,x
        dex
        bne     L4098

; ----------------------------------------------------------------------------
; Step 3: initialize variables (X is 0 here)
; ----------------------------------------------------------------------------
        lda     #$03
        sta     DSCLEN                  ; (set again a few lines below, same value)
        txa                             ; A = 0
        sta     SHIFTSIGNEXT
        sta     LASTPT+1
.if .defined(CONFIG_NULL) || .defined(CONFIG_PRINTNULLS)
        sta     Z15                     ; number of NULs after a CR = 0
.endif
        pha                             ; push 0 as the bottom of the stack marker, the
                                        ; FOR/GOSUB frame search stops at it
        sta     Z14                     ; output is not suppressed
        lda     #$03
        sta     DSCLEN
        jsr     CRDO                    ; start on a new line
        ldx     #TEMPST
        stx     TEMPPT                  ; empty the temporary string descriptor stack

; ----------------------------------------------------------------------------
; Step 4: top of memory
; CHANGED: the BIOS POST finds the top of RAM and stores it in MEMSIZ ($E3/$E4,
; see the defines). The MEMORY SIZE prompt and the RAM scan were removed.
; ----------------------------------------------------------------------------
        lda     MEMSIZ
        ldy     MEMSIZ+1
        sta     FRETOP                  ; string space grows down from the top of memory
        sty     FRETOP+1

; ----------------------------------------------------------------------------
; Step 5: TERMINAL WIDTH prompt (removed). Z17 and Z18 are not read (CONFIG_NO_CR).
; The code is kept commented out. It asked for a width of 16 to 255 (Enter = the
; defaults) and stored it in Z17, and the last print zone in Z18. Z17 and Z18 were
; removed from zeropage_basic.s, add them back to use this.
; ----------------------------------------------------------------------------
;L4106:
;        lda     #<QT_TERMINAL_WIDTH
;        ldy     #>QT_TERMINAL_WIDTH
;        jsr     STROUT
;        jsr     NXIN
;        stx     TXTPTR
;        sty     TXTPTR+1
;        jsr     CHRGET
;        tay
;        beq     L4136                   ; Enter, keep the defaults
;        jsr     LINGET
;        lda     LINNUM+1
;        bne     L4106                   ; more than 255, ask again
;        lda     LINNUM
;        cmp     #$10
;        bcc     L4106                   ; less than 16, ask again
;L2829:
;        sta     Z17                     ; terminal width
;L4129:                                  ; subtract 14 until it goes below 0
;        sbc     #$0E
;        bcs     L4129
;        eor     #$FF
;        sbc     #$0C
;        clc
;        adc     Z17
;        sta     Z18                     ; last print zone
; ----------------------------------------------------------------------------
; Step 6: set up the program area
; ----------------------------------------------------------------------------
L4136:
        ldx     #<RAMSTART2
        ldy     #>RAMSTART2
        stx     TXTTAB                  ; start of program text
        sty     TXTTAB+1
        ldy     #$00
        tya
        sta     (TXTTAB),y              ; a 0 byte before the first program line
        inc     TXTTAB                  ; the program starts one byte after it
        bne     L4192
        inc     TXTTAB+1
L4192:
        lda     TXTTAB
        ldy     TXTTAB+1
        jsr     REASON                  ; check there is memory (OUT OF MEMORY if not)

; ----------------------------------------------------------------------------
; Step 7: banner and free memory
; ----------------------------------------------------------------------------
; CHANGED: the banner, the free memory and the copyright are printed one by one.
; Before, QT_BYTES_FREE had no 0 at the end and ran into the copyright text.
        lda     #<QT_BASIC
        ldy     #>QT_BASIC
        jsr     STROUT                  ; ### SIMPLE 6502 BASIC ###
        jsr     CRDO                    ; blank line
        lda     MEMSIZ
        sec
        sbc     TXTTAB
        tax                             ; bytes free = MEMSIZ - TXTTAB
        lda     MEMSIZ+1
        sbc     TXTTAB+1
        jsr     LINPRT                  ; print the number in A (high) and X (low)
        lda     #<QT_BYTES_FREE
        ldy     #>QT_BYTES_FREE
        jsr     STROUT                  ; " BYTES FREE " (same line as the copyright)
        lda     #<QT_COPYWRITE
        ldy     #>QT_COPYWRITE
        jsr     STROUT                  ; (C) 1978 MICROSOFT
        jsr     SCRTCH                  ; NEW, empty program

; ----------------------------------------------------------------------------
; Step 8: final vectors and start the interpreter
; ----------------------------------------------------------------------------
        lda     #<STROUT
        ldy     #>STROUT
        sta     GOSTROUT+1              ; GOSTROUT now jumps to STROUT
        sty     GOSTROUT+2
        lda     #<RESTART
        ldy     #>RESTART
        sta     GORESTART+1             ; GORESTART now jumps to RESTART (the OK prompt)
        sty     GORESTART+2
        jmp     (GORESTART+1)           ; go to RESTART


; ============================================================================
; Messages
; ============================================================================

; Credits (removed, see PR_WRITTEN_BY)
;QT_WRITTEN_BY:
;      ; asc80 "COPYRIGHT 1977 BY MICROSOFT CO"  ; only inAppleSoft Version
;      ; .byte CR,0                              ; only inAppleSoft Version
;      .byte   CR,LF,$0C                         ; FORM FEED
;      ; .byte "WRITTEN BY RICHARD W. WEILAND."  ; Used for version < 1.1
;      .byte   "WRITTEN BY WEILAND & GATES"
;      .byte   CR,LF,0

; TERMINAL WIDTH prompt text (removed)
;QT_TERMINAL_WIDTH:
;      .byte   "TERMINAL "
;      .byte   "WIDTH"
;      .byte   0

; Printed after the number of bytes free. The trailing space separates it from the
; copyright, which is on the same line.
QT_BYTES_FREE:
      .byte   " BYTES FREE "
      .byte   0

; Startup banner
QT_BASIC:
; Leaving here all the banners for reference
; in the original source these are controlled by Config symbols
;
;  .byte   "OSI 6502 BASIC VERSION 1.0 REV 3.2" ; Ohio Scientific (OSI)
;  .byte   "MOS TECH 6502 BASIC V1.1"           ; KIM-1
;  .byte   "MICROTAN BASIC"                     ; Tangerine MICROTAN 65
;  .byte   "  AIM 65 BASIC V1.1"                ; Rockwell International AIM-65 SBC
;  .byte   "BASIC V1.1"                         ; Synertek SYM-1 SBC 
;  .byte   "*** COMMODORE BASIC ***"            ; CBM v1.0 1977 Commodore PET
;  .byte   "### COMMODORE BASIC ###"            ; CBM v2.0 1978 Commodore PET 2001
;  .byte	"APPLE BASIC V1.1"                  ; AppleSoft Basic 
;
; Copywrite line for all, except Commodore which had no (C) mention
; .byte   "(C) 1980 MICROSOFT"                        ; Microtan
; .byte   "(C) 1978 MICROSOFT"                        ; AIM 65
; .byte   "COPYRIGHT 1978 SYNERTEK SYSTEMS CORP."     ; Synertek SYM-1
; .byte   "COPYRIGHT 1977 BY MICROSOFT CO."           ; all others
      .byte   CR,LF
      .byte   "### SIMPLE 6502 BASIC ###" 
      .byte   CR,LF
      .byte   0

; Copyright, same line as BYTES FREE. The CR,LF leaves a blank line before OK.
QT_COPYWRITE:
      .byte   "(C) 1978 MICROSOFT"
      .byte   CR,LF
      .byte   0