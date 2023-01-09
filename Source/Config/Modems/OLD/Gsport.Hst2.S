 XC
 TR
 TR ADR

* GS Port Driver Bios
* written by Andy Nicholas on July 26, 1987
*
* History:
*
* 11/07/89 AMW
* 1. History section added
* 2. Checked and or modified for LLUCE
* 3. Section titles added
*
* 11/10/89 AMW
* Added interrupt buffers
*--------------------------
 rel
SLOT KBD 'Slot to assemble for (1/2)'
N0 = SLOT*16
CN = SLOT!$C0
SLTADR = SLOT!$C0*256
FLAG = SLOT-1

CR = $0d
LF = $0a

INITSTR = $11D0
ANSSTR = $11C0
CDBYTE = $11BF
BUFFER = $11A0

 do FLAG
 dsk rel/gsport2.hst
gs2hst ent
 else
 dsk rel/gsport1.hst
gs1hst ent
 fin

* Jump Table
*-------------------------------

 ORG $E00

MODEM DB N0 ;serial card slot * 16
INITSPD DB 0 ;init speed for modem

CALLSPD DB 0 ;Speed of current call

BYTCNT DB 0,0,0

 JMP INIT
 JMP RINGSET
 JMP RING
 JMP ANSRING
 JMP HANGUP
 JMP INP ;get a byte
 JMP OUT ;send a byte
 JMP GETCARR ;caller there?
 JMP SETSPEED ;speed of port
 JMP SETIRQ
 JMP RAISEDTR ;raise dtr
 JMP DUMMY
 JMP DUMMY

DOINIT JMP SLTADR
DOREAD JMP SLTADR
DOWRITE JMP SLTADR
DOSTATUS JMP SLTADR
DOEXT JMP SLTADR

*-------------------------------
* clear the input buffer

CLRBUFF LDA #<FLUSHLST
 LDX #>FLUSHLST
 LDY #0
 BEQ DOEXT

* set DTR on GS Serial Port, and hangup if needed
*-------------------------------

HANGUP LDA #$80 ;blow 'em off (hangup)

GSDTR STA DTRSTATE

 LDA #<DTRLST
 LDX #>DTRLST
 LDY #0
 BEQ DOEXT

* init the serial port pascal locations
*-------------------------------

INIT LDA SLTADR+$D ;get init address
 STA DOINIT+1
 LDA SLTADR+$E ;get read address
 STA DOREAD+1
 LDA SLTADR+$F ;get write address
 STA DOWRITE+1
 LDA SLTADR+$10 ;get status address
 STA DOSTATUS+1
 LDA SLTADR+$12
 STA DOEXT+1

DUMMY RTS

* input data
*-------------------------------

INP PHX  ;Save x
 PHY
 LDX #CN ;are we ready?
 LDY #N0
 LDA #1
 JSR DOSTATUS
 BCC :INP2 ;nope, exit

 LDX #CN ;yes, read
 LDY #N0
 JSR DOREAD

 SEC
:INP1 PLY
 PLX  ;Restore & return
 RTS

:INP2 LDA #0
 BRA :INP1

* output data
*-------------------------------

OUT PHX  ;Save x
 PHY  ;Save y
 PHA  ;Save a

:OUT1 LDX #CN ;ready for send?
 LDY #N0
 LDA #0
 JSR DOSTATUS
 BCC :OUT1 ;nope

 PLA  ;Get a
 LDX #CN
 LDY #N0
 JSR DOWRITE ;send it

 PLY  ;Get y
 PLX  ;Get x
 RTS

* init modem for ring
*-------------------------------

RINGSET JSR HANGUP

 LDA #0 ;let modem reset
 JSR WAIT
 JSR WAIT

 LDA #0
 JSR GSDTR

 LDY INITSPD ;set init speed
 JSR SETSPEED

 LDA #0 ;slight delay (let modem do init)
 JSR WAIT

 LDX #-1
:RSET2 INX  ;Do pre-inc
 LDA INITSTR,X ;get modem init string
 BEQ :RSET3 ;we are done

 JSR OUT ;output
 BRA :RSET2 ;loop (Z-bit set after wait)

