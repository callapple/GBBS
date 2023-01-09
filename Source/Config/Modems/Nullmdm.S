*-------------------------------
* Date 01/06/87
*-------------------------------
 lst off

 rel
 dsk rel/nullmdm

nullmdm ent

 org $e00

*-------------------------------
* jump table

 dfb 0 ;serial card slot
 dfb 0 ;init modem at?
 dfb 0 ;speed of call

bytcnt dfb 0,0,0

 JMP do_rts
 JMP do_rts
 JMP ring
 JMP do_rts
 JMP do_rts
 JMP inp
 JMP out
 JMP chkdcd
 jmp do_rts
 jmp do_rts
 jmp do_rts
 jmp do_rts

; init the serial card
do_rts RTS

; scan for ring and handle it
ring CLC
 RTS

; input data
inp LDA #0
 CLC
 RTS

; output data
out INC bytcnt ;do byte-counting
 BNE out1
 INC bytcnt+1
 BNE out1
 INC bytcnt+2

out1 RTS

; check for carrier
chkdcd CLC
 RTS

 asc 'NullModem'
