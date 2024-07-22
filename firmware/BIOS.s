; simple6502 BIOS ROM f
; Written by Mariano Luna, 2024
; License: BSD-3-Clause
; https://opensource.org/license/bsd-3-clause

.setcpu "65C02"           ; Thats what we got
.debuginfo +

.define VERSION "0.0.1"   ; Define the version number

.include "defines_simple6502.s" ; Include HW Constants and Labels

; -- ROM START --
;.org $8000 

; JUMP Table
.segment "HEADER"


; BIOS Start
.segment "BIOS"  
  .byte "simple6502 BIOS Ver: "
  .byte VERSION

; Reset Start 
reset:
  sei               ; 78      disable interrupts 
  cld               ; D8      turn decimal mode off
  ldx #$FF          ; A2 FF
  txs               ; 9A      set the stack start
  jsr post          ; do a POST
  jsr init_serial   ; init ACIA # IO_8
  ; Print startup message
  lda #<startupMessage
  sta PTR_TX
  lda #>startupMessage
  sta PTR_TX_H
  jsr serial_out_str
  do_nothing:   
    nop             ; EA
    lda #$FF
    sta $55FF
    jmp do_nothing  ; 4C 1A 80


; ### Subrutines ### 

; TX A Register as ASCII HEX byte
; Need to check this routine, can be optimized
serial_out_hex:
  pha
  lsr       ; process the high nibble
  lsr
  lsr
  lsr
  and #$0F
  ora #$30
  cmp #$3A 
  bcc @WRT   ; A is less so its less than 9 we are set
  adc #$06   ; A is more than 9 convert to letter
@WRT:
  jsr serial_out
  pla
  and #$0F  ; process the low nibble
  ora #$30 
  cmp #$3A 
  bcc @WRT2
  adc #$06
@WRT2:
  jsr serial_out
  rts


; Power on Self Test
; first thing will run on boot
post: 
  ; test RAM
  nop
  ; test ROM
  nop
  ; test ACIA
  nop
  rts

; init_serial
; Reset and set ACIA config. Init the RX buffer pointer
init_serial:
  lda #ACIA_RESET
  sta ACIA_CONTROL
  lda #ACIA_CFG_28    ; 28800 8,N,1
  sta ACIA_CONTROL
  ; Init the RX buffer pointers
  lda #0
  sta PTR_RD_RX_BUF
  sta PTR_WR_RX_BUF
  rts

; TX A Register via Serial
; Sends the char in A out the ACIA RS232
serial_out:  
  pha
  pool_acia: ; pulling mode until ready to TX
    lda ACIA_STATUS 
    and #ACIA_TDRE     ; looking at Bit 1 TX Data Register Empty > High = Empty
    beq pool_acia     ; pooling loop if empty
  pla
  sta ACIA_DATA       ; output char in A to TDRE
  rts

; Serial Receive 
; Checks if the ACIA has RX a characted and put it in A 
; if a byte was received sets the carry flag, if not it clears it
serial_in:
  lda ACIA_STATUS
  and #ACIA_RDRF    ; look at Bit 0 RX Data Register Full > High = Full
  beq @no_data      ; nothing in the RX Buffer
  lda ACIA_DATA     ; load the byte to A
  jsr serial_out    ; echo back
  sec
  rts 
@no_data:
  clc
  rts

; TX a string 
; Sends the a null terminated string via RS232
; - PTR_TX is a pointer to the string memory location
; - Y register is not preserved
serial_out_str:
  ldy #0
  @loop:
    lda (PTR_TX),y
    beq @null_found
    jsr serial_out
    iny
    bra @loop
  @null_found:
  rts

; ### Helper Routines ###
; Send CRLF > $0D,$0A 
; does not preserve A
out_crlf:
  lda #CR 
  jsr serial_out
  lda #LF 
  jsr serial_out
  rts

; ROM Data
; Startup Messages
startupMessage:
  .byte	$0C,$0D,$0A,"## Simple6502 ##",$0D,$0A,"-- v"
  .byte VERSION
  .byte	$0D,$0A,"OK"
  .byte $0D,$0A,$00



; ### Interrupt Handlers ###

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