********************************
*                              *
*   Config Program - Routine   *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------


*-------------------------------
* print a line of text
*-------------------------------

print sta psave ; save all reg's
 sty psave+1
 pla
 sta prnt ; point to address of data
 pla
 sta prnt+1

print2 inc prnt ; inc address
 bne print3
 inc prnt+1

print3 ldy #0
 lda (prnt),y ; get data
 cmp #1
 bne pr3a

pr3v jsr gettmp
 jsr gettmp ; get horiz/vert address
 sta cv
 jsr gettmp
 sta ch
 jmp print3

pr3a pha
 jsr cout ; display it
 pla
 bne print2 ; keep going

 jsr gettmp
 lda psave
 ldy psave+1
 jmp (prnt)

*-------------------------------
* get a byte from temp and advance pointers
*-------------------------------

gettmp ldy #0
 lda (prnt),y
 inc prnt
 bne gettmp2
 inc prnt+1
gettmp2 rts

*-------------------------------
* put a cursor, get a key, remove cursor, return
*-------------------------------

rdkey stx x_save ; save x & y
 sty y_save
 lda #$5f
 jsr plotchr ; bypass cout for speed

rdkey2 lda $c000 ; check for a key
 bpl rdkey2
 sta $c010 ; reset flag
 and #$7f
 cmp #1 ; case toggle?
 bne rdkey3 ; nope

 lda caseflg
 eor #$ff ; toggle case flag
 sta caseflg
 jmp rdkey2 ; get another key

rdkey3 cmp #'K'-$40 ; ctrl-k ?
 bne rdkey4 ; nope
 lda #'[' ; translate (backbracket)

rdkey4 cmp #'L'-$40 ; ctrl-l ?
 bne rdkey5 ; nope
 lda #'\' ; translate (backslash)

rdkey5 cmp #'O'-$40 ; ctrl-o ?
 bne rdkey6 ; nope
 lda #$df ; translate (underscrore)

rdkey6 bit caseflg ; change case?
 bpl rdkey7 ; nope

 cmp #'@' ; control or special?
 bcc rdkey7 ; yep

 cmp #$5B ; out of range? (real lower case)
 bcs rdkey7 ; yep

 clc  ; put into lower group
 adc #$20

rdkey7 sta $c030
 sta $c030 ; audio feedback

 pha
 lda #' ' ; remove cursor
 jsr plotchr
 pla
 ldx x_save
 ldy y_save
 jsr escape3 ; check for escape
 rts

caseflg db 0

*-------------------------------
* get a line of input
*-------------------------------

inpln ldy #0 ; start at first byte
inpln1 jsr rdkey ; get data
inpln1a cmp #cr ; return
 beq inpln6
 cmp #bs ; back space
 beq inpln2
 cmp #can ; ctrl-x / cancel
 beq inpln2
 cmp #del ; delete
 bne inpln3

inpln2 cpy #0 ; can we back up?
 beq inpln1 ; nope

 pha
 jsr prbs ; backspace w/delete
 dey  ; decrease line count
 pla
 cmp #can ; if its a cancel
 beq inpln2 ; keep going
 bne inpln1

inpln3 cmp #' ' ; if its a control char...
 bcc inpln1

 cpy maxlen ; check for max length
 bne inpln4
 jmp inpln1

inpln4 bit inpmode ; do we convert?
 bpl inpln4a ; nope

 jsr conv ; convert to upper

inpln4a bit inpmode ; check the inpmode
 bvc inpln5

 cmp #',' ; dont accept a comma
 beq inpln1
 cmp #' '
 bne inpln5 ; dont accept a space
 cpy #0 ; for first char of the line
 beq inpln1

inpln5 sta lnbuf,y ; save char
 iny
 jsr cout ; print it
 jmp inpln1 ; loop

inpln6 lda #cr
 sta lnbuf,y ; save the return
 cpy #0 ; was is just a return?
 bne inpln7 ; nope

 lda inpmode ; can we accept a blank line?
 and #$20
 bne inpln7 ; yep

 jmp inpln ; dont take, cr, start over

inpln7 lda inpmode ; do cr?
 and #$10
 bne inpln8 ; nope

 lda #cr
 jmp cout ; print the return and exit

inpln8 rts


inpmode db %00000000

*-------------------------------
* input a number in the range [1-x] where x={1-99}
*-------------------------------

inpnum stx maxnum ; save maximum number
 lda #2
 sta maxlen ; set length at 2
 lda ch
 sta prnt+1 ; record currnt horiz offset
 lda #%00010000
 sta inpmode ; use input mode 0

inpnum2 jsr inpln ; get line
 lda #0
 sta prnt ; make number init to 0

 lda lnbuf ; get data
 sec
 sbc #'0'
 cmp #10 ; in range?
 bcs inpnum5 ; nope, we are done

 sta prnt ; update total

 lda lnbuf+1 ; get more data
 sec
 sbc #'0'
 cmp #10 ; in range?
 bcs inpnum5 ; nope

inpnum3 dec prnt ; count down 10's
 bmi inpnum4

 clc
 adc #10 ; add 10 and loop
 bcc inpnum3

