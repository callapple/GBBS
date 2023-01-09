********************************
*                              *
*   Config - Userlist Purge    *
*                              *
********************************

*-------------------------------
* Date: 01/16/90 - LTW
*-------------------------------

usrkill ldx #<start
 lda #>start  ; setup esc handler
 jsr escape

 jsr TopBox
 jsr print
 db 1,3,6
 asc '- Purge Users From System -',00

 jsr cls
 jsr print
 db 1,7,0
 asc 'Purge a group of users:',0d,0d
 asc 'Delete normal users who have not called',0d
 asc 'since: (Use [RETURN] to kill no users)',0d,0d
 asc '[XX/XX/XX] ? ',00

 jsr inpdate  ; input the date threshold
 stx date
 sta date+1

 jsr print
 db cr
 asc 'Delete special users (those users who',0d
 asc 'have a percent (%) sign in their phone',0d
 asc 'number) who have not called since:',0d,0d
 asc '[XX/XX/XX] ? ',00

 lda #-1  ; set default to auto-mode
 sta date+4

 jsr inpdate
 stx date+2
 sta date+3
 ora date
 ora date+1
 ora date+2
 beq kill1  ; just do stat check

 jsr print
 db cr
 asc 'Wait for Sysop verification before',0d
 asc 'killing old users or kill automatic-',0d
 asc 'ally? Wait for verification [Y/N] ? ',00

 jsr inpyn
 lda #0
 ror a  ; save auto/manual status
 sta date+4

kill1 jsr cls
 jsr print
 asc 'Userpurge parameter summary:',0d,0d,0d
 asc 'Kill normal before: ',00
 ldx date
 lda date+1  ; get normal date
 clc
 jsr prdate  ; show date

 jsr print
 db cr,cr
 asc 'Kill special before: ',00
 ldx date+2
 lda date+3  ; print date
 clc
 jsr prdate

 jsr print
 db cr,cr
 asc 'Program mode: ',00
 bit date+4
 bpl kill2  ; manual mode

 jsr print
 asc 'Automatic',00
 jmp kill3

kill2 jsr print
 asc 'Manual',00

kill3 jsr print
 db cr,cr,cr
 asc 'Is the above correct [Y/N] ? ',00
 jsr inpyn
 bcc kill3a
 jmp usrkill  ; try it again

kill3a jsr print
 db cr,cr
 asc 'Make sure both the config disk',0d
 asc 'and the system disk are on-line.',00
kill3b jsr getcr
 lda #1
 jsr logspec
 bcs kill3b  ; opps, try again

 jsr cls
 jsr print
 asc 'Userpurge: Running...',00

 ldx #<usrname
 lda #>usrname ; open user file
 jsr movname
 jsr open

 ldx #<hdrbuf
 lda #>hdrbuf ; gobble record 0
 ldy #128
 jsr rdpart

 ldx #1
 stx date+6  ; start at user #1
 dex
 stx date+7
 stx date+8  ; reset killed count
 stx date+9
 stx date+10  ; reset open slots
 stx date+11
 stx sortbuf  ; reset delmail list
 stx sortbuf+1

kill4 lda $c000  ; check for keypress
 cmp #esc+128 ; did they hit esc?
 bne kill4k  ; nope

 sta $c010  ; clear key
 jmp kill6  ; end the userlist

kill4k lda #0
 sta hdrbuf
 ldx #<hdrbuf
 lda #>hdrbuf ; read a user record
 ldy #128
 jsr rdpart
 bcs kill4z  ; no more data

 lda hdrbuf  ; is there real data?
 bne kill4x  ; yep

kill4z jmp kill6  ; finish up userpurge

kill4x lda hdrbuf
 and #$7f
 cmp #' '  ; good user?
 bcc kill4b  ; nope, killed

 jsr prxuser  ; show user
 jsr chkill  ; kill user?
 bcc kill5  ; all is well, keep user

 bit date+4  ; check kill mode
 bmi kill4a  ; do auto-kill

 jsr print
 db cr,cr
 asc 'Kill this user [Y/N] ? ',00
 jsr inpyn
 bcs kill5  ; nope

