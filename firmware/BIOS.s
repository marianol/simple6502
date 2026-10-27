; simple6502 BIOS ROM 
; Written by Mariano Luna, 2024
; License: BSD-3-Clause
; https://opensource.org/license/bsd-3-clause

.setcpu "65C02"           ; Thats what we got
.debuginfo +

.define VERSION "0.7.0"   ; Define the version number

.include "defines_simple6502.s" ; Include HW Constants and Labels

; -- ROM START --
;.org $8000 

; ## BIOS Jump Table (public ABI) ##
; Fixed-address entry points so external programs can call BIOS routines at
; stable addresses that never change as the BIOS internals grow.
;
; The table lives at the very start of ROM ($8000) and each entry is a 3-byte
; JMP. CONTRACT: entries are APPEND-ONLY. Never insert, reorder, or remove a
; slot - that would shift every entry below it and break existing binaries.
; Add new routines to the end only.
;
; Slot  Address  Routine
; ----  -------  ----------------------------------------------------------
;  0    $8000    J_COLD_START  - cold start / reset entry
;  1    $8003    J_MONITOR     - enter WozMon monitor
;  2    $8006    J_SERIAL_OUT  - transmit A over serial
;  3    $8009    J_SERIAL_IN   - receive a byte (carry set if data)
;  4    $800C    J_SERIAL_STR  - transmit null-terminated string @ PTR_TX
;  5    $800F    J_SERIAL_HEX  - transmit A as two ASCII hex digits
;  6    $8012    J_OUT_CRLF    - transmit CR+LF
;  7    $8015    J_SERIAL_POLL - receive a byte, no echo (carry set if data)
;
; The equates for these addresses live in bios_jumptable.inc for programs to
; include. Keep that file in sync when appending entries here.
.segment "HEADER"
J_COLD_START: jmp reset          ; slot 0  $8000
J_MONITOR:    jmp WOZMON         ; slot 1  $8003
J_SERIAL_OUT: jmp serial_out     ; slot 2  $8006
J_SERIAL_IN:  jmp serial_in      ; slot 3  $8009
J_SERIAL_STR: jmp serial_out_str ; slot 4  $800C
J_SERIAL_HEX: jmp serial_out_hex ; slot 5  $800F
J_OUT_CRLF:   jmp out_crlf       ; slot 6  $8012
J_SERIAL_POLL: jmp serial_poll   ; slot 7  $8015

; Keep MONITOR as an alias for existing code that referenced it.
MONITOR = J_MONITOR

; ## BIOS Start ##
.segment "BIOS"  
  .byte "simple6502 BIOS Ver: "
  .byte VERSION

; Reset Vector Start 
reset:
  sei               ; 78      disable interrupts 
  cld               ; D8      turn decimal mode off

  ; --- Memory Check: Zero Page and Stack (Page 1) ---
  ; These run BEFORE the stack is used so we can test Page 1
  ; Using ONLY the A and X and immediate values - no ZP variables, no stack. 
  ; A mismatch jumps to post_fail.

  ; Test Zero Page ($0000-$00FF): checkerboard $55 then $AA
  ldx #0
@zp_55:
  lda #$55
  sta $00,x
  cmp $00,x
  bne post_fail
  inx
  bne @zp_55
@zp_aa:
  lda #$AA
  sta $00,x         ; x wrapped back to 0
  cmp $00,x
  bne post_fail
  inx
  bne @zp_aa

  ; Test Stack page / Page 1 ($0100-$01FF): safe to clobber, nothing pushed yet
  ldx #0
@sp_55:
  lda #$55
  sta $0100,x
  cmp $0100,x
  bne post_fail
  inx
  bne @sp_55