inpnum4 sta prnt ; save new total
inpnum5 lda prnt
 beq inpnum7 ; opps, problem

 cmp maxnum ; is it in range?
 bcc inpnum8
 beq inpnum8 ; all is well!

inpnum7 lda ch
 cmp prnt+1 ; at original spot?
 beq inpnum2 ; yep

 jsr prbs ; backup
 jmp inpnum7

inpnum8 rts

maxnum db 0

*-------------------------------
* print a backspace
*-------------------------------

prbs lda #bs ; do a backspace w/delete
 jsr cout
 lda #' '
 jsr cout
 lda #bs
 jmp cout

*-------------------------------
* input a 'y' or a 'n' for a yes/no situation
*-------------------------------

inpyn lda #1 ; max length 1
 sta maxlen
 lda ch ; save horiz position
 sta temp+1
 lda #%10010000
 sta inpmode

inpyn2 jsr inpln ; get the line
 lda lnbuf
 cmp #'Y' ; did they say 'YES' ?
 clc
 beq inpyn3 ; yep

 cmp #'N' ; did they say 'NO' ?
 sec
 beq inpyn3 ; yep

 lda ch
 cmp temp+1 ; are they the same?
 beq inpyn2

 jsr prbs ; backup
 jmp inpyn2

inpyn3 rts

*-------------------------------
* convert a character to uppercase
*-------------------------------

conv and #$7f ; strip high
 cmp #'a' ; below 'a'?
 bcc conv2 ; yep

 cmp #'z'+1 ; above 'z'?
 bcs conv2 ; yep

 sbc #$1f ; use clear carry for sbc $20
conv2 rts

*-------------------------------

copyinp stx temp ; point to dest
 sta temp+1
 tya
 pha  ; save ending byte

 ldx #0 ; start offsets
 ldy #0
copyin2 lda lnbuf,x ; get byte
 inx
 cmp #cr ; we done?
 beq copyin3 ; yep

 sta (temp),y ; copy and inc pointers
 inc temp
 bne copyin2
 inc temp+1
 bne copyin2

copyin3 pla  ; get back ending byte
 beq copyin4 ; opps, there wasnt one

 sta (temp),y ; save ending byte
 inc temp
 bne copyin4 ; inc pointers
 inc temp+1

copyin4 ldx temp ; return pointers
 lda temp+1
 rts

*-------------------------------
* copy a line of input to some location uppercase
*-------------------------------

ucopyinp stx temp ; point to dest
 sta temp+1
 tya
 pha  ; save ending byte

 ldx #0 ; start offsets
 ldy #0
ucopyin2 lda lnbuf,x ; get byte
 inx
 cmp #cr ; we done?
 beq ucopyin3 ; yep

 jsr conv ; convert to uppercase
 sta (temp),y ; copy and inc pointers
 inc temp
 bne ucopyin2
 inc temp+1
 bne ucopyin2

ucopyin3 pla  ; get back ending byte
 beq ucopyin4 ; opps, there wasnt one

 sta (temp),y ; save ending byte
 inc temp
 bne ucopyin4 ; inc pointers
 inc temp+1

ucopyin4 ldx temp ; return pointers
 lda temp+1
 rts

*-------------------------------
* print a string pointed by A & X
*   if y<128, use length = y
*   if y>127, stop at chr$(y)
*-------------------------------

prstr stx temp
 sta temp+1 ; point to data
 sty temp2
 tya
 and #$7f ; (was $7d ???)
 sta temp2+1 ; save possible length

 ldy #0
prstr2 lda (temp),y ; get data
 and #$7f ; clear high
 iny

 bit temp2 ; use which compare?
 bpl prstr3 ; other one

 cmp temp2+1 ; are we done?
 beq prstr4 ; yep

 jsr cout ; show and loop
 jmp prstr2

prstr3 cpy temp2 ; done?
 beq prstr4 ; yep

 jsr cout
 jmp prstr2

prstr4 tya
 clc
 adc temp ; compute next address
 tax
 lda #0
 adc temp+1
 rts

*-------------------------------
* skip a string pointed by A & X
*   if y<128, use length = y
*   if y>127, stop at chr$(y)
*-------------------------------

skipstr stx temp
 sta temp+1 ; point to data
 sty temp2
 tya
 and #$7f ; (was $7d ???)
 sta temp2+1 ; save possible length

 ldy #0
skstr2 lda (temp),y ; get data
 and #$7f ; clear high
 iny

 bit temp2 ; use which compare?
 bpl skstr3 ; other one

 cmp temp2+1 ; are we done?
 beq skstr4 ; yep

 jmp skstr2

skstr3 cpy temp2 ; done?
 bne skstr2 ; nope

skstr4 tya
 clc
 adc temp ; compute next address
 tax
 lda #0
 adc temp+1
 rts

*-------------------------------
* get names from a list
*-------------------------------

getname ldy #0
 lda (temp4),y ; we done?
 sec
 beq getnam3

getnam2 lda (temp4),y ; copy name
 sta flname+1,y
 iny
 cmp #0
 bne getnam2

 dey
 sty flname ; save length

 tya
 sec
 adc temp4 ; update length
 sta temp4
 lda temp4+1
 adc #0
 sta temp4+1
 clc
