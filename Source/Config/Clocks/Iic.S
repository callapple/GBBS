*-------------------------------
* //c System Clock - 24 hr
*-------------------------------
* Revised Date: 08/02/87
*-------------------------------

 lst off

 xc
 rel
 dsk rel/iicsys

iicsys ent

 org $0d00

lnbuf equ $200

ZBUF EQU $41
PTR EQU $42

stat1 equ $c099
comm1 equ $c09a
stat2 equ $c0a9
comm2 equ $c0aa

bytcnt equ $0e03
nullptr equ $0a

mli equ $bf00
date equ $bf90
time equ $bf92
get_time equ $82


slot hex 20
mode db 0

 bra getdate
timer db 00
 jmp gettime
 rts ; jmp setdate

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

* read time from clock
*-------------------------------
rdtime lda #64 ; read the date and time from clock
init1_1 pha
init1_2 sbc #1
 bne init1_2
 pla
 sbc #1 ; give plenty of setup delay
 bne init1_1

 php
 sei
init1_3 lda comm1 ; get current setting
 pha

 ldy #3
 ldx #22
 lda #8
init2 sta comm1 ; send init sequence to clock

init2_1 dex ; intra-bit delay
 bne init2_1

 eor #$0a ; toggle back and forth
 ldx #11
 dey
 bne init2 ; keep looping

 ldy #4
 ldx #8
 bne init3_2 ; skip initial delay

init3 lda #$34
 sta timer ; delay while clock sets up
init3_1 dec timer ; to send the date/time
 bne init3_1

init3_2 lda stat1 ; shift bit data into nibble
 rol
 rol
 rol
 ror datestr
 dex
 bne init3 ; go back to delay

 lda datestr
 eor #0 ; save the nibble
 sta datestr,y

 ldx #8
 dey
 bpl init3

 pla
init3_3 sta comm1 ; retore uart to initial settings

 ldy #15
 ldx #4

init4 lda datestr,x
 pha
 and #$0f ; process digit (make into ascii)
 ora #$30
 sta datestr,y

 dey
 pla
 lsr
 lsr
 lsr ; process top of nibble
 lsr
 ora #$30 ; turn into ascii
 sta datestr,y

 dey
 dey
 dex
 bpl init4
 plp

 lda #':'
 sta timestr+2 ; put time dividers in
 sta timestr+5

 ldx #<timestr ; point to string
 lda #>timestr
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

datestr asc '00 00 00'
timestr asc '00:00:00   '
