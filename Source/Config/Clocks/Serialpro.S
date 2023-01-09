*-------------------------------
* Serial Pro Driver - 12 hrs
*-------------------------------

 lst off

 rel
 dsk rel/serialpro

lnbuf equ $200
mli equ $bf00
date equ $bf90
get_time equ $82


serialpro ent

 org $0d00

*-------------------------------

slot hex 40
mode db 0

 jmp getdate
 jmp gettime
 jmp setdate

* get the date in prodos gbbs format
*-------------------------------
getdate jsr $bf00 ; mli call
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

* read the current time from clock
*-------------------------------
rdtime bit initbyt ; has routine been called before?
 bmi clock1 ; yep

 lda slot ; get clock slot
 lsr
 lsr
 lsr
 lsr
 ora #$c0 ; make into $Cn form

 sta clock2+2 ; modify code for slot
 sta clock3+2
 dec initbyt ; show routine has been init'ed

clock1 lda #$a6 ; use "&" mode
clock2 jsr $c020 ; modified ($c420)
clock3 jsr $c01d ; modified ($c4ld)

 ldy #12
 ldx #0
clock4 lda lnbuf,y
 sta timestr,x
 iny
 inx
 cpx #8
 bne clock4
 rts

* convert time to 12 hour format
*-------------------------------
convert lda timestr ;convert to 12 hour
 ldx timestr+1

conv and #$0f
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

initbyt hex 00
timestr asc '00:00:00 AM',00
