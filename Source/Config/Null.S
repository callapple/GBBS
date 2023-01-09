********************************
*                              *
* GBBS Pro - Null Modem Driver *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------

nullmdm org $0e00

; jump table

 db 0 ; serial card slot
 db 0 ; init modem at?
 db 0 ; speed of call

bytcnt db 0,0,0

 jmp do_rts
 jmp do_rts
 jmp ring
 jmp do_rts
 jmp do_rts
 jmp inp
 jmp out
 jmp chkdcd


; init the serial card
do_rts rts

; scan for ring and handle it
ring clc
 rts

; input data
inp lda #0
 clc
 rts

; output data
out inc bytcnt ; do byte-counting
 bne out1
 inc bytcnt+1
 bne out1
 inc bytcnt+2

out1 rts

; check for carrier
chkdcd clc
 rts

 org


