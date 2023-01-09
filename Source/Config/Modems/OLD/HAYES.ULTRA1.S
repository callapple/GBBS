 TTL 'Hayes Ultra - GS port driver'
 PAG

*-------------------------------
* GS Port Driver Bios
* written by Andy Nicholas on July 26, 1987
*-------------------------------
 XC
 XC  ;uses 65816 code

SLOT KBD 'Assemble for what slot (1,2)'
N0 = SLOT*16
CN = SLOT!$C0
SLTADR = SLOT!$C0*256
INTREG = $C039

 DO SLOT/2
CMDREG = $C038
DATAREG = $C03A
 ELSE
CMDREG = $C039
DATAREG = $C03B
 FIN
* Equates
*-------------------------------

VIDCOUT = $0906
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
Escape = 43


* Jump Table
*-------------------------------
 ORG $0E00
MODEM
 DB N0 ;serial card slot
MDMSPEED
INITSPD DB 5 ;initialize speed
CALLSPD DB 0 ;speed of call

BYTCNT DB 0,0,0

MDMINIT JMP INIT
MDMRSET JMP RESET
MDMRING JMP RING
MDMANS JMP ANSRING
MDMHANG JMP HANGUP
MDMIN JMP INP
MDMOUT JMP OUT
MDMDCD JMP M_CHKDCD
MDMSSPD JMP SETSPD
MDMDTR JMP RAISEDTR ;raise dtr
MDMCBUF JMP CLR_BUFF
MDMQUIT JMP QUIT

*DOINIT JMP SLTADR
*DOREAD JMP SLTADR
*DOWRITE JMP SLTADR
*DOSTATUS JMP SLTADR
*DOEXT JMP SLTADR

* clear the input buffer
*-------------------------------
CLR_BUFF STZ BufS
 STZ BufE
 RTS

* Hang up the modem if needed
*-------------------------------
HANGUP LDA #%11100000
RAISEDTR LDY #$05
 JMP WRITEREG

* init the serial port pascal locations
*-------------------------------
INIT SEI

 STZ BufS
 STZ BufE
 JSR MLI
 DB ALLOC_INT
 DA Alloc_Parms

 LDA CMDREG
 LDX #$00
:loop LDA PortTbl,x
 BMI :Init1
 STA CMDREG
 INX
 LDA PortTbl,x
 STA CMDREG
 INX
 BRA :loop

:Init1 CLI
 RTS

*INIT LDA SLTADR+$D ;get init address
* STA DOINIT+1
* LDA SLTADR+$E ;get read address
* STA DOREAD+1
* LDA SLTADR+$F ;get write address
* STA DOWRITE+1
* LDA SLTADR+$10 ;get status address
* STA DOSTATUS+1
* LDA SLTADR+$12
* STA DOEXT+1
*
* LDX #CN ;setup modem port
* LDY #N0
* JSR DOINIT
*
* LDA #<PORTINIT ;point to port init string
* LDX #>PORTINIT
* LDY #$0
* JMP XmitStr ;send it!

* Handle an interrupt if it's ours
*-------------------------------
Int_Hndl CLD  ;it's a valid handler

:GetInt LDY #3 ;we want register 3
 STY INTREG ;tell it which register we want
 LDA INTREG ;get the register status
 TAX
 AND #%00000100 ;is there a RX or EXT int pending?
 BEQ :NotOurs

:RxInt LDY #0 ;RR0
 JSR READREG
 AND #%00000001
 BEQ :GetInt

 LDY #1
 JSR READREG
 TAX
 AND #%01110000
 BEQ :GOOD

 TXA
 AND #%01000000 ;test for framing error
 BEQ :Latched

 LDA DATAREG ;eat the bad data
 BRA :RxInt ;any more data?

:Latched LDY #0 ;WR0
 LDA #%00110000 ;issue error reset command
 JSR WRITEREG
 BRA :RxInt

:GOOD LDA DATAREG
 LDX BufE
 STA Buffer,x
 INC BufE
 LDX BufS
 CPX BufE
 BNE :RxInt
 DEC BufE
 BRA :RxInt

:Ours CLC
 RTS

:NotOurs SEC
 RTS

* Reset modem before quitting ACOS
*-------------------------------
QUIT LDA #%01101010 ;raise DTR
 JSR RAISEDTR

 LDY INITSPD ;set init speed
 JSR SETSPD

 LDA #<QUITSTR
 LDX #>QUITSTR
 LDY #$80
 JSR XmitStr

 JMP HANGUP ;drop DTR

* input data
*-------------------------------
INP LDA CMDREG
 AND #%00000001 ;is there a character available?
 BEQ :nodata
 LDA DATAREG
 SEC
 RTS
:nodata CLC
 RTS

* output data
*-------------------------------

OUT PHA  ;save a

:OUT1 LDA CMDREG
 AND #%00000100 ;is the TX buffer empty?
 BEQ :OUT1 ;nope, wait

