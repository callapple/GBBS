*-------------------------------------------------
* Super Serial Card (SSC) Driver
* January 19, 1988
*
* History:
*
* May 1991, andy, changed to support interrupts
* Memorial Day 1991, andy, support hayes ultra
*-------------------------------------------------

 lst off
 xc

 rel
 dsk rel/ssc

cr equ $0d
lf equ $0a

data equ $c088
status equ $c089
command equ $c08a
control equ $c08b

INITSTR equ $11d0 ;uncomment these
ansstr equ $11c0
cdbyte equ $11bf

*-------------------------------------------------

VIDCOUT = $0906

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

ssc ent

 org $e00
modem

*-------------------------------------------------
* jump table

slot hex 20 ;serial card slot*16
INITSPD hex 00

callspd dfb 0 ;speed of call

BYTCNT dfb 0,0,0

 jmp init
 jmp reset
 jmp ring
 jmp answer
 jmp hangup
 jmp inp
 jmp out
 jmp chkdcd
 jmp setspd
 jmp raisedtr
 jmp flush
 jmp shutDown

*-------------------------------------------------
* init the serial card -- I hope this is only ever called once

init lda #0 ;reset bytes
 ldx slot
 sta status,x ;reset uart
 sta command,x ;reset command

 clc
 txa
 adc #<data
 sta dataloc+1 ;make into absolute save

 lda #0
 sta head ;reset the head and tail pointers
 sta tail

 jsr $bf00 ;alloc_interrupt
 dfb $40
 da allocParms

 lda allocParms+1
 sta deAllocParms+1

 cli  ;turn ints on
 rts

allocParms dfb 2
 dfb 0
 da int

*-------------------------------------------------
* shutDown -- shut the SSC down
*
* This will disable interrupts, but not drop carrier which should
* be done explicitly with the hangup routine.  Shutdown just makes
* it "safe" to exit.
*-------------------------------------------------

shutDown
 ldx slot
* lda #%00000000 ;DTS off, RTS off, interrupts OFF
 lda #%00001011 ;DTR on, RTS on, interrupts OFF
 sta command,x

 jsr $bf00
 dfb $41
 da deAllocParms
 rts

deAllocParms dfb 1
 dfb 0

*-------------------------------
* init modem for ring

reset JSR hangup

 STZ Carrier ;clear previous stuff
 STZ Protocol
 STZ Compression
 STZ Connect

 LDA #0 ;let modem reset
 JSR wait
 JSR wait

 JSR raisedtr

 LDY INITSPD ;set init speed
 JSR setspd

 LDA #0 ;slight delay (let modem do init)
 JSR wait

 LDX #-1
:RSET2 INX  ;do pre-inc
 LDA INITSTR,X ;get modem init string
 BEQ :RSET3 ;we are done

 JSR out ;output
 BRA :RSET2 ;loop (Z-bit set after wait)

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
 BEQ reset

:Result? JSR GetNumber
 BCC :RSET5
 BNE :RSET5

 lda #0
 sta BYTCNT ;reset byte counter
 sta BYTCNT+1
 sta BYTCNT+2

 JSR flush

 CLC
 RTS  ;return

* test for a ring and handle it
*-------------------------------
ring JSR GetNumber ;check for a char
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

:RING3 JSR setspd ;set the correct speed

 LDY #5
:RING4 LDA #0 ;let carrier's settle
 JSR wait
 DEY
 BNE :RING4

:Connect JSR flush
 SEC  ;we have a connection!
 RTS
:DropIt JSR reset
:NoData CLC
 RTS

*-------------------------------------------------
* send ata to phone

answer ldx #0
answer2 lda ansstr,x ;get text
 beq answer3 ;we are done

 jsr out ;send it

 lda #$80
 jsr wait

 inx
 bne answer2 ;loop

answer3 rts

*-------------------------------------------------
* hangup phone

hangup ldx slot ;get offset
 lda #0
 sta command,x ;hang up phone
 rts

*-------------------------------------------------
* int -- someone hit us with an interrupt
*        service it or pass it along
*
*        interrupts are disabled when they hit this routine
*
* registers don't need to be preserved by this routine
*
* And, believe it or not, reading the status register CLEARS the
* interrupt status flag on the 6551.  Augh!
*-------------------------------------------------

int
 cld  ;needed for all ProDOS interrupt handlers

 ldx slot
 lda status,x ;do we have data waiting, or are we interrupting?
 and #%10001000
 bne :data
 sec
 rts  ;otherwise, it wasn't our interrupt

