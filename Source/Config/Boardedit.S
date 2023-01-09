********************************
*                              *
* Config - Edit Bulletins Info *
*                              *
********************************

*-------------------------------
* Date: 01/19/87
*-------------------------------

brdedit jsr TopBox
 jsr print
 db 1,3,7
 asc '- Edit Bulletin Board Info -',00

brded1 jsr cls
 jsr print
 db 1,7,0
 asc 'Please make sure that both the "CONFIG"',0d
 asc 'disk and the "SYSTEM" disk are on-line',0d
 asc 'and available for access.',00
 jsr getcr ; wait for an 'ok'
 lda #1
 jsr logspec ; log there
 bcs brded1

do_edit ldx #$f0 ; reset stack
 txs
 ldx #<start
 lda #>start ; setup esc handler
 jsr escape

 jsr cls
 jsr print
 asc 'Select an Option:',0d,0d
 asc '  1) Clear all previous boards',0d
 asc '  2) Add a new bulletin board',0d
 asc '  3) Delete a bulletin board',0d
 asc '  4) Edit an existing board',0d
 asc '  5) Swap two bulletin boards',0d
 asc '  6) List all bulletin boards',0d
 asc '  7) Create board storage file',0d
 asc '  8) Return back to main menu',0d,0d
 asc 'Enter choice [1-8] ? ',00

 ldx #8 ; input choice
 jsr inpnum

 pha
 ldx #<do_edit ; setup esc handler
 lda #>do_edit
 jsr escape
 pla
 asl a
 tax

 lda edjmptbl,x
 sta prn
 inx  ;push low
 lda edjmptbl,x
 sta prn+1
 jmp (prn)

edjmptbl dw 0
 dw b_clr ; clear current boards
 dw b_add ; add a new board
 dw b_del ; delete a board
 dw b_edit ; edit a board
 dw b_swap ; swap 2 boards
 dw b_list ; list all boards
 dw b_creat ; create new bulletin board
 dw start

; clear all current boards
b_clr jsr cls ; clear screen
 jsr print
 db 1,7,12
 asc 'Clear all boards',0d,0d
 asc 'This operation will delete your board',0d
 asc 'configuration.  Do you really wish to',0d
 asc 'continue [Y/N] ? ',00
 jsr inpyn
 bcc b_clr1
 jmp do_edit ; nope

b_clr1 lda #0
 jsr snumbd2 ; set boards to 0
 jsr opend2
 ldx #<1152
 lda #>1152 ; set end of file
 jsr puteof
 jsr close
 jmp b_add0 ; add a new board

; add a new bulletin board
b_add jsr cls
 jsr print
 db 1,7,12
 asc 'Add a board',0d,0d
 asc 'Do you wish to add another bulletin',0d
 asc 'board to your system [Y/N] ? ',00
 jsr inpyn
 bcc b_add0
 jmp do_edit ; nope

b_add0 jsr gnumbd2 ; get number of boards
 clc
 adc #1 ; add 1 to number of boards
 sta recnum
 jsr snumbd2

 pha
 ldx #0
 txa
b_add1f sta hdrbuf,x ; fill buffer with zero's
 inx
 bpl b_add1f

 ldx #0
b_add1 lda newbd,x ; copy over the new board data
 sta hdrbuf,x
 inx
 cpx #newbdnd-newbd
 bne b_add1

 lda #'F' ; add on prefix
 sta lnbuf
 lda #':'
 sta lnbuf+1
 lda #'B'
 sta lnbuf+2
 lda #cr
 sta lnbuf+4 ; add end of line
 sta lnbuf+5

 pla  ; get number of boards
 pha
 jsr bindec8 ; translate into ascii
 stx lnbuf+3
 cmp #'0' ; was it greater than 10?
 beq b_add2 ; nope

 sta lnbuf+3 ; save complete spec
 stx lnbuf+4

b_add2 ldy #1 ; change default drive/name
 jsr chgdata

 jsr opend2 ; open data2
 pla
 tay  ; save new record number
 ldx #<hdrbuf ; point to record
 lda #>hdrbuf
 jsr writed2 ; save record
 jsr close

 lda #-1 ; set flag for going to create storage
 sta gomake
 jmp b_edit1 ; edit it


