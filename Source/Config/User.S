********************************
*                              *
*   Config - Print Userlist    *
*                              *
********************************

*-------------------------------
* Date: 11/29/86
*-------------------------------

usrlist ldx #<start
 lda #>start ; setup esc handler
 jsr escape

 jsr TopBox
 jsr print
 db 1,3,7
 asc '- Sort and Print Userlist -',00

 jsr cls
 jsr print
 db 1,7,0
 asc '  1 - Sort by user name',0d
 asc '  2 - Sort by the user number',0d
 asc '  3 - Sort by user password',0d
 asc '  4 - Sort by phone number',0d
 asc '  5 - Sort by last date on',0d
 asc '  6 - Sort by security level',0d
 asc '  7 - Return to main menu',0d,0d
 asc 'Which? [1-7] ',00

 ldx #7 ; get there choice
 jsr inpnum
 sta sortyp
 cmp #7 ; check for abort
 bne :over
 jmp start

:over ldx #<usrlist ; setup esc handler
 lda #>usrlist
 jsr escape

list0 jsr cls
 jsr print
 hex 0d
 asc 'Show users with which security flags:',0d,0d
 asc '[0]   = Un-Verified Users',0d
 asc '[1]   = Verified Users',0d
 asc '[34]  = Sysop Status',0d
 asc '[RET] = Print all users',0d,0d
 asc 'List which users [CR,0-34]: ',00

 lda #%00100000
 sta inpmode ; set input mode
 lda #2
 sta maxlen ; set input length

 lda #-1 ; default to all users
 sta seclvl
 jsr inpln ; input their choice
 lda lnbuf
 cmp #cr ; show all users?
 beq list0a ; get password status

 ldx #<lnbuf ; change to number
 lda #>lnbuf
 jsr numin
 stx seclvl ; save the level
 cpx #35
 bcc list0a ; out of range
 jmp list0

list0a jsr print
 hex 0d
 asc 'Display Passwords? [Y/N] ',00
 jsr inpyn
 lda #0
 ror a
 sta shwpass ; save password status

 jsr print
 hex 0d,0d
 asc 'Make sure printer, config disk, and'0d
 asc 'system disk are on-line and ready.',00
:oops jsr getcr
 lda #1 ; log to system disk
 jsr logspec
 bcs :oops ; opps, error

 jsr cls ; clear screen
 jsr print
 db 1,8,12
 asc 'Reading data...',00

 ldx #<usrname ; setup user file name
 lda #>usrname
 jsr movname

 ldx #1 ; start user number at 1
 stx temp
 dex
 stx temp+1

 lda #<sortbuf
 sta temp2 ; point to buffer
 lda #>sortbuf
 sta temp2+1

 jsr open ; open userfile
 bcc list1a ; all is well

 jsr close
 jsr cls
 jsr print
 asc 'Error: Unable to open file USERS',00
 jsr getcr
 jmp usrlist ; start over

list1a ldx #<hdrbuf ; gobble user #0
 lda #>hdrbuf
 ldy #128 ; 128 byte records
 jsr rdpart

list_2 lda #0 ; clear buffer
 sta hdrbuf
 ldx #<hdrbuf
 lda #>hdrbuf ; read in a user
 ldy #128 ; 128 byte records
 jsr rdpart
 bcs list2c ; opps, end of file

 lda hdrbuf
 and #$7f
 beq list2c ; no more users

 cmp #' '
 bcc list2a ; opps, no user in that slot

 lda seclvl ; show all users?
 bmi list2e ; yep
 beq list2d ; show non-verified

 pha
 lsr a
 lsr a ; divide by 8
 lsr a
 tax  ; and make into byte offset
 pla
 and #%00000111
 tay  ; get bit offset
 lda hdrbuf+92,x ; get byte
 and secmap,y ; check bit
 beq list2a ; nope, dont show
 bne list2e ; show it

list2d lda hdrbuf+92 ; check for non-verified
 and #%00000010
 bne list2a ; user is verified, dont show

list2e jsr list_5 ; handle sort dispatch

list2a inc temp
 bne *+4 ; inc user number
 inc temp+1
 jmp list_2 ; loop

list2c ldy #0
 tya  ; mark last entry
 sta (temp2),y

 lda sortbuf ; check for no entries
 bne list2f ; there is data

 jsr close ; close user file
 jsr cls
 jsr print
 asc 'No users fit parameters',00
 jsr getcr
 jmp usrlist ; restart