:RSET3 LDA #6
 STA COUNTLO
 STA COUNTHI

:RSET4 LDY #-1
:RSET5 DEY
 BEQ :DECOUNT

 JSR INP
 BCC :RSET5
 AND #$7F
 CMP #'0' ;check for "0" (numeric)
 BEQ :LEAVE
 BNE :RSET5

:DECOUNT DEC COUNTLO
 BNE :RSET4
 DEC COUNTHI
 BNE :RSET4
 BEQ RINGSET

:LEAVE JSR INP ;grab the <cr> off the tail end of the "0"
 BCC :LEAVE

 JSR CLRBUFF

 LDA #0
 STA BYTCNT ;reset byte counter
 STA BYTCNT+1
 STA BYTCNT+2
 CLC
 RTS  ;return

*-------------------------------
* test for a ring and handle it

RING JSR INP ;check for a char
 BCC :NORING ;nope...

 AND #$7F ;strip high
 CMP #'2' ;is it a 'ring'? (numeric)
 BNE :NOTRING ;nope, check for connect messages

*-------------------------------

:GRABCR JSR INP ;grab the <cr> off the tail end of the "2"
 BCC :GRABCR
 BCS ANSRING

*===============================

:NOTRING CMP #'1' ;is it a '1' or '10' or '13' or '18'?
 BEQ :GOTCODE ;yes, save it
 CMP #'5' ;is it connect 1200?
 BNE :NORING ;nope

:GOTCODE STA CODE

:2NDCHAR JSR INP ;second character will ALWAYS be there
 BCC :2NDCHAR

 AND #$7F ;strip high
 CMP #CR ;but might be a <cr>
 BNE :MULTCOD

*===============================

 LDY #0 ;connect 300?
 LDA CODE
 CMP #'1'
 BEQ :RING3

 INY
 CMP #'5' ;connect 1200?
 BEQ :RING3 ;nope, unknown code, keep checking
 BNE :NORING

*===============================

:MULTCOD STA CODE+1

 LDY #2 ;def = 2400 baud

 LDA CODE ;get the first code char
 CMP #'1' ;must be a one
 BNE :NORING ;if not, then keep trying

 LDA CODE+1 ;is it 2400?
 CMP #'0'
 BEQ :RING3

 INY
 CMP #'8' ;is it 4800?
 BEQ :RING3

 INY
 CMP #'3' ;is it 9600
 BEQ :RING3

*===============================

:RING3 JSR SETSPEED ;set the correct speed

 LDY #5
:RING4 LDA #0 ;let carrier's settle
 JSR WAIT
 DEY
 BNE :RING4

 JSR CLRBUFF
 SEC  ;we have a connection!
 RTS

:NORING CLC
 RTS

ANSRING JSR ANSWER ;the phone rang, so send 'ATA'

 CLC
 RTS

* wait routine
*-------------------------------