@sp_aa:
  lda #$AA
  sta $0100,x       ; x wrapped back to 0
  cmp $0100,x
  bne post_fail
  inx
  bne @sp_aa

  ; ZP and stack are good - establish the stack pointer and carry on.
  ldx #$FF          ; A2 FF
  txs               ; 9A      set the stack start
  jsr post          ; do the rest of POST (RAM walk)
  jsr init_serial   ; init ACIA # IO_8
  jsr via_init      ; detect + init VIA1 (sets carry if present)
  ; Print startup message (BIOS banner)
  lda #<startupMessage 
  sta PTR_TX
  lda #>startupMessage
  sta PTR_TX_H
  jsr serial_out_str
  ; If VIA1 was detected, announce it under the banner: "## VIA1 on $7F20"
  jsr via_report
 ; Print woz message
  lda #<wozmonMessage
  sta PTR_TX
  lda #>wozmonMessage
  sta PTR_TX_H
  jsr serial_out_str
  cli               ; enable IRQs now that handlers/VIA are set up
  jmp WOZMON        ; go to the monitor



; ### Subrutines ### 

; post_fail:
; Reached when the early ZP or Stack test fails. Serial is NOT up yet and we
; have no onboard failure indicator (LED/beeper) in rev 1.6 - that hardware is
; TODO. As a placeholder, we signal the fault on the DATA BUS: repeatedly
; writing $01 then $00 to a Zero Page location drives D0 with a steady ~1 kHz
; pattern (D1-D7 idle low) that can be caught with a scope or logic probe.
; This never returns - a failed ZP/stack test is terminal.
; Placed right before the POST tests so the reset-vector ZP/stack checks can
; reach it with a direct conditional branch (no trampoline needed).
;
; Timing: target ~1 kHz (1 ms period, 500 us per half) at 1.8432 MHz
; (~922 cycles per half-period). Each half is a write (~5 cyc) plus the
; delay loop dex/bne (5 cyc per iteration): X=$B6 (182) -> ~910 loop cycles
; + overhead ~= 920 cycles ~= 499 us -> ~1.0 kHz. Exact frequency is not
; important for a fault beacon; this just lands it near 1 kHz on a probe.
; Uses only the A and X registers - no ZP variables, no stack (it may be
; entered before the stack is trusted).
post_fail:
  lda #$01
  sta ZP_START          ; write 1 -> D0 high on the bus
  ldx #$B6              ; 182 -> ~half period delay (~500 us)
@fh:
  dex
  bne @fh
  lda #$00
  sta ZP_START          ; write 0 -> D0 low on the bus
  ldx #$B6
@fl:
  dex
  bne @fl
  bra post_fail         ; loop forever (fault beacon)

; post:
; Power on Self Test
; post runs after the early ZP/stack test, so the
; stack is already trusted here and we may use subroutines/registers freely.
post: 
  ; --- Walk RAM from $0200 up, store top of RAM in RAM_SIZE ---
  ; Checkerboard-test each byte ($55 then $AA) and read it back. Stop at the
  ; first byte that fails or when we reach the I/O space at $7F00 (we must
  ; NOT write into $7F00+ which would hit real hardware registers). RAM_SIZE
  ; holds the first non-RAM address, i.e. (top usable RAM address + 1).
  ; This is destructive, which is fine at cold boot (RAM is undefined anyway).
  lda #$00
  sta POST_PTR          ; pointer low  = $00
  lda #$02
  sta POST_PTR+1        ; pointer high = $02  -> start at $0200
@ram_walk:
  ; stop once we reach I/O space ($7F00)
  lda POST_PTR+1
  cmp #$7F
  beq @ram_done         ; high byte $7F and low byte $00 -> at $7F00
  ldy #0
  lda #$55              ; pattern 1
  sta (POST_PTR),y
  lda (POST_PTR),y
  cmp #$55
  bne @ram_done         ; readback failed -> end of RAM
  lda #$AA              ; pattern 2
  sta (POST_PTR),y
  lda (POST_PTR),y
  cmp #$AA
  bne @ram_done         ; readback failed -> end of RAM
  ; byte good, advance pointer
  inc POST_PTR
  bne @ram_walk
  inc POST_PTR+1
  bra @ram_walk