list2f lda sortbuf+12 ; only 1 user in list?
 beq list2g ; yep

 jsr print
 db 1,8,12 ; change on-screen operation
 asc 'Sort',00
 jsr list6 ; sort data

list2g jsr print
 db 1,8,12
 asc 'Printing data...',00

 lda #<sortbuf ; point to data
 sta temp2
 lda #>sortbuf
 sta temp2+1
 lda #0 ; count the page display
 sta prinit ; set printer to init
 sta pagecnt

list_3 ldy #0
 lda (temp2),y
 beq list_4 ; opps, end of list

 ldy #10
 lda (temp2),y ; get user number
 sta hdrbuf+128
 tax
 iny
 lda (temp2),y
 sta hdrbuf+129 ; save user number as data
 jsr gouser

 ldx #<hdrbuf
 lda #>hdrbuf ; read in user record
 ldy #128
 jsr rdpart

 bit shwpass ; show passwords?
 bpl list3b ; yep

 lda #'*'
 ldx #7
list3a sta hdrbuf+70,x ; cover password with *'s
 dex
 bpl list3a

list3b jsr pruser ; print users data

 clc
 lda temp2
 adc #12
 sta temp2 ; goto next record
 lda temp2+1
 adc #0
 sta temp2+1
 jmp list_3 ; do next user

list_4 jsr close ; close user file
list4a dec pagecnt ; check page count
 beq list4b

 lda #cr ; advance page
 jsr prcout
 jmp list4a

list4b lda #cr ; add 4 last lines
 jsr prcout
 jsr prcout
 jsr prcout
 jsr prcout
 jmp usrlist ; we are done

*-------------------------------
* handle moving data for sort

list_5 ldy #9
 lda #' '
list5f sta hdrbuf+$100,y ; fill with blanks just in case
 dey
 bpl list5f

 jsr list5b ; get into 10 byte form

 ldy #11 ; save user record number
 lda temp+1
 sta (temp2),y
 dey
 lda temp
 sta (temp2),y

 dey
list5a lda hdrbuf+$100,y ; copy over data
 sta (temp2),y
 dey
 bpl list5a

 clc
 lda temp2 ; go to next record
 adc #12
 sta temp2
 lda temp2+1
 adc #0
 sta temp2+1
 rts

sortyp db 0

*-------------------------------

list5b lda sortyp
 asl a
 tax
 lda displist,x
 sta prn
 inx
 lda displist,x
 sta prn+1
 jmp (prn)

displist dw 0
 dw sname ; sort user name
 dw sunum ; sort by user number
 dw spass ; sort by password
 dw sfone ; sort by phone number
 dw sdate ; sort by last user
 dw ssec ; sort by sec level

*-------------------------------

sname ldy #-1
sname2 iny
 lda hdrbuf,y ; search for divider
 and #$7f
 cmp #' ' ; control char?
 bcc sunum ; hmm, just blank out
 cmp #','
 bne sname2

 ldx #-1
sname3 inx
 iny
 lda hdrbuf,y ; move byte
 sta hdrbuf+$100,x
 and #$7f
 cmp #' '
 bcs sname3 ; loop and finish

 ldy #-1
sname4 iny
 lda hdrbuf,y ; add on first name
 sta hdrbuf+$100,x
 and #$7f
 inx
 cmp #',' ; done?
 bne sname4 ; nope

sunum rts  ; leave data as blanks

spass ldy #7
spass2 lda hdrbuf+70,y ; move password
 sta hdrbuf+$100,y
 dey
 bpl spass2
 rts

sfone ldx #0
 ldy #0
sfone2 lda hdrbuf+78,y ; get phone number
 sta hdrbuf+$100,x
 inx
 iny
 cpy #3
 bne *+3 ; skip if not at 3
 iny
 cpy #7
 bne *+3
 iny
 cpy #12 ; done?
 bne sfone2 ; nope
 rts

sdate lda hdrbuf+91 ; move date into sort field
 sta hdrbuf+$101
 lda hdrbuf+90
 sta hdrbuf+$102
 rts

ssec ldy #3
ssec2 lda hdrbuf+92,y ; move sec level in
 sta hdrbuf+$101,y
 dey
 bpl ssec2
 rts


