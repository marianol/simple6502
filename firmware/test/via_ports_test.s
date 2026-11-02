; Test of the VIA port routines, BIOS_VIA_CONFIG, BIOS_VIA_SET_DDR, BIOS_VIA_READ and BIOS_VIA_WRITE.
; They are called through the jump table of the real ROM. In sim65 the VIA registers are plain memory,
; so what a routine writes can be read back, which shows that it used the right register.
; Checked: the carry result, A/X/Y kept, the right register for each port, failures write nothing
; (bad port, bad VIA index, VIA not found), and the stack is balanced at the end.
.setcpu "65C02"
.include "bios_jumptable.inc"
.include "test.inc"

IO_PB   = $7F20                 ; VIA1 registers
IO_PA   = $7F21
IO_DDRB = $7F22
IO_DDRA = $7F23

.macro VIA_FOUND                ; what the BIOS reset leaves when it finds VIA1
        lda #BIOS_CFG_VIA1
        sta BIOS_MACHINE_CONFIG
.endmacro

.macro VIA_ABSENT               ; what the BIOS reset leaves when there is no VIA
        stz BIOS_MACHINE_CONFIG
.endmacro

.segment "USR_PROGRAM"
        tsx
        stx sp0
        stz IO_PB
        stz IO_PA
        stz IO_DDRB
        stz IO_DDRA
        VIA_FOUND

        ; --- BIOS_VIA_CONFIG
        SETREGS $11, 0, $22             ; VIA1 is found
        jsr BIOS_VIA_CONFIG
        CC 1
        AKEPT 2, $11
        KEPT 3, 0, $22
        SETREGS $11, 1, $22             ; index 1 is VIA2, there is none yet
        jsr BIOS_VIA_CONFIG
        CS 4
        AKEPT 5, $11
        KEPT 6, 1, $22
        SETREGS $11, $FF, $22           ; index far out of range
        jsr BIOS_VIA_CONFIG
        CS 7
        KEPT 8, $FF, $22
        VIA_ABSENT                      ; VIA1 not found at boot
        SETREGS $11, 0, $22
        jsr BIOS_VIA_CONFIG
        CS 9
        AKEPT 10, $11
        KEPT 11, 0, $22
        lda #BIOS_CFG_VIA1 | BIOS_CFG_VIA2   ; a VIA2 bit alone does not make index 1 valid
        sta BIOS_MACHINE_CONFIG
        SETREGS 0, 1, 0
        jsr BIOS_VIA_CONFIG
        CS 55
        VIA_FOUND

        ; --- BIOS_VIA_SET_DDR
        SETREGS $0F, 0, 0               ; port A
        jsr BIOS_VIA_SET_DDR
        CC 12
        AKEPT 13, $0F
        KEPT 14, 0, 0
        MEM 15, IO_DDRA, $0F
        MEM 16, IO_DDRB, $00
        SETREGS $F0, 0, 1               ; port B
        jsr BIOS_VIA_SET_DDR
        CC 17
        KEPT 18, 0, 1
        MEM 19, IO_DDRB, $F0
        MEM 20, IO_DDRA, $0F
        SETREGS $55, 0, 2               ; bad port
        jsr BIOS_VIA_SET_DDR
        CS 21
        KEPT 22, 0, 2
        SETREGS $55, 1, 0               ; bad VIA
        jsr BIOS_VIA_SET_DDR
        CS 23
        KEPT 24, 1, 0
        VIA_ABSENT                      ; VIA not found
        SETREGS $55, 0, 0
        jsr BIOS_VIA_SET_DDR
        CS 27
        VIA_FOUND
        MEM 25, IO_DDRA, $0F            ; none of the failures wrote anything
        MEM 26, IO_DDRB, $F0

        ; --- BIOS_VIA_WRITE
        SETREGS $5A, 0, 0               ; port A
        jsr BIOS_VIA_WRITE
        CC 29
        AKEPT 30, $5A
        KEPT 31, 0, 0
        MEM 32, IO_PA, $5A
        MEM 33, IO_PB, $00
        SETREGS $A5, 0, 1               ; port B
        jsr BIOS_VIA_WRITE
        CC 34
        KEPT 35, 0, 1
        MEM 36, IO_PB, $A5
        MEM 37, IO_PA, $5A
        SETREGS $77, 0, 2               ; bad port
        jsr BIOS_VIA_WRITE
        CS 38
        KEPT 39, 0, 2
        SETREGS $77, 1, 0               ; bad VIA
        jsr BIOS_VIA_WRITE
        CS 40
        VIA_ABSENT                      ; VIA not found
        SETREGS $77, 0, 0
        jsr BIOS_VIA_WRITE
        CS 41
        VIA_FOUND
        MEM 42, IO_PA, $5A              ; none of the failures wrote anything
        MEM 43, IO_PB, $A5

        ; --- BIOS_VIA_READ
        SETREGS 0, 0, 0                 ; port A
        jsr BIOS_VIA_READ
        CC 44
        AKEPT 45, $5A
        KEPT 46, 0, 0
        SETREGS 0, 0, 1                 ; port B
        jsr BIOS_VIA_READ
        CC 47
        AKEPT 48, $A5
        KEPT 49, 0, 1
        SETREGS 0, 0, 2                 ; bad port
        jsr BIOS_VIA_READ
        CS 50
        KEPT 51, 0, 2
        SETREGS 0, 1, 0                 ; bad VIA
        jsr BIOS_VIA_READ
        CS 52
        VIA_ABSENT                      ; VIA not found
        SETREGS 0, 0, 0
        jsr BIOS_VIA_READ
        CS 53

        ; --- the stack is balanced after all of that, failures included
        tsx
        cpx sp0
        beq :+
        FAIL 54
:       PASS

sp0:    .byte 0
