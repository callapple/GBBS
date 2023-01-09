********************************
*                              *
*      No Printer Driver       *
*                              *
********************************

*-------------------------------
* Date: 01/03/86
*-------------------------------
 lst off

 rel
 dsk rel/null

nullprint ent

 org $c00
; jump table
slot db $10

 jmp init
 jmp print
 jmp clear

; init printer
init rts

; print character: A = character
print rts

; clear print buffer (not available)
clear rts