; sort all the records into order
list6 lda #<sortbuf
 sta temp ; point to buffer #1
 lda #>sortbuf
 sta temp+1

 lda #<sortbuf+12
 sta temp2 ; point to buffer #2
 lda #>sortbuf+12
 sta temp2+1

list6a ldy #0
list6b lda (temp),y ; get first byte
 cmp (temp2),y ; check againt second
 beq list6c ; all is well
 bcs list6e
 bcc list6d ; order is correct

list6c iny  ; go to next char
 cpy #10 ; there yet?
 bne list6b ; nope

list6d clc
 lda temp ; advance pointer #1
 adc #12
 sta temp
 lda temp+1
 adc #0
 sta temp+1

 clc
 lda temp2 ; advance pointer #2
 adc #12
 sta temp2
 lda temp2+1
 adc #0
 sta temp2+1

 ldy #0 ; we done?
 lda (temp),y
 beq list6q ; yep

 lda (temp2),y ; done?
 bne list6a ; nope, do next record
list6q rts

list6e ldy #11
list6f lda (temp),y
 pha
 lda (temp2),y ; swap data
 sta (temp),y
 pla
 sta (temp2),y
 dey
 bpl list6f ; do 12 bytes

 lda temp+1
 cmp #>sortbuf ; at record #1 ?
 bne list6g ; nope

 lda temp
 cmp #<sortbuf ; at record #1 ?
 beq list6h ; yep

list6g sec
 lda temp ; backup record #1
 sbc #12
 sta temp
 lda temp+1
 sbc #0
 sta temp+1

 sec
 lda temp2 ; backup record #2
 sbc #12
 sta temp2
 lda temp2+1
 sbc #0
 sta temp2+1
list6h jmp list6a

*-------------------------------
; print out a user record
pruser dec pagecnt ; count down list
 bmi pruser0
 bne pruser1

 lda #cr
 jsr prcout ; advance page
 jsr prcout
 jsr prcout
 jsr prcout

pruser0 ldx #<prthdr
 lda #>prthdr
 ldy #-1 ; print page header
 jsr prdata

 lda sortyp
 lup 4
 asl a
 --^
 tax
pruser3 lda sortnam-16,x
 inx
 jsr prcout
 asl a
 bne pruser3

 ldx #77 ; move over to col 77
 jsr gocol

 ldx #<prthdr2 ; print rest of header
 lda #>prthdr2
 ldy #-1
 jsr prdata

 lda #58
 sta pagecnt ; reset page counter

pruser1 ldx #<hdrbuf ; point to buffer with data
 lda #>hdrbuf
 ldy #"," ; print first name
 jsr prdata
 stx prn ; save location
 sta prn+1

 lda #' ' ; put a space between first & last
 jsr prcout

 ldx prn ; pick up last location
 lda prn+1
 ldy #cr+128 ; print last name
 jsr prdata

 ldx #25 ; move over to col 25
 jsr gocol

 ldx #<hdrbuf+78 ; point buffer to data
 lda #>hdrbuf+78
 ldy #12
 jsr prdata ; print phone number

 ldx hdrbuf+128
 lda hdrbuf+129 ; translate number
 jsr decmem

 sec
 lda #43
 sbc txtnum ; move over to print user number
 tax
 jsr gocol

 ldy txtnum
 ldx #<txtnum+1
 lda #>txtnum+1
 jsr prdata ; print user number

 lda #'-' ; add in a dash
 jsr prcout

 ldx #<hdrbuf+70 ; point buffer data
 lda #>hdrbuf+70
 ldy #8
 jsr prdata ; print password

 ldx #54 ; move over to col 54
 jsr gocol

 lda hdrbuf+92
 lsr a ; dont show guest/user flag
 ldx #7
