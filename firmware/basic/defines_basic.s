; Definitions file for Simple6502 MSBasic build

; Define our target build since it may be used later
SIMPLE6502 := 1                     ; Target platform 

; Simple6502 BIOS entry points (BIOS_* labels from the BIOS jump table)
.include "bios_jumptable.inc"

; ----------------------------------------------------------------------------
; Build configuration (reference only)
;
; These are the CONFIG_ settings this source was configured with. They are
; commented out on purpose: the source no longer tests them, the code for the
; other settings was removed when it was cleaned up for the Simple6502. They are
; kept here to document how it was configured.
; The only symbol still tested is CONFIG_NULL (see the end of this block).
;
; BASIC version level. CONFIG_2A implies the lower ones, so all the Microsoft
; bugfixes up to version 2A are in (the level of CBM2, AIM-65 and SYM-1).
; CONFIG_2A := 1
; CONFIG_2 := 1
; CONFIG_11A := 1
; CONFIG_11 := 1
; CONFIG_10A := 1
;
; Features and options
; CONFIG_DATAFLG := 1                 ; LIST does not expand tokens inside quoted strings
; CONFIG_EASTER_EGG := 1              ; include the CBM2 "WAIT 6502" easter egg
; CONFIG_NO_CR := 1                   ; no automatic line wrap in PRINT/TAB/comma zones (terminal wraps itself)
; CONFIG_NO_LINE_EDITING := 1         ; disable support for Microsoft-style "@", "_", BEL etc.
; CONFIG_NO_READ_Y_IS_ZERO_HACK := 1  ; don't do a very volatile trick that saves one byte
; CONFIG_PEEK_SAVE_LINNUM := 1        ; preserve LINNUM on a PEEK
; CONFIG_SCRTCH_ORDER := 2            ; init calls SCRTCH (NEW) after printing the BYTES FREE banner
;
; Derived from INPUTBUFFER being at $0200 (outside zero page)
; CONFIG_NO_INPUTBUFFER_ZP := 1
; CONFIG_INPUTBUFFER_0200 := 1
;
; NULL statement (not enabled, and the only one still tested by the source).
; To use it, uncomment both lines. Other platforms used NULL_MAX = $0A (OSI, CBM1)
; or $F0-$F2 (AIM65, KIM, MICROTAN, SYM1).
; CONFIG_NULL := 1
; NULL_MAX := $0A
; ----------------------------------------------------------------------------

; The zero page variables are not declared here. The system zero page map is
; ../zeropage.s (BASIC_ZP_START, RAM_SIZE ...) and the BASIC variables are in
; zeropage_basic.s, including MEMSIZ.

; inputbuffer
INPUTBUFFER                 := $0200
INPUTBUFFERX = INPUTBUFFER & $FF00


; constants
SPACE_FOR_GOSUB := $3E
STACK_TOP		:= $FA

; This was used by the TERMINAL WIDTH Prompt and had no effect with CONFIG_NO_CR defined 
; not used now: Z17 and Z18 were removed from zeropage_basic.s, the code in
; init.s that stored these is commented out 
;WIDTH			:= 40       ; ends up in Z17
;WIDTH2			:= 30       ; ends up in Z18

RAMSTART2		:= $0400        ; is fine for us also it gives room for the INPUTBUFFER

; magic memory locations
ENTROPY = $E844             ; for RND seed, pulls 8 bits of the count value for VIA1 Timer 1 (T1C-L)
                            ; this is a free running timer in CBM computers used 
                            ; by basic for generating pseudorandom numbers.
                            ; @todo we need to change that to our timer

; monitor functions
MONCOUT	:= BIOS_SERIAL_OUT  ; character out, preserves A, X and Y
; MONRDKEY and MONRDKEY2 are in extra.s, LOAD and SAVE in loadsave.s

; Floating point parameters - @todo check if true
BYTES_FP		    := 5
BYTES_PER_ELEMENT   := BYTES_FP
BYTES_PER_VARIABLE  := BYTES_FP+2
MANTISSA_BYTES	    := BYTES_FP-1
BYTES_PER_FRAME     := 2*BYTES_FP+8
FOR_STACK1		    := 2*BYTES_FP+5
FOR_STACK2		    := BYTES_FP+4

MAX_EXPON = 10

STACK           := $0100
STACK2          := STACK

CR=13
LF=10

.ifndef CRLF_1
CRLF_1 := CR
CRLF_2 := LF
.endif



