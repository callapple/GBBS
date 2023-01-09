********************************
*                              *
*   Grappler Printer Driver    *
*                              *
********************************

*-------------------------------
* Date: 12/07/86
*-------------------------------
 lst off

 rel
 dsk rel/grappler

cr equ $0d
lf equ $0a

grappler ent

*-------------------------------

 org $c00
; jump table
slot db $10

 jmp init
 jmp print
 jmp clear

*-------------------------------
* init printer

init rts  ; no init code needed

*-------------------------------
* print character: A = character

print pha
 stx save_x

 ldx slot
print2 lda $c080,x ; check printer status
 and #%00000111 ; check busy/wait bits
 eor #%00000011 ; turn all bits off
 bne print2 ; wait to come ready

 pla
 pha
 and #$7f
 sta $c080,x ; print data
 cmp #cr
 bne print3

 lda #lf ; add lf to cr
 ldx save_x
 jsr print

print3 ldx save_x ; finish up
 pla
 rts

*-------------------------------
* clear print buffer (not available)

clear rts


save_x db 0
