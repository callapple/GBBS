********************************
*                              *
*   Config - ProDOS disk I/O   *
*                              *
********************************

*-------------------------------
* Date:  3/11/88
*-------------------------------

create2 equ * ; entry for external files
create sty p_creat+4 ; save filetype
 jsr mli
 db $c0
 dw p_creat
 rts


open ldy #0
bfopen lda bufadr,y ; point at buffer
 sta p_open+4

 jsr mli
 db $c8 ; open
 dw p_open
 bne open2

 lda p_open+5 ; save refnum
 sta refnum
 clc
 rts

open2 lda #-1 ; make sure refnum is illegal
 sta refnum
 sec
 rts

bufadr db >fbuf1,>fbuf2,>msgbuf


close lda refnum ; use refnum
 sta p_close+1
 jsr mli
 db $cc ; close
 dw p_close
 rts

flush lda refnum ; use refnum
 sta p_close+1
 jsr mli
 db $cd ; flush
 dw p_close
 rts


; setup for single line read
rdlnset lda refnum
 sta p_new0+1 ; save refnum
 sta p_new1+1
 sta p_rdln+1

 jsr mli
 db $c9 ; enable newline
 dw p_new1
 rts


; read a line from a file
rdline jsr mli
 db $ca ; read
 dw p_rdln
 bne rdline2 ; read error

 ldx p_rdln+6 ; is there a cr at end of line?
 lda lnbuf-1,x
 and #$7f
 cmp #cr
 bne rdline2 ; no more stuff
 clc
 rts

rdline2 lda #0 ; no data in line
 sta lnbuf
 sec  ; eof
 rts


; read a single byte
rdbyte lda refnum ; save refnum
 beq rdbyte2

 sta p_rbyt+1
 jsr mli
 db $ca ; read 1 byte
 dw p_rbyt
 bne rdbyte2

 lda p_byte ; get byte
 clc  ; were done
 rts

rdbyte2 lda #0 ; fake data
 sec
 rts


; write a block for the msg routines
wrblk pha
 lda #$cb ; use write call
 sta rwtype ; --- does modify
 pla
 jmp rwblk

; read a block for the msg routines
rdblk pha
 lda #$ca ; use read call
 sta rwtype ; --- does modify
 pla

rwblk stx p_rdblk+2
 sta p_rdblk+3 ; save read address

 lda #0
 sta p_rdblk+4
 sty p_rdblk+5 ; save number of blocks to read

 lsr p_rdblk+5 ; divide by 2
 ror p_rdblk+4

 lda refnum ; get refnum
 sta p_rdblk+1

 jsr mli ; call mli
rwtype db $ca ; *** modified ***
 dw p_rdblk
 rts


; write a byte of data
wrbyte sta p_byte ; save data
 pha
 lda refnum
 beq wrbyte2 ; if no refnum

 sta p_rbyt+1
 jsr mli
 db $cb ; write byte
 dw p_rbyt
 clc  ; all is well
 beq wrbyte3

wrbyte2 sec  ; opps, problem
wrbyte3 pla  ; get back data
 rts


; position file
posmsg ldy msgref ; save refnum
 sty refnum

 lsr a ; setup Y,A,X w/exact byte
 tay
 txa
 ror a
 pha
 lda #16
 ror a
 tax
 pla
 jmp setpos


; find the end of file
geteof lda refnum ; save refnum
 sta p_mark+1
 jsr mli
 db $d1 ; get eof
 dw p_mark
 ldx p_mark+2
 lda p_mark+3 ; get length
 ldy p_mark+4
 rts

; set a mark into a file
setmark ldy #0

; do actual position set within file
setpos stx p_mark+2
 sta p_mark+3 ; point to new location
 sty p_mark+4

 lda refnum
 sta p_mark+1 ; save refnum

setpos2 jsr mli
 db $ce ; set mark
 dw p_mark
 cmp #$4d ; check for out-of-range
 bne setpos3

 jsr mli
 db $d0 ; set eof
 dw p_mark
 beq setpos2 ; position again

setpos3 rts


; get current file marker
getmark lda refnum ; save refnum
 sta p_mark+1
 jsr mli
 db $cf ; get mark
 dw p_mark
 sec
 bne getmrk2 ; opps, error

 clc
 ldx p_mark+2 ; all is well
 lda p_mark+3
getmrk2 rts

delfile jsr mli
 db $c1 ; delete file
 dw p_del
 rts

; ------ parms ------

p_open db 3
 dw flname
 dw fbuf1
 db 0

p_close db 1
 db 0

p_rbyt db 4
 db 0
 dw p_byte
 dw 1
 dw 0

p_byte db 0

p_mark db 2
 db 0
 db 0,0,0

p_new0 db 3
 db 0
 db 0
 db 0

p_new1 db 3
 db 0
 db $7f
 db $0d

p_rdln db 4
 db 0
 dw lnbuf
 dw $00ff
 dw $0000

p_rdblk db 4
 db 0
 dw $0000
 dw $0080
 dw $0000

p_del db 1
 dw flname

p_creat db 7
 dw flname
 db $c3
 db 0
 dw 0
 db $01
 dw $0000
 dw $0000


