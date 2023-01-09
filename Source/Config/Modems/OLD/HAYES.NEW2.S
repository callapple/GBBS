 TTL 'Hayes Ultra - GS port driver'
 PAG

*-------------------------------------------------
* GS Port Driver Bios
*
* History:
*
* July 26, 1987, written by andy
*
* May, 1991, andy, changed to allocate a 16k input buffer instead
* of using the normal 2k input buffer
*-------------------------------------------------
 XC
 XC  ;uses 65816 code
 rel

SLOT KBD 'Assemble for what slot (1,2)'
N0 = SLOT*16
CN = SLOT!$C0
SLTADR = SLOT!$C0*256

 DO SLOT/2
 dsk rel/gsport2
ultra2 ent
 else
 dsk rel/gsport1
ultra1 ent
 fin

CDBYTE equ $11bf ;comment these out and uncomment the stuff at the
ANSSTR equ $11c0 ;end to make this a "bloadable" driver
INITSTR equ $11d0

 DO SLOT/2
MODEMREG = $C038
 ELSE
MODEMREG = $C0A8
 FIN

*-------------------------------
* Equates
*-------------------------------

PTR = $A
MLI = $BF00
ALLOC_INT = $40

Return = 13
SM_OK = 0 ;Modem 'OK'
SM_Con03 = 1 ;Modem 'CONNECT 300'
SM_Ring = 2 ;Modem 'RING'
SM_NoCar = 3 ;Modem 'NO CARRIER'
SM_Con12 = 4 ;Modem 'CONNECT 1200'
SM_Con24 = 10 ;Modem 'CONNECT 2400'
SM_Con48 = 11 ;Modem 'CONNECT 4800'
SM_Con96 = 12 ;Modem 'CONNECT 9600'
SM_Con19 = 14 ;Modem 'CONNECT 19200'
SM_Con38 = 28 ;Modem 'CONNECT 38400'

SM_Car03 = 40 ;Modem 'CARRIER 300'
SM_Car12 = 46 ;Modem 'CARRIER 1200'
SM_Car24 = 47 ;Modem 'CARRIER 2400'
SM_Car48 = 48 ;Modem 'CARRIER 4800'
SM_Car96 = 50 ;Modem 'CARRIER 9600'

Comp_MNP5 = 66 ;Modem 'COMPRESSION: CLASS 5'
Comp_V42bis = 67 ;Modem 'COMPRESSION: V.42BIS'
Comp_ADC = 68 ;Modem 'COMPRESSION: ASC'
Comp_NONE = 69 ;Modem 'COMPRESSION: NONE'

Prot_None = 70 ;Modem 'PROTOCOL: NONE'
Prot_ALT = 80 ;Modem 'PROTOCOL: ALT'

PrtSpdL = 12
PrtSpdH = 13

*-------------------------------
* Jump Table
*-------------------------------
 ORG $0E00
MODEM
 DB N0 ;serial card slot
MDMSPEED
INITSPD DB 5 ;initialize speed
CALLSPD DB 0 ;speed of call

Buffer
BYTCNT DB 0,0,0

MDMINIT JMP INIT
MDMRSET JMP RESET
MDMRING JMP RING
MDMANS JMP ANSWER
MDMHANG JMP HANGUP
MDMIN JMP INP
MDMOUT JMP OUT
MDMDCD JMP M_CHKDCD
MDMSSPD JMP SETSPD
MDMDTR JMP RAISEDTR ;raise dtr
MDMFLUSH JMP CLRBUFF
MDMQUIT jmp QUIT

* clear the input buffer
*-------------------------------

CLRBUFF LDA #<FlushInQ
 LDX #>FlushInQ
 LDY #0
 JMP DOEXT

* Hang up the modem if needed
*-------------------------------
HANGUP LDA #$80
GSDTR STA DTRSTATE
 LDA #<DTRLIST
 LDX #>DTRLIST
 LDY #0
 JMP DOEXT

*-------------------------------------------------
* init the serial port pascal locations
*
* this should only ever be called once during the lifetime of
* acos

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

* lda #<GetOutBuffer
* ldx #>GetOutBuffer
* ldy #0
* jsr doext
*
* lda #<GetInBuffer
* ldx #>GetInBuffer
* ldy #0
* jsr doext

 clc
 xce
 rep #$30
 mx %00

 pha
 pea $1000 ;type 1, application, auxID = 0
 ldx #$2003
 jsl $e10000
