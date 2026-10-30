
.feature org_per_seg
.zeropage

; The BASIC zero page variables. BASIC_ZP_START and BASIC_ZP_END come from the system
; zero page map (../zeropage.s), which reserves $4A-$DD for BASIC and checks that the
; BIOS blocks stay outside it. The check on the BASIC side is at the end of this file.
;
; CHANGED: one block starting at BASIC_ZP_START, the variables follow each
; other. It used to be four blocks (ZP_START1-4) with gaps between them.
.org BASIC_ZP_START

; CHANGED: USR has its own 3 byte vector (JMP), it was an alias of GORESTART.
; init.s sets it to JMP IQERR. The user POKEs the routine address into USR+1/USR+2.
USR:
	.res 3


GORESTART:
	.res 3
GOSTROUT:
	.res 3
GOAYINT:
	.res 2
GOGIVEAYF:
	.res 2

Z15:
	.res 1
POSX:
	.res 1
; CHANGED: Z17 and Z18 (terminal width) removed, nothing used them.
LINNUM:
TXPSV:
	.res 2


CHARAC:
	.res 1
ENDCHR:
	.res 1
EOLPNTR:
	.res 1
DIMFLG:
	.res 1
VALTYP:
	.res 2
DATAFLG:
	.res 1
SUBFLG:
	.res 1
INPUTFLG:
	.res 1
CPRMASK:
	.res 1
Z14:
	.res 1


TEMPPT:
	.res 1
LASTPT:
	.res 2
TEMPST:
	.res 9
INDEX:
	.res 2
DEST:
	.res 2
RESULT:
	.res BYTES_FP
RESULT_LAST = RESULT + BYTES_FP-1
TXTTAB:
	.res 2
VARTAB:
	.res 2
ARYTAB:
	.res 2
STREND:
	.res 2
FRETOP:
	.res 2
FRESPC:
	.res 2
; CHANGED: MEMSIZ is not part of this block, it is the BIOS RAM_SIZE (see the end of this file).
CURLIN:
	.res 2
OLDLIN:
	.res 2
OLDTEXT:
	.res 2
Z8C:
	.res 2
DATPTR:
	.res 2
INPTR:
	.res 2
VARNAM:
	.res 2
VARPNT:
	.res 2
FORPNT:
	.res 2
LASTOP:
	.res 2
CPRTYP:
	.res 1
FNCNAM:
TEMP3:
	.res 2
DSCPTR:
	.res 3
DSCLEN:
	.res 2
JMPADRS			:= DSCLEN + 1
Z52:
	.res 1
ARGEXTENSION:
	.res 1
TEMP1:
	.res 1
HIGHDS:
	.res 2
HIGHTR:
	.res 2
TEMP2:
	.res 1
INDX:
TMPEXP:
	.res 1
EXPON:
	.res 1
LOWTR:
LOWTRX:
	.res 1
EXPSGN:
	.res 1
FAC:
	.res BYTES_FP
FAC_LAST = FAC + BYTES_FP-1
FACSIGN:
	.res 1
SERLEN:
	.res 1
SHIFTSIGNEXT:
	.res 1
ARG:
	.res BYTES_FP
ARG_LAST = ARG + BYTES_FP-1
ARGSIGN:
	.res 1
STRNG1:
	.res 2
SGNCPR = STRNG1
FACEXTENSION = STRNG1+1
STRNG2:
	.res 2
CHRGET:
TXTPTR = <(GENERIC_TXTPTR-GENERIC_CHRGET + CHRGET)
CHRGOT = <(GENERIC_CHRGOT-GENERIC_CHRGET + CHRGET)
CHRGOT2 = <(GENERIC_CHRGOT2-GENERIC_CHRGET + CHRGET)
RNDSEED = <(GENERIC_RNDSEED-GENERIC_CHRGET + CHRGET)

; CHANGED: top of memory. The BIOS POST finds it and stores it in its RAM_SIZE ($E3/$E4, see
; ../zeropage.s), and BASIC reads it from the same place, the memory size prompt is gone.
; It is the first address that is not RAM. MEMSIZ is a name for RAM_SIZE, not new bytes.
MEMSIZ := RAM_SIZE

; The block above must end inside the range the system zero page map reserves for BASIC.
; RNDSEED is the last item (5 bytes) and the end of the block.
.assert RNDSEED + 4 <= BASIC_ZP_END, error, "BASIC zero page variables run past BASIC_ZP_END (see ../zeropage.s)"
