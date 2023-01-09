*-------------------------------
* Single Speed External
*-------------------------------
* 3/19/88 Andrew E. Nicholas
*-------------------------------
 lst off

 rel
 dsk rel/singlespd

cr equ $0d
lf equ $0a

data equ $c088
status equ $c089
command equ $c08a
control equ $c08b

initstr equ $11d0
ansstr equ $11c0
cdbyte equ $11bf

singlespd ent  ;(Start)
 org $e00

*-------------------------------
* jump table

slot dfb $20 ;serial card slot
initspd dfb 0 ;transmit / receive
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

init LDA #0 ;reset
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

ringset LDX slot ;get offset
 LDA #%00001011 ;turn on DTR, RTS
 STA command,x

 sei  ;disable ints

 LDY initspd ;set init speed
 JSR setspd

 LDA data,x ;clear data strobe

 LDA #0 ;long delay
 JSR wait
 jsr wait

 LDX #-1 ;start at -1
rset2 INX  ;do pre-inc
 lda #$80
 jsr wait
 LDA initstr,x ;get modem init string
 BEQ rset3 ;we are done
 jmp rset2

rset3 lda #6
 sta countlo
 sta counthi

rset4 ldy #$FF
rset5 dey
 beq decount

 jsr inp
 bcc rset5
 and #$7f
 cmp #'K' ;check for "OK"
 beq leave
 jmp rset5

decount dec countlo
 bne rset4
 dec counthi
 bne rset4
 jmp ringset

leave lda #0
 sta bytcnt ;reset byte counter
 sta bytcnt+1
 sta bytcnt+2
 clc
 rts  ;return

*-------------------------------
* scan for ring and handle it

ring LDX slot ;get offset
 LDA status,x
 AND cdbyte ;strip out CD byte
 CLC
 BNE ring3 ;nothing

 SEC  ;we have a connection
 LDX #5
ring2 LDA #0 ;delay before going online
 JSR wait
 DEX
 BNE ring2
 JSR inp ;gobble extra
 SEC

ring3 RTS

*-------------------------------
* send ata to phone

answer LDX #0
answer2 LDA ansstr,x ;get text
 BEQ answer3 ;we are donw

 JSR out ;send it

 lda #$80 ;delay a little
 jsr wait

 INX
 BNE answer2 ;loop

answer3 RTS

*-------------------------------
* hangup phone

hangup LDX slot ;get offset
 LDA #0
 STA command,x ;hang up phone
 RTS

*-------------------------------
* input data

inp STX save_x ;save X
 LDX slot ;get offset
 LDA status,x ;get status
 AND #%00001000
 CLC
 BEQ inp2 ;no data

 LDA data,x
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
 AND #%00010000
 BEQ out2 ;loop until ready
 PLA

dataloc STA data ;self-modified
 LDX save_x
 RTS

*-------------------------------
* check for carrier sec = we have carrier

chkdcd STX save_x ;dont kill any reg's
 PHA

 LDX slot ;get offset
 LDA status,x
 AND cdbyte ;check carrier
 CLC
 BNE chkdcd2

 SEC
chkdcd2 PLA restore ;all & return
 LDX save_x
 RTS

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
 sei  ;re-disable

 ldx save_x
 rts

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

speed dfb %00010110 ;300
 dfb %00011000 ;1200
 dfb %00011010 ;2400
 dfb %00011100 ;4800
 dfb %00011110 ;9600
 dfb %00011111 ;19200

countlo db 0
counthi db 0
save_x dfb 0
timecnt dfb 0

 asc 'SingleSpd'