kill4a jsr print
 db cr,cr
 asc 'User Killed',00

 lda #0  ; do small delay
 jsr $fca8
 lda #cr  ; delete user
 sta hdrbuf

 ldx date+6  ; position to user record
 lda date+7
 jsr gouser

 ldx #<hdrbuf
 lda #>hdrbuf ; write out new user record
 ldy #128
 jsr wrpart

 ldx date+6
 lda date+7
 jsr delmail  ; kill the users mail (mark for kill)

 inc date+8
 bne kill4b  ; inc number of deleted users
 inc date+9

kill4b inc date+10  ; inc number of open slots
 bne kill5
 inc date+11

kill5 inc date+6  ; loop and do next user
 bne kill5a
 inc date+7
kill5a jmp kill4

kill6 jsr close  ; we are done
 lda sortbuf
 ora sortbuf+1 ; delete mail?
 beq kill7  ; nope

 jsr kilmail  ; delete mail

kill7 jsr cls
 jsr print
 asc 'Userpurge Result Summary:',0d,0d,0d
 asc 'Total number of user slots: ',00
 ldx date+6
 lda date+7
 jsr prnumb

 jsr print
 db cr,cr
 asc 'Total number of users purged: ',00
 ldx date+8
 lda date+9
 jsr prnumb

 jsr print
 db cr,cr
 asc 'Total number of free slots: ',00
 ldx date+10
 lda date+11
 jsr prnumb

 jsr getcr
 jmp start


; check to see if user should be killed
chkill lda hdrbuf+85 ; get phone/kill status
 and #$7f
 cmp #'*'  ; never kill?
 beq chkill4  ; yep

 cmp #'%'  ; use special check?
 beq chkill2  ; yep

 lda date+1  ; check date?
 ora date
 beq chkill4  ; nope

 lda hdrbuf+91 ; check high
* and #%00011111
 cmp date+1 
 bcc chkill3  ; kill him
 bne chkill4  ; all is well

 lda hdrbuf+90 ; check low
 cmp date
 bcs chkill4  ; they are ok
 bcc chkill3  ; kill them

chkill2 lda date+3  ; check date?
 ora date+2
 beq chkill4  ; nope

 lda hdrbuf+91 ; check high
* and #%01111111
 cmp date+3
 bcc chkill3  ; kill the sucker
 bne chkill4  ; all is well

 lda hdrbuf+90 ; check low
 cmp date+2
 bcs chkill4  ; they are ok

chkill3 sec   ; kill user
 rts

chkill4 clc   ; save user
 rts


; print data on user to kill
prxuser ldx #7  ; clear bottom of screen
 jsr cleos
 lda #7  ; vtab 3
 sta cv

 lda #'#'  ; add in prefix
 jsr cout

 ldx date+6
 lda date+7  ; compute user-number text
 jsr prnumb

 pha
 lda #' '
 jsr cout  ; move over 1 space
 pla

 ldx #<hdrbuf ; point at user name
 lda #>hdrbuf
 ldy #","  ; display first name
 jsr prstr

 pha
 lda #' '
 jsr cout  ; move over 1 space
 pla

 ldy #cr+128
 jsr prstr  ; display last name
 jsr cleol  ; clear to end

 ldy #cr+128  ;skip lowercase name
 jsr skipstr

 jsr print
 db cr
 asc 'of ',00

 ldy #cr+128
 jsr prstr  ; print where from
 jsr cleol

 jsr print
 db cr,cr
 asc 'Last Date On: ',00

 ldx hdrbuf+90
 lda hdrbuf+91
 sec
 jmp prdate  ; display date


; input a date
inpdate lda #8  ; set length
 sta maxlen
 lda #%11100000
 sta inpmode
 lda ch
 sta date+5

inpdat1 jsr inpln  ; get date
 lda lnbuf
 cmp #cr  ; blank line?
 bne inpdat2  ; yep

 ldx #0  ; return no date
 txa
 rts

inpdat2 lda #0  ; reset scratch
 sta temp3

 ldx #<lnbuf
 lda #>lnbuf   ; get month of year
 jsr numin
 txa
 lsr a
 ror temp3
 lsr a
 ror temp3  ; do low
 lsr a
 ror temp3
 sta temp3+1  ; save high

 ldx #<lnbuf+6
 lda #>lnbuf+6 ; get the year
 jsr numin
 txa
 and #%01111111
 asl a
 ora temp3+1  ; add in month

 pha
 ldx #<lnbuf+3
 lda #>lnbuf+3  ; get day of month
 jsr numin
 txa
 and #%00011111
 ora temp3
 tax   ; restore day
 ora temp3+1
 bne inpdat4

 pla
