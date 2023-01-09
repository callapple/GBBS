********************************
*                              *
*   ACOS Loader Version 2.0    *
*                              *
********************************

*-------------------------------
* Date: 12/21/86
*-------------------------------
 typ $ff
 dsk acos.system

 org $2000

cr equ $0d
lf equ $0a

mli equ $bf00
home equ $fc58
cout equ $fdf0
vtab equ $fc22
inpln equ $fd6f
rdkey equ $fd35

lnbuf equ $0200
flname equ $0300
acosobj equ $0800
drivea equ $0815

dirinfo equ $5c00
dirbuf equ $5e00
prefix equ $6000
flbuf equ $6100
flbuf1 equ $6500

runadr equ $6900

temp equ $00
temp2 equ $02
numfls equ $04
blkcnt equ $06
prn equ $08

; relocate code up to $800

 lda temp ; save startup bytes
 pha
 lda temp+1
 pha

 lda #<objcode ; to obj code
 sta temp
 lda #>objcode
 sta temp+1

 lda #<runadr ; point to dest address
 sta temp2
 lda #>runadr
 sta temp2+1

 ldx #$10 ; move $10 pages
 ldy #0
domove lda (temp),y ; move a byte
 sta (temp2),y
 iny
 bne domove

 inc temp+1 ; go to the next page
 inc temp2+1
 dex
 bne domove

 pla
 sta startup+1 ; save startup bytes
 pla
 sta startup
 jmp runadr ; execute code

 ds \ ; fill space

objcode org runadr

; set to normal 40 col text mode
init lda $c30b
 cmp #1
 bne init_2

 lda $c30c
 cmp #$82
 bne init_1

 lda $c058
 clc
 bcc init_2

init_1 cmp #$87
 bne init_2

 lda #0
 sta $c0b2

init_2 lda #0 ; reset screen
 sta $20
 sta $22
 lda #40
 sta $21
 lda #24
 sta $23

 jsr home ; clear screen
 jsr pr ; show main screen
 asc '########################################' ; 1
 asc '# ACOS LOADER  V2.1 #    ACOS FILES    #' ; 2
 asc '# COPYRIGHT 1986-90 ####################' ; 3
 asc '#  L&L PRODUCTIONS  #                  #' ; 4
 asc '#####################                  #' ; 5
 asc '#    FILENAMES      #                  #' ; 6
 asc '#####################                  #' ; 7
 asc '#                   #                  #' ; 8
 asc '#                   ####################' ; 9
 asc '#                   #  DELETED FILES   #' ; 10
 asc '#                   ####################' ; 11
 asc '#                   #                  #' ; 12
 asc '#                   #                  #' ; 13
 asc '#                   #                  #' ; 14
 asc '#                   #                  #' ; 15
 asc '#                   ####################' ; 16
 asc '#                   # STARTUP SEGMENT  #' ; 17
 asc '#                   ####################' ; 18
 asc '#                   #                  #' ; 19
 asc '########################################' ; 20
 asc '# STATUS:                              #' ; 21
 asc '#   LOADING ACOS.OBJ                   #' ; 22
 asc '########################################',00 ; 23

 jsr mli
 db $c7 ; get prefix
 dw p_pfx

 lda prefix
 bne gotdef ; we have a default

 lda $bf30 ; save currently used disk
 sta p_onln+1

 jsr mli
 db $c5 ; get the online volume
 dw p_onln

 lda prefix+1 ; get rid of drive specifier
 and #$0f
 tax
 inx  ; add 1 for '/'
 stx prefix

 lda #'/' ; put in leading slash
 sta prefix+1

 jsr mli
 db $c6 ; set the prefix
 dw p_pfx

gotdef ldx $280 ; get length of path
gotdef2 dex
 beq loadg ; we have the path set

 lda $280,x
 cmp #'/' ; find path?
 bne gotdef2 ; nope

 stx $280 ; set new length

 jsr mli
 db $c6 ; set prefix
 dw p_pfx2

loadg lda #0
 sta $bf94
 jsr mli ; close ALL open files
 db $cc
 dw r_close

 jsr mli
 db $c8 ; open a file
 dw r_open

 lda r_open+5 ; move refnum
 sta r_read+1

 jsr mli
 db $ca ; read in acos.obj
 dw r_read

 jsr mli
 db $cc ; close file
 dw r_close

; check for turnkey run
 lda startup ; is first i/d byte ok?
 cmp #1
 bne sname ; nope

 lda startup+1
 sta startup ; make sure they dont match again
 cmp #2
 beq sname4