@ram_done:
  ; POST_PTR now points one past the last good RAM byte -> store as RAM_SIZE
  lda POST_PTR
  sta RAM_SIZE_L
  lda POST_PTR+1
  sta RAM_SIZE_H

  ; --- VIA1 Timer 1 periodic tick (TOCKS jiffy clock) ---
  ; STUB: left for when the VIA routines are implemented. This will configure
  ; VIA1 Timer 1 for a ~10ms periodic IRQ and the IRQ handler will increment
  ; the 3-byte TOCKS counter. The VIA is on the external I/O card (not onboard
  ; in rev 1.6), so this stays a stub for now.
  nop
  rts

; ### Serial Routines ###
; Initializes the on board serial interface 
; Reset and set config for the ACIA. Init the RX buffer pointer
init_serial:
  lda #ACIA_RESET
  sta ACIA_CONTROL
  lda #ACIA_CFG_28    ; 28800 8,N,1, see defines file for options
  sta ACIA_CONTROL
  ; Init the RX buffer pointers
  lda #0
  sta PTR_RD_RX_BUF
  sta PTR_WR_RX_BUF
  rts

; ### VIA Routines ###

; via_init:
; Detect VIA1 (on the external I/O card, $7F20) and, if present, set up
; Timer 1 as a free-running ~10ms periodic interrupt that drives the TOCKS
; jiffy clock (incremented in the IRQ handler).
;
; Detection: DDRB is a plain read/write register with no external side effect
; on the value stored, so we write two patterns ($55, $AA) and read them back.
; An absent card reads back open-bus / mirror values and will fail one of the
; two checks. (Writing DDRB only sets pin directions, harmless for detection.)
;
; Sets VIA_PRESENT (and returns carry set) if the VIA responded; clears both
; otherwise. Leaves IRQs enabled on the VIA only when present.
; Clobbers A, X.
via_init:
  stz VIA_PRESENT       ; assume absent until proven
  ; --- presence check on DDRB ---
  lda #$55
  sta VIA1_DDRB
  cmp VIA1_DDRB
  bne @absent
  lda #$AA
  sta VIA1_DDRB
  cmp VIA1_DDRB
  bne @absent
  ; --- VIA present: configure Timer 1 free-run tick ---
  lda #$00
  sta VIA1_DDRB         ; leave Port B as inputs (benign default)
  sta VIA1_DDRA         ; leave Port A as inputs too
  ; clear the 3-byte TOCKS jiffy counter
  stz TOCKS_L
  stz TOCKS_M
  stz TOCKS_H
  ; disable all VIA interrupt sources first
  lda #VIA_IER_CLR_ALL
  sta VIA1_IER
  ; ACR: Timer 1 continuous (free-run), PB7 output off
  lda #VIA_ACR_T1_FREERUN
  sta VIA1_ACR
  ; load Timer 1 latch/counter for the ~10ms period
  lda #<VIA_T1_10MS
  sta VIA1_T1CL         ; writing T1C-L loads the low latch
  lda #>VIA_T1_10MS
  sta VIA1_T1CH         ; writing T1C-H loads high latch + starts T1
  ; enable the Timer 1 interrupt
  lda #VIA_IER_T1_ENABLE
  sta VIA1_IER
  ; mark present
  lda #$01
  sta VIA_PRESENT
  sec                   ; carry set = present
  rts
@absent:
  stz VIA1_DDRB         ; restore a benign DDRB (inputs)
  stz VIA_PRESENT
  clc                   ; carry clear = absent
  rts

; via_report:
; If VIA1 was detected, print a line under the BIOS banner:
;   ## VIA1 on $7F20
; Does nothing if the VIA is absent. Clobbers A, Y.
via_report:
  lda VIA_PRESENT
  beq @done
  lda #<viaMessage
  sta PTR_TX
  lda #>viaMessage
  sta PTR_TX_H
  jsr serial_out_str
@done:
  rts

; serial_out:
; Transmit the char in the A Register via the on board
; serial ACIA TTL-RS232
; This routine uses pooling mode and will wait until the ACIA 
; TX Data Register (TXDR) bit 1 is Empty to send the character. 
serial_out:  
  pha
  pool_acia: ; pulling mode until ready to TX
    lda ACIA_STATUS 
    and #ACIA_TDRE     ; looking at Bit 1 TX Data Register Empty > High = Empty
    beq pool_acia     ; pooling loop if empty
  pla
  sta ACIA_DATA       ; output char in A to TDRE
  rts