getnam3 rts

*-------------------------------
* translate a binary to text [0-99]
*-------------------------------

bindec8 ldy #0 ; start 10's counter
bin8 cmp #10
 bcc bin8a ; less than 10, were done

 sbc #10 ; minus 10
 iny  ; add 1 to the 10's counter
 bne bin8 ; loop

bin8a adc #'0' ; make 1's into text
 tax  ; save
 tya
 adc #'0' ; make 10's into text
 rts  ; were done

*-------------------------------
* print out a translated binary [0-99]
*-------------------------------

decout8 cmp #'0' ; are 10's zero?
 beq out8a

 jsr cout ; print it
out8a txa
 jmp cout ; print 1's

*-------------------------------
* input a number [X-A point to text]
*-------------------------------

numin stx numptr ; point to text
 sta numptr+1
 lda #0
 sta num ; zero totals
 sta num+1

numin2 ldy #0
 lda (numptr),y ; get digit
 and #$7f ; clear high
 sec
 sbc #'0' ; make in 0-9 range
 cmp #'9'+1
 bcs numin4 ; opps, we are done

 inc numptr ; point to next byte
 bne *+4
 inc numptr+1

 sta num+2 ; save digit
 lda #0
 sta num+3

 ldx #10
numin3 clc  ; num = num + num2
 lda num
 adc num+2
 sta num+2
 lda num+1
 adc num+3
 sta num+3
 dex
 bne numin3 ; num = num * 10

 lda num+2 ; move result
 sta num
 lda num+3
 sta num+1
 jmp numin2 ; loop

numin4 ldx num ; return value
 lda num+1
 rts

*-------------------------------
* display a decimal number [0 to 65535]
*-------------------------------

decmem stx num ; save number
 sta num+1

 lda #0
 sta num+2
 sta num+3
 sta num+5
 sta num+6

 sed
 ldy #$10 ; use decimal mode
decmem2 asl num
 rol num+1
 lda num+2
 adc num+2 ; do actual 'woz' conversion
 sta num+2
 lda num+3
 adc num+3
 sta num+3
 rol num+4
 dey  ; loop down
 bne decmem2

 cld  ; done with decimal
 ldy #4 ; print 5 digits

decmem3 lda num+4 ; get digit
 and #$0f
 bne decmem4 ; is it zero?

 bit num+5 ; is this a leading zero?
 bpl decmem5 ; yep

decmem4 dec num+5
 clc
 adc #'0' ; print digit
 ldx num+6
 sta txtnum+1,x ; save number to memory
 inc num+6

decmem5 ldx #3 ; move up next digit
decmem6 asl num+1
 rol num+2
 rol num+3
 rol num+4
 dex
 bpl decmem6

 dey  ; count down digits
 bmi decmem7
 bne decmem3

 stx num+5 ; print last zero for sure
 bpl decmem3
decmem7 lda num+6 ; save number length
 sta txtnum
 rts

num db 0,0,0,0,0,0,0
txtnum db 0,0,0,0,0,0

*-------------------------------
* escape handler
*-------------------------------

escape sta escadr ; possible reset
 cmp #0 ; turn off handler?
 beq escape2 ; yep

 stx escadr+1 ; save escape address
 sta escadr+2
 tsx
 stx escadr+3 ; save stack location
 lda #-1
 sta escadr ; turn on handler
escape2 rts

; check for esc and handle if needed
escape3 bit escadr ; is handler enabled?
 bpl escape5 ; nope

 pha
 and #$7f ; did escape occur?
 cmp #esc
 bne escape4 ; nope

 lda escadr+1 ; setup jump location
 sta temp
 lda escadr+2
 sta temp+1
 ldx escadr+3
 txs  ; reset stack
 pla
 pla  ; restore stack
 jmp (temp) ; change program control

escape4 pla
escape5 rts

escadr db 0,0,0,0

*-------------------------------
* print a number
*-------------------------------

prnumb jsr decmem ; convert number
 ldx #<txtnum+1
 lda #>txtnum+1
 ldy txtnum
 iny  ; display it
 jmp prstr

*-------------------------------
* wait for a return
*-------------------------------

getcr jsr print
 db 1,22,0
 asc 'Press [RETURN] to continue...',00

:loop jsr rdkey
 cmp #cr
 bne :loop
 rts

*-------------------------------
* wait for a 'g'o message
*-------------------------------

getg jsr print
 db 1,20,0
 asc 'Press [G] when diskette is online.',00

getg2 jsr rdkey ; wait for 'g'
 jsr conv
 cmp #'G'
 beq getg3
 cmp #'*'
 bne getg2
 brk
getg3 rts

*-------------------------------
* write the changes back into the 'g' file
*-------------------------------

wrtchg jsr cls
 jsr svacos ; write configuration back to disk
 jmp start

*-------------------------------
* check to see if in init mode
*-------------------------------

chinit bit init ; in init mode?
 bpl chinit2 ; nope

 pla  ; return to init routine
 pla
chinit2 rts  ; return to caller


