* GS Port Driver Bios - Slot #1
* written by Andy Nicholas on July 26, 1987
*-------------------------------

 rel
 dsk rel/gsport1

cr equ $0d
lf equ $0a

initstr equ $11d0
ansstr equ $11c0
cdbyte equ $11bf
Buffer equ $11a0

* setup for call
*-------------------------------

gsport1 ent

* Jump Table
*-------------------------------

 org $e00

 hex 10 ;serial card slot * 16
initspd hex 00 ;init speed for modem

callspd dfb 0 speed

bytcnt dfb 0,0,0

 jmp init
 jmp ringset
 jmp ring
 jmp answerRing
 jmp hangup
 jmp inp ;get a byte
 jmp out ;send a byte
 jmp getcarr ;caller there?
 jmp setspeed ;speed of port
 jmp raisedtr ;raise dtr

doinit jmp $c100
doread jmp $c100
dowrite jmp $c100
dostatus jmp $c100
doext jmp $c100

* init the serial port pascal locations
*-------------------------------

init lda $c10d ;get init address
 sta doinit+1
 lda $c10e ;get read address
 sta doread+1
 lda $c10f ;get write address
 sta dowrite+1
 lda $c110 ;get status address
 sta dostatus+1
 lda $c112
 sta doext+1

 rts

* input data
*-------------------------------

inp phx save ;x
 phy
 ldx #$c1 ;are we ready?
 ldy #$10
 lda #1
 jsr dostatus
 bcc inp2 ;nope, exit

 ldx #$c1 ;yes, read
 ldy #$10
 jsr doread

 sec
 ply
 plx restore ;& return
 rts

inp2 lda #0
 clc
 ply
 plx
 rts

* output data
*-------------------------------

out phx save ;x
 phy save ;y
 pha save ;a

out1 ldx #$c1 ;ready for send?
 ldy #$10
 lda #$00
 jsr dostatus
 bcc out1 ;nope

 pla get ;a
 ldx #$c1
 ldy #$10
 jsr dowrite ;send it

 ply get ;y
 plx get ;x
 rts

* init modem for ring
*-------------------------------

ringset jsr hangup

 lda #0 ;let modem reset
 jsr wait
 jsr wait

 lda #$00
 jsr gsdtr

 ldy initspd ;set init speed
 jsr setspeed

 lda #0 ;slight delay (let modem do init)
 jsr wait

 ldx #$FF
rset2 inx do ;pre-inc
 lda initstr,x ;get modem init string
 beq rset3 ;we are done

 jsr out ;output
 bra rset2 ;loop (Z-bit set after wait)

rset3 lda #6
 sta countlo
 sta counthi

rset4 ldy #$FF
rset5 dey
 beq decount

 jsr inp
 bcc rset5
 and #$7f
 cmp #'0' ;check for "0" (numeric)
 beq leave
 jmp rset5

decount dec countlo
 bne rset4
 dec counthi
 bne rset4
 jmp ringset

leave jsr inp ;grab the <cr> off the tail end of the "0"
 bcc leave

 jsr clearBuffer

 lda #0
 sta bytcnt ;reset byte counter
 sta bytcnt+1
 sta bytcnt+2
 clc
 rts  ;return

*-------------------------------
* test for a ring and handle it

ring jsr inp ;check for a char
 bcc noRing ;nope...

 and #$7f ;strip high
 cmp #'2' ;is it a 'ring'? (numeric)
 bne notRing ;nope, check for connect messages

********************************
grabCR jsr inp ;grab the <cr> off the tail end of the "2"
 bcc grabCR

answerRing jsr answer ;the phone rang, so send 'ATA'

 clc
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

 ldy #2 ;def = 2400 baud

 lda code ;get the first code char
 cmp #'1' ;must be a one
 bne noRing ;if not, then keep trying

 lda code+1 ;is it 2400?
 cmp #'0'
 beq ring3

 iny
 cmp #'1' ;is it 4800?
 beq ring3

 iny
 cmp #'2' ;is it 9600
 beq ring3

 iny
 cmp #'4' ;is it 19200?
 beq ring3
 jmp noRing

********************************
ring3 jsr setspeed ;set the correct speed

 ldy #5
ring4 lda #0 ;let carrier's settle
 jsr wait
 dey
 bne ring4

 jsr clearBuffer
 sec  ;we have a connection!
 rts

noRing clc
 rts

*-------------------------------
* clear the input buffer

clearBuffer
 lda #Flush_List
 ldx #>Flush_List
 ldy #0
 jmp doext

* set DTR on GS Serial Port, and hangup if needed
*-------------------------------

hangup lda #$80 ;blow 'em off (hangup)

