*-------------------------------
* Z-RAM Ultra 2-3 - 12 hour
*-------------------------------
* Date Revised: 01/30/90
*-------------------------------

 lst off

 rel
 dsk rel/ultra

ultra ent

 org $0d00

*-------------------------------
get_time equ $82
mli equ $bf00
date equ $bf90

 db 00
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

* read the current time from clock
*-------------------------------
rdtime lda #$c060
holdclk lda #%00000101
 sta $c06d
 sta $c06d
 sta $c06d
 ldy #30
loop lda $c06d
 and #%00000010
 beq readtime
 dey
 bne loop
 lda #%00000100
 sta $c06d
 sta $c06d
 sta $c06d
 bne holdclk

readtime lda $c065 ; 10's of hour
 and #%00000011
 ora #$30
 sta timestr
 lda $c064 ; 1's of hour
 and #%00001111
 ora #$30
 sta timestr+1
 lda $c063 ; 10's of minute
 and #%00000111
 ora #$30
 sta timestr+3
 lda $c062 ; 1's of minute
 and #%00001111
 ora #$30
 sta timestr+4
 lda $c061 ; 10's of seconds
 and #%00000111
 ora #30
 sta timestr+6
 lda $c060 ; 1's of seconds
 and #%00001111
 ora #$30
 sta timestr+7
 lda #%00000100
 sta $c06d
 sta $c06d ; release hold bit
 sta $c06d
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


* variables
*-------------------------------
timestr asc '00:00:00   ',00
