; Board test ROM for the simple6502
; Written by Mariano Luna, 2024
; License: BSD-3-Clause
; https://opensource.org/license/bsd-3-clause

.setcpu "65C02"           ; Thats what we got

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
  sei ;disable interrupts 
  cld ;turn decimal mode off
  ldx #$FF
  txs ; set the stack start
  ; do nothing
  do_nothing:
    nop
    jmp do_nothing


; IRQ Handler 
irq_handler:
    nop
    rti

; NMI Handler Vector 
nmi_handler:
    nop
    rti

; -- VECTORS --
.segment "RESETVECTORS"
  ;.org $fffa
  .word nmi_handler ; NMI
  .word reset       ; RESET
  .word irq_handler ; IRQ/BRK