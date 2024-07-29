; User Program scratchpad 
; Written by Mariano Luna, 2024
; License: BSD-3-Clause
; https://opensource.org/license/bsd-3-clause

; this is to write and compile user programs to run in memory

; ## VIA TEST ##
VIA1_BASE   = $7F20 ; IO_03
VIA1_PORTB  = VIA1_BASE         ; $7F20
VIA1_PORTA  = VIA1_BASE + 1     ; $7F21
VIA1_DDRB   = VIA1_BASE + 2     ; $7F22
VIA1_DDRA   = VIA1_BASE + 3     ; $7F23
VIA1_T1CL   = VIA1_BASE + 4     ; $7F24 Timer 1 Counter Low byte
VIA1_T1CH   = VIA1_BASE + 5     ; $7F25 Timer 1 Counter High byte 
; $7F26 T1L-L
; $7F27 T1L-H
; $7F28 T2CL
; $7F29 T2CH
VIA1_SR     = VIA1_BASE + 10    ; $7F2A SR Shift Register
VIA1_ACR    = VIA1_BASE + 11    ; $7F2B Auxiliary Control register @
VIA1_IFR    = VIA1_BASE + 13    ; $7F2D IFR > Interrupt Flag Register
VIA1_IER    = VIA1_BASE + 14    ; $7F2E ; Interrupt Enable Register

; Simple test of VIA port B 
.segment "USR_PROGRAM" 
; .org $0300 ; Wozmon has the buffer @ $0200
; Set VIA portB 
lda #$ff ; Set all pins on port B to output
sta $7F22 ; VIA1_DDRB > init port B
lda #%10101011 ; put a bit pattern in port B
sta $7F20 ; VIA1_PORTB
jmp $FF03 ; gop back to soft start WOZMON

 ; TESTED IN HW AND WORKING
 ; assembled with https://www.masswerk.at/6502/assembler.html
 ; 0300:  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
 ; 0300: A9 FF 8D 22 7F A9 AB 8D 20 7F 4C 03 FF
 ; once added you can change 306 to what you want to put in PortB and run it again