*-------------------------------------------------

:loop ldx slot ;check for another character's arrival, just
 lda status,x ;in case
 and #%10001000
 beq :noError

:data and #%00001000
 beq :error ;if we were interrupting, but there's no character
 lda data,x ;waiting, then something screwed up, so leave

 ldx head
 sta buffer,x ;save our character at the head
 inx  ;next pos

 cpx tail
 beq :loop ;if it will, then don't move the head
 stx head ;if it won't, then keep moving the head up
 jmp :loop

*-------------------------------------------------
:error lda status,x ;Read status twice in a row to clear the interrupt
 lda status,x ;pending flag

:noError clc
 rts

*-------------------------------------------------
* inp -- get a character from the buffer, maybe
*        SEC if we got a char in (A)
*        CLC if not
*-------------------------------------------------

inp stx save_x

 ldx tail
 cpx head
 beq :bad ;if they are the same, nothing in the buffer

 lda buffer,x ;get the byte first, then bump up our tail pointer
 inc tail ;point to potential next character

:good ldx save_x
 sec
 rts

:bad lda #0
 ldx save_x
 clc
 rts

*-------------------------------------------------
* output data

out
 pha
 stx save_x

out2 ldx slot
 lda status,x ;check status
 tax
 and #%00001000
 beq :noIncoming

 php
 sei
 jsr int
 plp
 jmp out2

:noIncoming
 txa
 and #%00010000
 beq out2 ;loop until ready
 pla

dataloc sta data ;self modified
 ldx save_x
 rts

*-------------------------------------------------
* flush -- (A) is destroyed, all regs preserved

flush php
 sei
 lda #0
 sta head
 sta tail
 plp
 rts

*-------------------------------------------------
* check for carrier

chkdcd pha
 stx save_x

:loop ldx slot ;get offset
 lda status,x
 tax
 and #%00001000
 beq :noIncoming

 php
 sei
 jsr int
 plp
 jmp :loop

:noIncoming
 txa
 and cdbyte ;check carrier
 clc
 bne chkdcd2

 sec
chkdcd2 pla  ;restore all & return
 ldx save_x
 rts

*-------------------------------------------------
* set the rs-232 speed/speed in Y reg

setspd
 stx save_x

 ldx slot ;get offset
 lda speed,y ;get speed
 sta control,x ;set speed

 lda #1 ;find caller speed (x300)
 sta callspd
 cpy #0 ;at 300?
 beq setspd3 ;yep

 asl callspd ;speed = speed * 2
setspd2 asl callspd ;speed = speed * 2
 dey
 bne setspd2 ;loop until correct speed found

setspd3
 ldx save_x
 rts

*-------------------------------------------------
* turn on dtr/rts

raisedtr
 ldx slot ;get offset
 lda #%00001001 ;turn on DTR, RTS, interrupts ON
 sta command,x
 rts

*-------------------------------------------------
* wait routine

wait sec
wait2 pha
wait3 sbc #1
 bne wait3
 pla
 sbc #1
 bne wait2
 rts

*-------------------------------
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

:GetData jsr inp
RingHung RTS

*-------------------------------
* Table of Speeds and other important stuff

save_x dfb 0

head dfb 00 ;start and end at the same place
tail dfb 00

speed dfb %00010110 ;300
 dfb %00011000 ;1200
 dfb %00011010 ;2400
 dfb %00011100 ;4800
 dfb %00011110 ;9600
 dfb %00011111 ;19200

COUNTHI DB 0
COUNTLO DB 0

TmpField ds 4
Tbl_Conn DFB 7,SM_Con03,SM_Con12,SM_Con24,SM_Con48,SM_Con96,SM_Con19
Tbl_Carr DFB 6,SM_Car03,SM_Car12,SM_Car24,SM_Car48,SM_Car96
DecByte hex 00

buffer ds 256

 DS $3B0-*+modem

 DS 11
Carrier DS 1
Protocol DS 1
Compression DS 1
Connect DS 1

*CDBYTE DB %00001000 ;mask DCD only (0=connected)
*
*ANSSTR ASC 'ATA'0D00
* DS $10-*+ANSSTR ;DON'T TOUCH
*
*INITSTR ASC 'ATS0=1S2=128S95=44&C1&D2&K3&S0VEMW1'0D00
* DS $30-*+INITSTR ;DON'T TOUCH