; serial_poll:
; Non-blocking, NON-echoing read of the ACIA. Checks whether a byte is
; waiting and returns immediately either way.
; - Byte waiting: byte in A, Carry set
; - Nothing waiting: Carry clear (A is undefined)
; - X, Y preserved
; Intended for programs that poll the keyboard (BASIC GET / Ctrl-C check,
; games, editors) and do their own echoing.
serial_poll:
  lda ACIA_STATUS
  and #ACIA_RDRF    ; look at Bit 0 RX Data Register Full > High = Full
  beq @no_data      ; nothing in the RX Buffer
  lda ACIA_DATA     ; load the byte to A
  sec               ; we have data set Carry
  rts
@no_data:
  clc               ; no data RX clear carry
  rts

; serial_in: 
; Takes the byte recived by that ACIA and returns it in A (acumulator)  
; if a byte was received sets the Carry Flag, if not it clears it
; Same as serial_poll, but echoes the received byte back to the terminal.
;
serial_in:
  jsr serial_poll   ; non-blocking read, no echo
  bcc @no_data      ; nothing received, carry already clear
  jsr serial_out    ; echo back (returns the byte in A)
  sec               ; we have data set Carry
@no_data:
  rts

; serial_in_raw:
; Blocking read of one byte from the ACIA into A. No echo, no buffering.
; Spins until a byte is available in the RX Data Register.
; Used by the Intel HEX loader where we parse before echoing.
; - A holds the received byte on return
; - X, Y preserved
serial_in_raw:
  lda ACIA_STATUS
  and #ACIA_RDRF    ; Bit 0 RX Data Register Full > High = Full
  beq serial_in_raw ; wait for a byte
  lda ACIA_DATA     ; load the byte to A
  rts

; serial_out_str:
; Sends the a null terminated string via serial
; uses the ZP variable PTR_TX (PTR_TX_L + PTR_TX_H) as the pointer 
; to the string memory location
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

; # Helper Routines for Serial comms

; serial_out_hex:
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

; out_crlf
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

; ### Monitor Command Dispatch & Intel HEX Load/Save ###

; cmd_dispatch:
; Called from WozMon's command parser with the current input char in A.
; Decodes the single-letter commands R (run), L (load Intel HEX) and
; S (save Intel HEX). If the char is none of these, returns with A and X
; unchanged so WozMon can continue its normal hex parse.
; For R/L/S the command is executed and control returns to WozMon
; (WARMWOZ) rather than back to the caller.
; - On no match: A and X preserved, RTS
cmd_dispatch:
  cmp #'R'          ; run program at XAM address?
  beq @run
  cmp #'L'          ; load Intel HEX?
  beq @load
  cmp #'S'          ; save Intel HEX?
  beq @save
  rts               ; not a command, back to WozMon hex parse (A,X intact)
@run:
  jsr @run_sub      ; JSR so an RTS from the user program returns here
  jmp WARMWOZ       ; then warm-start the monitor
@run_sub:
  jmp (XAML)        ; run at the last XAM address
@load:
  jsr load_ihex
  jmp WARMWOZ
@save:
  jsr save_ihex
  jmp WARMWOZ

; load_ihex:
; Receive an Intel HEX stream from the serial port and store it in memory.
; Each data record (type 00) is written at the 16-bit address carried in the
; record itself, so no manual deposit address is needed. A record checksum is
; verified; on mismatch the load aborts with an error message. An EOF record
; (type 01) ends the load with "OK".
; Record: ':' LL AAAA TT <data...> CC   (all hex ASCII)
; Uses IHEX_* zero page scratch. Clobbers A, X, Y.
load_ihex:
  ; prompt
  lda #<loadMsg
  sta PTR_TX
  lda #>loadMsg
  sta PTR_TX_H
  jsr serial_out_str
