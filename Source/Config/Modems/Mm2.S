*--------------------------
*Internal Micromodem ][ //e
*--------------------------
* Date 12/09/86
*--------------------------

 lst off

 rel
 dsk rel/mm2

data EQU $c087
status EQU $c086
cr1 EQU $c086
ringin EQU $c085
cr2 EQU $c085
cr3 EQU $c083

mm2 ent

 org $e00

*-------------------------------
* jump table

slot dfb $20 ;serial card slot
 dfb 0 ;transmit / receive
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

init sei
 LDX slot ;get slot offset
 LDA %00000000 ;reset tone/speaker
 STA cr3,x
 RTS

*-------------------------------
* setup for call

ringset LDA #0 ;reset time-on
 STA bytcnt
 STA bytcnt+1
 STA bytcnt+2
 STA carwait ;reset wait flag
 TAY set ;300 baud
 JMP setspd

*-------------------------------
* scna for ring and handle it

ring LDX slot ;get offset
 BIT carwait ;do they want manual-answer?
 BMI ring2a ;yep

 LDA ringin,x ;check for ring
 AND %10000000
 BNE ring4 ;nothing

ring2 LDA ringin,x ;wait for ring to clear
 AND %10000000
 BEQ ring2

ring2a LDA %00000011 ;reset uart
 STA cr1,x
 LDA %00010101 ;set for 8n1
 STA cr1,x

 LDA %00000000 ;reset modem
 STA cr2,x
 LDA %10001011 ;pick up phone [enable carrier]
 STA cr2,x

 LDA #$50 ;setup carrier wait time
 STA carwait

 LDA #$3c ;wait for things to settle
 JSR wait

ring3 LDA #0 ;do big wait...
 JSR wait

 LDA data,x
 LDA status,x ;reset carrier flag
 LDA status,x ;do we have carrier?
 AND %00000100
 BEQ ring5 ;yep

 DEC carwait ;loop until count is done
 BNE ring3

 JSR hangup
ring4 CLC  ;nothing happened
 RTS

ring5 LDA #-1 ;reset carrier timing
 STA carwait
 SEC
 RTS

*-------------------------------
* send ata to phone

answer LDA #-1 ;signal we want manual-answer
 STA carwait
 RTS

*-------------------------------
* hangup phone

hangup LDX slot ;get offset
 LDA %00000001
 STA cr2,x ;hang up phone
 RTS

*-------------------------------
* input data

inp STX save_x ;save X
 LDX slot ;get offset
 LDA status,x ;get status
 AND %00000001
 CLC
 BEQ inp2 ;no data

 LDA data,x ;get data
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
out2 LDA status,x ;check status
 AND %00000110
 BEQ out2 ;loop until ready
 PLA

 STA data,x ;output byte
 LDX save_x
 RTS

*-------------------------------
* check for carrier

chkdcd STX save_x ;dont kill any reg's
 PHA

 LDX slot
 LDA status,x ;reset carrier flag
 LDA status,x ;check carrier
 AND %00000100
 CLC
 BNE chkdcd2 ;opps, no carrier

 SEC  ;sec = we have carrier
chkdcd2 PLA  ;restore & return
 LDX save_x
 RTS

*-------------------------------
* set the rs-232 speed [speed offset in Y]

setspd LDA #1 ;find caller speed (x300)
 STA callspd
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
* available speeds

save_x dfb 0

timecnt dfb 0
carwait dfb 0

 asc 'MM2'
