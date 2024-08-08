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
;   CSB     = PB2 .. PB5
;   MISO    = PB7
;   PB6     = Reserved for something since is a test BIT
; CLK and MOSI should have a pull up so they do not float before initialization
;
; - Implementation:
; Implemented in SPI Mode 0
; To Clock the signal INC/DEC PortB 
; MISO is set in PB7 to read incoming data useing the BIT instruction and the N flag
; to test with BPL and BMI.

; Constants
SPI_CLK     = %00000001
SPI_MOSI    = %00000010
SPI_CS      = %00000100
SPI_CS_DIS  = %00111100 ; disable CS1 Set ALL ~CS to high, CLK, MOSI & MISO low
SPI_CS1_EN  = %00111000 ; enable CS1 Set other ~CS to high, CLK, MOSI & MISO low
SPI_MISO    = $10000000
SPI_PORT    = VIA1_PORTA
SPI_DDR     = VIA1_DDRA 
SPI_COMMAND = $40  ; put this in ZP
SPI_COMMAND_L = SPI_COMMAND     ; put this in ZP
SPI_COMMAND_H = SPI_COMMAND + 1 ; put this in ZP


; VIA1_setupSPI:
; Initialize SPI on PORT B of VIA 1 using bit 6 and 7 as input and the rest as output 
; uses SPI_xxx constants Bit 1 is CLK, Bit 2 MOSI, Bit 8 MISO & Bit 3,4,5 & 6 as CS
; Return: None 
; Preserves: Y,X
SPI_setupVIA1:
  lda #%00111111    ; Set bit 6 and 7 as inputs all the rest as outputs
  sta SPI_DDR       ; Set pin directions
  lda #SPI_CS_DIS   ; Set all ~CS to high, CLK, MOSI & MISO low
  sta SPI_PORT      ; deselect any periferial all CSB high

  ; set port B for the lights
  lda #$ff ; Set all pins on port B to output
  sta VIA1_DDRB     ; $7F22  VIA1_DDRB > init port B
  lda #%10101010    ; put a bit pattern in port B
  sta VIA1_PORTB    ; $7F20 > VIA1_PORTB
  ;rts
  jmp $FF03         ; go back to soft start WOZMON 


; SPI_CS1_enable:
; Asserts (turns low) the chip select line ~CS
SPI_CS1_enable: 
  pha
  lda SPI_CS1_EN    ; Enable ~CS1 
  sta SPI_PORT      
  pla
  ;rts
  jmp $FF03         ; go back to soft start WOZMON 

; SPI_CS_disable:
; Disables (turns high) all chip select lines 
SPI_CS_disable:
  pha
  lda SPI_CS_DIS    ; Disable all ~CS lines 
  sta SPI_PORT      
  pla
  ;rts
  jmp $FF03         ; go back to soft start WOZMON 