; delete a current board
b_del jsr cls
 jsr print
 db 1,7,12
 asc 'Delete a Board',0d,0d,00

 jsr gnumbd2 ; get number of boards
 pha

 jsr print
 asc 'Enter the number of the bulletin',0d
 asc 'board that you want to delete.',0d
 asc 'Delete Board [1-',00

 pla
 pha
 jsr bindec8 ; print # of boards
 jsr decout8

 jsr print
 asc '] ? ',00

 pla  ; get number of boards
 pha
 tax
 jsr inpnum ; get selection
 sta temp2

 pla
 sec
 sbc #1 ; save new number of boards
 sta temp2+1
 jsr snumbd2 ; set new number of boards

 jsr opend2
 ldx temp2+1 ; did they do last board?
 inx
 cpx temp2
 beq b_del3 ; yep

b_del2 ldy temp2 ; get the board part marker
 iny
 ldx #<hdrbuf ; move back a board
 lda #>hdrbuf
 jsr readd2 ; get data

 ldy temp2
 ldx #<hdrbuf
 lda #>hdrbuf
 jsr writed2 ; save data

 lda temp2
 inc temp2
 cmp temp2+1 ; done?
 bne b_del2 ; nope

b_del3 jsr geteof ; get the end of file
 sec
 pha
 txa
 sbc #128 ; move back eof 128 bytes
 tax
 pla
 sbc #0
 jsr puteof
 jsr close ; close file
 jmp do_edit ; go back to start

; edit a board
b_edit jsr cls
 jsr print
 db 1,7,12
 asc 'Edit a Board',0d,0d,00

 jsr gnumbd2 ; get number of boards
 pha

 jsr print
 asc 'Enter the number of the bulletin',0d
 asc 'board that you want to edit.',0d
 asc 'Edit Board [1-',00

 pla  ; get # of boards
 pha
 jsr bindec8 ; display number
 jsr decout8

 jsr print
 asc '] ? ',00

 pla
 tax  ; limit input
 jsr inpnum
 sta recnum ; and save

 lda #0 ; reset jump to create storage
 sta gomake

b_edit1 jsr opend2
 ldy recnum
 ldx #<hdrbuf
 lda #>hdrbuf ; read in record
 jsr readd2
 jsr close

b_edit2 ldx #<do_edit
 lda #>do_edit ; setup esc handler
 jsr escape

 jsr cls
 jsr print
 db 1,7,0
 asc '1) Name: ',00

 ldx #<hdrbuf
 lda #>hdrbuf
 ldy #cr+128
 jsr prstr ; print name

 jsr print
 db cr
 asc '2) File: ',00
 ldy #cr+128
 jsr prstr ; print filename

 jsr print
 db cr,cr
 asc '3) Access: ',00
 ldy #","
 jsr prstr ; show access level

 jsr print
 db 1,10,18
 asc '4) Write: ',00
 ldy #cr+128
 jsr prstr ; show write level

 jsr print
 db cr,cr
 asc '5) Aux Sysop Numb: ',00
 pha
 stx temp3

 jsr numin ; get value from number
 stx temp3+1
 ora temp3+1 ; save zero status
 sta temp3+1

 ldx temp3
 pla
 ldy #","
 jsr prstr ; show sysop number

 jsr print
 db cr
 asc '6) Aux Sysop Name: ',00
 ldy #cr+128
 jsr prstr ; print name

 pha
 lda ch ; did anything get printed?
 cmp #19
 bne b_edit5 ; yep, dont process

 lda temp3+1 ; was their an aux sysop?
 beq b_edit6 ; nope

 jsr print
 asc '[ Use Real Name ]',00
 jmp b_edit5

b_edit6 jsr print
 asc '[ No Aux Sysop ]',00