WAIT SEC  ;from apple ][+ ref man - pg 147
:WAIT2 PHA
:WAIT3 SBC #1
 BNE :WAIT3
 PLA
 SBC #1
 BNE :WAIT2
 RTS

* Check for carrier using Get_Port_Stat routine
*-------------------------------

GETCARR PHX
 PHY

 LDA #<CARRLIST
 LDX #>CARRLIST
 LDY #0
 JSR DOEXT

 CLC
 LDA CARRBITS
 AND CDBYTE
 BEQ :NOCARR
 SEC
:NOCARR PLY
 PLX
 RTS

* send ata to phone
*-------------------------------

ANSWER LDA #$80
 JSR WAIT

 LDX #-1
:ANSWER2 INX
 LDA ANSSTR,X ;get text
 BEQ :ANSWER3 ;we are done

 JSR OUT ;send it
 BRA :ANSWER2

:ANSWER3 RTS

* set the rs-232 speed [speed offset in Y]
*
* 0 =   300 baud
* 1 =  1200 baud
* 2 =  2400 baud
* 3 =  4800 baud
* 4 =  9600 baud
* 5 = 19200 baud
*-------------------------------

SETSPEED PHX
 PHY

 LDA #1 ;find caller speed (x300)
 STA CALLSPD
 CPY #0 ;at 300?
 BEQ :DO_BAUD ;yep

 ASL CALLSPD ;speed = speed * 2
:SETSPD2 ASL CALLSPD ;speed = speed * 2
 DEY
 BNE :SETSPD2 ;loop until correct speed found

:DO_BAUD PLA  ;get y-reg
 BNE :TRY1200
 LDX #<B300
 LDA #>B300
 BRA :SETBAUD

:TRY1200 CMP #1
 BNE :TRY2400
 LDX #<B1200
 LDA #>B1200
 BRA :SETBAUD

:TRY2400 CMP #2
 BNE :TRY4800
 LDX #<B2400
 LDA #>B2400
 BRA :SETBAUD

:TRY4800 CMP #3
 BNE :TRY9600
 LDX #<B4800
 LDA #>B4800
 BRA :SETBAUD

:TRY9600 CMP #4
 BNE :TR19200
 LDX #<B9600
 LDA #>B9600
 BRA :SETBAUD

:TR19200 LDX #<B19200
 LDA #>B19200

:SETBAUD STX :BAUDRD+1
 STA :BAUDRD+2

 LDX #CN
 LDY #N0
 JSR DOINIT

 LDX #0
:BAUDRD LDA -1,X
 BEQ :FINISH
 JSR OUT
 INX
 BRA :BAUDRD

:FINISH LDX #0
:LOOP LDA PORTINIT,X
 BEQ :DONE
 JSR OUT
 INX
 BRA :LOOP

:DONE LDA #<OUT_BUF
 LDX #>OUT_BUF
 LDY #0
 JSR DOEXT

 PLX
 RTS

*-------------------------------
* setup interupt routine

SETIRQ RTS

*-------------------------------
* raise dtr

RAISEDTR LDA #0
 PHX
 PHY

 JSR GSDTR

 PLY
 PLX
 RTS

* Table of Speeds and other important stuff
*-------------------------------

COUNTHI DB 0
COUNTLO DB 0

B300 DB 1
 ASC '6B'00 ;accept 300 Baud
B1200 DB 1
 ASC '8B'00 ;accept 1200 Baud
B2400 DB 1
 ASC '10B'00 ;accept 2400 Baud
B4800 DB 1
 ASC '12B'00 ;accept 4800 Baud
B9600 DB 1
 ASC '14B'00 ;accept 9600 Baud
B19200 DB 1
 ASC '15B'00 ;accept 19200 baud

PORTINIT DB 1
 ASC '0D' ;8 bits
 DB 1
 ASC '2P' ;no parity
 DB 1
 ASC 'AD' ;auto-tabbing
 DB 1
 ASC 'XD' ;no xoff recognition
 DB 1
 ASC 'FD' ;no find keyboard
 DB 1
 ASC 'CD' ;no column overflow
 DB 1
 ASC 'ED' ;echo disabled
 DB 1
 ASC 'MD' ;no lf masking
 DB 1
 ASC 'BE' ;buffering enabled
 DB 1
 ASC 'Z'
 DB 0 ;no more control characters

*-------------------------------

OUT_BUF DB 4 ;Parameters to set the
 DB $13 ;Output buffer
 DA 0
 ADRL BUFFER ;Buffer it where
 DA 2 ;Buffer 2 bytes

*-------------------------------

CARRLIST DB 3 ;Parameter list for
 DB 6 ;detecting carrier drop
 DA 0
CARRBITS DA 0 ;Carrier status here

*-------------------------------

DTRLST DB 3 ;Parameter list for
 DB $B ;setting DTR
 DA 0
DTRSTATE DA 0 ;Bit 7 affects DTR

*-------------------------------

FLUSHLST DB 2 ;parameter list for flushing input queue
 DB $14
 DA 0

*-------------------------------

CODE DS 2 ;2 byte code returned by modem

 ASC 'GSPort'
 DB SLOT!$30
 ASC '/HST'


