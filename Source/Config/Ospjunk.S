********************************
*                              *
*   Config Program - Ospjunk   *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------

*-------------------------------
* load the acos.obj file after find out where it is

ldconfg jsr cls ; clear screen

 jsr print
 asc 'Please enter the pathname of the volume',0d
 asc 'or subdirectory which contains the file',0d,0d
 asc 'ACOS.OBJ',0d,0d,0d
 asc 'Path: /',00

 lda #32 ; set maximum pathname at 32
 sta maxlen
 lda #%11000000
 sta inpmode ; set input mode

 jsr inpln
 iny
 sty lnbuf-2 ; save length
 lda #'/'
 sta lnbuf-1 ; save initial '/'

 jsr mli
 db $c6 ; set prefix
 dw p_spfx
 bne ldcon2 ; error

 jsr mli
 db $c7 ; get prefix and put into
 dw p_pfx4 ; program byffer

 jsr ldacos ; load in the stats
 bcc logcon ; all is ok

ldcon2 jmp ldconfg ; opps, error


*-------------------------------
* log back to the config disk
; log back to config disk
logcon jsr mli
 db $c6 ; set prefix
 dw p_pfx2

; ... later, add in error checking

 rts

*-------------------------------
* log the destination disk

logdst jsr mli
 db $c6
 dw p_pfx3

; ... later, add in error checking

 rts

*-------------------------------
* log the program disk

logprg lda prgpfx ; has a program prefix been defined?
 beq logcon ; nope, log to config disk

 jsr mli
 db $c6 ; log to program disk (with ACOS.OBJ)
 dw p_pfx4
 rts

*-------------------------------
* move filename to user routine

movname stx dosbyt ; point to filename
 sta dosbyt+1

 ldy #15
movnam2 lda (dosbyt),y ; copy filename
 sta flname,y
 dey
 bpl movnam2
 rts


; variables and stuff
msgref db 0
module db 0
sdvparm db 0,0,0
fnam2 equ fnam1
fbuf2 equ fbuf1
msgnam equ fnam1
msgbuf equ fbuf1
miscnam equ fnam1
miscbuf equ fbuf1

*-------------------------------
* log drive specifier a-l

logspec ldx #0 ; start offset at 8
 sta temp
 cmp #0 ; we done (drive a:)
 beq logspc3 ; yep

logspc2 txa  ; use as base
 sec  ; add extra 1
 adc devnam,x ; add offset
 tax  ; make into offset
 dec temp ; done?
 bne logspc2 ; nope

logspc3 lda devnam,x
 sta temp ; save path length
 ldy #0
logspc4 lda devnam,x ; copy pathname
 sta lnbuf,y
 inx
 iny
 dec temp ; count down
 bpl logspc4

 jsr mli
 db $c6 ; log to the prefix
 dw p_pfx
 clc
 beq *+3 ; no errors
 sec
 rts


copyrts jmp logcon ; log back to main

*-------------------------------
* copy a list of files

copy stx temp4 ; save pointer for getname
 sta temp4+1

copy2 jsr getname ; get source name
 bcs copyrts

 jsr logcon ; log to config disk

 ldx #<flname ; get info on file
 lda #>flname
 jsr getinfo
 bne copy2 ; opps, error, skip this file

 jsr open
 jsr geteof ; get eof marker
 stx p_geof+2
 sta p_geof+3 ; save marker
 sta temp
 cpx #0 ; save number of pages to read
 beq *+4
 inc temp

 ldx #<copybuf
 lda #>copybuf
 ldy #>copymax*2 ; get maximum ram space
 jsr rdblk

 jsr close ; close the file

 jsr logdst ; log to destination

 ldy #0 ; use type $00
 jsr create ; create file

 jsr open ; open file

 lda temp
 asl a ; get number of blocks (1/2 pages) to write
 tay
 ldx #<copybuf
 lda #>copybuf
 jsr wrblk ; write out the block

 jsr seteof ; set end of file
 jsr close

 ldx #<flname
 lda #>flname
 jsr setinfo ; set file info
 jmp copy2


*-------------------------------
* get info on a file

getinfo stx p_ginfo+1 ; point to filename
 sta p_ginfo+2
 lda #10
 sta p_ginfo

 jsr mli
 db $c4 ; get info
 dw p_ginfo
 rts

*-------------------------------
* set the file info

setinfo stx p_ginfo+1 ; point to filename
 sta p_ginfo+2
 lda #7
 sta p_ginfo

 jsr mli
 db $c3 ; set info
 dw p_ginfo
 rts

