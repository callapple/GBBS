
*-------------------------------
* Multiple Speed Modem Driver
*-------------------------------
* 3/18/88 AEN
*-------------------------------
 lst off

 rel
 dsk rel/multispd

cr EQU $0d
lf EQU $0a

data equ $c088
status equ $c089
command equ $c08a
control equ $c08b

initstr equ $11d0
ansstr equ $11c0
cdbyte equ $11bf

multispd ent  ;(Start)
 org $e00

*-------------------------------
* jump table

slot dfb $20 ;serial card slot
initspd db 0 ;init speed
callspd db 0 ;speed of call

bytcnt db 0,0,0

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

ringset LDX slot ;get offset
 LDA #%00000000 ;kill DTR, RTS
 STA command,x

 LDA #0 ;let modem reset
 JSR wait

 LDA #%00001011 ;turn on DTR, RTS
 STA command,x

 sei  ;disable ints

 LDY initspd ;set init speed
 JSR setspd

 LDA data,x ;clear data strobe

 lda #0 ;long delay
 jsr wait
 jsr wait

 LDX #-1 ;start at -1
rset2 INX do ;pre-inc
 LDA initstr,x ;get modem init string
 BEQ rset3 ;we are done

 JSR out ;output

 lda #$80
 jsr wait
 jmp rset2 ;loop

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

jring jmp ringset ;128 byte branches!!

*-------------------------------
* scan for ring and handle it

ring LDX slot
 LDA status,x ;do we have carrier?
 AND cdbyte
 CLC
 BNE ring3 ;nope

 LDA data,x ;gobble byte(s)
 LDA data,x
 LDA #0 ;reset speed byte
 STA spdata

 LDY #0 ;set default to 300
ring1 JSR setspd

ring2 LDA status,x ;we still get carrier
 AND cdbyte
 BNE jring ;nope

 LDA status,x ;have a char waiting?
 AND #%00001000
 BEQ ring2 ;nope, check carrier

 LDA status,x ;check framing
 AND #%00000010
 BNE ring4 ;oops, framing error

 LDA data,x ;get byte (no framing error)
 STA spdata ;save speed data
 AND #$7f
 CMP #cr ;is it a return?
 BEQ ring2a ;yep, we have the speed

 AND #%01110000 ;check for higher speed
 CMP #%01110000
 BEQ ring5 ;go to up a notch
 JMP ring2 ;loop back

ring2a SEC all ;is well, connect
ring3 RTS

ring4 LDA data,x ;empty uart
 LDA data,x

 LDA spdata ;get last "legal" byte
 AND #%11100000 ;check for 300 baud overrun
 CMP #%11100000
 BEQ ring5 ;looks like a higher speed

 LDY curspd ;what speed
 BEQ ring2 ;hmm, cant go below 300

 DEY
 JMP ring1 ;set new speed, check again

ring5 LDY curspd ;we at 2400?
 CPY initspd ;as high as we can go?
 BEQ ring2 ;yep, cant go any higher

 INY
 JMP ring1 ;set new speed, up 1 notch

*-------------------------------
* send ata to phone

answer LDX #0
answer2 LDA ansstr,x ;get text
 BEQ answer3 ;we are donw

 JSR out ;send it

 lda #$80
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
 AND #%00010000
 BEQ out2 ;loop until ready
 PLA

dataloc STA data ;output byte
 LDX save_x
 RTS

*-------------------------------
*  check for carrier

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

setspd STY curspd ;save current speed
 STX save_x
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
 db %00011111 ;19200

countlo db 0
counthi db 0
curspd dfb 0 ;current speed

timecnt dfb 0 ;1-second counter
spdata dfb 0 ;speed data
save_x dfb 0
;end

 asc 'MultiSpd'