:OUT2 LDA CMDREG
 AND HSMASK ;is modem able to recieve?
 BEQ :OUT2

 PLA  ;get back data
 STA DATAREG ;and send it
 RTS

* init modem for ring
*-------------------------------

RESET JSR HANGUP


:Reset1 STZ Carrier ;clear previous stuff
 STZ Protocol
 STZ Compression
 STZ Connect

 LDA #0 ;let modem reset
 JSR WAIT
 JSR WAIT

 LDA #%01101010 ;raise DTR
 JSR RAISEDTR

 LDY INITSPD ;set init speed
 JSR SETSPD

 LDA #<INITSTR ;point to init string
 LDX #>INITSTR
 LDY #0
 JSR XmitStr ;transmit init string

 LDA #6
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

 JSR CLR_BUFF

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
 BCC :Result
* BCC :NoData
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

:Connect JSR CLR_BUFF
 SEC  ;we have a connection!
 RTS
:DropIt JSR RESET
:NoData CLC
 RTS

* Check for carrier using Get_Port_Stat routine
*-------------------------------
M_CHKDCD LDA CMDREG
 AND CDMASK ;is carrier there?
 CLC
 BEQ :NOCARR ;Nope, so return with carry clear
 SEC
:NOCARR RTS

* send ata to phone
*-------------------------------
ANSRING JSR ANSWER ;the phone rang so send answer string
 CLC
 RTS

ANSWER LDA #<ANSSTR ;point to init string
 LDX #>ANSSTR
 LDY #$80
 JMP XmitStr ;transmit init string

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
 BEQ :DO_BAUD

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
 PHY
 LDA PrtSpd,y
 LDY #PrtSpdL
 JSR WRITEREG
 PLY
 INY
 LDA PrtSpd,y
 LDY #PrtSpdH
 JSR WRITEREG

:DONE PLX
 RTS

* Send string to modem
*
* A&X point to string
* Y is time for wait loop
*-------------------------------
XmitStr STA PTR
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

:getCR jsr :GetData
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
:GetByte JSR :GetData
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

:GetData jsr INP
 bcc :GD_Exit
 php
 bit DeBug?
 BPL :GD_Done

 pha
 phx
 phy
 cmp #Return
 bne :Getshow
 lda #' '
:Getshow JSR VIDCOUT
 ply
 plx
 pla
:GD_Done PLP
:GD_Exit RTS

RingHung RTS

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

* write to a SCC Register (Y=Reg to write, A=Data to Write)
*-------------------------------
WRITEREG STY CMDREG
 STA CMDREG
 RTS
* Read a SCC Register (Y=Reg to read, A=Data read)
*-------------------------------
READREG STY CMDREG
 LDA CMDREG
 RTS

* Table of Speeds and other important stuff
*-------------------------------
COUNTHI DB 0
COUNTLO DB 0
*-------------------------------
PrtSpd DB 126,1,94,0,46,0,22,0,10,0,4,0,1,0 ;speeds 300-38400
*-------------------------------
PortTbl DFB #$09,#%01000010 ;Chanel B Reset (Optional)
 DFB #$04,#%01000100 ;x16clk, 1 stop bit, no parity
 DFB #$03,#%11000000 ;8 data bits, reviever disabled
 DFB #$05,#%01100010 ;DTR High, 8 data bits, RTS off, NO SDLC
 DFB #$0b,#%01010000 ;clocks based on BRG
 DFB #$0e,#%00000000 ;null cmd, no loopback
 DFB #$0e,#%00000001 ;enable BR gen.
 DFB #$03,#%11000001 ;enable Rx
 DFB #$05,#%01101010 ;enable Tx
 DFB #$01,#%00010000 ;allow int on Rx only
 DFB #$09,#%00001010 ;reenable master interrupt
 DFB #$FF ;we are done!
*-------------------------------
Alloc_Parms DB 02
 ds 0 ;priority
 da Int_Hndl
*-------------------------------
Tbl_Conn DFB 8,SM_Con03,SM_Con12,SM_Con24,SM_Con48,SM_Con96,SM_Con19,SM_Con38
Tbl_Carr DFB 6,SM_Car03,SM_Car12,SM_Car24,SM_Car48,SM_Car96
DecByte hex 00
DeBug? hex 80

BufS ds 1
BufE ds 1
Buffer ds 128

 DS $3BA-*+MODEM

Carrier DS 1
Protocol DS 1
Compression DS 1
Connect DS 1


*These may need to be reversed...
HSMASK DB %00001000 ;mask for hardware handshake
CDMASK DB %00100000 ;mask DCD only (0=connected)

ANSSTR ASC 'ATA'0D00
 DS $8-*+ANSSTR ;DON'T TOUCH

QUITSTR ASC 'ATZ'0D00
 DS $8-*+QUITSTR ;DON'T TOUCH

INITSTR ASC 'ATS0=1S2=128&C1&D2&K3&S0VEM'0D00
 DS $30-*+INITSTR ;DON'T TOUCH


