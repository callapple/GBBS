 PAG
********************************
*                              *
*       ACOS.OBJ - Start       *
*                              *
********************************
 DATE
*-------------------------------

   ;FATAL SEI
FATAL JSR MDMINIT
FATAL1 JSR VIDINIT
 JSR PRINIT
 STA KBDSTRB
; SEI
 JSR CLRBUF
 LDA LORESMD ;** it makes things work !! **

 LDA SETRAM ;select ram card
 LDA SETRAM

 LDX #0
 STX REMOTE
 STX DOCHAT ;turn off chat
 STX INCHAT
 STX TIMEON
 STX TIMEON+1
 STX LOGOFF

 STX MSGREF
 STX LSTTXT

 STX GSBLVL
 STX FORLVL

 STX ANU_ON
 DEX
 STX PWHIDE

 LDA #$60
 STA USERVEC ;put RTS in modem-user-routine

 LDA #4
 STA REFNUM ;close all files
:FATAL2 JSR CLOSE
 DEC REFNUM
 BPL :FATAL2

 LDA #1
 LDX #23
:FATAL3 STA BITMAP,X ;move 1 - 000 pattern
 LDA #0 ;and free up memory
 DEX
 BNE :FATAL3

 LDA #$CF
 STA BITMAP ;protect bottom pages

 LDY #10 ;reset device table
:FATAL4 LDA DEVTBL,Y
 STA DEVUSE,Y
 DEY
 BPL :FATAL4

 LDA #<RESET ;set up reset vector
 STA RESETVEC
 LDA #>RESET
 STA RESETVEC+1

 EOR #$A5 ;get power-up byte
 STA SOFTEV

 RTS

FATAL5 LDX #15
:STARTUP LDA BBS_PRG,X ;copy default filename
 JSR CONV ;convert to upper case
 STA FLNAME,X
 DEX
 BPL :STARTUP

FATAL6 LDA #'A'
 LDX #0
 JSR LOGSPEC ;log to A:

 JSR LD_MOD ;load module

 JSR CLEAR

RUNMOD1 LDA #<CODEND ;point at program
 STA PRGPTR
 LDA #>CODEND
 STA PRGPTR+1

 LDX #$FF ;set up stack
 TXS

RUNMOD2 JSR CHKBYT ;get token
 CMP #end
 BLT :RUNMOD3 ;if 'let', don't get byte

 JSR GETBYT ;gobble
 CMP #0
 BMI SYNTAX ;special character? Y = error

:RUNMOD3 STA CMD ;save cmd
 SEC  ;mark as command
 JSR EX_TOK ;execute it
 BIT LOGOFF ;drop user?
 BPL RUNMOD2 ;nope

 JSR DO_CL3 ;close all open files
 LDA NOCDVEC ;point to no cd routine
 STA PRGPTR
 LDA NOCDVEC+1
 STA PRGPTR+1

 LDA #0
 STA NOCDFLG ;reset cd flag
 STA LOGOFF

 JMP RUNMOD2 ;keep going

RESET INC SOFTEV ;make sure next reset reboots
 LDA #0
 STA SHWTRC ;clear trace mode
 STA AUTORST ;disable auto reset

 JMP RESTART1

*-------------------------------
* enter error dispatch routines
*-------------------------------

SYNTAX LDX #syntax ;syntax error
 BNE BADERR

NOLBLDEF LDX #nolabel ;undefined label
 BNE BADERR

DO_END LDX #endprog ;end of program
BADERR STX ERRNO ;save error #
 BIT ONERRFLG
 BPL :KILLIT

 LDA PRGPTR ;save where error occurred
 STA FROMERR
 LDA PRGPTR+1
 STA FROMERR+1

 LDA ONERRVEC ;point to error handler routine
 STA PRGPTR
 LDA ONERRVEC+1
 STA PRGPTR+1

 LDA #0
 STA ONERRFLG ;reset onerr flag
 JMP RUNMOD2

:KILLIT JSR ERROR ;show error
RESTART1 LDA SETRAM ;select ram card
 LDA SETRAM

 LDA #0
 STA REMOTE ;turn off remote

 JSR MDM1_2 ;hang up modem

 JSR PR
 ASC "*** RESTART: S,M,Q ?"00

 LDA #0
 STA TEMP ;start restart timeout
 STA TEMP+1
 LDA #-10
 STA TEMP2

:REST2 LDA AUTORST ;auto-restart?
 BEQ :REST2A ;nope

 INC TEMP
 BNE :REST2A
 INC TEMP+1 ;do low/med counter
 BNE :REST2A

 INC TEMP2
 BNE :REST2A

 DEC AUTORST ;countdown auto-restart count
 JMP REST3 ;restart system

:REST2A JSR GET ;get input
 JSR CONV ;make upper case
 CMP #'S'
 BEQ REST3 ;restart system

 CMP #'M'
 BEQ REST4 ;restart module

 CMP #'*'
 BEQ REST5 ;goto monitor

 CMP #'Q'
 BNE :REST2 ;quit

 JSR MDMQUIT ;reset the modem before quiting

 LDA #$FF
 STA INVFLG ;reset inverse flag

 JSR MLI
 DB $65
 DA P_QUIT

REST3 LDA #3 ;reset auto-restart byte
 STA AUTORST

 JSR FATAL ;cold start
 JMP FATAL5

REST4 JMP RUNMOD1 ;warm start

REST5 LDA SETROM ;enable rom
 JMP ENTRMON

*-------------------------------
* handle an incoming irq (and fix it)
*-------------------------------

IRQ_FIX STA IRQ_A
 PLA
 PHA
 AND #%00010000
 BNE :BRKD
 LDA IRQ_A
 PHA
 TXA
 PHA
 TYA
 PHA
 LDA #'I'-ctrl
 STA TOPRIGHT
 JSR MDMIN
 JSR MDMIN
 PLA
 TAY
 PLA
 TAX
 PLA
 RTI

:BRKD STA SETROM
 JMP (IRQVECT)

* save buffers & variables

BBS_PRG STR 'LOGON.SEG' ;main segment name
 DS 16-*+BBS_PRG,$20

P_QUIT DB 4
 DS 6

AUTORST DB 3 ;allow auto-restart 3 times

IRQ_A DB 0


