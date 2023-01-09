
*-------------------------------------------------
* USRobotics 2400 driver written by Andy Nicholas
* January 19, 1988
*
* History:
*
* May 1991, andy, changed to support interrupts
*-------------------------------------------------

 xc

* rel
* dsk rel/ssc

cr equ $0d
lf equ $0a

data equ $c088
status equ $c089
command equ $c08a
control equ $c08b

InitStr equ $11d0
ansstr equ $11c0
cdbyte equ $11bf

*-------------------------------------------------

ssc ent

 org $e00

*-------------------------------------------------
* jump table

slot hex 20 ;serial card slot*16
initspd hex 00

callspd dfb 0 ;speed of call

bytcnt dfb 0,0,0

 jmp init
 jmp ringset
 jmp ring
 jmp answer
 jmp hangup
 jmp inp
 jmp out
 jmp chkdcd
 jmp setspd
 jmp RaiseDTR
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

* setup for call
*-------------------------------

ringset ldx slot ;get offset

 lda #%00000000 ;kill DTR, RTS and interrupts
 sta command,x

 lda #0 ;let modem reset
 jsr wait
 jsr wait

 lda #%00001001 ;DTR on, RTS on, interrupts ON
 sta command,x

 ldy initspd ;set init speed
 jsr setspd

 jsr flush ;get rid of anything in the buffer

 lda #0 ;slight delay (let modem do init)
 jsr wait

 ldx #0
:loop lda #$80
 jsr wait
 lda InitStr,x ;get modem init string
 beq rset3
 jsr out ;output
 inx
 bne :loop

rset3
 ldx #6
 stx count

rset4 ldy #$FF
rset5 dey
 beq decount

 jsr inp
 bcc rset5
 and #$7f
 cmp #'0' ;check for "0" (OK) in numeric mode
 beq leave
 jmp rset5

decount
 dex
 bne rset4
 dec count
 bne rset4
 jmp ringset

leave jsr flush

 lda #0
 sta bytcnt ;reset byte counter
 sta bytcnt+1 ;is already reset
 sta bytcnt+2
 clc
 rts  ;return

*-------------------------------------------------
* scan for ring and handle it

ring jsr inp ;check for a char
 bcc noRing ;nope...

 and #$7f ;strip high
 jmp notRing
* cmp #'2' ;is it a 'ring'? (numeric)
* bne notRing ;nope, check for connect messages

********************************
*grabCR jsr inp ;grab the <cr> off the tail end of the "2"
* bcc grabCR

*answerRing jsr answer ;the phone rang, so send 'ATA'

noRing clc
 rts

********************************
notRing
 cmp #'1' ;is it a '1' or '10' or '11' or '12' or '14'?
 beq gotCode ;yes, save it
 cmp #'5' ;is it connect 1200?
 bne noRing ;nope

gotCode sta code

secondChar jsr inp ;second character will ALWAYS be there
 bcc secondChar

 and #$7f ;strip high
 cmp #cr ;but might be a <cr>
 bne multiCode

********************************
singleCode ldy #0 ;connect 300?
 lda code
 cmp #'1'
 beq ring3

 iny
 cmp #'5' ;connect 1200?
 beq ring3 ;nope, unknown code, keep checking
 jmp noRing

********************************
multiCode
 sta code+1

 lda code ;get the first code char
 cmp #'1' ;must be a one
 bne noRing ;if not, then keep trying

 ldx #rCodesEnd-rCodes-1
 lda code+1
:loop cmp rCodes,x
 beq :bingo
 dex
 bpl :loop
 jmp noRing

:bingo lda sCodes,x
 tay
ring3 jsr setspd ;set the correct speed

 ldy #5
ring4 lda #0 ;let carrier's settle
 jsr wait
 dey
 bne ring4

 jsr flush

 sec  ;we have a connection!
 rts

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

RaiseDTR
 stx save_x

 ldx slot ;get offset
 lda #%00001001 ;turn on DTR, RTS, interrupts ON
 sta command,x

 ldx save_x
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

*-------------------------------------------------
* global data area

code dw 0 ;2 byte code from modem
save_x dfb 0
count dfb $FF

head dfb 00 ;start and end at the same place
tail dfb 00

speed dfb %00010110 ;300
 dfb %00011000 ;1200
 dfb %00011010 ;2400
 dfb %00011100 ;4800
 dfb %00011110 ;9600
 dfb %00011111 ;19200

rCodes asc '0' ;2400
 asc '1' ;4800
 asc '2' ;9600
 asc '4' ;19200
 asc '5' ;1200/ARQ
 asc '6' ;2400/ARQ
 asc '7' ;9600/ARQ
rCodesEnd

sCodes dfb 2 ;2400
 dfb 3 ;4800
 dfb 4 ;9600
 dfb 5 ;19200
 dfb 1 ;1200/ARQ
 dfb 2 ;2400/ARQ
 dfb 4 ;9600/ARQ

buffer ds 256
 asc 'SSC/Interrupt/AutoAnswer'