pruser2 lsr a
 pha
 lda #0 ; show 1 or 0 flag status
 adc #'0'
 jsr prcout
 pla
 dex  ; print 7 flags
 bne pruser2

 ldx #63 ; move over to col 63
 jsr gocol

 lda hdrbuf+90 ; get most of month
 lsr hdrbuf+91 ; shift last bit into carry
 ror a ; move bit in
 lup 4
 lsr a
 --^
 jsr bindec8
 jsr prdec8 ; print it out
 lda #'/'
 jsr prcout

 lda hdrbuf+90
 and #%00011111 ; strip off month bits
 jsr bindec8
 jsr prdec8 ; print out
 lda #'/'
 jsr prcout

 lda hdrbuf+91 ; get year
 jsr bindec8
 jsr prdec8

 lda hdrbuf+99
 and #%00001111
 tax  ; display time limit
 lda #0
 jsr decmem

 sec
 lda #75
 sbc txtnum ; move over to print time limit
 tax
 jsr gocol

 ldy txtnum
 ldx #<txtnum+1
 lda #>txtnum+1
 jsr prdata ; print time limit

 lda #'0' ; add on zero (time * 10)
 jsr prcout
 lda #cr ; end of line data
 jmp prcout


; print out selected data
prdata stx prn ; point to data
 sta prn+1
 sty prn+2 ; save delimeter
 sty prn+3 ; save length

 ldy #0
prdata2 lda (prn),y ; get data
 inc prn
 bne *+4 ; goto next byte
 inc prn+1

 ora #$80 ; set high for ascii check
 cmp prn+2 ; we done?
 beq prdata3 ; yep

 jsr prcout ; print data
 dec prn+3 ; count down length
 bne prdata2 ; keep going

prdata3 ldx prn
 lda prn+1 ; get new address
 rts


; go to a specified column
gocol stx prn ; save end address
gocol2 lda prcol ; are we done?
 cmp prn
 bcs gocol3 ; yep

 lda #' ' ; move over a space
 jsr prcout
 jmp gocol2 ; keep going

gocol3 rts


; print out a 2 byte number [xx]
prdec8 jsr prcout ; call
 txa  ; ... fall into ...

; print character: A = character
prcout pha  ; save all reg's
 stx prsv_x
 sty prsv_y

 ldx #$13
prcout1 lda $24,x ; save zero page stuff
 sta przero,x
 dex
 bpl prcout1

 bit prinit ; has printer been used?
 bmi prcout3 ; yep

 lda #$10
 sta $26 ; setup slot pointer
 lda #$c1
 sta $37 ; point ($0036) at $c100
 lda #0 ; init printer card
 sta prcol ; reset column
 tax
 tay
 sta $24
 sta $27 ; zero character buffer
 sta $36

 jsr $c100
 lda $36 ; point to output routine
 sta jpcout2+1
 lda $37
 sta jpcout2+2
 dec prinit ; show we have done init

 lda #'I'-$40 ; send ctrl-I 80 n
 jsr jpcout
 lda #'8'
 jsr jpcout
 lda #'0'
 jsr jpcout
 lda #'N'
 jsr jpcout

prcout3 lda #0 ; set ch over to border
 sta $24
 inc prcol ; move over 1 col
 pla  ; get byte to print
 pha
 and #$7f ; print with high-bit off
 cmp #cr
 bne prcout5

 ldx #0 ; reset column
 stx prcol
prcout5 jsr jpcout

 ldx #$13
prcout4 lda przero,x ; restore zero page
 sta $24,x
 dex
 bpl prcout4

 ldx prsv_x ; restore reg's
 ldy prsv_y
 pla
 rts

jpcout ora #$80
jpcout2 jmp $c000 ; do output routine

prinit db 0
prsv_x db 0
prsv_y db 0
przero ds $14


; position to a user
gouser stx temp+1 ; reset scratch bytes
 ldx #0
 stx temp

 lsr a ; do multipication
 ror temp+1
 ror temp
 ldx temp
 tay
 lda temp+1
 jmp setpos ; position to user


seclvl db 0
shwpass db 0
secmap db $01,$02,$04,$08,$10,$20,$40,$80

prcol db 0
pagecnt db 0

prthdr asc '**  GBBS Pro  Userlist  -  Version 2.20  '
 asc '-  List Sorted By: ',ff
prthdr2 asc '**',0d
 asc '[Name]                     [Phone]    [User] '
 asc '[Pass]    [Sec]    [Last]  [Time]',0d
 asc '[Alias]                    [Number]   [Numb] '
 asc '[Word]    [Lvl]    [Call] [Limit]',0d,0d,ff

sortnam asc 'User Name     ',00,00
 asc 'User Number   ',00,00
 asc 'User Password ',00,00
 asc 'Phone Number  ',00,00
 asc 'Last Date On  ',00,00
 asc 'Security Level',00,00