b_edit5 pla
 jsr print
 db cr,cr
 asc '7) Max #  of Bulletins: ',00
 ldy #","
 jsr prstr ; show max bulletins

 jsr print
 db cr
 asc '8) Auto Kill Threshold: ',00
 ldy #","
 jsr prstr

 jsr print
 db cr
 asc '9) Bulletin #  to Kill: ',00
 ldy #cr+128
 jsr prstr

 jsr print
 db cr,cr
 asc '10) Abort without Saving',0d
 asc '11) Save changes and Quit',0d,0d

 asc 'Edit [1-11] ? ',00
 ldx #11
 jsr inpnum
 cmp #10
 bcs b_edit3 ; opps, save or abort

 pha
 asl a
 tax
 lda xyedit-2,x ; do positioning
 sta cv
 lda xyedit-1,x
 sta ch

 ldx #<b_edit2
 lda #>b_edit2 ; setup esc handler
 jsr escape

 lda #%00100000 ; set default mode
 sta inpmode
 lda #30 ; max length 30 chars
 sta maxlen
 jsr inpln ; get their input
 pla

 tay
 dey  ; setup data pointer
 cmp #6 ; was it aux sysop name?
 beq b_edit3 ; yep

 ldx lnbuf ; did they enter a line?
 cpx #cr
 bne b_edit3 ; yep
 jmp b_edit2 ; nope

b_edit3 jsr b_edit4 ; handle dispatch
 jmp b_edit2

b_edit4 asl a
 tax
 lda edjmptbl1,x
 sta prn
 inx  ;push low
 lda edjmptbl1,x
 sta prn+1
 jmp (prn)

edjmptbl1 dw 0
 dw chgdata
 dw chgdata
 dw e_acces
 dw e_acces
 dw e_auxnb
 dw chgdata
 dw e_var
 dw e_var
 dw e_var
 dw e_abort
 dw e_edit


; code to handle editing each parameter
e_acces ldx #<34
 lda #>34
 jmp chgnumb ; change the number

e_auxnb ldx #<5000
 lda #>5000
 jsr chgnumb ; change the number
 ldx #<lnbuf
 lda #>lnbuf
 jsr numin ; get number
 stx temp
 ora temp
 bne e_auxnm ; opps, an aux sysop

 lda #cr
 sta lnbuf
 ldy #5 ; kill aux sysop
 jsr chgdata
e_auxnm rts

e_var ldx #<1024 ; maximum of 1024 bulletins
 lda #>1024
 jmp chgnumb

e_edit jsr print
 db 1,22,0
 asc 'Save: Are you Sure [Y/N] ? ',00
 jsr inpyn
 bcs e_abt2 ; nope

 jsr opend2 ; open data2
 ldx #<hdrbuf
 lda #>hdrbuf
 ldy recnum ; get record number
 jsr writed2 ; write record
 jsr close
 bit gomake ; make storage file
 bpl e_abt1

 lda recnum ; create file number recnum
 jmp makebd

e_abt1 jmp do_edit ; we are done

e_abort jsr print
 db 1,22,0
 asc 'Abort: Are you Sure [Y/N] ? ',00
 jsr inpyn
 bcc e_abt1 ; yep

e_abt2 rts


; swap 2 boards
b_swap jsr cls
 jsr print
 db 1,7,12
 asc 'Swap two boards',0d,0d,00

 jsr gnumbd2 ; get # of boards
 sta temp+1

 jsr print
 asc 'Enter the numbers of the two bulletin',0d
 asc 'boards that you wish to swap.',0d,0d
 asc 'Swap Board [1-',00

 lda temp+1
 pha
 jsr bindec8 ; print number
 jsr decout8

 jsr print
 asc '] ? ',00 ; prompt for number

 pla
 pha
 tax
 jsr inpnum ; get first board #
 sta temp

 jsr print
 db cr,cr
 asc 'With Board [1-',00

 pla
 pha
 jsr bindec8 ; print number
 jsr decout8

 jsr print
 asc '] ? ',00

 pla
 tax  ; get second board
 jsr inpnum
 sta temp+1

 jsr opend2 ; open data2

 ldy temp+1
 ldx #<hdrbuf
 lda #>hdrbuf
 jsr readd2 ; read data2

 ldy temp ; get first board
 ldx #<hdrbuf+$100
 lda #>hdrbuf+$100
 jsr readd2 ; read second record

 ldy temp
 ldx #<hdrbuf
 lda #>hdrbuf
 jsr writed2 ; write second record

 ldy temp+1
 ldx #<hdrbuf+$100
 lda #>hdrbuf+$100
 jsr writed2 ; write first record
 jsr close
 jmp do_edit


