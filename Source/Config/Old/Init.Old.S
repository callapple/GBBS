*-------------------------------
* config/init
*-------------------------------
* Date: 3/11/88
*-------------------------------

doinit ldx #<begin ; setup esc handler
 lda #>begin
 jsr escape

 jsr cls

 lda #30
 sta maxlen
 lda #%00000000
 sta inpmode

 jsr print
 asc 'What are you going to call your system?',0d
 asc ':',00
 jsr inpln

 ldx #<datadef
 lda #>datadef
 ldy #cr
 jsr copyinp ; copy name into file
 stx temp4
 sta temp4+1

 lda #20 ; limit length
 sta maxlen

 jsr print
 hex 0d
 asc 'Enter your FULL name. (20 chars max)',0d
 asc ':',00
 jsr inpln ; get name

 ldx #<user ; copy line uppercase
 lda #>user
 ldy #cr
 jsr ucopyinp
 ldy #cr
 jsr copyinp ; copy the line
 stx temp3
 sta temp3+1

 ldx temp4
 lda temp4+1
 ldy #cr
 jsr copyinp
 stx temp4
 sta temp4+1

 ldy #0
init1d lda user,y
 iny
 cmp #$20
 bne init1d
 dey
 lda #','
 sta user,y

init2 lda #%11000000
 sta inpmode

 jsr print
 hex 0d
 asc 'Enter your telephone number',0d
 asc '(XXX-XXX-XXXX): ',00

 jsr inpln ; get tele number
 cpy #12
 bne init2

 ldx #<usrtele
 lda #>usrtele
 ldy #0
 jsr copyinp ; copy the line

 lda #16
 sta maxlen ; set length for city

 jsr print
 hex 0d
 asc 'What city do you call from? (16 char)',0d
 asc ':',00

 jsr inpln ; get where from
 ldx temp3
 lda temp3+1
 ldy #','
 jsr copyinp ; copy the input
 stx temp2
 sta temp2+1

 lda #2
 sta maxlen ;set length for state

init2a jsr print
 hex 0d
 asc 'What state do you call from? (XX):',00

 jsr inpln ;get state
 cpy #2
 bne init2a
 ldx temp2
 lda temp2+1
 ldy #cr
 jsr copyinp ;copy to date area



 lda #8
 sta maxlen

init3 jsr cls
 jsr print
 asc 'Enter a 4-8 char password:',00

 jsr inpln
 cpy #4
 bcc init3

 ldx #<usrpass
 lda #>usrpass
 ldy #0
 jsr copyinp ; copy the line

 lda #20
 sta maxlen

 jsr print
 hex 0d
 asc 'Enter a second password for remote'0d
 asc 'sysop access (1-20 chars)'0d
 asc ':',00

 jsr inpln ; get second password
 ldx temp4
 lda temp4+1
 ldy #cr
 jsr copyinp ; copy password into data file
 stx temp4
 sta temp4+1 ; save new pointers

 ldy #0
init3a lda xdata,y ; copy rest of the data file
 sta (temp4),y
 iny
 cmp #0
 bne init3a

 jsr cls ; clear screen
 jsr print
 db 1,7,5
 asc '- System Information -',0d,0d
 asc 'System Name: ',00

 ldx #<datadef
 lda #>datadef
 ldy #cr+128
 jsr prstr ; show system name
 stx temp4
 sta temp4+1

 jsr print
 hex 0d,0d
 asc 'Sysop Name: ',00

 ldx temp4
 lda temp4+1
 ldy #cr+128
 jsr prstr ; show sysop name
 stx temp4
 sta temp4+1

 jsr print
 hex 0d,0d
 asc 'Sysop Phone Number: ',00

 ldx #<usrtele
 lda #>usrtele
 ldy #13
 jsr prstr ; show tele number

 jsr print
 hex 0d,0d
 asc 'Sysop is From: ',00

 ldx temp3
 lda temp3+1
 ldy #cr+128
 jsr prstr ; show where from

 jsr print
 hex 0d,0d
 asc 'Logon Password:  ',00

 ldx #<usrpass
 lda #>usrpass
 ldy #9
 jsr prstr ; show main password

 jsr print
 hex 0d,0d
 asc 'Remote Password: ',00

 ldx temp4
 lda temp4+1
 ldy #cr+128
 jsr prstr ; show remote password

 jsr print
 hex 0d,0d
 asc 'Is this information correct? [Y/N] ',00

 jsr inpyn
 bcc init4
 jmp doinit