; get name of starting segment
sname lda acosobj+2 ; point to filename
 sta temp
 lda acosobj+3
 sta temp+1

 jsr prstat
 asc 'SOURCE MODULE [',00
 ldy #0
 lda (temp),y

 tax
sname2 iny
 lda (temp),y ; print filename
 ora #$80
 jsr cout
 dex
 bne sname2

 jsr pr ; finish off string
 asc ']: ',00

 jsr inpln
 cpx #0 ; cr?
 beq sname4 ; yep
 cpx #14 ; 14 or over?
 bcs sname ; yep

 txa
 tay
sname3 lda lnbuf-1,y ; copy filename
 sta (temp),y
 dey
 bne sname3

 txa  ; save length
 sta (temp),y
 jmp sname ; go back

sname4 ldx acosobj+2
 lda acosobj+3 ; display in window 3
 ldy #3
 jsr prwind

 lda #<drivea ; point to pathname
 sta p_ginfo+1
 lda #>drivea
 sta p_ginfo+2

chkprg jsr mli
 db $c4 ; get file info
 dw p_ginfo
 beq docheck

 jsr prstat
 asc 'INSERT SYSTEM DISK INTO OTHER DRIVE',0d,00
 jsr getcr
 jmp chkprg

; get a directory and look for ".s" files.
; if any exist, check to see if they have 
; been changed. If so, kill the ".c" file.

docheck jsr prstat
 asc 'STATUS:',0d
 asc '  CHECKING FILES...',00

logprg jsr mli
 db $c7 ; get the current prefix
 dw p_pfx

 ldy drivea
logprg1 lda drivea,y ; are these 2 paths the same?
 eor prefix,y
 and #%11011111
 bne logprg2 ; nope

 dey
 bne logprg1 ; keep checking

logprg2 jsr mli ; open the current prefix
 db $c8
 dw p_open

 lda p_open+5 ; get refnum
 sta p_rdinf+1
 sta p_rddir+1
 sta p_pos+1

 jsr mli ; read dir info
 db $ca
 dw p_rdinf

 jsr mli ; set to byte 0
 db $ce
 dw p_pos

 ldx #0
 stx numfls ; 0 files processed
 stx numfls+1
 dex
 stx blkcnt ; start at file 1 in block

rdloop lda #<dirbuf+4 ; point to buf
 sta temp
 lda #>dirbuf+4
 sta temp+1

 jsr mli ; read block
 db $ca
 dw p_rddir
 bne rdloop1 ; opps, error

 lda blkcnt ; first pass?
 bpl rdloop2 ; nope

 inc blkcnt ; set to 0
 jmp rdloop5 ; go to next entry

rdloop2 lda numfls ; we done?
 cmp dirinfo+$25
 bne rdloop3 ; nope

 lda numfls+1 ; check high
 cmp dirinfo+$26
 bne rdloop3 ; were done

rdloop1 jmp finish

rdloop3 ldy #0
 lda (temp),y ; get length and type
 and #$0f
 sta (temp),y ; get rid of extra stuff
 sta temp2
 bne rdlp3a

 jmp rdloop5

rdlp3a inc numfls ; inc file count
 bne rdloop4
 inc numfls+1

rdloop4 ldx temp
 lda temp+1 ; display filename in window 0
 ldy #0
 jsr prwind

 ldy drivea ; get length of path
 tya
 tax  ; save length
mvpath lda drivea,y
 sta flname,y ; move pathname
 dey
 bpl mvpath

 lda #'/' ; add in slash
 inx
 sta flname,x

 ldy #0
mvpath2 inx
 iny
 lda (temp),y ; get name of file
 sta flname,x
 cpy temp2
 bne mvpath2

 lda #'C' ; make into '.c'
 sta flname,x
 stx flname ; update length

 lda temp2 ; get length
 cmp #3 ; is it a possible '.s' file?
 bcc rdloop5 ; nope

 tay
 lda (temp),y ; check for 's' in '.s'
 cmp #'S'
 bne rdloop5

 dey
 lda (temp),y ; check for '.' in '.s'
 cmp #'.'
 bne rdloop5