; list all boards
b_list jsr cls
 jsr print
 db 1,7,12
 asc 'List all boards',0d,0d,00

 jsr gnumbd2 ; get number of boards
 clc
 adc #1
 sta recnum+1 ; save total + 1

 lda #1 ; start at record 1
 sta recnum
 jsr opend2 ; open data file
 lda #11
 sta recnum+2 ; only list 11 lines

b_list2 ldy recnum
 cpy recnum+1
 beq b_list3 ; we are done

 ldx #<hdrbuf
 lda #>hdrbuf
 jsr readd2 ; read data file

 lda recnum
 jsr bindec8
 jsr decout8
 jsr print
 asc ')',00
 lda #4
 sta ch ; htab over

 ldx #<hdrbuf
 lda #>hdrbuf ; print name of board
 ldy #cr+128
 jsr prstr

 ldy #34 ; htab over
 sty ch

 ldy #cr+128
 jsr prstr ; print drive spec
 lda #cr
 jsr cout ; move down a line
 inc recnum
 dec recnum+2
 bne b_list2 ; list next entry

 lda #11 ; reset line counter
 sta recnum+2
 jsr getcr ; wait for a return
 ldx #9 ; clear bottom of screen
 jsr cleos
 jsr print
 db 1,9,0,00
 jmp b_list2 ; clear and loop

b_list3 lda recnum+2 ; did we just wait for a return?
 cmp #11
 beq b_list4 ; yep

 jsr getcr
b_list4 jsr close
 jmp do_edit ; return to menu


; create a new bulletin file
b_creat jsr cls
 jsr print
 db 1,7,8
 asc 'Create board storage file',0d,0d,00

 jsr gnumbd2 ; get the number of boards
 pha

 jsr print
 asc 'Enter the number of the board you wish',0d
 asc 'to create a storage file for.',0d
 asc 'Create for Board [1-',00

 pla
 pha
 jsr bindec8 ; display number of boards
 jsr decout8

 jsr print
 asc '] ? ',00
 pla
 tax  ; get board number
 jsr inpnum

makebd pha
 jsr opend2 ; open the data file
 pla
 tay  ; point to record
 ldx #<hdrbuf
 lda #>hdrbuf
 jsr readd2 ; read the file
 jsr close

b_cre2 jsr cls
 jsr print
 db 1,7,8
 asc 'Create board storage file',0d,0d
 asc 'Name: ',00

 ldx #<hdrbuf
 lda #>hdrbuf ; print board name
 ldy #cr+128
 jsr prstr

 jsr print ; print file name
 db cr,cr
 asc 'File: ',00
 ldy #cr+128
 jsr prstr

 jsr print
 db cr,cr
 asc 'Directory Capacity [default=',00

 lda #6
 jsr findata
 jsr numin ; get max bulletins
 pha
 clc
 txa
 adc #31 ; move up
 and #%11100000 ; make multiple of 32
 tax
 pla
 adc #0
 stx crbbs ; save the default
 sta crbbs+1
 jsr prnumb ; display default capacity

 jsr print
 asc ']: ',00
 lda #4 ; only allow 4 chars
 sta maxlen
 lda #%00100000
 sta inpmode
 jsr inpln ; get the input
 ldx crbbs ; get default capacity
 lda crbbs+1
 ldy lnbuf
 cpy #cr
 beq b_cre3 ; use default

 ldx #<lnbuf ; get number
 lda #>lnbuf
 jsr numin
b_cre3 stx crbbs+2 ; save input
 sta crbbs+3
 ora crbbs+2 ; check for 0
 bne *+5
 jmp b_cre2 ; make them do it again

 jsr print
 db cr
 asc 'Storage Capacity  [default=',00

 ldx crbbs
 lda crbbs+1 ; display default
 jsr prnumb
 jsr print
 asc 'k]: ',00

 jsr inpln
 ldx crbbs ; default storage
 lda crbbs+1
 ldy lnbuf
 cpy #cr
 beq b_cre4 ; use default

 ldx #<lnbuf
 lda #>lnbuf ; get number
 jsr numin
