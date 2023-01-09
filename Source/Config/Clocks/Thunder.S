*-------------------------------
* Thunderclock Driver - 24 hrs
*-------------------------------
* Date Revised: 08/04/87
*-------------------------------

 lst off

 rel
 dsk rel/thunder

lnbuf equ $200
date equ $bf90

thunder ent
 org $d00

*-------------------------------

slot hex 40
mode db 0

 jmp getdate
 jmp gettime
 jmp setdate

; get the date in prodos/gbbs format
getdate jsr $bf00
 hex 82
 hex 0000

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

* read time from clock
*-------------------------------
rdtime bit initbyt ; has routine been called before?
 bmi clock1 ; yep

 lda slot ; get clock slot
 lup 4
 lsr
 --^
 ora #$c0 ; make into $Cn form

 sta clock2+2 ; modify code for slot
 sta clock3+2
 dec initbyt ; show routine has been init'ed

clock1 lda #"#" ; use "&" mode (24 hour)
clock2 jsr $c00b ; modified ($c40b)
clock3 jsr $c008 ; modified ($c408)

 ldy #0
clock4 lda lnbuf+9,y ; get time from input buffer
 sta timestr,y
 iny
 cpy #8
 bne clock4
 lda #":" ; put colens back into string
 sta timestr+2
 sta timestr+5
 lda #' '
 sta timestr+9 ; make sure that the am/pm is reset
 sta timestr+10
 rts

* convert time to 12 hour format
*-------------------------------
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

* data area
*-------------------------
initbyt hex 00
timestr asc '00:00:00   ',00