; jsr bell  ; give them warning
inpdat3 lda ch
 cmp date+5
 beq inpdat1  ; get new input

 lda #bs  ; backup 1 space
 jsr cout
 jmp inpdat3  ; start again

inpdat4 pla
 rts

date ds 12


; print the date to the console
prdate stx temp  ; save date
 sta temp+1
 ora temp  ; check for date
 bne prdate2
 bcs prdate1  ; show old user

 jsr print
 asc .[ Don't Purge ].,00
 rts

prdate1 jsr print
 asc '00/00/00',00
 rts

prdate2 txa   ; get most of month
 lsr temp+1   ; shift last bit into carry
 ror a  ; move bit in
 lsr a
 lsr a
 lsr a
 lsr a  ; get into position
 jsr bindec8
 jsr decprn8  ; print it out
 lda #'/'
 jsr cout

 lda temp
 and #%00011111 ; translate day
 jsr bindec8
 jsr decprn8  ; print out
 lda #'/'
 jsr cout

 lda temp+1
 and #%01111111
 jsr bindec8
   ; fall through to print year
; print out a 8 bit number
decprn8 jsr cout
 txa
 jmp cout


; delete a users mail
delmail stx temp  ; save user number
 sta temp+1

 lda #<sortbuf-$100
 sta temp2  ; point to tablk of mail to kill
 lda #>sortbuf-$100
 sta temp2+1
 ldy #-1

delml2 iny   ; do a pre-inc
 bne *+4
 inc temp2+1
 lda (temp2),y
 iny
 ora (temp2),y ; check for end of table
 bne delml2  ; nope

 dey
 lda temp  ; save user number
 sta (temp2),y
 iny
 lda temp+1
 sta (temp2),y
 iny   ; go to next table entry
 bne *+4
 inc temp2+1

 lda #0  ; save end of table marker
 sta (temp2),y
 iny
 sta (temp2),y
 rts


; kill the users mail
kilmail rts   ; remove for now

 jsr cls
 jsr print
 asc 'Please remove the system disk and',0d,0d
 asc 'replace it with the mail disk. All',0d,0d
 asc 'deleted users will then have their',0d,0d
 asc 'mail marked for deletion.',00

kilml1 jsr getcr
 lda #4
 jsr logspec
 bcs kilml1

 jsr cls
 jsr print
 db 1,8,10
 asc 'Deleting Mail',00

 ldx #<mail
 lda #>mail
 ldy #0  ; open the mail file
 jsr open

 ldx #<lnbuf
 lda #>lnbuf
 ldy #8  ; read in header
 jsr rdpart

 lda #<sortbuf ; point to buffer
 sta temp2
 lda #>sortbuf
 sta temp2+1

kilml2 ldy #0
 lda (temp2),y ; get user # to kill
 sta temp
 iny
 lda (temp2),y
 sta temp+1
 ora temp
 beq kilml4  ; we are done

 lda temp+1
 asl temp
 rol a
 asl temp  ; compute dir block
 rol a
 asl temp
 rol a
 sta temp+1
 jsr posdir  ; position to block

 ldx #<hdrbuf
 lda #>hdrbuf
 ldy #128  ; read in dir block
 jsr rdpart

 lda temp
 lsr a  ; get offset into block
 tax
 lda hdrbuf+2,x ; do they have mail?
 ora hdrbuf+3,x
 beq kilml3  ; nope

 lda #0  ; set marker to 1024
 sta hdrbuf,x
 lda #4
 sta hdrbuf+1,x

 lda temp+1  ; position back to block
 jsr posdir

 ldx #<hdrbuf
 lda #>hdrbuf
 ldy #128  ; write out directory block
 jsr wrpart

kilml3 inc temp2  ; inc to next user #
 inc temp2
 bne *+4
 inc temp2+1
 jmp kilml2

kilml4 jmp close  ; close mail and return


; position into the directory
posdir lda lnbuf  ; get # of bit-maps
 sta temp3
 lda #16
 lsr temp3
 ror a  ; position into dir file
 tax
 lda temp3
 ldy #0
 jmp setmark


; name of the mail file on disk
mail db 4
 asc 'MAIL'
