*-------------------------------
* No Clock Driver
*-------------------------------
* Revised Date: 08/02/87
*-------------------------------

 lst off

 rel
 dsk rel/null

bytcnt equ $0e03
nullptr equ $0a


nullclk ent

 org $0d00

*-------------------------------

slot hex 00
mode db 0

 jmp getdate
 jmp gettime
 jmp setdate

* get the date in prodos/gbbs format
*-------------------------------

getdate ldx date
 lda date+1
 rts

* set the date manually
*-------------------------------

setdate cpy #8 ; is it 8 chars long?
 bne setdt2 ; nope

 stx nullptr ; point to string
 sta nullptr+1

 ldy #7
 lda (nullptr),y
 tax  ; process year
 dey
 lda (nullptr),y
 jsr decbin8
 sta date+1 ; save year

 ldy #4
 lda (nullptr),y
 tax  ; process day
 dey
 lda (nullptr),y
 jsr decbin8
 and #%00011111
 sta date ; save day

 ldy #1
 lda (nullptr),y
 tax  ; process month
 dey
 lda (nullptr),y
 jsr decbin8
 and #%00001111 ; get rid of extra junk
 asl
 asl
 asl
 asl
 asl
 rol date+1 ; put bit into year field
 ora date
 sta date ; put rest into day field
setdt2 rts

* get the current estimated time
*-------------------------------

gettime lda bytcnt+2 ; show hours
 jsr bindec8
 sta timestr
 stx timestr+1

 lda bytcnt+1 ; show minutes
 jsr bindec8
 sta timestr+3
 stx timestr+4

 lda bytcnt+0 ; show seconds
 jsr bindec8
 sta timestr+6
 stx timestr+7

 ldx #<timestr ; point to string
 lda #>timestr
 rts

* convert a 2 byte decimal number to binary
*-------------------------------

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

timestr asc '00:00:00 ET'
date hex 0000