b_cre4 stx crbbs+4 ; save input
 sta crbbs+5
 ora crbbs+4
 bne *+5
 jmp b_cre2 ; make them do it again

 jsr cls
 jsr print
 db 1,7,10
 asc 'Board Specifications:',0d,0d
 asc 'Name: ',00

 ldx #<hdrbuf
 lda #>hdrbuf
 ldy #cr+128 ; show board name
 jsr prstr

 jsr print
 db cr,cr
 asc 'File: ',00
 ldy #cr+128 ; show file name
 jsr prstr

 jsr print
 db cr,cr
 asc 'Max Bulletins: ',00
 ldx crbbs+2
 lda crbbs+3
 jsr prnumb

 jsr print
 db cr,cr
 asc 'Max Storage: ',00
 ldx crbbs+4
 lda crbbs+5
 jsr prnumb

 jsr print
 asc 'k',0d,0d
 asc 'Is the above correct [Y/N] ? ',00
 jsr inpyn
 bcc *+5
 jmp do_edit

 lda #1 ; point to filename
 jsr findata
 stx temp
 sta temp+1

 ldy #0
 lda (temp),y
 jsr conv ; find & save drive
 sec
 sbc #'A'
 sta drvspec

 iny  ; check for drive spec
 lda (temp),y
 and #$7f
 cmp #':'
 beq b_cre4b ; got it

 jsr print
 db cr,cr
 asc 'Error: This board does not have a drive',0d
 asc 'specifier in its filename.',00
 jsr getcr
 jmp do_edit

b_cre4b ldx #-1 ; point into flname buffer
b_cre5 inx
 iny
 lda (temp),y ; copy filename
 jsr conv
 sta flname+1,x
 cmp #'.' ; done?
 bcc b_cre6 ; nope

 cpx #16 ; truncate length
 bne b_cre5

b_cre6 stx flname ; save filename length
 jsr print
 db cr,cr
 asc 'Make sure ',00
 lda drvspec
 clc
 adc #'A'
 jsr cout
 jsr print
 asc ': is on-line.',00

b_cre7 jsr getg
 lda drvspec
 jsr logspec ; log to drive
 bcs b_cre7 ; opps, try again

 ldx #<flname
 lda #>flname ; see if file exists
 ldy #0
 jsr open
 php
 jsr close
 plp
 bcc *+5
 jmp b_cre7a ; nope file by that name

 jsr cls
 jsr print
 db 1,7,0
 asc 'There is already a bulletin storage',0d
 asc 'file with this name. If you proceed,',0d
 asc 'the bulletins in that file will be',0d
 asc 'destroyed.',0d,0d
 asc 'Do you wish to continue [Y/N] ? ',00
 jsr inpyn
 bcc *+5
 jmp do_edit ; abort create


 ldx #<flname
 lda #>flname
 jsr delfile ; delete file in question

b_cre7a clc
 lda crbbs+4 ; round up blocks
 adc #127
 sta crbbs+4
 lda crbbs+5
 adc #0
 asl crbbs+4 ; move in bit 7
 rol a
 sta bullhdr ; and save

 clc
 lda crbbs+2
 adc #31
 sta crbbs+2 ; round up dir's
 lda crbbs+3
 adc #0
 lup 3
 asl crbbs+2 ; shift in 3 bits
 rol a
 --^
 sta bullhdr+1 ; and save

 clc
 adc bullhdr
 sta drvspec ; save total blocks to write

 ldx #<flname ; create a new file
 lda #>flname
 ldy #6 ; use binary file type
 jsr create

 ldx #<flname ; open the new file
 lda #>flname
 ldy #0
 jsr open

 ldx #<bullhdr
 lda #>bullhdr
 ldy #8 ; write out the header
 jsr wrpart

 ldx #0
 txa
b_cre8 sta hdrbuf,x ; fill buffer with zero's
 inx
 bne b_cre8

b_cre9 ldx #<hdrbuf ; write out a blank block
 lda #>hdrbuf
 ldy #128
 jsr wrpart
 dec drvspec ; count down and loop
 bne b_cre9

 jsr close
 jmp do_edit

; --- sub-routines ---

; open the data2 file
opend2 ldx #<data2 ; open data2 file
 lda #>data2
 jsr movname ; setup name pointer
 jmp open

data2 str 'DATA2'

