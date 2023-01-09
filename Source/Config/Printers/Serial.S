********************************
*                              *
*    Serial Printer Driver     *
*                              *
********************************

*-------------------------------
* Date: 12/07/86
*-------------------------------
 lst off

 rel
 dsk rel/serial

cr equ $0d
lf equ $0a

serial ent

 org $c00

*-------------------------------
; jump table
slot db $10

 jmp init
 jmp print
 jmp clear

*-------------------------------
* flag init status for output

init pha
 lda #0 ; signal that printer not init'ed
 sta initflg
 pla
 rts

*-------------------------------
* print character: A = character

print php  ; disable int's
 sei
 pha  ; save all reg's
 stx save_x
 sty save_y
 lda $c082 ; enable roms

 ldx #$13
print1 lda $24,x ; save zero page stuff
 sta zero,x
 dex
 bpl print1

 bit initflg ; has printer been used?
 bmi print3 ; yep

 lda slot
 sta $26 ; save slot for card
 lup 4
 lsr a ; move down slot
 --^
 clc
 adc #$c0
 sta print2+2
 sta $37 ; point ($0036) at $c100

 lda #0 ; init printer card
 tax
 tay
 sta $24 ; zero horiz offset
 sta $27 ; zero character buffer
 sta $36
print2 jsr $c100
 lda $36 ; point to output routine
 sta jprint+1
 lda $37
 sta jprint+2
 dec initflg ; show we have done init

 lda #'I'-$40 ; send ctrl-I 80 n
 jsr doprint
 lda #'8'
 jsr doprint
 lda #'0'
 jsr doprint
 lda #'N'
 jsr doprint
 lda #cr
 jsr doprint

print3 lda #0 ; set ch over to border
 sta $24
 pla  ; get byte to print
 pha
 jsr doprint

 ldx #$13
print4 lda zero,x ; restore zero page
 sta $24,x
 dex
 bpl print4

 lda $c083 ; enable ram card
 lda $c083
 ldx save_x ; restore reg's
 ldy save_y
 pla
 plp  ; restore int status
 rts

doprint ora #$80 ; print with high-bit set
jprint jmp $c000 ; do output routine


; clear print buffer (not available)
clear rts


save_x db 0
save_y db 0
initflg db 0

zero ds $14