; SPI_SD_init:
; Reset sequence for SD card, places it in SPI mode, completes initialization.
; Initi sequence: 1/ Clock 80 cycles with MOSI and CS high. 2/Send CMD 08 & check we received an 
; GO_IDLE_STATE 3/ Send CMD8 to check if we have a 1.x or 2.x SD card 4/ send proper init 
; command per version
; Init process is here https://chlazza.nfshost.com/imgs/SDcardInitFlowchart_3.01.png
; Return: A > Contains the value of the last SD response, 
;             $00 on init success, erros othewise
SPI_SD_init:
  ; Card power up the power up time SHOULD have taken care of that ms (~542K Cycles @ 1.8432MHz)
  ; after than an init delay of +74 CLK cycles with the card disabled in 1ms
  
  ldx #74           ; send 74 CLK pulses (low-high transitions)
  lda #SPI_CS_DIS   ; Set all ~CS to high, CLK, MOSI & MISO low
  sta SPI_PORT      
  @loop             ; send 74 clock cycles
    inc SPI_PORT    ; clock high
    pha             ; waste 3 cycles 
    pla             ; waste 4 cycles = 7 cycles total = 3.8us = 263.314286kHz
    dec SPI_PORT    ; clock low
    pha             ; waste 3 cycles 
    pla             ; waste 4 cycles
    dey 
    bne @loop   

  ; Select SD card 
  lda SPI_CS1_EN        ; Enable ~CS1 
  sta SPI_PORT 
  ; send CMD0 = GO_IDLE_STATE - resets card to idle state, and SPI mode
  lda #<cmd0_bytes
  sta SPI_COMMAND_L
  lda #>cmd0_bytes
  sta SPI_COMMAND_H
  jsr SD_send_command   ; send CMD0 
  ; check for Idle state ($01) or Illegal command response ($04)
  jsr SD_wait_result    ; wait for a result
  cmp #$01              ; R1=$01 The card is in idle state and running the initializing process.
  bne SD_init_exit 
  ; Wait for the card to initialize.
  ; how much... I have no clue, shoud I research, yes. Will do it, nor now :)
  jsr delay_ms          ; 'bout 1.4ms
  jsr delay_ms          ; 'bout 1.4ms
  
  ; use CMD8 to see if we have a v2.00+ or v1.x
  ; CMD8 = SEND_IF_COND - Sends SD Memory Card interface condition that includes 
  ;                       Host Supply Voltage (VHS) information and asks the accessed 
  ;                       card whether card can operate in supplied voltage range.
  lda #<cmd8_bytes
  sta SPI_COMMAND_L
  lda #>cmd8_bytes
  sta SPI_COMMAND_H
  jsr SD_send_command   ; send CMD8  
  ; Check response 
  jsr SD_wait_result    ; wait for a result
  ; if R=$04 (Illegal command, response bit 2 set) then v1.x else v2.0+
  ; for now let's deal with 2.0+ and fail otherwise
  ; The response to CMD8 for v2 is format R7
  ; R7 is 5 bytes long, and the first byte is identical to R1
  cmp #$01              ; R=$01 in idle state, 
  bne SD_init_exit 
  ; The card is v2.0+ get the other 4 bytes of the R7 response
  ; let's ignore this for now but will be good to save them somewhere
  jsr SD_wait_result 
  jsr SD_wait_result 
  jsr SD_wait_result 
  jsr SD_wait_result 
  
  ; At this point we can send CMD58 to read operation conditions register (OCR)
  ; this is optional and I am lazy so will ignore it for now
  ; @todo: investigate this 
  

  ; send ACMD41 SD_SEND_OP_COND (send operating condition), this is is what starts 
  ; the card's initialization process.
  ; first we need to send CMD55 this is an APP_CMD a required prefix for ACMD commands
  ; timeout value for initialization beginning from the end of the first ACMD41 is 1 sec

  ldx #$64               ; retry counter 100 times for ACMS41 

  @send_ACMD41:
    lda #<cmd55_bytes
    sta SPI_COMMAND_L
    lda #>cmd55_bytes
    sta SPI_COMMAND_H
    jsr SD_send_command   ; send CMD55
    ; check for Idle state ($01) 
    jsr SD_wait_result    ; wait for a result
    cmp #$01              ; R1=$01 The card is in idle state 
    bne SD_init_exit 
    
    jsr delay_ms          ; 'bout 1.4ms wait just in case.

    ; now we can send ACMD41: SD_SEND_OP_COMMAND
    lda #<acmd41_bytes
    sta SPI_COMMAND_L
    lda #>acmd41_bytes
    sta SPI_COMMAND_H
    jsr SD_send_command   ; send CMD
    ; check for Response: 
    ; ACMD41 starts the initialization process. In the startup sequence, we will continue to 
    ; send ACMD41 (always preceded by CMD55) until the card is inizialised.s 
    ; R1 = $01 = not ready, in idle state 
    ; R1 = $00 = card ready
    jsr SD_wait_result    ; wait for a result
    cmp #$00              ; SD card ready if R1 = $00
    beq SD_init_exit      ; Card ready init complete      
    ; retry ACMD41 after about 10ms
    ldy #$07
    @delayloop
      jsr delay_ms          ; 'bout 1.4ms wait just in case.
      dey
      bne @delayloop
    dex                     ; retry counter
    beq @send_ACMD41        ; retry ACMD41 until ready
  ; got to #100 retries without success return FF as error
  lda #ff;
  SD_init_exit: 
  ; on error it jumps here exiting with R1 in A
  pha
  lda #SPI_CS_DIS    ; Disable all ~CS lines 
  sta SPI_PORT   
  pla
  jmp $FF03         ; go back to soft start WOZMON
  ;rts


; SPI_send:
; send the byte in the Accumulator via SPI using MODE 0
; the CS line must be properly asserted before calling
; I keeep the set and clear in X and Y precalculated based on Jeff Laughton
; Return: A 
; Preserves: Y,X
SPI_send:
  phx 
  phy
  ; precalculate send a 1 (y) or a 0 (x)
  pha               ; save A that has the TX byte
  lda SPI_PORT      ; get current status 
  and #%00111100    ; preserve ~CS lines and set MOSI and CLK low (0) 
  tax               ; Save in X how to send a 0
  ora #%00000010    ; set MOSI 1 
  tay               ; Save in Y how to send a 1
  ; get ready to TX
  ; remember we will TX the bit in the carry
  pla               
  sec               ; set carry bit to use as and a marker
  rol               ; push the marker in A and move the bit to TX in the carry

  @sendbyte:        ; send the but in the carry via SPI
    bcs @send_1     ; send a 1?
    ; carry is 0 so send Y
    stx SPI_PORT    ; send MOSI to 1, clock 0
    inc SPI_PORT    ; clock it
    asl             ; move the next bit to C fill with 0
    bne @sendbyte   ; since we have the marker once finish the 8 bits A will be 0
    beq @done       ; branch always I cloud use a bra from the 65C02    
 
    @send_1:
      ; carry is 1 so send Y
      sty SPI_PORT  ; send MOSI to 1, clock 0
      inc SPI_PORT  ; clock it
      asl           ; move the next bit to C fill with 0
      bne @sendbyte ; since we have the marker once finish the 8 bits A will be 0
      ; fallthough, we are finished

  @done:
    dec SPI_PORT    ; leave clock low
    ply 
    plx 
    jmp $FF03 ; go back to soft start WOZMON
    ;rts

