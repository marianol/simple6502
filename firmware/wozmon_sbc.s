;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak in 1976
;  Adapted to the simple6502 SBC with MC60B50 ACIA by Mariano Luna
;
; Changelog:
; - 5 bytes less
; - updated to use BIOS ruitines fro Serial I/O
; - moved Variables to defines_[platfrom].s
; - updates to use standard ASCII (not Apple 1 bit 7 set) 
; - input now case insensitive
; - 

; TEST PROGRAM
; 0400: A9 20 20 77 80 18 69 01 C9 7F 30 F6 4C 00 04
;
;                            * = $0400
; 0400   A9 20      L0400     LDA #$20
; 0402   20 77 80   L0402     JSR $8077
; 0405   18                   CLC
; 0406   69 01                ADC #$01
; 0408   C9 7F                CMP #$7F
; 040A   30 F6                BMI L0402
; 040C   4C 00 04             JMP L0400
;                             .END
; Page 0 Variables
XAML            = $24           ;  Last "opened" location Low
XAMH            = $25           ;  Last "opened" location High
STL             = $26           ;  Store address Low
STH             = $27           ;  Store address High
L               = $28           ;  Hex value parsing Low
H               = $29           ;  Hex value parsing High
YSAV            = $2A           ;  Used to see if hex value is given
MODE            = $2B           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM

; Other Variables

IN              = $0200         ;  Input buffer to $027F

WOZMON:
                ; Run out of mem so assuming serial is inizialized by BIOS
                ; with only one of this JSRs 'WOZMON' overflows the
                ; 'MONITOR' segment memory area by 1 byte
                ; if you are running this independently of the bios you
                ; will need to uncomment the next 2 lines
                ; JSR     init_serial    ; Initialize ACIA
                ; JSR     out_crlf       ; send CR+LF
WARMWOZ:        LDA     #$1B           ; Begin with escape. 
NOTCR:
                CMP     #$08           ; Backspace key? * Changed to the actual BS key
                BEQ     BACKSPACE      ; Yes.
                CMP     #$1B           ; ESC?
                BEQ     ESCAPE         ; Yes.
                INY                    ; Advance text index.
                BPL     NEXTCHAR       ; Auto ESC if line longer than 127.
ESCAPE:
                LDA     #$5C           ; "\".
                JSR     ECHO           ; Output it.
GETLINE:
                JSR     out_crlf       ; * Send CR+LF
                LDY     #$01           ; Initialize text index.
BACKSPACE:      DEY                    ; Back up text index.
                BMI     GETLINE        ; Beyond start of line, reinitialize.
NEXTCHAR:
                LDA     ACIA_STATUS    ; Check AICIA status. 
                AND     #ACIA_RDRF     ; Key ready?
                BEQ     NEXTCHAR       ; Loop until ready.
                LDA     ACIA_DATA      ; Load character. B7 will be '0'.
                CMP     #$60           ;* Lower case?
                BMI     GO_ON          ;* Nope, go on
                AND     #$5F           ;* convert to Upper case ASCII
GO_ON:          STA     IN,Y           ; Add to text buffer.
                JSR     ECHO           ; Display character.
                CMP     #$0D           ; CR?
                BNE     NOTCR          ; No.
                LDY     #$FF           ; Reset text index.
                LDA     #$00           ; For XAM mode.
                TAX                    ; 0->X.
SETBLOCK:
                ASL
SETSTOR:
                ASL                    ; Leaves $7B if setting STOR mode.
                STA     MODE           ; $00 = XAM, $74 = STOR, $B8 = BLOCK XAM.
BLSKIP:
                INY                    ; Advance text index.
NEXTITEM:
                LDA     IN,Y           ; Get character.
                CMP     #$0D           ; CR?
                BEQ     GETLINE        ; Yes, done this line.
                CMP     #$2E           ; "."?
                BCC     BLSKIP         ; Skip delimiter.
                BEQ     SETBLOCK       ; Set BLOCK XAM mode.
                CMP     #$3A           ; ":"?
                BEQ     SETSTOR        ; Yes, set STOR mode.
                CMP     #$52           ; "R"?
                BEQ     RUNPRG            ; Yes, run user program.
                STX     L              ; $00 -> L. * Woz is relying on X being zero
                STX     H              ;    and H.
                STY     YSAV           ; Save Y for comparison
