*-------------------------------
* ProDOS Clock Driver
*-------------------------------
* Revised Date: 08/02/87
*-------------------------------

 lst off

 rel
 dsk rel/prodos

mli equ $bf00
date equ $bf90
time equ $bf92
get_time equ $82

prodos ent
 org $0d00

*-------------------------------

 db 0
mode db 0

 jmp getdate
 jmp gettime
 jmp setdate

* get the date in prodos gbbs format
*-------------------------------
getdate jsr mli ; mli call
 db get_time
 hex 0000 ; no pramater table

 ldx date
 lda date+1
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

* read time from prodos
*-------------------------------
rdtime jsr getdate ; update time

 lda time+1 ; get current hour
 jsr bindec8 ; translate to ascii
 sta timestr ; save hour
 stx timestr+1

 lda time ; get minutes
 jsr bindec8 ; translate to ascii
 sta timestr+3 ; save minute
 stx timestr+4

 lda #' ' ; clear out any possible am/pm
 sta timestr+9
 sta timestr+10

 rts

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
 iny  ; add 1 to the 10's counter
 bne bin8a ; loop

bin8b adc #'0' ; make 1's into text
 tax  ; save
 tya
 adc #'0' ; make 10's into text
 rts  ; were done

*              '01234567890
timestr asc '12:00:00   '