*        _GetNewID
 pla
* sta ourID

 pha
 pha
 pea 0
 pea $4000 ;want 16k
 pha  ;our user id
 pea $c018 ;locked, fixed, NO special memory, noCross
 pea 0 ;(if we use special memory, acos gets clobbered)
 pea 0 ;no fixed location
 ldx #$0902
 jsl $e10000
*        _NewHandle
 pla
 sta 0 ;get the handle (better not get an error)
 sta OurHandle
 pla
 sta 2
 sta OurHandle+2

 lda [0] ;deref the handle and put the address
 tax
 ldy #2
 lda [0],y
 sta In_Buf+4+2
 stx In_Buf+4

 lda #$4000 ;how big, 16k
 sta In_Buf+8

 mx %11
 sec
 xce

 jsr initPort

* ldx #5
*:oloop lda OutDefaults,x
* sta Out_Buf+4,x
* dex
* bpl :oloop

 jsr resetInBuf
 jsr resetOutBuf

 LDX #0
:LOOP LDA PORTINIT,X
 BEQ :DONE
 JSR OUT
 INX
 BRA :LOOP

:DONE
 CLC
 RTS

*-------------------------------------------------
* shutDown -- reset the port buffer to its old buffer size and
*             address, and kill the memory we allocated for the 16k
*             buffer which we used.
*
*             We do this for both the input and output buffers
*
* The port buffers aren't restored, instead the port is re-init'd
* before we through away the extra memory which we needed.  This works
* on the assumption that initport will reset our buffers
*-------------------------------

QUIT
* ldx #5 ;move 6 bytes
*:loop1 lda GetOutBuffer+4,x
* sta Out_Buf+4,x
* lda GetInBuffer+4,x
* sta In_Buf+4,x
* dex
* bpl :loop1
*
* jsr resetInBuf

 jsr initPort

 clc
 xce
 rep #$30
 mx %00

 lda OurHandle+2
 pha
 lda OurHandle
 pha
 ldx #$1002
 jsl $e10000
*        _DisposeHandle

 mx %11
 sec
 xce

:noInputBuffer
* LDA #>QUITSTR ;send the init string to the modem
* LDX #<QUITSTR
* LDY #0
* JSR SENDSTR
* JMP HANGUP

initPort
 LDX #CN ;setup modem port
 LDY #N0
 JMP DOINIT

*-------------------------------
resetOutBuf
 lda #<Out_Buf ;reset the output buffer
 ldx #>Out_Buf
 ldy #0
 jmp DOEXT

*-------------------------------
resetInBuf
 lda #<In_Buf ;reset the output buffer
 ldx #>In_Buf
 ldy #0
 jmp DOEXT

* input data
*-------------------------------
INP PHX  ;save x
 PHY

 LDX #CN
 LDY #N0
 LDA #1
 JSR DOSTATUS
 BCC INP2

 LDX #CN
 LDY #N0
 JSR DOREAD

 SEC
INP1 PLY  ;restore & return
 PLX
 RTS

INP2 LDA #0
 BRA INP1

* Check for carrier using Get_Port_Stat routine
*-------------------------------
M_CHKDCD PHX
 PHY

 LDA #<CARRLIST
 LDX #>CARRLIST
 LDY #0
 JSR DOEXT

 CLC
 LDA CARRBITS
 AND CDBYTE
 BEQ INP1
 SEC
:NOCARR BRA INP1

* output data
*-------------------------------

OUT PHX  ;save x
 PHY  ;save y
 PHA  ;save a

:OUT1 LDX #CN ;ready for send?
 LDY #N0
 LDA #0
 JSR DOSTATUS
 BCC :OUT1 ;nope

 PLA  ;get a
 LDX #CN
 LDY #N0
 JSR DOWRITE ;send it

 PLY  ;get y
 PLX  ;get x
 RTS

* init modem for ring
*-------------------------------

RESET JSR HANGUP

 STZ Carrier ;clear previous stuff
 STZ Protocol
 STZ Compression
 STZ Connect

 LDA #0 ;let modem reset
 JSR WAIT
 JSR WAIT

 JSR RAISEDTR

 LDY INITSPD ;set init speed
 JSR SETSPD

 LDA #0 ;slight delay (let modem do init)
 JSR WAIT
 JSR CLRBUFF

 LDA #>INITSTR ;send the init string to the modem
 LDX #<INITSTR
 LDY #0
 JSR SENDSTR

