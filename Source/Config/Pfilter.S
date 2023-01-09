* Date: 3/11/88
*-------------------------------

*-------------------------------
* profanity filter
*-------------------------------
   ; change profanity filter (yuk)
do_filt jsr logprg ; log to 'acos.obj' drive
 ldx #<gname
 lda #>gname ; point to filename
 jsr movname
 jsr open ; open file

 ldx #00
 lda filter ; point at filter table
 jsr setmark

 ldx #<hdrbuf
 lda #>hdrbuf
 ldy #2 ; read 1 page (2 blocks)
 jsr rdblk
 jsr close ; thats it for now

filt2 jsr TopBox
 jsr print
 db 1,3,7
 asc '- Edit Profanity Filter -',00
 jsr cls

 lda #0 ; start at #1
 sta temp2

filt3 ldx temp2 ; get entry number
 jsr fndword ; find the word
 bcs filt5 ; opps, end of table

 lda ch ; save current horiz
 pha

 lda temp2 ; print entry letter
 clc
 adc #'A'
 jsr cout
 inc temp2 ; goto next entry next pass

 lda #')' ; show a border
 jsr cout
 inc ch ; move over 1 space

filt4 lda hdrbuf,y ; get data
 php
 jsr cout ; print data
 iny
 plp
 bpl filt4 ; keep showing

 pla
 clc
 adc #19
 sta ch ; move over horiz position

 lda #' ' ; either wrap or move 1 space
 jsr cout
 jmp filt3

filt5 jsr print
 db 1,20,0
 asc 'Cmd: A=Add, D=Delete, Q=Quit ? ',00

 lda #1
 sta maxlen ; get command
 lda #%10000000
 sta inpmode
 jsr inpln

 lda lnbuf
 cmp #'A'
 bne :tryd
 jmp fl_add
:tryd cmp #'D'
 beq fl_del
:tryq cmp #'Q'
 bne filt5
 jmp fl_quit

*-------------------------------
* delete a word from list

fl_del ldx #20
 jsr cleos ; clear line
 jsr print
 db 1,20,0
 asc 'Delete [A-',00

 clc
 lda temp2
 adc #'@'
 jsr cout ; print range

 jsr print
 asc '] ? ',00

 lda #%10000000
 sta inpmode ; set mode

 jsr inpln ; get data
 lda lnbuf
 cmp #'A'
 bcc filt5 ; move back, error

 sec
 sbc #'A' ; make into [0-xxx] range
 cmp temp2
 bcc *+5
 jmp filt5 ; out of range

 pha
 tax
 inx
 jsr fndword ; locate second word
 sty temp2+1 ; save offset
 pla
 tax
 jsr fndword ; locate first word
 ldx temp2+1 ; point to second word

fl_del2 lda hdrbuf,x ; move data
 sta hdrbuf,y
 iny
 inx
 bne fl_del2 ; loop
 jmp filt2 ; show new screen

; add a word to list
fl_add ldx #20
 jsr cleos ; clear line
 jsr print
 db 1,20,0
 asc 'Enter new word: ',00

 lda #16 ; 16 chars max length
 sta maxlen
 lda #%10000000
 sta inpmode ; set input mode

 jsr inpln ; get the data
 lda lnbuf
 cmp #'A'
 bcc fl_add4 ; abort

 ldx temp2 ; get last word
 jsr fndword ; find end
 sty temp2+1 ; save current end

 ldx #0
fl_add2 lda lnbuf,x
 cmp #'A'
 bcc fl_add3

 sta hdrbuf,y ; add byte
 inx
 iny
 bne fl_add2 ; and loop

 lda #0
 ldy temp2+1 ; mark old end of table
 sta hdrbuf,y

 jsr print
 db 1,20,0
 asc 'Error: Filter Table Overrun.   Press [RETURN] ',00
 jsr getcr ; wait for cr
fl_add4 jmp filt5 ; get new data

fl_add3 lda #0 ; mark end of table
 sta hdrbuf,y
 dey
 lda hdrbuf,y ; mark as last char
 ora #$80
 sta hdrbuf,y
 jmp filt2 ; show new table

; quit from filter changer
fl_quit ldx #20
 jsr cleos ; clear bottom of screen
 jsr print
 db 1,20,0
 asc 'Is the above table correct [Y/N] ? ',00
 jsr inpyn
 bcc fl_save
 jmp start ; nope!

fl_save jsr logprg ; log to 'acos.obj' drive
 ldx #<gname
 lda #>gname ; setup name buffer
 jsr movname
 jsr open ; open file

 ldx #00
 lda filter ; position to filter table
 jsr setmark

 ldx #<hdrbuf
 lda #>hdrbuf
 ldy #2 ; write 1 page (2 blocks)
 jsr wrblk
 jsr close ; thats it for now
 jmp start


; locate a word [indexed by x]
fndword ldy #0
 cpx #0 ; we done?
 beq fndwd2 ; yep

fndwd1 lda hdrbuf,y ; loop until next word
 beq fndwd4 ; end of table

 iny  ; goto next byte
 asl a ; check high bit
 bcc fndwd1

 dex  ; count down entries
 bne fndwd1

fndwd2 lda hdrbuf,y
 beq fndwd4 ; opps, that is end marker

fndwd3 clc
 rts  ; we are done

fndwd4 sec  ; opps, end of table
 rts

*-------------------------------
* Quit
*-------------------------------

; quit the program
do_quit jsr $fc58 ; clear screen
 sta $c051 ; goto text mode

 lda #$ff ; reset inverse flag
 sta $32


 jsr mli
 db $65 ; quit
 dw p_quit
 rts


p_quit db 4
 db 0
 dw 0
 db 0
 dw 0


