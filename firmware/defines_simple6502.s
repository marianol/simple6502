; Herdware for the simple6502 SBC board
;
; This file has the common labels, variables and costants that define the 
; herdware of my simple6502 SBC https://github.com/marianol/simple6502/
; is ment to be included in source files and keep hardware related data 
; separated from the main assembly code.

; simple6502 SBC
; Memory Map Address Space
; 0x0000 - 0x7EFF : RAM 32K - 256 bytes (31.75K)
; 0x7F00 - 0x7FFF : I/O 256 bytes decoded to 8 IO lines
; 0x8000 - 0xFFFF : ROM 32K
; Clock is @1.8432MHz so 0.542534722us per cycle

; I/O Space 
IO_1    = $7F00 ; Slot #1 0x7F00 - 0x7F0F
IO_2    = $7F10 ; Slot #2 0x7F10 - 0x7F1F
IO_3    = $7F20 ; VIA #1  0x7F20 - 0x7F2F 
IO_4    = $7F30 ; Available 0x7F30 - 0x7F3F 
IO_5    = $7F40 ; Available 0x7F40 - 0x7F4F
IO_6    = $7F50 ; Available 0x7F50 - 0x7F5F 
IO_7    = $7F60 ; Available 0x7F60 - 0x7F6F
IO_8    = $7F70 ; MC68B50 ACIA  0x7F70 - 0x7F7F
;  0x7F80 - 0x7FFF : This section is not decoded 127 bytes

; -----------
; ACIA MC68B50
; The simple6502 has an serial interface on board at IO_8
; the ACIA is driven by the main clock (CLK) @ 1.8432Mhz 
; RS is tied to A0 and CS0 is tied to A1
; The 68B50 Control register is as follows:
; - Bit 0-1: Config clock Divider & Reset > 00: ÷1, 01: ÷16, 10: ÷64, 11: Master reset
; - Bit 2-4: Config bit length, parity & stop >
; - Bit 5-6: TX control bits 
;               > 00: RTSB low, TDRE IRQ disabled
;               > 01: RTSB low, TDRE IRQ enabled
;               > 10: RTSB high, TDRE IRQ disabled
;               > 11: RTSB low, transmits brake level, TDRE disabled
; - Bit 7: RX IRQ 0 Disabled / 1 Enabled

ACIA_BASE     = IO_8
ACIA_STATUS   = ACIA_BASE + 2   ; Read RS 0 + R 
ACIA_CONTROL  = ACIA_BASE + 2   ; Write RS 0 + W
ACIA_DATA     = ACIA_BASE + 3   ; RS 1 + R/W > RX/TX

; ACIA Preset Configurations
; This are intended to simplify config of the CTRL register 
ACIA_CFG_115    = %00010101    ; 8-N-1, 115200bps, no IRQ - /16 CLK 
ACIA_CFG_115I   = %10010101    ; 8-N-1, 115200bps, IRQ - /16 CLK 
ACIA_CFG_28     = %00010110    ; 8-N-1, 28800bps, no IRQ - /64 CLK 
ACIA_CFG_28I    = %10010110    ; 8-N-1, 28800bps, IRQ - /64 CLK 

; ACIA Helper Constants
ACIA_TDRE       = %00000010    ; bitmask for TRDE
ACIA_RDRF       = %00000001    ; bitmask for RDRF
ACIA_RESET      = %00000011    ; 6850 reset

; 6522 VIA 
; The VIA is not onboard in Rev 1.6 PCB 
; but reserving this I/O for the main VIA
;
; VIA Interrupt Flag Register (IFR) Reference
; BIT   |  0  |  1  |  2       |  3  |  4  |   5    |   6    |  7  |
; Desc  | CA2 | CA1 | Shift    | CB2 | CB1 | Timer2 | Timer2 | IRQ |
;                     Register 
VIA1_BASE   = IO_3
VIA1_PORTB  = VIA1_BASE         ; $7F20
VIA1_PORTA  = VIA1_BASE + 1     ; $7F21
VIA1_DDRB   = VIA1_BASE + 2     ; $7F22
VIA1_DDRA   = VIA1_BASE + 3     ; $7F23
VIA1_T1CL   = VIA1_BASE + 4     ; $7F24 T1C-L Timer 1 Counter (low byte)
VIA1_T1CH   = VIA1_BASE + 5     ; $7F25 T1C-H Timer 1 Counter (high byte) 
VIA1_T1L    = VIA1_BASE + 6     ; $7F26 T1L-L
VIA1_T1H    = VIA1_BASE + 7     ; $7F27 T1L-H
VIA1_T2CL   = VIA1_BASE + 8     ; $7F28 T2C-L
VIA1_T2CH   = VIA1_BASE + 9     ; $7F29 T2C-H
VIA1_SR     = VIA1_BASE + 10    ; $7F2A SR Shift Register
VIA1_ACR    = VIA1_BASE + 11    ; $7F2B Auxiliary Control register @
VIA1_PCR    = VIA1_BASE + 12    ; PCR Peripheral Control Register
VIA1_IFR    = VIA1_BASE + 13    ; $7F2D IFR > Interrupt Flag Register
VIA1_IER    = VIA1_BASE + 14    ; $7F2E ; Interrupt Enable Register


; ### ZeroPage Variables ###
ZP_START        = $00
PTR_RD_RX_BUF   = $E5 ; RX Read Buffer Pointer
PTR_WR_RX_BUF   = $E6 ; RX Write Buffer Pointer
PTR_TX          = $E7 ; Transmit String Pointer
PTR_TX_L        = $E7 ; LO Byte
PTR_TX_H        = $E8 ; HI Byte

; WozMon ZeroPage Variables
; uses $24 to $2B used 
; These are defined in wozmon_sbc.s here only for reference
; XAML            = $24           ;  Last "opened" location Low
; XAMH            = $25           ;  Last "opened" location High
; STL             = $26           ;  Store address Low
; STH             = $27           ;  Store address High
; L               = $28           ;  Hex value parsing Low
; H               = $29           ;  Hex value parsing High
; YSAV            = $2A           ;  Used to see if hex value is given
; MODE            = $2B           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM


; ### Useful Constants ###
; ASCII 
CR      = $0D
LF      = $0A
BS      = $08
DEL     = $7F 
SPACE   = $20
ESC     = $1B
NULL    = $00
