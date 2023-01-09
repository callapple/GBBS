*--------------------------
* Internal - Apple Cat 212
*--------------------------
* Date 12/09/86
*--------------------------
 lst off

 rel
 dsk rel/cat212

swbyt EQU $c080
byt212 EQU $c080
squbyt EQU $c081
shbyt EQU $c082
indata EQU $c08b
spdbyt EQU $c08b
acbyte EQU $c08d
xmtbyt EQU $c08d
outdat EQU $c08e
status1 EQU $c08f
devbyt EQU $c08f

cat212 ent

 org $e00

*-------------------------------
* jump table

slot dfb $20 ;serial card slot
initspd dfb 0 ;initialize speed
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
 jmp dummy ;raise dtr
 jmp dummy ;clear buffer
 jmp dummy ;quit

dummy rts

*-------------------------------
* init the modem card

init SEI
 LDX slot ;get slot offset
 LDY #0
init2 LDA initbyt,y ;init all 16 bytes
 STA $c080,x
 INX
 INY
 CPY #$10
 BNE init2
 RTS

*-------------------------------
* setup for call

ringset LDA #0 ;reset time-on
 STA bytcnt
 STA bytcnt+1
 STA bytcnt+2
 STA carwait ;reset wait flag
 TAY  ;set 300 baud
 JMP setspd

*-------------------------------
* scan for ring and handle it

ring LDX slot ;get offset
 BIT carwait ;do they want manual-answer?
 BMI ring2a ;yep

 LDA acbyte,x
 AND #%00000001
 BEQ ring4 ;nothing

ring2 LDA acbyte,x ;wait for ring to clear
 AND #%00000001
 BNE ring2

ring2a LDA #%00000010 ;pick up phone
 STA shbyt,x

 LDA #80 ;setup carrier wait time
 STA carwait

 LDA #%10000001 ;disable 212 mode
 STA squbyt,x

 LDA #128 ;wait
 JSR wait

 LDA #%00000001 ;enable 212 mode
 STA squbyt,x

 LDA #60 ;wait for things to settle
 JSR wait

ring3 LDA #0 ;do big wait...
 JSR wait

 LDA swbyt,x ;do we have carrier?
 AND #%00100000
 BNE ring5 ;yep

 LDA acbyte,x ;do we have 212 carrier
 AND #%00000100
 BNE ring6 ;yep

 DEC carwait ;loop until count is done
 BNE ring3

 JSR hangup
ring4 CLC  ;nothing happened
 RTS

ring5 LDA #%00010000 ;reset xmtbyt
 STA xmtbyt,x
 STA xmtdata
 LDA #%10000001 ;disable 212 card
 STA squbyt,x
 LDA #%00000000 ;send uart to 103 board
 STA devbyt,x
 JMP ring7 ;finish connect

ring6 LDA #%00000101 ;reset 212 card
 STA byt212,x
 LDA #%00000001 ;re-enable 212 card
 STA squbyt,x
 LDA #%00001010 ;send uart to 212 card
 STA devbyt,x
 LDA #%00011111 ;reset xmtbyt
 STA xmtbyt,x
 STA xmtdata
 LDY #1 ;set speed to 1200
 JSR setspd

ring7 LDA #-1 ;reset carrier timing
 STA carwait
 SEC
 LDA #0 ;do delay last
 JMP wait

*-------------------------------
* send ata

answer LDA #-1 ;signal we want manual-answer
 STA carwait
 RTS

*-------------------------------
* hangup phone

hangup LDX slot ;get offset
 LDA #%00011111
 STA xmtbyt,x ;turn off 103 carrier
 LDA #%10000001
 STA squbyt,x ;turn off 212 carrier
 LDA #0
 STA shbyt,x ;hang up phone
 RTS

*-------------------------------
* input data

inp STX save_x ;save X
 LDX slot ;get offset
 LDA status1,x ;get status
 AND #%00001000
 CLC
 BEQ inp2 ;no data

 LDA xmtdata ;reset char ready byte
 STA xmtbyt,x

 LDA indata,x ;get data
 SEC
inp2 LDX save_x ;restore & return
 RTS

*-------------------------------
* output data

out STX save_x ;save x
 DEC timecnt ;count down bytes per second
 BNE out1 ;not a seconds worth yet

 PHA
 LDA callspd ;reset counter
 ASL
 ASL
 ASL  ;time count = base.rate * 32
 ASL
 ASL
 STA timecnt
 PLA

 INC bytcnt ;seconds - at 64 yet?
 BIT bytcnt
 BVC out1 ;nope

 LDX #0 ;reset seconds
 STX bytcnt

 INC bytcnt+1 ;minutes - at 64 yet?
 BIT bytcnt+1
 BVC out1 ;nope

 LDX #0 ;reset minutes
 STX bytcnt+1

 INC bytcnt+2 ;inc hours

out1 LDX slot

 PHA
out2 LDA status1,x ;check status
 AND #%00010000
 BEQ out2 ;loop until ready
 PLA

 STA outdat,x ;output byte
 LDX save_x
 RTS

*-------------------------------
* check for carrier

chkdcd STX save_x ;dont kill any reg's
 PHA

 LDA carwait ;do we have carrier?
 BEQ chkdcd3 ;nope

 LDX slot
 LDA callspd ;check calling speed
 CMP #4 ;at 1200 baud?
 BEQ dcd212 ;yep

 LDA swbyt,x ;check carrier
 AND #%00100000
 BEQ chkdcd2 ;no carrier

chkdcd1 LDA #-1 ;buffer carrier detect
 STA carwait
 SEC
 BCS chkdcd4 ;use return routine

dcd212 LDA acbyte,x ;check 212 carrier
 AND #%00000100
 BNE chkdcd1 ;all is well

chkdcd2 DEC carwait ;count down
chkdcd3 CLC
chkdcd4 PLA  ;restore all & return
 LDX save_x
 RTS

*-------------------------------
* set the rs232 speed

setspd STX save_x
 LDX slot ;get offset
 LDA speed,y ;get speed
 STA spdbyt,x ;set speed

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
* wait routine

wait SEC  ;from apple ][+ ref man - pg 147
wait2 PHA
wait3 SBC #1
 BNE wait3
 PLA
 SBC #1
 BNE wait2
 RTS

*-------------------------------

speed dfb %00100010,%00000000 ;handle 300, 1200

save_x dfb 0

timecnt dfb 0
carwait dfb 0
xmtdata dfb 0

initbyt dfb $04,$81,$00,$06,$04,$80,$00,$06
 dfb $00,$64,$07,$22,$05,$1f,$00,$00

 asc 'Cat212'
