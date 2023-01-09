*-------------------------------
* //c System Clock - 24 hr
*-------------------------------
* Revised Date: 08/02/87
*-------------------------------

 rel
 dsk rel/iicsys

lnbuf equ $200

ZBUF EQU $41
PTR EQU $42

stat1 equ $c099
comm1 equ $c09a
stat2 equ $c0a9
comm2 equ $c0aa

bytcnt equ $0e03
nullptr equ $0a


iicsys ent

 org $0d00

*-------------------------------

slot hex 20

 jmp getdate
 jmp gettime
 jmp setdate

; get the date in prodos/gbbs format
getdate jsr $bf00 ; read date from MLI
 hex 82
 hex 0000

 ldx $bf90
 lda $bf91

setdate rts

; get the current time
gettime jsr rdclock ; read the clock

 lda #':'
 sta timestr+2 ; put time dividers in
 sta timestr+5

 ldx #<timestr ; point to string
 lda #>timestr
 rts

; read the date time from clock
rdclock lda slot
 cmp #$10
 beq init1

 lda #<stat2 ; set status port to slot 2
 sta init3_2+1
 lda #<comm2 ; set comm port to slot 2
 sta init1_3+1
 sta init2+1
 sta init3_3+1

init1 lda #64
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

init2_1 dex  ; intra-bit delay
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
 lsr  ; process top of nibble
 lsr
 ora #$30 ; turn into ascii
 sta datestr,y

 dey
 dey
 dex
 bpl init4
 plp
 rts

timer hex 00
datestr asc '00 00 00'
timestr asc '00:00:00   '
date hex 0000


