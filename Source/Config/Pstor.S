********************************
*                              *
* GBBS Config - Prodos Storage *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------

re_stor jsr cls ; clear screen

 lda #<hdrbuf
 sta temp
 lda #>hdrbuf
 sta temp+1

 ldx #0 ; start pointers
 ldy #0
 sty temp2 ; set device count at zero
stor2 lda devnam,x ; get drive info
 sta temp2+1

stor3 lda devnam,x ; copy pathname
 sta (temp),y
 inx
 iny
 dec temp2+1
 bpl stor3

 clc
 lda temp ; go to next address
 adc #128
 sta temp
 lda temp+1
 adc #0
 sta temp+1

 ldy #0
 inc temp2 ; inc number of pathnames
 lda temp2
 cmp #12 ; done all 12?
 bne stor2 ; nope

stor4 jsr TopBox
 jsr print
 db 1,3,2
 asc '- Edit Drive Specifier Allocation -',00
 jsr cls

 ldx #-1
stor5 inx
 jsr shwpfx ; show drive
 lda #cr ; add end of line
 jsr cout
 cpx #11
 bcc stor5 ; show all 12 entries

stor6 jsr print
 db 1,20,0
 asc 'Edit: [A-L] or Q=Quit ? ',00

 lda #%10000000
 sta inpmode ; set mode 0
 lda #1
 sta maxlen ; set length to 1

 jsr inpln ; get input
 lda lnbuf
 cmp #'Q' ; quit?
 bne stor7 ; yep

 jmp stor9 ; handle quit

stor7 sec
 sbc #'A' ; make into range
 cmp #12 ; is it ok?
 bcs stor6 ; nope

 pha
 tax
 jsr finddrv ; find the drive location

 ldx #20
 jsr cleos ; claer last line

 ldx #20 ; position
 stx cv
 ldx #0
 stx ch

 pla
 clc
 adc #'A' ; show drive specifier
 jsr cout
 jsr print
 asc ': /',00

 lda #30 ; make max length 32 total
 sta maxlen
 lda #%10100001
 sta inpmode

 jsr inpln
 lda lnbuf-1,y
 cmp #'/' ; check for ending slash
 bne stor7f

 lda #cr ; delete ending slash
 sta lnbuf-1,y

stor7f lda lnbuf ; did they just do a return?
 cmp #cr
 bne stor8 ;nope

 jsr print
 db 1,20,0
 asc 'Clear contents of this line [Y/N] ? ',00

 jsr inpyn ; get answer
 bcs stor7a ; nope

 ldy #0
 tya  ; nullify an entry
 sta (temp4),y
stor7a jmp stor4 ; do another

stor8 ldx #0
 ldy #2
stor8a lda lnbuf,x ; copy pathname
 sta (temp4),y
 inx
 iny
 cmp #cr
 bne stor8a

 ldy #0 ; save length
 txa
 sta (temp4),y
 iny
 lda #'/' ; add leading slash
 sta (temp4),y
 jmp stor4 ; show results


stor9a jmp start ; abort out

stor9 ldx #20
 jsr cleos ; clear bottom
 jsr print
 db 1,20,0
 asc 'Is the above correct [Y/N] ? ',00
 jsr inpyn
 bcs stor9a ; nope

 lda #<hdrbuf
 sta temp ; point at pathnames
 lda #>hdrbuf
 sta temp+1

 ldx #0
 ldy #0
 sty temp2 ; start with drive A:
stor9b lda (temp),y
 sta temp2+1 ; save length

stor9c lda (temp),y ; get data
 sta devnam,x
 inx
 cpx #$f0 ; is table ok?
 beq stor9d ; nope, it is too big

 iny
 dec temp2+1 ; count down length
 bpl stor9c

 clc
 lda temp
 adc #$80 ; go to next field
 sta temp
 lda temp+1
 adc #0
 sta temp+1

 ldy #0 ; reset pointer within field
 inc temp2
 lda temp2 ; done all 12 yet?
 cmp #12
 bne stor9b ; nope, loop
 jmp wrtchg ; write changes to disk

stor9d jsr cls
 jsr print
 asc 'ERROR !',0d,0d
 asc 'Overflow error. Too much data within '
 asc 'drive table. Cut down on the amount',0d,0d
 asc 'of data within the table.'
 db 1,20,0
 asc 'Press [RETURN] to continue... ',00

stor9e jsr rdkey ; wait for a return
 cmp #cr
 bne stor9e
 jmp stor4 ; get new stuff


; point to the pathname of a device
finddrv lda #0 ; set lower to 0
 sta temp4
 txa
 lsr a
 ror temp4 ; put extra into low
 clc
 adc #>hdrbuf
 sta temp4+1 ; setup high
 rts


; show a pathname of a device
shwpfx jsr finddrv ; position
 txa
 clc
 adc #'A' ; show drive name
 jsr cout

 lda #':' ; add colon
 jsr cout

 lda #' ' ; put in space
 jsr cout

 ldy #0 ; check for data
 lda (temp4),y
 sta temp2+1
 beq prdrv3 ; nope, there isnt any

prdrv2 iny
 lda (temp4),y ; get byte of name
 jsr conv
 jsr cout ; show it
 dec temp2+1
 bne prdrv2 ; keep going

 clc
 rts

prdrv3 sec  ; no data
 rts


