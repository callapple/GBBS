 org $e00
slot dfb #$02
mde dfb #$00
baud dfb #$04 ; baudrate / 300 of caller's baud
initbaud dfb #$04 ; baudrate / 300 to init port at
mode dfb #$01 ; 1=DCD detection, 0=DSR detection
lockport dfb #$00 ; 1 = port locked at init speed - software
; 2 = port locked at init speed - cts
   ; 0 = follow callers rate (normal)

initit equ $fd0

 jmp imdriver ; inits driver
 jmp iport ; inits port, dtr on, sends init.txt to modem
 jmp check ; for ring / connect / etc
 jmp answer ; force answer
 jmp hangup ; guess
 jmp getchar ; checks for char. from modem, a= char got
   ; clc = no character, sec = got data
 jmp mout ; sends data out to modem, purges buffer first
 jmp chkcar ; figures out baud from returns

imdriver   ; inits driver
 lda #$04
 sta hdwshk+1
 lda lockport
 cmp #$02
 bne nohdwl
 lda #$20
 sta hdwshk+1
nohdwl lda #$08
 sta chkmsk+1
 lda mode
 bne nodcd
 lda #$20
 sta chkmsk+1
nodcd lda $c038
 rts

iport   ; inits port
 lda $c038
 ldx #$00
iplp lda iptbl,x
 beq ipdn
 sta $c038
 inx
 lda iptbl,x
 sta $c038
 inx
 jmp iplp
ipdn ldy #30
 jsr wait
 ldy #$05
 lda #%01101010
 jsr writereg
 ldy initbaud
 jsr setbaud
atzst ldx #$00
atzlp lda atz,x
 beq atzdn
 jsr mout
 ldy #$04
 jsr wait
 inx
 jmp atzlp
atzdn
 ldy #$30
 jsr wait

atzacc ldx #$00
initlp lda initit,x
 beq initdn
 jsr mout
 ldy #$04
 jsr wait
 inx
 jmp initlp
initdn rts

answer ldx #$00
anslp lda ata,x
 beq ansdn
 jsr mout
 ldy #$04
 jsr wait
 inx
 jmp anslp
ansdn rts

checklo ldy #$ff
 jmp checka
check ldy #$01
checka jsr getchar
 bcs norts
 dey
 cpy #$00
 bne checka
 clc
 rts
norts
 and #$7f
 cmp #'1'
 bne not1200
 lda #$04
 jmp gotbaud
not1200 cmp #'2'
 bne not2400
 lda #$08
 jmp gotbaud
not2400 cmp #'9'
 bne checklo
 lda #$20
gotbaud sta $e02

 ldy lockport
 bne locked

 tay
 jsr setbaud
locked sec
 rts

atz dfb #$0d
 asc 'ATZ'
 dfb #$0d,#$00
ata dfb #$0d
 asc 'ATA'
 dfb #$0d,#$00

bdtbl dfb #$01,#$04,#$08,#$20,#$40,#$00

iptbl dfb #$09,#%01000000
 dfb #$04,#%01001100
 dfb #$03,#%11000000
 dfb #$05,#%01100000
 dfb #$09,#%00000000
 dfb #$0a,#%00000000
 dfb #$0b,#%01010110
 dfb #$0e,#%00000001
 dfb #$03,#%11000001
 dfb #$05,#%11101010
 dfb #$0a,#%00000000
 dfb #$0f,#%11010010
 dfb #$00,#%00000000

chkcar   ; check for carrier - clc=user gone
 lda $c038
chkmsk and #$20
 clc
 beq chkcarb
 sec
chkcarb rts

hangup   ; what do you think?
 ldy #$05
 lda #%11100000
 jmp writereg

getchar   ; gets character from modem
   ; a=character got, clc = no character, sec=data got
 lda $c038
 and #$01
 beq nodata
 lda $c03a
 sec
 rts
nodata clc
 rts

mout   ; sends data to modem, makes sure no incoming 1st
 pha

mouta lda $c038
 and #$04
 beq mouta

moutb lda $c038
hdwshk and #$20
 beq moutb

 pla
 sta $c03a
 rts

setbaud
 tya
 ldy #$00
setbdlp cmp bdtbl,y
 beq gotit
 iny
 bne setbdlp

gotit
 tya
 asl
 tax

 lda sbtbl,x
 ldy #$0c
 jsr writereg
 inx
 iny
 lda sbtbl,x
 jmp writereg

sbtbl dfb #$7e,#$01
 dfb #$5e,#$00
 dfb #$2e,#$00
 dfb #$0a,#$00
 dfb #$04,#$00

writereg
 sty $c038
 sta $c038
 rts

wait lda $c019
 bpl wait
waita lda $c019
 bmi waita
 dey
 bne wait
 rts