:RSET3 LDA #6
 STA COUNTLO
 STA COUNTHI

:RSET4 LDY #-1
:RSET5 DEY
 BNE :Result?

 DEC COUNTLO
 BNE :RSET4
 DEC COUNTHI
 BNE :RSET4
 BEQ RESET

:Result? JSR GetNumber
 BCC :RSET5
 BNE :RSET5

 STZ BYTCNT ;reset byte counter
 STZ BYTCNT+1
 STZ BYTCNT+2

 JSR CLRBUFF

 CLC
 RTS  ;return

* test for a ring and handle it
*-------------------------------
RING JSR GetNumber ;check for a char
 BCC :NoData ;nope...

 CMP #SM_OK ;is it a 'OK'? (numeric)
 BEQ :Ring1
 CMP #SM_Ring ;is it a 'ring'? (numeric)
 BEQ :Ring1
 CMP #SM_NoCar ;is it a 'no carrier'? (numeric)
 BNE :IsCnct? ;nope, check for connect messages
:Ring1 JMP :NoData ;yes, ignore it!

:Result JSR GetNumber

 BVS :IsCnct?
 BCC :NoData
 BCS :DropIt
*-------------------------------
:IsCnct? JSR RingHung

 CMP #Prot_None
 BCC :TstComp ;it's not 70 or greater
 STA Protocol ;save it so we can look at it in acos
 BCS :Result

:TstComp CMP #Comp_MNP5
 BCC :TstCarr ;is not 66 or greater
 STA Compression ;save it so we can look at it in ACOS
 BCS :Result

:TstCarr CMP #SM_Car03 ;Carrier message?
 BCC :TstConn ;No, test for connect message
 STA Carrier
 BCS :Result

:TstConn LDY Tbl_Conn
:TstCon1 DEY
 BMI :Result ;no more to check, so go back and wait
 CMP Tbl_Conn,Y ;is it a valid code?
 BNE :TstCon1 ;nope, keep checking

 STA Connect ;save it so we can look at it in ACOS
 DEY  ;reduce it one for setbaud

:RING3 JSR SETSPD ;set the correct speed

 LDY #5
:RING4 LDA #0 ;let carrier's settle
 JSR WAIT
 DEY
 BNE :RING4

:Connect JSR CLRBUFF
 SEC  ;we have a connection!
 RTS
:DropIt JSR RESET
:NoData CLC
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

* send ata to phone
*-------------------------------
ANSWER LDA #>ANSSTR
 LDX #<ANSSTR
 LDY #$80
 JMP SENDSTR

* set the rs-232 speed [speed offset in Y]
*
* 0 =   300 baud
* 1 =  1200 baud
* 2 =  2400 baud
* 3 =  4800 baud
* 4 =  9600 baud
* 5 = 19200 baud
* 6 = 38400 baud
*-------------------------------

SETSPD PHX
 PHY

 LDA Carrier ;no carrier speed so ignore it
 BEQ :setspd1 ;(but always set the acos baud rate, andy)

:FndCarr LDY Tbl_Carr
:FndCar1 DEY
 BEQ :setspd1 ;This had better NEVER happen
 CMP Tbl_Carr,Y ;is it a valid code?
 BNE :FndCar1 ;nope, keep checking

 DEY  ;reduce it one for callspd

 CPY #4
 BCC :setspd1

 PLY  ;get back original speed
 PHY

:setspd1 LDA #1 ;find caller speed (x300)
 STA CALLSPD
 CPY #0 ;at 300?
 BEQ :DO_BAUD ;yep

 ASL CALLSPD ;speed = speed * 2
:SETSPD2 ASL CALLSPD ;speed = speed * 2
 DEY
 BNE :SETSPD2 ;loop until correct speed found

:DO_BAUD PLA  ;get desired speed off stack
 ASL  ;shift in one for index
 TAY  ;transfer for Y for indexing
 LDA #PrtSpdL
 STA MODEMREG
 LDA PrtSpd,y
 STA MODEMREG
 INY
 LDA #PrtSpdH
 STA MODEMREG
 LDA PrtSpd,y
 STA MODEMREG

:DONE PLX
 RTS

*-------------------------------
* raise dtr
*-------------------------------

RAISEDTR phx
 phy

 LDA #0
 jsr GSDTR

 ply
 plx
 rts

* Get the two digit result code in one byte (Hex Format)
*-------------------------------
GetNumber lda #-1
 sta DecByte
