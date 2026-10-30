; simple6502 zero page map
;
; This is the one place where zero page variables are declared. Do NOT add
; "NAME = $xx" equates for zero page variables to a defines file: declare the
; variable here with .res inside the block it belongs to. That way the
; assembler allocates the bytes, a block that grows is caught by the .assert
; at the end of the block, and the whole map can be read in one file.
; See docs/ZEROPAGE_MAP.md for the full map with the BASIC variables.
;
; Layout rules:
;  - Each block is anchored with .org at a FIXED address and its variables
;    follow each other with .res. Do not move a block: programs (and the jump
;    table, e.g. BIOS_SERIAL_STR reads PTR_TX) rely on these addresses.
;  - Several labels in front of one .res are aliases of the same bytes
;    (TOCKS and TOCKS_L, PTR_TX and PTR_TX_L ...).
;  - WozMon relies on XAML/XAMH, STL/STH and L/H being adjacent, in that order.
;  - BASIC owns BASIC_ZP_START..BASIC_ZP_END. It declares its variables in
;    basic/zeropage_basic.s. It shares RAM_SIZE with the BIOS (BASIC's MEMSIZ).
;
; This file is included by BIOS.s and by basic/msbasic.s, so both builds check
; their blocks against the same map.

; The zero page range reserved for BASIC. Its variables are declared in
; basic/zeropage_basic.s, which checks that they stay inside this range.
; $4A-$DD: the BASIC variables, the copy of the CHRGET code and RNDSEED.
; $DE-$DF stay free as spare.
BASIC_ZP_START = $4A
BASIC_ZP_END   = $DD

.feature org_per_seg
.zeropage

; ----------------------------------------------------------------------------
; $00 fault beacon scratch
; post_fail writes $01/$00 here to toggle D0 on the data bus.
; ----------------------------------------------------------------------------
.org $00
ZP_START:
  .res 1
.assert * <= $24, error, "zero page: block at $00 runs into WozMon variables"

; ----------------------------------------------------------------------------
; $24-$2B WozMon
; ----------------------------------------------------------------------------
.org $24
XAML:                   ; Last "opened" location Low
  .res 1
XAMH:                   ; Last "opened" location High
  .res 1
STL:                    ; Store address Low
  .res 1
STH:                    ; Store address High
  .res 1
L:                      ; Hex value parsing Low
  .res 1
H:                      ; Hex value parsing High
  .res 1
YSAV:                   ; Used to see if hex value is given
  .res 1
MODE:                   ; $00=XAM, $7F=STOR, $AE=BLOCK XAM
  .res 1
.assert * <= $30, error, "zero page: WozMon block runs into the Intel HEX variables"

; ----------------------------------------------------------------------------
; $30-$35 Intel HEX load/save scratch
; ----------------------------------------------------------------------------
.org $30
IHEX_ADDR:              ; record load address (LO/HI)
IHEX_ADDR_L:
  .res 1
IHEX_ADDR_H:
  .res 1
IHEX_LEN:               ; record byte count
  .res 1
IHEX_TYPE:              ; record type (00 data, 01 EOF)
  .res 1
IHEX_SUM:               ; running checksum accumulator
  .res 1
IHEX_TMP:               ; general scratch
  .res 1
.assert * <= $40, error, "zero page: Intel HEX block runs into the register print variables"

; ----------------------------------------------------------------------------
; $40-$46 monitor register print
; ----------------------------------------------------------------------------
.org $40
P_STATUS:
PC_REG_H:
  .res 1
PC_REG_L:
  .res 1
SP_REG:
  .res 1
A_REG:
  .res 1
X_REG:
  .res 1
Y_REG:
  .res 1
SR_REG:
  .res 1
.assert * <= BASIC_ZP_START, error, "zero page: register print block runs into the BASIC variables"

; ----------------------------------------------------------------------------
; BASIC_ZP_START-BASIC_ZP_END: reserved for BASIC, see the top of this file.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; $E0-$EB BIOS system variables
; ----------------------------------------------------------------------------
.org $E0
TOCKS:                  ; Jiffy-like clock, 3 bytes, ~10ms per tick
TOCKS_L:
  .res 1
TOCKS_M:
  .res 1
TOCKS_H:
  .res 1
RAM_SIZE:               ; RAM size, 2 bytes: top usable RAM address + 1.
RAM_SIZE_L:             ; The POST writes it, BASIC reads it as MEMSIZ.
  .res 1
RAM_SIZE_H:
  .res 1
PTR_RD_RX_BUF:          ; RX Read Buffer Pointer
  .res 1
PTR_WR_RX_BUF:          ; RX Write Buffer Pointer
  .res 1
PTR_TX:                 ; Transmit string pointer (used by BIOS_SERIAL_STR)
PTR_TX_L:
  .res 1
PTR_TX_H:
  .res 1
POST_PTR:               ; POST RAM-walk pointer, 2 bytes
  .res 2
VIA_PRESENT:            ; non-zero if VIA1 was detected and initialized
  .res 1
.assert * <= $100, error, "zero page: BIOS system block runs past the end of the zero page"
.assert TOCKS > BASIC_ZP_END, error, "zero page: BIOS system block overlaps the BASIC variables"
