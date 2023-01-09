********************************
*                              *
*   Parallel Printer Driver    *
*                              *
********************************

*-------------------------------
* Date: 12/07/86
*-------------------------------
 lst off

 rel
 dsk rel/parallel

cr equ $0d
lf equ $0a


parallel ent

*-------------------------------

 org $c00

slot db $10

 jmp init
 jmp print
 jmp clear

*-------------------------------

init lda slot
 lup 4
 lsr a
 --^
 clc
 adc #$c0 ; get $Cx value
 sta print2+2
 rts

*-------------------------------
* print character: A = character

print pha
 stx save_x
print2 lda $c1c1 ; is printer ready?
 bmi print2 ; nope

 pla
 pha
 ldx slot ; get offset
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

clear rts

save_x db 0