:get1st jsr :GetByte ;get the first byte
 bvc :exit
 bcs :get1st
 sta DecByte ;and incase the next byte is a CR

:get2nd jsr :GetByte ;get the second byte
 bvc :get2nd
 bcs :exit

 ldy #10
:dec8a clc
 adc DecByte ; add the 10's digit, 10 times
 dey
 bne :dec8a
 sta DecByte

:getCR jsr INP
 bcc :getCR

:exit lda DecByte
 php
 cmp #SM_NoCar
 BNE :getDaOK
 STZ Protocol
 LDA #SM_Car03
 sta Carrier
 lda #SM_Con03

:getDaOK plp
 rts

* Flags on Exit:
* Overflow Carry  Condidtion
* -------- -----  ----------
*  Clear   Clear  No data recieved
*   Set    Clear  Number recieved
*   Set     Set   <CR> recieved
:GetByte JSR INP
 clv
 bcc :Done
 and #$7f
 cmp #Return
 beq :DatExit
 cmp #' '
 bcc :GetByte
 cmp #'0'
 bcc :GetByte
 cmp #'9'+1
 bcs :GetByte
 eor #'0'
 clc
:DatExit bit :Done
:Done rts

RingHung RTS

* Send string to modem
*
* A&X point to string
* Y is time for wait loop
*-------------------------------
SENDSTR STA PTR
 STX PTR+1

 TYA
 JSR WAIT

 LDY #-1
:Xmit2 INY
 LDA (PTR),Y ;get text
 BEQ :Xmit3 ;we are done

 JSR OUT ;send it
 BRA :Xmit2

 CLC
:Xmit3 RTS

*-------------------------------------------------
* Table of Speeds and other important stuff

DOINIT JMP SLTADR
DOREAD JMP SLTADR
DOWRITE JMP SLTADR
DOSTATUS JMP SLTADR
DOEXT JMP SLTADR

OurHandle ds 4

COUNTHI DB 0
COUNTLO DB 0

*-------------------------------------------------
PrtSpd DB 126,1,94,0,46,0,22,0,10,0,4,0,1,0 ;speeds 300-38400
*-------------------------------------------------
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
CARRLIST DB 3 ;parameter list for
 DB 6 ;detecting carrier drop
 DA 0
CARRBITS DA 0 ;carrier status here
*-------------------------------
DTRLIST DB 3 ;parameter list for
 DB $B ;setting DTR
 DA 0
DTRSTATE DA 0 ;bit 7 affects DTR
*-------------------------------
FlushInQ DB 2 ;parameter list for flushing input queue
 DB $14
 DA 0
*-------------------------------
Tbl_Conn DFB 8,SM_Con03,SM_Con12,SM_Con24,SM_Con48,SM_Con96,SM_Con19,SM_Con38
Tbl_Carr DFB 6,SM_Car03,SM_Car12,SM_Car24,SM_Car48,SM_Car96
DecByte hex 00
*-------------------------------------------------
* These get copied to Out_Buf

*OutDefaults
* adrl Buffer
* dw 3

*-------------------------------------------------
*GetOutBuffer
* hex 04
* hex 11
* dw 0 ;result
* ds 4 ;address
* dw 0 ;length

*-------------------------------------------------
Out_Buf hex 04 ;Parameters to set the
 hex 13 ;Output buffer
 da 0
 adrl Buffer ;Buffer it where
 dw 3 ;buffer 3 bytes

*-------------------------------------------------
*GetInBuffer
* hex 04
* hex 10
* dw 0 ;result
* ds 4 ;address
* dw 0 ;length

*-------------------------------------------------
In_Buf hex 04 ;Parameters to set the
 hex 12 ;Output buffer
 da 0
 ds 4 ;Buffer it where (modified later)
 dw $4000 ;buffer 16k

 DS $3b0-*+MODEM

 DS 11
Carrier DS 1
Protocol DS 1
Compression DS 1
Connect DS 1

*CDBYTE DB %00001000 ;mask DCD only (0=connected)
*
*ANSSTR ASC 'ATA'0D00
* DS $8-*+ANSSTR ;DON'T TOUCH
*
*QUITSTR ASC 'ATZ'0D00
* DS $8-*+QUITSTR ;DON'T TOUCH
*
*INITSTR ASC 'ATS0=1S2=128S95=44S36=5&C1&D2&K3&S0VEMW1'0D00
* DS $30-*+INITSTR ;DON'T TOUCH