*-------------------------------
* set the current end of file

puteof stx p_geof+2 ; set eof marker
 sta p_geof+3

seteof lda refnum
 sta p_geof+1

 jsr mli
 db $d0 ; set eof
 dw p_geof
 rts

*-------------------------------
* rename a file

rename stx temp4 ; point to data
 sta temp4+1
 jsr getname ; get first name

 ldy #63
ren2 lda flname,y ; copy first name
 sta lnbuf+128,y
 dey
 bpl ren2

 jsr getname ; get new name

 jsr mli
 db $c2 ; rename file
 dw p_ren
 rts

*-------------------------------
* find the config disk

findcon ldx #23
 lda #0
:loop sta $bf58,x ; clear prodos system bit-map
 dex
 bne :loop

 jsr mli
 db $c7 ; get prefix
 dw p_pfx2 ; point to path

 lda conpfx ; is prefix set to null?
 bne findc2 ; nope

 lda $bf30 ; get current slot/drive
 sta p_onlin+1

 jsr mli
 db $c5 ; find out prefix of volume
 dw p_onlin

 lda conpfx+1
 and #$0f ; just save name length
 clc
 adc #1 ; advance length of prefix
 sta conpfx

 lda #'/' ; add leading slash for volume name
 sta conpfx+1

findc2 jmp logcon ; log to config

*-------------------------------
* check free space on volume

chkspc lda drive
 asl a
 asl a
 asl a
 ora slot ; make into #dsss0000 format
 asl a
 asl a
 asl a
 asl a

 sta p_onln+1
 jsr mli
 db $c5 ; get drive name
 dw p_onln
 beq chkspc2 ; all is well

 lda #0 ; return 0 blocks free -- error
 tax
 rts

chkspc2 lda dstpfx+1
 and #$0f
 tax  ; make into volume name
 inx
 stx dstpfx
 lda #'/'
 sta dstpfx+1

 ldx #<dstpfx
 lda #>dstpfx ; get info on volume
 jsr getinfo

 sec
 lda p_ginfo+5 ; return total number of free blocks
 sbc p_ginfo+8
 tax
 lda p_ginfo+6
 sbc p_ginfo+9
 rts

*-------------------------------
* setup initial drive spec list

setspec
 jsr chkspc ;reset path to original drive
 jsr makesegs ;tack the /program on path

 ldy #0
 lda #1
 jsr coppath ;copy 1 path (A:)

 sty temp
 jsr chkspc ;reset path
 jsr makesys ;SYSTEM
 ldy temp

 lda #1 ;copy 1 path (B:)
 jsr coppath

 sty temp
 jsr chkspc
 jsr makegfile ;GFILES
 ldy temp

 lda #1 ;copy 1 paths (C:)
 jsr coppath

 sty temp
 jsr chkspc
 jsr makednload ;DOWNLOAD
 ldy temp

 lda #1 ;copy 1 path (D:)
 jsr coppath

 sty temp
 jsr chkspc
 jsr makeupload ;UPLOAD
 ldy temp

 lda #1 ;copy 1 path (E:)
 jsr coppath

 sty temp
 jsr chkspc
 jsr makebltn ;BULLETINS
 ldy temp

 lda #1 ;copy 1 path (F:)
 jsr coppath

 sty temp
 jsr chkspc
 jsr makemail ;MAIL
 ldy temp

 lda #1 ;copy 1 path (G:)
 jsr coppath

 ldx #6 ; fill out rest of the specs (h: - l:)
 lda #0
:loop sta devnam,y
 iny
 dex
 bne :loop

 rts

*-------------------------------
* copy a path onto the pathname

coppath sta temp

:loop6 ldx #-1
:loop5 inx
 lda dstpfx,x ; copy in pathname
 sta devnam,y
 iny
 cpx dstpfx ; done?
 bne :loop5 ; nope

 dec temp ; count down paths to enter
 bne :loop6
 rts

*-------------------------------
* setup /xxx/gbbs.pro/program and log it

makesegs jsr makegbbs
 ldx #0
 ldy dstpfx
:loop lda prgname+1,x ; copy on /xxxx/gbbs.pro/program
 sta dstpfx+1,y
 inx
 iny
 inc dstpfx ; update length
 cpx prgname
 bne :loop
 rts

setprg jsr makesegs
 jsr mli
 db $c0 ; create new path
 dw p_crpth
 rts

*-------------------------------
* setup /xxx/gbbs.pro/system and log it