@next_record:
  jsr serial_in_raw     ; wait for start-of-record
  cmp #':'
  bne @next_record      ; ignore anything until a ':' (CR/LF between records)
  stz IHEX_SUM          ; reset running checksum (65C02 stz)
  jsr get_hex_byte      ; LL  byte count
  sta IHEX_LEN
  jsr get_hex_byte      ; AAAA high byte of address
  sta IHEX_ADDR_H
  jsr get_hex_byte      ; AAAA low byte of address
  sta IHEX_ADDR_L
  jsr get_hex_byte      ; TT  record type
  sta IHEX_TYPE
  ; data bytes. Only type 00 records are written to memory; any other record
  ; type (e.g. 04 extended linear address) is still read so its checksum is
  ; validated, but the bytes are discarded.
  ldy #0
@data_loop:
  cpy IHEX_LEN
  beq @read_checksum
  jsr get_hex_byte      ; one data byte (also folds into IHEX_SUM)
  ldx IHEX_TYPE         ; store only for data records (type 00)
  bne @skip_store
  sta (IHEX_ADDR),y     ; store at record address + index
@skip_store:
  iny
  bra @data_loop
@read_checksum:
  jsr get_hex_byte      ; CC  record checksum byte
  ; At this point IHEX_SUM = (sum of all record bytes incl checksum) & $FF.
  ; A valid record makes that total zero.
  lda IHEX_SUM
  bne @bad_checksum
  ; record good - was it the EOF record?
  lda IHEX_TYPE
  cmp #$01
  beq @done
  bra @next_record
@done:
  lda #<okMsg
  sta PTR_TX
  lda #>okMsg
  sta PTR_TX_H
  jsr serial_out_str
  rts
@bad_checksum:
  lda #<errMsg
  sta PTR_TX
  lda #>errMsg
  sta PTR_TX_H
  jsr serial_out_str
  rts

; save_ihex:
; Emit memory as an Intel HEX stream over the serial port.
; Range comes from WozMon's parsed block syntax: type "START.END" then "S".
;   XAML/XAMH = start address, L/H = end address (inclusive).
; Writes 16-byte type 00 data records followed by a type 01 EOF record.
; Uses IHEX_* zero page scratch. Clobbers A, X, Y.
save_ihex:
  ; WozMon's block-XAM ("START.END") leaves the start address in STL/STH and
  ; the end address in L/H, but it advances XAML/XAMH to the end while dumping.
  ; Re-seed our working pointer (XAML/XAMH) from STL/STH so we start at START.
  lda STL
  sta XAML
  lda STH
  sta XAMH
  jsr out_crlf
@line:
  ; bytes remaining = end - start ; stop once start > end
  lda XAMH
  cmp H
  bcc @emit_line        ; start high < end high -> more to do
  bne @eof              ; start high > end high -> done
  lda XAML
  cmp L
  beq @emit_line        ; equal: still one byte to emit this pass
  bcc @emit_line        ; start low < end low -> more to do
  bra @eof              ; start > end -> done
@emit_line:
  ; decide this record's length: min(16, end-start+1)
  ; compute remaining low estimate; simplest robust approach: emit up to 16
  ; bytes but stop at end address inside the loop.
  stz IHEX_SUM
  lda #':'
  jsr serial_out
  ; byte count placeholder handling: we count as we go, so first figure length
  jsr @calc_len         ; -> IHEX_LEN (1..16)
  lda IHEX_LEN
  jsr put_hex_byte      ; LL
  lda XAMH
  jsr put_hex_byte      ; AAAA hi
  lda XAML
  jsr put_hex_byte      ; AAAA lo
  lda #$00
  jsr put_hex_byte      ; TT = 00 data
  ldy #0
@save_data:
  cpy IHEX_LEN
  beq @save_cksum
  lda (XAML),y
  jsr put_hex_byte
  iny
  bra @save_data
@save_cksum:
  ; checksum = two's complement of sum so far
  lda IHEX_SUM
  eor #$FF
  inc
  jsr put_hex_byte
  jsr out_crlf
  ; advance start by IHEX_LEN
  lda XAML
  clc
  adc IHEX_LEN
  sta XAML
  bcc @line
  inc XAMH
  bra @line
