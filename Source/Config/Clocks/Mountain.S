*-------------------------------
* Mountian Hardware Driver
*-------------------------------
* Revised Date: 08/02/87
*-------------------------------

 lst off

 rel
 dsk rel/mountain

mountain ent

 org $0d00

mli equ $bf00
date equ $bf90
time equ $bf92
get_time equ $82


slot hex 40
mode db 0

 jmp getdate
 jmp gettime
 jmp setdate

* get the date in prodos gbbs format
*-------------------------------
getdate jsr mli ; mli call
 db get_time ; get_time
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

* get time routine
*-------------------
rdtime jsr rdclock
 lda #':' ; clean up format
 sta timestr+2
 sta timestr+5
 rts

* read time from clock
*----------------------
rdclock lda $38
 pha
 lda $39 ; save zp addresses
 pha
 lda slot
 lsr
 lsr
 lsr
 lsr
 ora #$c0
 sta $39 ; point to clock entry
 sta callclk+2
callclk jsr $c000 ; call clock
 pla
 sta $39
 pla  ; restore zp
 sta $38

 ldx #$0d
 ldy #0
movtime lda $286,x ; move returned string
 and #$7f
 sta datestr,y
 iny
 dex
 bpl movtime
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

; convert a 2 byte decimal number to binary
decbin8 and #$7f
 sec
 sbc #'0'
 sta decbyte ; save 10's digit
 txa  ; move 1's into A
 and #$7f
 sec
 sbc #'0'

 ldy #10
dec8a clc
 adc decbyte ; add the 10's digit, 10 times
 dey
 bne dec8a
 rts  ; return with result

decbyte hex 00
datestr asc '00/00/00'
timestr asc '00:00:00   '