makesys jsr makegbbs
 ldx #0
 ldy dstpfx
:loop lda sysname+1,x ; copy on /xxxx/gbbs.pro/system
 sta dstpfx+1,y
 inx
 iny
 inc dstpfx ; update length
 cpx sysname
 bne :loop
 rts

setsys jsr makesys

 jsr mli
 db $c0 ; create new path
 dw p_crpth
 rts

*-------------------------------
* setup /xxx/gbbs.pro/gfiles and log it

makegfile jsr makegbbs
 ldx #0
 ldy dstpfx
:loop lda gfilename+1,x ; copy on /xxxx/gbbs.pro/gfiles
 sta dstpfx+1,y
 inx
 iny
 inc dstpfx ; update length
 cpx gfilename
 bne :loop
 rts

setgfile jsr makegfile

 jsr mli
 db $c0 ; create new path
 dw p_crpth
 rts

*-------------------------------
* setup /xxx/gbbs.pro/download and log it

makednload jsr makegbbs
 ldx #0
 ldy dstpfx
:loop lda dnldname+1,x ; copy on /xxxx/gbbs.pro/download
 sta dstpfx+1,y
 inx
 iny
 inc dstpfx ; update length
 cpx dnldname
 bne :loop
 rts

setdnload jsr makednload

 jsr mli
 db $c0 ; create new path
 dw p_crpth
 rts

*-------------------------------
* setup /xxx/gbbs.pro/upload and log it

makeupload jsr makegbbs
 ldx #0
 ldy dstpfx
:loop lda upldname+1,x ; copy on /xxxx/gbbs.pro/upload
 sta dstpfx+1,y
 inx
 iny
 inc dstpfx ; update length
 cpx upldname
 bne :loop
 rts

setupload jsr makeupload

 jsr mli
 db $c0 ; create new path
 dw p_crpth
 rts

*-------------------------------
* setup /xxx/gbbs.pro/bulletins and log it

makebltn jsr makegbbs
 ldx #0
 ldy dstpfx
:loop lda bltnname+1,x ; copy on /xxxx/gbbs.pro/bulletins
 sta dstpfx+1,y
 inx
 iny
 inc dstpfx ; update length
 cpx bltnname
 bne :loop
 rts

setbltn jsr makebltn

 jsr mli
 db $c0 ; create new path
 dw p_crpth
 rts

*-------------------------------
* setup /xxx/gbbs.pro/mail and log it

makemail jsr makegbbs
 ldx #0
 ldy dstpfx
:loop lda mailname+1,x ; copy on /xxxx/gbbs.pro/mail
 sta dstpfx+1,y
 inx
 iny
 inc dstpfx ; update length
 cpx mailname
 bne :loop
 rts

setmail jsr makemail

 jsr mli
 db $c0 ; create new path
 dw p_crpth
 rts

*-------------------------------
* setup /xxx/gbbs.pro and log it

makegbbs ldx #0
 ldy dstpfx
:loop lda dirname+1,x ; copy on /xxxx/gbbs.pro
 sta dstpfx+1,y
 inx
 iny
 inc dstpfx ; update length
 cpx dirname
 bne :loop
 rts

setgbbs jsr makegbbs
 jsr mli
 db $c0 ; create new path
 dw p_crpth
 rts

*-------------------------------
* variables

dirname str '/GBBS.PRO'
prgname str '/PROGRAM'
sysname str '/SYSTEM'
gfilename str '/GFILES'
dnldname str '/DOWNLOAD'
upldname str '/UPLOAD'
bltnname str '/BULLETINS'
mailname str '/MAIL'

p_spfx db 1
 dw lnbuf-2

p_geof db $02
 db 0
 db 0,0,0

p_ginfo db $0a
 dw 0
 db 0
 db 0
 dw 0
 db 0
 dw 0
 dw 0
 dw 0
 dw 0
 dw 0

p_ren db $02
 dw lnbuf+128
 dw flname

p_pfx db 1
 dw lnbuf

p_pfx2 db 1
 dw conpfx

p_pfx3 db 1
 dw dstpfx

p_pfx4 db 1
 dw prgpfx

conpfx ds 40,0 ; max length

dstpfx ds 40,0 ; max length

prgpfx ds 40,0 ; max length

p_onlin db 2
 db 0
 dw conpfx+1

p_onln db 2
 db 0
 dw dstpfx+1

p_crpth db 7
 dw dstpfx
 db $c3
 db $0f
 dw $0000
 db $0d
 dw 0
 dw 0