gsdtr sta DTRstate

 lda #DTR_List
 ldx #>DTR_List
 ldy #0
 jmp doext

* wait routine
*-------------------------------

wait sec  ;from apple ][+ ref man - pg 147
wait2 pha
wait3 sbc #1
 bne wait3
 pla
 sbc #1
 bne wait2
 rts

* Check for carrier using Get_Port_Stat routine
*-------------------------------

getcarr phx
 phy

 lda #carrlist
 ldx #>carrlist
 ldy #0
 jsr doext

 lda carrbits
 and cdbyte
 beq nocarr
 sec
 ply
 plx
 rts

nocarr clc
 ply
 plx
 rts

* send ata to phone
*-------------------------------

answer ldx #$ff
answer2 inx
 lda ansstr,x ;get text
 beq answer3 ;we are done

 jsr out ;send it
 bra answer2

answer3 rts

* set the rs-232 speed [speed offset in Y]
*-------------------------------

setspeed phx
 phy

 lda #1 ;find caller speed (x300)
 sta callspd
 cpy #0 ;at 300?
 beq Do_Baud ;yep

 asl callspd ;speed = speed * 2
setspeed2 asl callspd ;speed = speed * 2
 dey
 bne setspeed2 ;loop until correct speed found

Do_Baud pla  ;get y-reg
 bne Try1200
 lda #<Baud300
 sta Baudread+1
 lda #>Baud300
 sta Baudread+2
 bra SetBaud

Try1200 cmp #1
 bne Try2400
 lda #<Baud1200
 sta Baudread+1
 lda #>Baud1200
 sta Baudread+2
 bra SetBaud

Try2400 cmp #2
 bne Try4800
 lda #<Baud2400
 sta Baudread+1
 lda #>Baud2400
 sta Baudread+2
 bra SetBaud

Try4800 cmp #3
 bne Try9600
 lda #<Baud4800
 sta Baudread+1
 lda #>Baud4800
 sta Baudread+2
 bra SetBaud

Try9600 cmp #4
 bne Try19200
 lda #<Baud9600
 sta Baudread+1
 lda #>Baud9600
 sta Baudread+2
 bra SetBaud

Try19200 lda #<Baud19200
 sta Baudread+1
 lda #>Baud19200
 sta Baudread+2

SetBaud ldx #$c1
 ldy #$10
 jsr doinit

 ldx #0
Baudread lda $ffff,x
 beq Fin_Init
 jsr out
 inx
 bra Baudread

Fin_Init ldx #0
Init_Loop lda Port_Init,x
 beq donebaud
 jsr out
 inx
 bra Init_Loop

donebaud lda #Out_Buf
 ldx #>Out_Buf
 ldy #0
 jsr doext

 plx
 rts

*-------------------------------
* raise dtr

raisedtr lda #0
 phx
 phy

 jsr gsdtr

 ply
 plx
 rts

* Table of Speeds and other important stuff
*-------------------------------

counthi db 0
countlo db 0

Baud300 hex 01
 asc '6B'
 hex 00 ;accept 300 Baud
Baud1200 hex 01
 asc '8B'
 hex 00 ;accept 1200 Baud
Baud2400 hex 01
 asc '10B'
 hex 00 ;accept 2400 Baud
Baud4800 hex 01
 asc '12B'
 hex 00 ;accept 4800 Baud
Baud9600 hex 01
 asc '14B'
 hex 00 ;accept 9600 Baud
Baud19200 hex 01
 asc '15b'
 hex 00 ;accept 19200 baud

Port_Init   ;
 hex 01
 asc '0D' ;8 bits
 hex 01
 asc '2P' ;no parity
 hex 01
 asc 'AD' ;auto-tabbing
 hex 01
 asc 'XD' ;no xoff recognition
 hex 01
 asc 'FD' ;no find keyboard
 hex 01
 asc 'CD' ;no column overflow
 hex 01
 asc 'ED' ;echo disabled
 hex 01
 asc 'MD' ;no lf masking
 hex 01
 asc 'BE' ;buffering enabled
 hex 01
 asc 'Z'
 hex 00 ;no more control characters

*-------------------------------

Out_Buf hex 04 ;Parameters to set the
 hex 13 ;Output buffer
 da 0
 adrl Buffer ;Buffer it where
 da 2 buffer

*-------------------------------

carrlist hex 03 ;Parameter list for
 hex 06 ;detecting carrier drop
 da 0
carrbits da 0 Carrier

*-------------------------------

DTR_List hex 03 ;Parameter list for
 hex 0b ;setting DTR
 da 0
DTRstate da 0 bit

*-------------------------------

Flush_List hex 02 ;parameter list for flushing input queue
 hex 14
 da 0

*-------------------------------

code ds 2
 asc 'GSPort1'


