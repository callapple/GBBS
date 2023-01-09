*-------------------------------
* GS Clock driver bios
* Written by Andy Nicholas - 07/30/87
* rewritten by Andy 3/11/88
*-------------------------------

 lst off

 xc
 xc ; goto 65816 mode

 rel
 dsk rel/gsclock

gsclock ent

 org $d00

* Jump Table
*-------------------------------

dow db 0
mode db 0

 jmp getdate ;call to get the date
 jmp gettime ;call to get the time (formatted)
 jmp setdate ;known return point

* Read Clock from ProDOS
*-------------------------------

mli equ $bf00
date equ $bf90

getdate jsr mli ;read the clock into
 hex 82 ;buffer at $200
 da 0

 ldx date ;read date in compressed form
 lda date+1 ;into A & X
setdate rts

* get the current time
*-------------------------------
gettime jsr rdtime
 bit mode
 bpl gtime1
 jsr convert

gtime1 ldx #<timestr ; point to string
 lda #>timestr
 rts

* read time from clock
*-------------------------------
rdtime clc ;go to native mode
 xce
 rep #$30 ;and 16 bit A, X, and Y
 mx %00

 pha ;stack space for results
 pha
 pha
 pha
 ldx #$0d03 ;ReadTimeHex
 jsl $e10000 ;Tool Locater
 sec
 xce ;emulation mode
 mx %11

 pla ; seconds
 jsr bindec8 ; convert to two byte
 sta timestr+6
 stx timestr+7
 pla ; minutes
 jsr bindec8 ; convert to two byte
 sta timestr+3
 stx timestr+4
 pla ; hour
 jsr bindec8 ; convert to two byte
 sta timestr
 stx timestr+1
 pla ; year
 pla ; day of month
 pla ; month
 pla ; unused byte
 pla ; day of the week
 sta dow

 lda #' '
 sta timestr+9
 sta timestr+10

 rts ;bye..


* convert time to 12hr format
*----------------------------
convert lda timestr ;convert to 12 hour
 ldx timestr+1

 and #$0f
 tay
 txa
 and #$0f

 dey
 bmi conv2
 clc
 adc #10
 dey
 bmi conv2
 adc #10

conv2 cmp #12
 bne conv2a
 lda #24
conv2a tay
 bne conv3
 lda #12

conv3 ldx #'A'
 cmp #13
 bcc conv4

 sbc #12
 ldx #'P'

conv4 ldy #'0'
conv5 cmp #10
 bcc conv6

 sbc #10
 iny
 bne conv5

conv6 ora #'0'
 sta timestr+1
 sty timestr
 stx timestr+9
 ldx #'M'
 stx timestr+10
 rts

* translate a binary to text [0-99]
*-------------------------------
bindec8 cmp #60 ; put limit of 59
 bcc bin8
 lda #59

bin8 ldy #0 ; start 10's counter
bin8a cmp #10
 bcc bin8b ; less than 10, were done

 sbc #10 ; minus 10
 iny ; add 1 to the 10's counter
 bne bin8a ; loop

bin8b adc #'0' ; make 1's into text
 tax ; save
 tya
 adc #'0' ; make 10's into text
 rts ; were done

*              '01234567890
timestr asc '12:00:00   '