rdloop4c ldx temp
 lda temp+1
 ldy #1 ; display .s source file
 jsr prwind

 lda temp ; point at filename
 sta p_ginfo+1
 sta p_open2+1
 lda temp+1
 sta p_ginfo+2
 sta p_open2+2

 lda #10 ; setup for get.info
 sta p_ginfo

 jsr mli ; get file info
 db $c4
 dw p_ginfo
 bne rdloop5 ; hmmm, error

 lda p_ginfo+5 ; check backup bit
 bne rdlop4a ; all is well

 lda #1
 sta p_ginfo+5 ; set bit in mod.time

 lda #7 ; setup for set.file.info
 sta p_ginfo

 jsr mli ; set info
 db $c3
 dw p_ginfo

 ldy #0
 lda (temp),y ; change file into .C
 tay
 lda #'C'
 sta (temp),y

 ldx temp
 lda temp+1
 ldy #2 ; display in window 2
 jsr prwind

 ldy #0
 lda (temp),y
 tay  ; change file back to .S
 lda #'S'
 sta (temp),y

 jsr mli ; delete '.c' file
 db $c1
 dw p_del

rdlop4a jsr flcopy ; copy over the file

rdloop5 clc
 lda temp ; go to next entry
 adc dirinfo+$23
 sta temp
 lda temp+1
 adc #0
 sta temp+1

 inc blkcnt ; inc place within block
 lda blkcnt
 cmp dirinfo+$24
 beq rdloop6 ; go to next block

 jmp rdloop2 ; do next entry within this block

rdloop6 lda #0 ; reset count
 sta blkcnt
 jmp rdloop ; do another block

finish lda #0
 sta p_close+1

 jsr mli ; close file
 db $cc
 dw p_close

 lda $c000 ; did they want to pause?
 cmp #$a0
 beq wait2c ; yep, wait to see

 jmp exeacos

wait2c lda #1
 sta $20
 sta $22
 lda #38
 sta $21
 lda #22
 sta $23
 jsr home ; clear screen
 jsr pr
 db cr
 asc ' MAKE SURE THESE DISKS ARE IN PLACE:',0d,00


 ldy #0 ; move A:
 ldx #<lnbuf
 lda #>lnbuf
 jsr movpath ; move pathname

 ldy #1 ; move B:
 ldx #<lnbuf+128
 lda #>lnbuf+128
 jsr movpath ; move pathname

 ldy lnbuf ; get pathname length
 iny
show2 dey  ; count down
 bmi show3 ; they match

 lda lnbuf,y
 cmp lnbuf+128,y ; are they the same?
 beq show2 ; yep

 jsr pr
 db cr
 asc ' BOOT DISK     -- ',00
 ldy lnbuf
 ldx #<lnbuf+1
 lda #>lnbuf+1
 jsr prstr ; show pathname

show3 jsr pr
 db cr
 asc ' SYSTEM DISK   -- ',00
 ldy lnbuf+128
 ldx #<lnbuf+129
 lda #>lnbuf+129
 jsr prstr ; show pathname

 ldy #5
 ldx #<lnbuf ; move pathname
 lda #>lnbuf
 jsr movpath

 jsr pr
 db cr
 asc ' BULLETIN DISK -- ',00
 ldy lnbuf
 ldx #<lnbuf+1
 lda #>lnbuf+1
 jsr prstr ; show pathname

 ldy #6
 ldx #<lnbuf+128
 lda #>lnbuf+128 ; move pathname
 jsr movpath

 ldy lnbuf ; get length of path
 iny
show4 dey
 bmi show5 ; the path's match

 lda lnbuf,y ; are they the same?
 cmp lnbuf+128,y
 beq show4 ; yep

 jsr pr
 db cr
 asc ' MAIL DISK     -- ',00
 ldy lnbuf+128
 ldx #<lnbuf+129
 lda #>lnbuf+129
 jsr prstr

show5 jsr pr
 db cr,cr
 asc ' ONCE THESE DISKS ARE IN PLACE',0d,0d
 asc ' ',00
 jsr getcr

exeacos lda #0
 sta $bf94 ; set level to 0

 jsr mli
 db $cc ; close all open files
 dw r_close ; specifically EXEC files

 lda acosobj+6
 sta temp
 lda acosobj+7
 sta temp+1
 jmp (temp) ; start acos running


; sub-routines
; print a line of status
prstat lda #2
 sta $20
 lda #36
 sta $21
 lda #20 ; set window
 sta $22
 lda #22
 sta $23
 jsr home ; clear window

pr pla  ; point to string
 sta prn
 pla
 sta prn+1

pr2 inc prn ; get next byte
 bne pr3
 inc prn+1

pr3 ldy #0 ; get byte
 lda (prn),y
 ora #$80
 cmp #"#" ; inverse block?
 bne pr3a ; nope
 lda #$20

