; User Program scratchpad 
; Written by Mariano Luna, 2024
; License: BSD-3-Clause
; https://opensource.org/license/bsd-3-clause

; this is to write and compile user programs to run in memory
.setcpu "65C02"           ; Thats what we got
.debuginfo +

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


.segment "USR_PROGRAM" 
;.org $0300 ; Wozmon has the buffer @ $0200

; # SPI bit banging implementation on VIA
; https://wilsonminesco.com/6502primer/potpourri.html#BITBANG_SPI
; - Specifications
; Wiring:
;   VIA Port B
;   CLK     = PB0
;   MOSI    = PB1
;   MISO    = PB7
;   CSB     = PB2 .. PB5
;   PB6     = Reserved for something since is a test BIT
; CLK and MOSI should have a pull up so they do not float before initialization

; Implementation:
; To Clock the signal INC/DEC PortB 
; To read incoming data use the BIT instruction to test (with BPL and BMI)

; Constants
SPI_CLK     = %00000001
SPI_MOSI    = %00000010
SPI_MISO    = $10000000
SPI_PORT    = VIA1_PORTB

; VIA1_setupSPI:
; Initialize SPI on PORT B of VIA 1
SPI_setupVIA1:
  lda #%00111111  
  sta VIA1_DDRB     ; Set bit 6 and 7 as inputs
  lda #%00111100
  sta SPI_PORT      ; de select any periferial all CSB high
  jmp $FF03 ; go back to soft start WOZMON 
  ;rts


; SPI_send:
; send the byte in the Accumulator via SPI using MODE 0
; the CS line should be properly asserted before calling
; I keeep the set and clear in X and Y precalculated based on Jeff Laughton
; A is not preserved
SPI_send:
  phx 
  phy

  ; need to or with the current CS.... or use TRB or TSB
  ldy #SPI_MOSI     ; set MOSI 1 with CLK in 0
  ldx #0            ; set MOSI 0 with CLK in 0

  sec               ; set carry bit to use as and a marker
  rol               ; push the marker in and move the bit to TX in the carry

  @sendbyte:
    bcs @send_1
    ; carry is 0 so send 0
    stx SPI_PORT    ; set MOSI to 0 and reset clock
    inc SPI_PORT    ; clock it
    asl             ; move next bit to carry
    bne @sendbyte   ; since we have the marker once finish the 8 bits A will be 0
    bra @done       
 
    @send_1:
      ; carry is 1 so send 1
      sty SPI_PORT  ; set MOSI to 1 and reset clock
      inc SPI_PORT  ; clock it
      asl
      bne @sendbyte   ; since we have the marker once finish the 8 bits A will be 0
      ; fallthough if we are finished

  @done:
    sty SPI_PORT  ; leave clock low
    ply 
    plx 
    jmp $FF03 ; go back to soft start WOZMON
    ;rts

; SPI_receive:
; Get a full byte from SPI MODE 0 and return it in A
; A is not preserved (obviously)
SPI_receive:
  phy
  ldy #0            ; CLK & MOSI low constant
  lda #1            ; start with a 1 as a marker, as we shift when it 
                    ; lands in the carry it indicates we have received a full byte

  @getbyte:
    sty SPI_PORT    ; Set CLK & MOSI low
    inc SPI_PORT    ; Clock in
                    ;  INC will also set N based on the value of PB7 which is MOSI
                    ;  so there is no need to read the port to A
    bpl @gotzero    ; Did we got a 0?
    ; got a one
    sec             ; Rx a 1 so set carry and 
    rol             ; rotate into A, along with the marker bit 
    bcc @getbyte    ; if we still do not see the marker keep receiving 
    bra @done       ; skip to the end

    @gotzero:
      asl           ; rx a zero so shift one into A
      bcc @getbyte  ; if we still do not see the marker keep receiving 
    
    @done:
      sty SPI_PORT  ; Set CLK & MOSI low
      ply 
      jmp $FF03 ; go back to soft start WOZMON
      ;rts


; Simple test of VIA port B 
; Set VIA portB 
; setVIA_PortB:
;   lda #$ff ; Set all pins on port B to output
;   sta $7F22 ; VIA1_DDRB > init port B
;   lda #%10101011 ; put a bit pattern in port B
;   sta $7F20 ; VIA1_PORTB
;   jmp $FF03 ; go back to soft start WOZMON

 ; TESTED IN HW AND WORKING
 ; assembled with https://www.masswerk.at/6502/assembler.html
 ; 0300:  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
 ; 0300: A9 FF 8D 22 7F A9 AB 8D 20 7F 4C 03 FF
 ; once added you can change 306 to what you want to put in PortB and run it again