; SPI_receive_byte:
; Get a full byte from SPI MODE 0 and return it in A
; Tick the clock 8 times with MOSI high, capturing bits from MISO and returning them
; Will keep CS low but expect the CS to be managed outside of the subroutine
; Return: A 
; Preserves: Y,X
SPI_receive_byte:
  phy
  lda SPI_PORT      ; get current status 
  and #%00111100    ; preserve ~CS lines and set MOSI and CLK low (0) 
  ora #%00000010    ; preserve ~CS lines and set MOSI high
  tay               ; Save in Y CLK & MOSI low constant
  lda #1            ; start with a 1 as a marker, as we shift when it 
  clc               ; lands in the carry it indicates we have received a full byte

  @getbyte:
    sty SPI_PORT    ; Clock out, set CLK, CS & MOSI low
    inc SPI_PORT    ; Clock in > 6 cycles ~ 397 kHz
                    ;  INC will also set N based on the value of PB7 which is MOSI
                    ;  so there is no need to read the port to A
    bpl @gotzero    ; Did we got a 0?
    ; got a one
    sec             ; rx a 1 so set carry and 
    rol             ; rotate into A, along with the marker bit 
    bcc @getbyte    ; if we still do not see the marker in C keep receiving 
    bcs @done       ; skip to the end // could have used BRA if 65c02

    @gotzero:
      asl           ; rx a zero so shift one into A
      bcc @getbyte  ; if we still do not see the marker in C keep receiving 
      ; done so fall though
    
    @done:
      sty SPI_PORT  ; Set CLK, CS & MOSI low
      ply 
      jmp $FF03 ; go back to soft start WOZMON
      ;rts

; SD_send_command:
; Will send through SPI the 6 byte command stored in SPI_COMMAND zp variable
; CS should be properly asserted before calling it 
SD_send_command:
  ldy #0                    ; init index
  lda SPI_COMMAND
  @loop
    lda (SPI_COMMAND),y     ; load command byte
    jsr SPI_send            ; send byte
    iny
    cpy #6
    bne @loop
  jmp $FF03 ; go back to soft start WOZMON
  ;rts

; SD_wait_result:
; Wait for the SD card to return something other than $ff
; CS has to be propery asserted before calling
; Return: A 
; Preserves: Y,X
SD_wait_result:
  jsr SPI_receive_byte
  cmp #$ff
  beq SD_wait_result
  jmp $FF03 ; go back to soft start WOZMON
  ;rts

; delay_ms:
; Total delay including JRS/RTS = 2561 cycles = 1.389ms @ 1.8432MHz 
delay_ms:
  ldy  #0       ; 2 cycles
  ldx  #0       ; 2 cycles
  @loop   
    dex         ; 510 cycles = 2 cycles * 255
    bne  @loop  ; 765 (3 cycles 8 255 in loop) + 2 cycles at end
    dey         ; 510 cycles > 2 cycles * 255
    bne  @loop  ; 765 (3 cycles 8 255 in loop) + 2 cycles at end
    ; 2549 cycles + 6 JSR + 6 RTS
  rts

; Complied BIN
; ADDR:  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
; 0300: A9 3F 8D 22 7F A9 3C 8D 20 7F 4C 03 FF DA 5A A0 
; 0310: 02 A2 00 38 2A B0 0B 8E 20 7F EE 20 7F 0A D0 F5 
; 0320: 80 09 8C 20 7F EE 20 7F 0A D0 EA 8C 20 7F 7A FA 
; 0330: 4C 03 FF 5A A0 00 A9 01 8C 20 7F EE 20 7F 10 06  
; 0340: 38 2A 90 F4 80 03 0A 90 EF 8C 20 7F 7A 4C 03 FF
; Entry points
; al 000333 .SPI_receive_byte
; al 00030D .SPI_send
; al 000300 .SPI_setupVIA1

; SD Commands
; format: Command byte, data 1, data 2, data 3, data 4, CRC
cmd0_bytes:
  .byte $40, $00, $00, $00, $00, $95
cmd8_bytes:
  .byte $48, $00, $00, $01, $aa, $87
cmd55_bytes:
  .byte $77, $00, $00, $00, $00, $01
acmd41_bytes:
  .byte $69, $40, $00, $00, $00, $01


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