pr3a jsr cout ; print
 asl a
 bne pr2 ; keep going

 inc prn ; make into correct address
 bne pr4
 inc prn+1

pr4 jmp (prn) ; return


; get a return
getcr jsr pr
 asc 'PRESS [RETURN] TO CONTINUE...',00
getcr2 jsr $fd35
 cmp #$8d
 bne getcr2
 rts


; print a filename within a window
prwind stx prn ; point to filename
 sta prn+1
 lda wndlft,y ; define text window
 sta $20
 sta $24
 lda wndrgt,y
 sta $21
 lda wndtop,y
 sta $22
 lda wndbtm,y
 sta $23
 sec  ; make into vtab
 sbc #1
 sta $25
 jsr $fc22 ; vtab down
 lda #$8d
 jsr $fdf0 ; scroll down

 ldy #0
 lda (prn),y ; get filename length
 tax
prwind2 iny
 lda (prn),y ; print name
 ora #$80
 jsr $fdf0
 dex
 bne prwind2
 rts

wndlft db 02,22,22,22
wndrgt db 16,16,16,16
wndtop db 07,03,11,18
wndbtm db 19,08,15,19


; print a string pointed to by X & A, length Y
prstr stx prn
 sta prn+1 ; point at string
 tya
 tax  ; save length
 ldy #0
prstr2 lda (prn),y ; get data
 ora #$80
 jsr $fdf0
 iny
 dex
 bne prstr2 ; do entire string
 rts


; move a pathname into a buffer
movpath stx temp ; point to buffer
 sta temp+1

 ldx #0
move2 dey  ; count down
 bmi move3 ; all finished

 txa
 sec
 adc drivea,x ; add in next offset
 tax
 jmp move2

move3 lda drivea,x ; get path length
 sta temp2 ; save as counter

 ldy #0
move4 lda drivea,x
 sta (temp),y ; save in buffer
 inx
 iny
 dec temp2 ; count down length
 bpl move4
 rts


; copy over a source file
flcopy jsr mli
 db $c8 ; does '.c' file exist?
 dw p_open1
 bne flcopy1 ; nope, copy source

 lda p_open1+5
 sta p_close+1
 jsr mli ; close compiled file
 db $cc
 dw p_close
flcopy2 rts  ; all is well

flcopy1 ldx flname ; change '.c' back to '.s'
 lda #'S'
 sta flname,x

 jsr mli
 db $c0 ; create new file
 dw p_creat
 bne flcopy2 ; file must already exist

 jsr mli
 db $c8 ; open old file
 dw p_open2

 lda p_open2+5 ; save refnum
 sta p_read+1
 sta p_close+1

 jsr mli
 db $ca ; read in file
 dw p_read

 jsr mli
 db $cc ; close source file
 dw p_close

 jsr mli
 db $c8 ; open new file
 dw p_open1

 lda p_open1+5 ; setup write routine
 sta p_write+1
 sta p_close+1
 lda p_read+6 ; setup write length
 sta p_write+4
 lda p_read+7
 sta p_write+5

 jsr mli
 db $cb ; write out segment
 dw p_write

 jsr mli ; close file 2
 db $cc
 dw p_close
 rts  ; we are done


; prodos parmlist
startup dw 0

p_creat db 7
 dw flname
 db $c3
 db $04
 dw 0
 db 1
 dw 0
 dw 0

p_open db 3
 dw prefix
 dw flbuf
 db 0

p_open1 db 3
 dw flname
 dw flbuf1
 db 0

p_open2 db 3
 dw 0
 dw flbuf1
 db 0

p_rdinf db 4
 db 0
 dw dirinfo
 dw $0100
 dw 0

p_rddir db 4
 db 0
 dw dirbuf
 dw $0200
 dw 0

p_read db 4
 db 0
 dw copybuf
 dw copylen
 dw $0000

p_write db 4
 db 0
 dw copybuf
 dw copylen
 dw $0000

p_close db 1
 db 0

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

p_del db 1
 dw flname

p_pos db 2
 db 0
 db $00,$00,$00

p_pfx db 1
 dw prefix

p_pfx2 db 1
 dw $280

p_onln db 2
 db 0
 dw prefix+1

; data for relocated code
r_open db 3
 dw r_file
 dw flbuf1 ; use last possible buffer
 db 0

r_read db 4
 db 0
 dw acosobj
 dw $6000
 dw $0000

r_close db 1
 db 0

r_file db 8
 asc 'acos.obj'

copybuf equ *
copylen equ mli-copybuf

 end


