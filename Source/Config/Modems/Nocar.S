*-------------------------------
* No Carrier Driver
*-------------------------------
* 3/18/88 AEN
*-------------------------------
 lst off

 rel
 dsk rel/nocar

cr equ $0d
lf equ $0a

data equ $c088
status equ $c089
command equ $c08a
control equ $c08b

initstr equ $11d0 ;location of init string
ansstr equ $11c0 ;location of auto-answer string
cdbyte equ $11bf ;location of carrier detect mask

nocar ent  ;(Start)
 org $e00

*-------------------------------
* jump table

slot dfb $20 ;serial card slot
initspd dfb 0
callspd dfb 0 ;speed of call

bytcnt dfb 0,0,0

 JMP init
 JMP ringset
 JMP ring
 JMP answer
 JMP hangup
 JMP inp
 JMP out
 JMP chkdcd
 jmp setspd
 jmp raisedtr
 jmp dummy
 jmp dummy

dummy rts
*-------------------------------
* init the serial card

init LDA #0 ;reset bytes
 LDX slot
 STA status,x ;reset uart
 STA command,x ;reset command

 clc
 txa
 adc #<data
 sta dataloc+1 ;make into absolute save
 rts

*-------------------------------
* setup for call

ringset JSR hangup
 LDA #%00001011 ;turn on DTR, RTS
 STA command,x

 sei

 LDY initspd ;set init speed
 JSR setspd

 LDA data,x ;clear data strobe

rset LDA #0 ;slight delay (let modem do init)
 JSR wait
 JSR wait

 JSR chkok ;is modem out there and ready?
 BCS rset2 ;yep

 LDX #0 ;print modem init string
 JSR prstr
 JMP rset

rset2 LDA #0
 STA bytcnt ;reset byte counter
 STA bytcnt+1
 STA bytcnt+2
 CLC
 RTS return

rset5 JMP ringset ;extend a branch

*-------------------------------
* scan for ring and handle it

ring LDA #5 ;make sure timer never triggers
 STA cdcount+2
 JSR inp ;check for a char
 BCC ring5 ;nope...

 AND #$7f ;strip high
 CMP #'3'
 BEQ rset5 ;no carrier

 LDY #0
 CMP #'1' ;connect 300
 BEQ ring3

 INY
 CMP #'5' ;connect 1200
 BEQ ring3

 INY
 CMP #'6' ;connect 2400
 BEQ ring3

 CMP #'2' ;check for ring
 CLC
 BNE ring5 ;nope, nothing

 LDA #0
 JSR wait ;slight delay
 JSR wait

answer LDX #ansstr
 JSR prstr ;answer the phone
 CLC
 RTS

ring3 JSR setspd ;set the correct speed

 LDY #5
ring4 LDA #0 ;let carrier's settle
 JSR wait
 DEY
 BNE ring4

 JSR inp ;gobble extra stuff coming in
 JSR inp

 LDA #-1 ;set cd status to connected
 STA cdstat
 SEC we ;have a connection!
ring5 RTS

*-------------------------------
* hangup phone

hangup LDX slot ;get offset
 LDA #0
 STA cdstat
 STA command,x ;hang up phone
 JSR wait
 CLC *** make
 RTS

*-------------------------------
* input data

inp STX save_y ;save X
 INC cdcount
 BNE inp2
 INC cdcount+1 ;count up tries
 BNE inp2 ;all is still ok

 DEC cdcount+2 ;count big stuff
 BNE inp2

 LDA #5 ;reset counter
 STA cdcount+2

 JSR chkok ;is modem out there?
 BCC inp2 ;nope, it isnt, must be user

 LDX #0 ;we have lost CD
 STX cdstat

inp2 LDX slot ;get offset
 LDA status,x ;get status
 AND #%00001000
 CLC
 BEQ inp3 ;no data

 LDA #-1
 STA cdstat ;reset status & counter
 LDA #0
 STA cdcount
 STA cdcount+1
 LDA #5
 STA cdcount+2

 LDA data,x ;get data
 CMP #28 ;kill connection?
 SEC
 BNE inp3 ;nope

 LDX #1
 STX cdcount+2 ;reset counter

inp3 LDX save_y ;restore & return
 RTS

*-------------------------------
* output data

out STX save_x ;save x
 DEC timecnt ;count down 1 section
 BNE out1

 INC bytcnt ;1 second gone by
 BIT bytcnt
 BVC out1

 LDX #0 ;reset seconds
 STX bytcnt

 INC bytcnt+1 ;1 minute gone by
 BIT bytcnt+1
 BVC out1

 LDX #0 ;reset minutes
 STX bytcnt+1

 INC bytcnt+2 ;1 hour gone by

out1 LDX slot

 PHA
out2 LDA status,x ;check status
 PHA
 AND #%00000100
 BEQ out3 ;no error, all is well

 LDA data,x
 CMP #28 ;was is loss of carrier?
 BNE out3 ;nope

 LDA #1 ;set count down for CD loss
 STA cdcount+2

out3 PLA
 AND #%00010000
 BEQ out2 ;loop until ready
 PLA

dataloc STA data ;output byte
 LDX save_x
 RTS

*-------------------------------
* check for carrier

chkdcd LDA cdstat
 PHA
 ASL
 PLA
 EOR #$ff
prstr2 RTS

*-------------------------------
* print control string to modem

prstr LDA initstr,x ;get data byte
 BEQ prstr2 ;did it work?

 INX
 JSR out ;output byte
 CMP #cr
 BNE prstr

 LDA #0 ;slight pause
 JSR wait
 BEQ prstr ;loop (z-bit always set)

*-------------------------------
* check for OK from question

chkok LDX #atstr ;send an AT
 JSR prstr

 LDY #250 ;check 250 times
chkok2 DEY count ;down
 CLC
 BEQ chkok3 ;no OK gotton

 LDA #40 ;delay slightly
 JSR wait
 JSR inp
 BCC chkok2

 CMP #'0' ;check for "0" for OK
 BNE chkok2
 LDA #80
 JSR wait
 JSR inp ;gobble EOL char
 SEC we ;have confirmation
chkok3 RTS

*-------------------------------
* set the rs-232 speed [speed offset in Y]

setspd STX save_x
 LDX slot ;get offset
 LDA speed,y ;get speed
 STA control,x ;set speed

 LDA #1 ;find caller speed (x300)
 STA callspd
 CPY #0 ;at 300?
 BEQ setspd3 ;yep

 ASL callspd ;speed = speed * 2
setspd2 ASL callspd ;speed = speed * 2
 DEY
 BNE setspd2 ;loop until correct speed found

setspd3 LDX save_x ;restore & return
 RTS

*-------------------------------
* turn on dtr/rts

raisedtr stx save_x
 ldx slot

 lda #%00001011 ;turn on DTR, RTS
 sta command,x
 sei

 ldx save_x
 rts

*-------------------------------
* wait routine

wait SEC from ;apple ][+ ref man - pg 147
wait2 PHA
wait3 SBC #1
 BNE wait3
 PLA
 SBC #1
 BNE wait2
 RTS

*-------------------------------
* available speeds

speed dfb %00010110 ;300
 dfb %00011000 ;1200
 dfb %00011010 ;2400
 dfb %00011100 ;4800
 dfb %00011110 ;9600
 dfb %00011111 ;19200

atstr EQU *-initstr
 asc 'AT'
 hex 0808
 asc '  '
 hex 08082800

timecnt dfb 0 ;1-second counter
cdstat dfb 0 ;carrier status
cdcount dfb 0,0,0 ;loss of cd counter
save_x dfb 0
save_y dfb 0

 asc 'Nocarrier'