NEXTHEX:
                LDA     IN,Y           ; Get character for hex test.
                EOR     #$30           ; Map digits to $0-9.
                CMP     #$0A           ; Digit?
                BCC     DIG            ; Yes.
                ADC     #$88           ; Map letter "A"-"F" to $FA-FF.
                CMP     #$FA           ; Hex letter?
                BCC     NOTHEX         ; No, character not hex.
DIG:
                ASL
                ASL                    ; Hex digit to MSD of A.
                ASL
                ASL
                LDX     #$04           ; Shift count.
HEXSHIFT:
                ASL                    ; Hex digit left, MSB to carry.
                ROL     L              ; Rotate into LSD.
                ROL     H              ; Rotate into MSD's.
                DEX                    ; Done 4 shifts?
                BNE     HEXSHIFT       ; No, loop.
                INY                    ; Advance text index.
                BNE     NEXTHEX        ; Always taken. Check next character for hex.
NOTHEX:
                CPY     YSAV           ; Check if L, H empty (no hex digits).
                BEQ     ESCAPE         ; Yes, generate ESC sequence.
                BIT     MODE           ; Test MODE byte.
                BVC     NOTSTOR        ; B6=0 is STOR, 1 is XAM and BLOCK XAM.
                LDA     L              ; LSD's of hex data.
                STA     (STL,X)        ; Store current 'store index'.
                INC     STL            ; Increment store index.
                BNE     NEXTITEM       ; Get next item (no carry).
                INC     STH            ; Add carry to 'store index' high order.
TONEXTITEM:     JMP     NEXTITEM       ; Get next command item.
; Update to allow R to run programs with JSR 
; this enables the program to return to monitor on RTS
RUNPRG:
                JSR     RUNSUB         ;* do a JSR to the JMP to Address we want to run.
                JMP     WARMWOZ        ;* if the program does an RTS we warm start WozMON.
RUNSUB:                                ; added a new label to allow for the JSR hack
                JMP     (XAML)         ; Run at current XAM index.
NOTSTOR:
                BMI     XAMNEXT        ; B7 = 0 for XAM, 1 for BLOCK XAM.
                LDX     #$02           ; Byte count.
SETADR:         LDA     L-1,X          ; Copy hex data to
                STA     STL-1,X        ;  'store index'.
                STA     XAML-1,X       ; And to 'XAM index'.
                DEX                    ; Next of 2 bytes.
                BNE     SETADR         ; Loop unless X = 0.
NXTPRNT:
                BNE     PRDATA         ; NE means no address to print.
                JSR     out_crlf       ; Send CR+LF 
                LDA     XAMH           ; 'Examine index' high-order byte.
                JSR     PRBYTE         ; Output it in hex format.
                LDA     XAML           ; Low-order 'examine index' byte.
                JSR     PRBYTE         ; Output it in hex format.
                LDA     #$3A           ; ":".
                JSR     ECHO           ; Output it.
PRDATA:
                LDA     #$20           ; Blank.
                JSR     ECHO           ; Output it.
                LDA     (XAML,X)       ; Get data byte at 'examine index'.
                JSR     PRBYTE         ; Output it in hex format.
XAMNEXT:        STX     MODE           ; 0 -> MODE (XAM mode).
                LDA     XAML
                CMP     L              ; Compare 'examine index' to hex data.
                LDA     XAMH
                SBC     H
                BCS     TONEXTITEM     ; Not less, so no more data to output.
                INC     XAML
                BNE     MOD8CHK        ; Increment 'examine index'.
                INC     XAMH
MOD8CHK:
                LDA     XAML           ; Check low-order 'examine index' byte
                AND     #$07           ; For MOD 8 = 0
                BPL     NXTPRNT        ; Always taken.
PRBYTE:
                PHA                    ; Save A for LSD.
                LSR
                LSR
                LSR                    ; MSD to LSD position.
                LSR
                JSR     PRHEX          ; Output hex digit.
                PLA                    ; Restore A.
PRHEX:
                AND     #$0F           ; Mask LSD for hex print.
                ORA     #$30           ; Add "0".
                CMP     #$3A           ; Digit?
                BCC     ECHO           ; Yes, output it.
                ADC     #$06           ; Add offset for letter.
ECHO:
                PHA                    ; Save A.
                STA     ACIA_DATA      ; Output character.
                LDA     #$FF           ; Initialize delay loop.
TXDELAY:        DEC                    ; Decrement A.
                BNE     TXDELAY        ; Until A gets to 0.
                PLA                    ; Restore A.
                RTS                    ; Return.