@eof:
  ; EOF record :00000001FF
  lda #<eofRec
  sta PTR_TX
  lda #>eofRec
  sta PTR_TX_H
  jsr serial_out_str
  rts
; @calc_len: how many bytes to emit this record (1..16), bounded by end addr
@calc_len:
  ; remaining = end - start (16-bit). If remaining+1 >= 16 use 16 else remaining+1
  ; compute end - start
  lda L
  sec
  sbc XAML
  sta IHEX_TMP          ; low of (end-start)
  lda H
  sbc XAMH              ; high of (end-start)
  bne @full             ; high byte nonzero -> at least 256 left, use 16
  lda IHEX_TMP
  cmp #15               ; remaining low >= 15 ? (remaining+1 >= 16)
  bcc @partial
@full:
  lda #16
  sta IHEX_LEN
  rts
@partial:
  lda IHEX_TMP          ; remaining (end-start), bytes left-1
  inc                   ; +1 to make it inclusive count
  sta IHEX_LEN
  rts

; get_hex_byte:
; Read two ASCII hex characters from serial (raw, no echo) and return the
; assembled byte in A. The byte is also added into IHEX_SUM for checksum
; verification. Clobbers A; preserves X, Y.
get_hex_byte:
  phx
  jsr serial_in_raw     ; high nibble char
  jsr ascii_to_nib
  asl
  asl
  asl
  asl
  sta IHEX_TMP          ; high nibble in place
  jsr serial_in_raw     ; low nibble char
  jsr ascii_to_nib
  ora IHEX_TMP          ; combine nibbles
  tax                   ; keep byte in X
  clc
  adc IHEX_SUM          ; fold into running checksum
  sta IHEX_SUM
  txa                   ; return byte in A
  plx
  rts

; ascii_to_nib:
; Convert ASCII hex char in A ('0'-'9','A'-'F','a'-'f') to nibble value 0-15.
; No validation - assumes well-formed input. Clobbers A.
ascii_to_nib:
  cmp #'9'+1
  bcc @digit            ; '0'-'9'
  and #$DF              ; fold lower to upper case
  sbc #$07              ; 'A'(after carry) maps to 10 ; carry set from cmp path
@digit:
  and #$0F
  rts

; put_hex_byte:
; Transmit the byte in A as two ASCII hex chars and fold it into IHEX_SUM.
; Clobbers A; preserves X, Y.
put_hex_byte:
  pha
  clc
  adc IHEX_SUM          ; checksum tracks raw byte value
  sta IHEX_SUM
  pla
  jsr serial_out_hex    ; reuse BIOS hex printer
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
viaMessage:
  .byte "## VIA1 on $7F20"
  .byte CR,LF,$00
; Intel HEX loader/saver messages
loadMsg:
  .byte CR,LF,"Paste Intel HEX..",CR,LF,$00
okMsg:
  .byte CR,LF,"OK",CR,LF,$00
errMsg:
  .byte CR,LF,"CKSUM ERR",CR,LF,$00
eofRec:
  .byte ":00000001FF",CR,LF,$00

; ### Interrupt Handlers ###

; # IRQ Handler
; Services VIA1 Timer 1 (the ~10ms tick) by incrementing the 3-byte TOCKS
; jiffy counter. Only A is used, so only A is preserved. Other sources (ACIA
; RX, etc.) can be added here later; unrecognised IRQs simply return.
irq_handler:
    pha                   ; preserve A (X,Y untouched below)
    ; Was it VIA1 Timer 1? Check IFR bit 6. (If the VIA is absent this reads
    ; open bus, but then it is not an IRQ source so the board won't assert IRQ.)
    lda VIA1_IFR
    and #VIA_IFR_T1
    beq @not_t1           ; not Timer 1 -> nothing we handle
    ; Clear the Timer 1 interrupt flag by reading T1C-L.
    lda VIA1_T1CL
    ; Increment the 24-bit TOCKS counter (little-endian).
    inc TOCKS_L
    bne @done
    inc TOCKS_M
    bne @done
    inc TOCKS_H
@done:
@not_t1:
    pla                   ; restore A
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