*-------------------------------

init4 lda #-1
 sta init ; set init mode

einit1 jsr re_mdm
einit2 ldx #<einit1
 lda #>einit1 ; if esc, go back 1 level
 jsr escape
 jsr re_pr
einit3 ldx #<einit2
 lda #>einit2
 jsr escape
 jsr re_clk

*-------------------------------

 ldy #<devnam
 lda #0
:loop sta confbuf,y ; zero out pathname buffer
 iny
 bne :loop

*-------------------------------
* start the hardware config

hard1 ldx #<einit3
 lda #>einit3 ; backup 1 level
 jsr escape

 jsr TopBox
 jsr print
 db 1,2,2
 asc '- Copy Files to Mass Storage Device -'00

 jsr cls
 jsr print
 asc 'Please enter the slot and drive of your'0d
 asc 'mass storage device. If your media is',0d,0d
 asc 'removable, then please make sure there'0d
 asc 'is formatted media in place.',0d,0d,0d
 asc '     Slot? [1-7] ',00
 ldx #7
 jsr inpnum
 sta slot ; save the slot

 jsr print
 hex 0d
 asc '    Drive? [1-2] ',00
 ldx #2
 jsr inpnum
 sta drive ; save the drive
 dec drive ; make into [0-1] range

 jsr print
 hex 0d,0d,0d
 asc 'Is the above correct [Y/N] ? ',00
 jsr inpyn
 bcc *+5
 jmp hard1 ;nope

 jsr cls
 jsr print
 asc 'If you continue, 2 subdirectories will'0d
 asc ' be created on your mass storage',0d
 asc 'device. (GPRO.SEGS and GPRO.SYS) All'0d
 asc ' needed files will be copied into',0d
 asc 'these subdirectories.  No existing'0d
 asc 'files will be destroyed.'00
 jsr getcr

 lda #0 ; no more turning away..
 jsr escape ; [p. floyd]

 jsr chkspc ; check drive space
 cmp #3 ; are there are at least 768 blocks free?
 bcc *+5 ; not enough room
 jmp hard2

 jsr cls
 jsr print
 asc 'The storage device checked does not'0d
 asc 'contain enough storage space to run',0d
 asc 'the system. You need to make some'0d
 asc 'more room on the device, or choose',0d
 asc 'another device.',00

 jsr getcr
 jmp hard1 ; goto hard/floppy question

hard2 jsr cls
 jsr print
 asc 'Should the GBBS Pro transfer system'0d
 asc 'be installed onto this device? [Y/N] '00

 jsr inpyn
 bcc :trans
 lda #0
 sta settrans
 sta superlist ;mark the end of the supertac list as such
 jmp :notrans

