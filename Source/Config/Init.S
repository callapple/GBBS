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
 lda #%00000000
 sta inpmode

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
 lda #%11000000
 sta inpmode

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
 db 1,7,8
 asc '- System  Information -',0d,0d
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

einit0 jsr re_vid
einit1 ldx #<einit0
 lda #>einit0
 jsr escape
 jsr re_mdm
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
 db 1,3,4
 asc '- Copy Files to Storage Device -'00

 jsr cls
 jsr print
 asc 'Please enter the slot and drive of your'0d
 asc 'mass  storage device.  If your media is',0d
 asc 'removable,  then please make sure there'0d
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
 asc 'If you  continue,  a directory GBBS.PRO',0d
 asc 'will be  created  on your mass  storage',0d
 asc 'device. All needed files will be copied',0d
 asc 'into  this  folder. Existing files will',0d
 asc 'not be destroyed.',00
 jsr getcr

 lda #0 ; no more turning away..
 jsr escape ; [p. floyd]

 jsr chkspc ; check drive space
 cmp #2 ; are there are at least 512 blocks free?
 bcc :nospace ; not enough room
 jmp hard2

:nospace jsr cls
 jsr print
 asc "The storage device  checked doesn't have",0d
 asc 'enough  free  storage  space  to run the',0d
 asc 'system.  You need to make some more room'0d
 asc 'on the device, or choose another device.',00

 jsr getcr
 jmp hard1 ; goto hard/floppy question

hard2 jsr cls
 jsr print
 asc 'The configuration  program is now going'0d
 asc 'to copy all the files  necessary to run',0d
 asc 'GBBS Pro onto your mass storage device.',00

 jsr getg ; get permission
 jsr cls

 jsr setgbbs ;create xxx/gbbs.pro/

 jsr setspec ;update the drive spec list

 jsr chkspc ;reset path to original drive
 jsr setprg ;create & log xxx/gbbs.pro/program
 jsr make1 ;do copy in 5 parts

 jsr chkspc ;reset path to original drive
 jsr setsys ;create & log xxx/gbbs.pro/system
 jsr make2

 jsr chkspc ;reset path to original drive
 jsr setgfile ;create & log xxx/gbbs.pro/gfiles
 jsr make3

 jsr chkspc ;reset path to original drive
 jsr setdnload ;create & log xxx/gbbs.pro/download
 jsr make4

 jsr chkspc ;reset path to original drive
 jsr setupload ;create xxx/gbbs.pro/upload

 jsr chkspc ;reset path to original drive
 jsr setbltn ;create & log xxx/gbbs.pro/bulletins
 jsr make5

 jsr chkspc ;reset path to original drive
 jsr setmail ;create & log xxx/gbbs.pro/mail
 jsr make7

*-------------------------------

 jsr cls
 jsr print
 asc 'Your  system  is now  configured and is'0d
 asc 'ready to run. To bring  up your  system',0d
 asc 'for operation, do the following:',0d,0d
 asc 'Boot up your  mass storage  device  and'0d
 asc 'type "PREFIX GBBS.PRO/PROGRAM".',0d,0d
 asc 'Type "-ACOS" to start your system.',00

 jsr getcr
 jmp do_quit

*-------------------------------
* copy boot stuff over
*-------------------------------

make1 ldx #<disk1 ; is first disk online?
 lda #>disk1
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #1,'0d
 asc '/GBBS.CONFIG online.'00

 jsr getg ; wait for ok
 jmp make1 ;check it to make sure

:online jsr cls
 jsr print
 asc 'Copying ACOS Kernel and Segments...',00

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
 ldy #20 ; write 10 pages (5 blocks)
 jsr wrblk
 jmp close ; close file and return


*-------------------------------
* make main part of disk in XXX/GBBS.PRO/SYSTEM

make2 ldx #<disk2 ; is second disk in place?
 lda #>disk2
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #2,'0d
 asc '/GBBS.SYSTEM online.'00

 jsr getg ; wait for ok
 jmp make2

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro System Files...',00

 ldx #<list2 ; copy system files
 lda #>list2
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

 rts ;oi, we be done!

*-------------------------------
* copy files into XXX/GBBS.PRO/GFILES

make3 ldx #<disk2 ; is second disk in place?
 lda #>disk2
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #2,',0d
 asc '/GBBS.SYSTEM online.'00

 jsr getg ; wait for ok
 jmp make3

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro General Files...',00

 ldx #<list3 ; copy segments to xxx/gbbs.pro/system
 lda #>list3
 jmp copy

*-------------------------------
* copy files into XXX/GBBS.PRO/DOWNLOAD

make4 ldx #<disk2 ; is second disk in place?
 lda #>disk2
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #2,',0d
 asc '/GBBS.SYSTEM online.'00

 jsr getg ; wait for ok
 jmp make4

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro Download Files...',00

 ldx #<list4 ; copy files to xxx/gbbs.pro/download
 lda #>list4
 jmp copy

*-------------------------------
* copy files into XXX/GBBS.PRO/BULLETINS

make5 ldx #<disk2 ; is second disk in place?
 lda #>disk2
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #2,',0d
 asc '/GBBS.SYSTEM online.'00

 jsr getg ; wait for ok
 jmp make5

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro Message File...',00

 ldx #<list5 ; copy file  to xxx/gbbs.pro/bulletins
 lda #>list5
 jmp copy

*-------------------------------
* copy files into XXX/GBBS.PRO/MAIL

make7 ldx #<disk2 ; is second disk in place?
 lda #>disk2
 jsr verify
 bcc :online ; yes, it is

 jsr cls
 jsr print
 asc 'Please place GBBS Pro Disk #2,',0d
 asc '/SYSTEM online.'00

 jsr getg ; wait for ok
 jmp make7

:online jsr cls
 jsr print
 asc 'Copying GBBS Pro Mail File...',00

 ldx #<list7 ; copy file to xxx/gbbs.pro/mail
 lda #>list7
 jmp copy

*-------------------------------
* print the slot or drive

prslot lda slot
 clc
 adc #'0' ; print slot
 jmp cout

prdriv lda drive
 clc ; print drive
 adc #'1'
 jmp cout

*-------------------------------
* variables
*-------------------------------

diskid db $a2,$20,$a0,$00

gname2 str 'ACOS.OBJ'
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

*-------------------------------
* lists for identifying files

disk1 str '/GBBS.CONFIG'
disk2 str '/GBBS.SYSTEM'

list1 asc 'acos',00
 asc 'acos.obj',00
 asc 'logon.seg.s',00
 asc 'main.seg.s',00
 asc 'msg.seg.s',00
 asc 'system.seg.s',00
 db 00

list2 asc 'bbs',00
 asc 'data',00
 asc 'data1',00
 asc 'data2',00
 asc 'hlp.edit',00
 asc 'hlp.main',00
 asc 'hlp.msg',00
 asc 'hlp.user',00
 asc 'hlp.xfer',00
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
 asc 'x.up',00
 asc 'x.dn',00
 asc 'xdos',00
 db 00

list3 asc 'g1',00
 asc 'g1.1',00
 asc 'g1.2',00
 db 00

list4 asc 'd1',00
 asc 'd1.1',00
 asc 'd1.2',00
 asc 'd1.3',00
 asc 'd1.4',00
 db 00

list5 asc 'b1',00
 db 00

list7 asc 'mail',00
 db 00
