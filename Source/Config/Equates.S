********************************
*                              *
*   Config Program - Equates   *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------

bs equ $08
lf equ $0a
up equ $0b
cr equ $0d
fs equ $15
can equ $18
esc equ $1b
del equ $7f

; memory allocation / buffers

lnbuf equ $0200
flname equ $0300
fltext equ $0301
reset equ $03f2
confbuf equ $0800
filter equ $0805
devnam equ $0815
viddrv equ $0900
prdrv equ $0c00
clkdrv equ $0d00
mdmdrv equ $0e00
cdbyte equ $11bf
ansstr equ $11c0
initstr equ $11d0
hdrbuf equ $1200

cdtype equ $1ffd
modemtype equ $1ffe
serialtype equ $1fff

mli equ $bf00

initbuf equ $1800
ansbuf equ $1830
fbuf1 equ $1c00
fnam1 equ $1e00

sortbuf equ $8000
copybuf equ $6000
copymax equ $5800
; zero page usage

temp equ $00
temp2 equ $02
temp3 equ $04
temp4 equ $06
x_save equ $09
y_save equ $0a
chrptr equ $0b
base equ $0d
maxlen equ $0f
inverse equ $10
point0 equ $11
point1 equ $14
prn equ $16 ; [4 bytes]
numptr equ $1a
psave equ $1c
prnt equ $1e

ch equ $24
cv equ $25

fmparm equ $60
doszero equ $62
dosptr equ $64
part equ $66
dosbyt equ $68

point3 equ $fd