:trans lda #1
 sta settrans

 jsr print
 hex 0d0d0d
 asc 'Please enter the number of volumes that'0d
 asc 'should be allocated to the GBBS Pro',0d
 asc 'file transfer system.',0d,0d,0d
 asc 'Number of volumes? [1-99] ',00

 ldx #99 ;max is 99
 jsr inpnum
 sta volumes

 jsr bindec8
 sta stacacc+2 ;sysop high (10's)
 stx stacacc+3 ;sysop high (1's)
 sta stacacc+7 ;user high
 stx stacacc+8 ;user high
 sta stacacc+12
 stx stacacc+13 ;elite high
 sta stacacc+17
 stx stacacc+18 ;priv high
 sta stacacc+22
 stx stacacc+23 ;board manager high

:notrans jsr setspec
 jsr chkspc ;reset

 jsr cls
 jsr print
 asc 'The configuration program is now going'0d
 asc 'to copy all the files needed to run',0d
 asc 'GBBS Pro onto your mass storage device.',00

 jsr getg ; get permission
 jsr cls

 jsr setdrv ;create & log xxx/mpro.segs
 jsr make1 ;do copy in 3 parts
 jsr make2

 jsr chkspc ;reset path to original drive

 jsr setsys ;create & log xxx/mpro.sys
 jsr make3

 lda settrans ;did they want a transfer system?
 bne :doit ;yes, set it up
 jmp noxfer ;nope, skip the next step

:doit jsr settac ;create & log xxx/mpro.sys/transfer/vol.
 jsr make4

*-------------------------------
* setup supertac volumes

 jsr chkspc ;reset path to /xxx/
 jsr makesys ;add /xxx/mpro.sys/
 jsr maketac1 ;add /xxx/mpro.sys/stac
 jsr maketac2 ;add /xxx/mpro.sys/stac/vol.

 lda #0
 sta curvol ;start at volume 1
 inc dstpfx ;add one to length of destination prefix

:loop inc curvol ;++current volume
 lda curvol ;which volume are we at?
 cmp #10 ;did we do 10 yet?
 bcc :less10 ;nope, we have less than 10
 cmp #11 ;more than 9, but how much more?
 bcs :over10 ;>= 11, so we not right on 10
 inc dstpfx ;smack dab on 10, so length is one greater

:over10 jsr bindec8 ;convert volume we're on to decimal

 ldy dstpfx ;get current length
 dey  ;character before the end
 sta dstpfx,y ;store 10's
 txa  ;get 1's
 iny  ;next character forward
 sta dstpfx,y ;store 1's

 jsr mli ; create /xxx/mpro.sys/stac/vol.XX
 db $c0 ; create new path
 dw p_crpth
 jmp :over

:less10 ldx dstpfx ;add single number to end of prefix
 clc
 adc #'0' ;make it ascii
 sta dstpfx,x

 jsr mli ; create /xxx/mpro.sys/stac/vol.X
 db $c0 ; create new path
 dw p_crpth

:over lda curvol ;how many volumes done
 cmp volumes ;done 'em all yet?
 bne :loop ;nope, do some more


*-------------------------------

noxfer jsr cls
 jsr print
 asc 'Your system is now configured and is'0d
 asc 'ready to run. To bring up your system',0d
 asc 'for operation, do the following:',0d,0d
 asc 'Boot up your mass storage device and'0d
 asc 'type "PREFIX GPRO.SEGS".',0d,0d
 asc 'Type "-ACOS" to start your system',0d
 asc 'running.'0d

 jsr getcr
 jmp do_quit

volumes db 00
curvol db 00

*-------------------------------
* copy boot stuff over
*-------------------------------

make1 ldx #<disk1 ; is first disk online?
 lda #>disk1
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #1, /CONFIG,'0d
 asc 'online.'00

 jsr getg ; wait for ok
 jmp make1 ;check it to make sure

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro...',00

 ldx #<list1 ; copy acos & acos.obj
 lda #>list1
 jsr copy

*-------------------------------

 jsr logdst ; log to destination
 ldx #<gname2
 lda #>gname2 ; open file
 jsr movname
 jsr open

 ldx #<confbuf
 lda #>confbuf ; write configured system out
 ldy #18 ; write 9 pages (16.5 blocks)
 jsr wrblk
 jsr close ; close file

 ldx #<program
 lda #>program ; create file named "PROGRAM"
 jsr movname
 ldy #$f5 ; make into special type
 jmp create

*-------------------------------
* copy second set of files into XXX/GPRO.SEGS

make2 ldx #<disk2 ; is second disk in place?
 lda #>disk2
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #2,',00
 asc '/SEGS, online.'00

 jsr getg ; wait for ok
 jmp make2

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro program segments...',00

 ldx #<list2 ; copy segments to xxx/mpro.segs
 lda #>list2
 jmp copy

*-------------------------------
* make main part of disk in XXX/GPRO.SYS

make3 ldx #<disk3 ; is third disk in place?
 lda #>disk3
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #3, /FILE,'0d
 asc 'online.'00

 jsr getg ; wait for ok
 jmp make3

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro system files...',00

 ldx #<list3 ; copy last 4 files
 lda #>list3
 jsr copy

 jsr logdst ; log to seg sub
 ldx #<usrname ; open user file
 lda #>usrname
 jsr movname
 jsr open

 ldx #<user-128 ; write out sysop data
 lda #>user-128
 ldy #2 ; write 1 page (2 blocks)
 jsr wrblk

 jsr close ; finish up

 ldx #<dtanam1
 lda #>dtanam1 ; open data1 file
 jsr movname
 jsr open

 ldx #<datadef
 lda #>datadef
 ldy #4 ; write 2 pages (4 blocks)
 jsr wrblk
 jsr close
 jmp logcon ; log back

*-------------------------------
* make supertac segments

make4 ldx #<list4 ;copy protocol up/down
 lda #>list4 ;and xdos
 jsr copy

:loop ldx #<disk4 ; is fourth disk in place?
 lda #>disk4
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #4,'0d
 asc '/STAC, online.'00

 jsr getg ; wait for ok
 jmp :loop

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro transfer system files.',00

 ldx #<list5 ;copy supertac files
 lda #>list5
 jsr copy

* copy the access file to the supertac stuff

 jsr logdst ;log to supertac seg parts
 ldx #<access ;open user file
 lda #>access
 jsr movname
 jsr open

 ldx #<stacacc ;write out sysop data
 lda #>stacacc
 ldy #1 ;write 128 bytes
 jsr wrblk

 jsr close ;finish up
 jsr logcon ;log back to config
 rts  ;oi, we be done!

*-------------------------------
* print the slot or drive

prslot lda slot
 clc
 adc #'0' ; print slot
 jmp cout

prdriv lda drive
 clc  ; print drive
 adc #'1'
 jmp cout

*-------------------------------
* variables
*-------------------------------

diskid db $a2,$20,$a0,$00

gname2 str 'ACOS.OBJ'
program str 'PROGRAM'
access str 'ACCESS'
slot db 0
drive db 0
dtanam1 str 'DATA1'

user ds 70,0
usrpass asc '        '
usrtele asc 'xxx-xxx-xxxx'
 dw 0 ;when$
 db %11111110,%11111111,%11111111
 db %11111111,%00000111
 db $50,$00,$00,$00,$00,$00,$00,$00,$00,$00
 ds 20,0 ;bytes

datadef asc 'System Name',0d
 asc 'Sysop Name',0d
 asc 'Second Password',0d

 ds 120,0

xdata asc '---------------------------------------',0d
 asc 'Ctrl-S Stop/Start  Spacebar to Exit',0d
 asc 'Press N for Next Bulletin',0d
 asc '1,0',0d
 db 0

condata asc ' '
 asc 'N'
 db 2
 db 32,40,64,80

stacacc asc '1',0d ;sysop low access
 asc '50',0d ;sysop high access
 asc '1',0d ;user low access
 asc '50',0d ;user high access
 asc '1',0d ;elite low access
 asc '50',0d ;elite high access
 asc '1',0d ;priv low access
 asc '50',0d ;priv high access
 asc '1',0d ;board manager low access
 asc '50',0d ;board manager high access
 hex 0d0d

*-------------------------------
* lists for identifying files

disk1 str '/CONFIG',00
disk2 str '/SEGS',00
disk3 str '/FILE',00
disk4 str '/STAC',00

list1 asc 'acos',00
 asc 'acos.obj',00
 db 00

list2 asc 'logon.seg.s',00
 asc 'main.seg.s',00
 asc 'msg.seg.s',00
 asc 'system.seg.s',00
 asc 'maint.seg.s',00
 asc 'mail.seg.s',00

* supertac segments
* a 00 is placed here if they don't want to include the
* transfer system's segments

superlist asc 'supertac.s',00
 asc 'supertac.sys.s',00
 asc 'supertac.aux.s',00
 asc 'purge.seg.s',00
 db 00

list3 asc 'bbs',00
 asc 'data',00
 asc 'data1',00
 asc 'data2',00
 asc 'g1',00
 asc 'g1.1',00
 asc 'g1.2',00
 asc 'g1.3',00
 asc 'hlp.edit',00
 asc 'hlp.main',00
 asc 'hlp.msg',00
 asc 'hlp.user',00
 asc 'mnu.val.40',00
 asc 'mnu.val.80',00
 asc 'mnu.new',00
 asc 'sys.newinfo',00
 asc 'sys.news',00
 asc 'sys.info',00
 asc 'sys.questions',00
 asc 'users',00
 asc 'v1.1',00
 asc 'v1.2',00
 asc 'v1.3',00
 asc 'v1.4',00
 asc 'b1',00
list4 asc 'protocol.up',00
 asc 'protocol.down',00
 asc 'xdos',00
 db 00

list5 asc 'access',00
 asc 'xshow',00
 asc 'xcat',00
 asc 'menu.supertac',00
 asc 'menu.sysop',00
 asc 'menu.aux',00
 asc 'menu.batch',00
 db 00