; get number of boards
gnumbd2 lda #1 ; log to system drive
 jsr logspec
 jsr opend2 ; open data2
 ldx #<1120 ; position to byte 1120
 lda #>1120
 jsr setmark

 ldx #<lnbuf+128 ; read # boards into lnbuf
 lda #>lnbuf+128
 ldy #10
 jsr rdpart

 jsr close ; close file

 ldx #<lnbuf+128
 lda #>lnbuf+128 ; get # of boards
 jsr numin
 txa
 rts

; save number of boards
snumbd2 pha
 jsr opend2 ; open data2 file
 ldx #<1120
 lda #>1120 ; position to byte 1120
 jsr setmark
 pla

 pha
 jsr bindec8 ; translate to 2 digit
 sta lnbuf+128
 stx lnbuf+129
 lda #cr ; add terminator char
 sta lnbuf+130

 ldx #<lnbuf+128
 lda #>lnbuf+128
 ldy #10 ; write out 10 bytes
 jsr wrpart

 jsr close
 pla
 rts

; read in a record from the data2 file
readd2 jsr findd2 ; find a record 
 ldy #128
 jmp rdpart

; write out a record to the data2 file
writed2 jsr findd2 ; find a record
 ldy #128
 jmp wrpart

; find a  record
findd2 pha
 txa  ; save buffer address
 pha

 lda #0
 sta temp3
 tya
 clc
 adc #8 ; offset 8, 128 byte records

 lsr a
 ror temp3 ; records are 128 bytes
 ldx temp3
 ldy #0
 jsr setmark ; position there

 pla
 tax  ; restore & return
 pla
 rts


; insert data into record
chgdata sty temp3 ; save record number
 iny
 tya
 jsr chg9 ; find second entry
 txa
 pha

 lda temp3
 jsr chg9 ; find actual entry
 inx
 stx temp3 ; save pointer
 pla
 tay

 lda #0 ; mark end of data
 sta hdrbuf+128

chgd2 lda hdrbuf,y ; delete current text
 sta hdrbuf,x
 inx
 iny
 asl a
 bne chgd2

 ldx #-1
chgd3 inx
 lda lnbuf,x ; get data
 cmp #cr
 beq chgd5 ; opps, we are done

 ldy temp3 ; get pointer
 inc temp3 ; (do forward order)
chgd4 pha
 lda hdrbuf,y
 sta temp3+1 ; save byte
 pla
 sta hdrbuf,y
 beq chgd3

 iny
 lda temp3+1 ; restore byte
 jmp chgd4

chgd5 rts


; lookup data within a record
findata jsr chg9 ; find data
 inx
 lda #>hdrbuf
 rts


; lookup an entry
chg9 ldx #-1
 ldy #0
 sta x_save ; save counter
 asl a
 beq chg9b ; we are done

chg9a inx
 lda hdrbuf,x ; get data
 cmp delim,y
 bne chg9a

 iny
 cpy x_save ; we done?
 bne chg9a ; nope

chg9b rts


; make sure a number is legal and change it
chgnumb stx temp3 ; save range
 sta temp3+1
 sty temp2

 ldx #<lnbuf
 lda #>lnbuf
 jsr numin ; process number

 cmp temp3+1
 beq chgnum0
 bcc chgnum1
 bcs chgnum3

chgnum0 cpx temp3
 beq *+4
 bcs chgnum3

chgnum1 jsr decmem ; process number

 ldx #5
chgnum2 lda txtnum+1,x ; copy number
 sta lnbuf,x
 dex
 bpl chgnum2

 ldx txtnum
 lda #cr ; end line
 sta lnbuf,x

 ldy temp2
 jmp chgdata

chgnum3 rts


; new board default data
newbd asc 'New Board',0d,
 asc 'F:Bxx',0d
 asc '1,1',0d
 asc '0,',0d
 asc '128,0,0',0d
newbdnd db 0

; positions on edit template
xyedit db 7,9
 db 8,9
 db 10,11,10,28
 db 12,19
 db 13,19
 db 15,24
 db 16,24
 db 17,24
 db 0,0
 db 0,0

; field delimiters within file
delim db cr,cr
 asc ',',0d
 asc ',',0d
 asc ','
 asc ','
 db cr
; toggle for add
gomake db 0

; working record number
recnum db 0,0,0

; record of bbs stats
crbbs db 0,0,0,0,0,0

; drive spec 
drvspec db 0,0

; bulletin file header
bullhdr db 0,0,0,0,0,0,0,0


