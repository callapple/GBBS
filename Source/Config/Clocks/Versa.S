*-------------------------------
* Promethus Versacard Driver
*-------------------------------
* Revised Date: 08/02/87
*-------------------------------

 lst off

 rel
 dsk rel/versa

versa ent

 org $0d00

*-------------------------------

get_time equ $82
mli equ $bf00
date equ $bf90

slot hex 40
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

* figure the current time
*-------------------------------
rdtime jsr rdclock
 lda timestr
 pha  ; fix hour (remove) am/pm info)
 and #%00110011
 sta timestr
 pla

 lsr
 lsr
 lsr  ; move am/pm bit into carry
 bcc gettim2 ; it is am (default)

 lda #'P' ; change to pm
 sta timestr+9

gettim2 lsr  ; move 12/24 hour bit into carry
 bcc gettim3 ; in 12 hour mode, all is well

 lda #' ' ; in 24 hour mode kill am/pm
 sta timestr+9
 sta timestr+10

gettim3 rts

* read the date from clock
*----------------------------
rdclock ldx #0
 ldy slot ; get slot offset
rdclk2 lda clkparm,x ; get function
 beq rdclk4
 bmi rdclk3 ; just ascii data

 and #%00111111 ; kill high status info
 sta $c082,y ; point to data

 lda $c083,y ; load in data
 and #%00001111 ; get rid of extra
 ora #'0' ; make into numeric digit
rdclk3 and #$7f ; kill high (from ascii)
 sta timestr,x
 inx
 jmp rdclk2 ; go until out of data
rdclk4 rts

* convert time to 12hr format
*--------------------------------
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

* convert a 2 byte decimal number to binary
*--------------------------------
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

* variables
*-------------------------
timestr asc '00:00:00 AM',00

clkparm hex 1514
 asc ":"
 hex 1312
 asc ":"
 hex 1110
 asc " AM"
 hex 00
