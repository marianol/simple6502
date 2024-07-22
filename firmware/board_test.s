; Board test ROM for the simple6502
; Written by Mariano Luna, 2024
; License: BSD-3-Clause
; https://opensource.org/license/bsd-3-clause

.setcpu "65C02"           ; Thats what we got
.debuginfo +

.define VERSION "0.1.0"   ; Define the version number

.include "defines_simple6502.s" ; Include HW Constants and Labels

; -- ROM START --
;.org $8000 

; JUMP Table
.segment "HEADER"
  .byte "board_test Ver: "
  .byte VERSION

; BIOS Start
.segment "BIOS"  

; Reset Start 
reset:
  sei               ; 78      disable interrupts 
  cld               ; D8      turn decimal mode off
  ldx #$FF          ; A2 FF
  txs               ; 9A      set the stack start
  
  cli               ; 58      enable interrupts 
  ; do nothing
  do_nothing:   
    nop             ; EA
    jmp do_nothing  ; 4C 1A 80


; IRQ Handler 
irq_handler:
    nop       ; EA
    rti       ; 40 

; NMI Handler Vector 
nmi_handler:
    nop       ; EA
    rti       ; 40

; -- VECTORS --
.segment "RESETVECTORS"
  ;.org $fffa
  .word nmi_handler ; NMI
  .word reset       ; RESET
  .word irq_handler ; IRQ/BRK