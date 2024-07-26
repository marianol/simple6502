; simple6502 BIOS ROM 
; Written by Mariano Luna, 2024
; License: BSD-3-Clause
; https://opensource.org/license/bsd-3-clause

.setcpu "65C02"           ; Thats what we got
.debuginfo +

.define VERSION "0.1.2"   ; Define the version number

.include "defines_simple6502.s" ; Include HW Constants and Labels

; -- ROM START --
;.org $8000 

; ## Header ##
; the top of the rom will have a JUMP Table for the common BIOS routines
.segment "HEADER" 
;BASIC:        jmp COLD_START
MONITOR:      jmp WOZMON

; ## BIOS Start ##
.segment "BIOS"  
  .byte "simple6502 BIOS Ver: "
  .byte VERSION

; Reset Vector Start 
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
 ; Print woz message
  lda #<wozmonMessage
  sta PTR_TX
  lda #>wozmonMessage
  sta PTR_TX_H
  jsr serial_out_str
  jmp WOZMON        ; go to the monitor

; ### Subrutines ### 




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

; ### Helper Serial Routines ###

; serial_out_hex
; Transmit the value of the A Register as ASCII HEX byte
; Need to check this routine, can be optimized
serial_out_hex:
  pha             ; keep the register for further manipulation
  lsr             ; process the high nibble (MSD) shifting it to the low nibble
  lsr
  lsr
  lsr
  and #$0F        ; Mask LSD for hex print.
  ora #$30        ; this is like adding $30 > ASCII numbers start at $30 the OR %00110000 sets the high bits shifting the hex value to the right place.
  cmp #$3A        ; is less than '9' $39
  bcc @done       ; A is < 9 ($3A) so we already have the ASCII of the number
  adc #$06        ; A is > 9 ($3A) so add 6 + carry (carry is set by CMP) to offset for letters (A $41 - F $46)
@done:
  jsr serial_out  ; send the MSD since its ready
  pla             ; get the original value back
  and #$0F        ; process the low nibble (LSD)
  ora #$30 
  cmp #$3A 
  bcc @done2
  adc #$06
@done2:
  jsr serial_out
  rts

; Transmit a CR+LF > $0D,$0A 
; Preserves all registers
out_crlf:
  pha
  lda #CR 
  jsr serial_out
  lda #LF 
  jsr serial_out
  pla
  rts

; ROM Data
; Startup Messages
startupMessage:
  .byte	$0C,$0D,$0A,"## Simple6502 ##",$0D,$0A,"-- v"
  .byte VERSION
  .byte	$0D,$0A,"OK"
  .byte $0D,$0A,$00
wozmonMessage:
  .byte	CR,LF,"> WozMon <"
  .byte CR,LF,$00

; ### Interrupt Handlers ###

; # IRQ Handler 
irq_handler:
    nop       ; EA
    ; BIT  VIA1_STATUS   ; Check 6522 VIA1's status register without loading.
    ; BMI  SERVICE_VIA1  ; If it caused the interrupt, branch to service it.
    ; BIT  VIA2_STATUS   ; Otherwise, check VIA2's status register.
    ; BMI  SERVICE_VIA2  ; If that one did the interrupt, branch to service it.
    ; JMP  SERVICE_ACIA  ; If both VIAs say "not me," it had to be the 6551 ACIA.
    rti       ; 40 

; # NMI Handler Vector 
nmi_handler:
    nop       ; EA
    rti       ; 40

; -- MONITOR --
; .org $FF00
; ## WozMon ##
.segment "WOZMON"  
.include "wozmon_sbc.s" 

; -- VECTORS --
;.org $fffa
.segment "RESETVECTORS"
  .word nmi_handler ; NMI
  .word reset       ; RESET
  .word irq_handler ; IRQ/BRK