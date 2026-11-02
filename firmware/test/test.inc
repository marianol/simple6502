; Helpers for the sim65 tests (see README.md in this folder).
;
; A test program runs in sim65, where all of memory is RAM. That lets a test set up the BIOS state it
; needs (BIOS_MACHINE_CONFIG for example) and read back what a routine wrote to a hardware register.
;
; The program ends with PASS, or stops at the first check that fails with that check's number as the
; exit code. Number every check in a test differently, from 1 to 125 (0 is a pass, 126 is how sim65
; reports a program that never finished). run_tests.sh prints the source line of the check that failed.

SIM65_EXIT = $FFF9              ; sim65 paravirtual exit: the exit code is in A

.macro FAIL n
        lda #n
        jmp SIM65_EXIT
.endmacro

.macro PASS
        lda #0
        jmp SIM65_EXIT
.endmacro

; Load A, X and Y
.macro SETREGS ra, rx, ry
        lda #ra
        ldx #rx
        ldy #ry
.endmacro

; Carry must be clear (CC) or set (CS). Check the carry first, the checks below change it.
.macro CC n
        bcc :+
        FAIL n
:
.endmacro

.macro CS n
        bcs :+
        FAIL n
:
.endmacro

; X and Y must have these values
.macro KEPT n, kx, ky
        cpx #kx
        beq :+
        FAIL n
:       cpy #ky
        beq :+
        FAIL n
:
.endmacro

; A must have this value
.macro AKEPT n, ka
        cmp #ka
        beq :+
        FAIL n
:
.endmacro

; The byte at addr must have this value (clobbers A)
.macro MEM n, addr, val
        lda addr
        cmp #val
        beq :+
        FAIL n
:
.endmacro
