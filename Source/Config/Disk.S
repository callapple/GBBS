*-------------------------------
* Disk stuff for config
*-------------------------------
* Date: 3/11/88
*-------------------------------

*-------------------------------
* read in a partial record [1-255 bytes]

rdpart stx part
 sta part+1 ; point to buffer
 tya
 tax  ; save counter

 ldy #0
:loop jsr rdbyte ; read in data
 bcs :error ; error

 sta (part),y
 iny
 dex
 bne :loop ; do next byte

 clc  ; all went well
:error rts

*-------------------------------
* write a partial block of data to disk

wrpart stx part ; point to data
 sta part+1
 tya
 tax  ; save length

 ldy #0
:loop lda (part),y ; write out data
 jsr wrbyte
 iny
 dex
 bne :loop ; do next byte

 rts


*-------------------------------
* verify a that a disk is online

verify stx verify_p+1 ; point to wanted path
 sta verify_p+2

 jsr mli
 db $c6 ; set prefix
 dw verify_p
 bcs :error

 jsr mli ;get prefix for source volume
 db $c7 ;get prefix
 dw p_pfx2 ;point to path
:error rts

verify_p db 1
 dw 0 ;address of path to set


*-------------------------------
* load config/acos.obj from disk

ldacos jsr logprg ; log to the program disk
 ldx #<gname
 lda #>gname
 jsr movname ; move filename
 jsr open ; open 'acos.obj'
 bcs :error ; error

 ldx #<confbuf ; load config part into buffer
 lda #>confbuf
 ldy #20 ; read 10 pages (5 blocks)
 jsr rdblk
 jsr close ; close file
 clc
:error rts

*-------------------------------
* write config/acos.obj back to disk

svacos jsr logprg ; log to program disk
 ldx #<gname
 lda #>gname
 jsr movname ; move filename
 jsr open
 bcs :error

 ldx #<confbuf ; write config back to disk
 lda #>confbuf
 ldy #20
 jsr wrblk ; write 10 pages (5 blocks)
 jsr close
 clc
:error rts

refnum db 0


