
*-------------------------------
* video driver for config
*-------------------------------

*-------------------------------
* Date: 3/11/88
*-------------------------------

page1 equ $c054
page2 equ $c055

VideoStartup sta $c00c ;clr80vid
 sta $c000 ;clr80col
 sta page1

 lda #0 ; set to page 1
 sta inverse ; set to normal mode
 rts

*-------------------------------

cls lda #6 ;clear screen
 sta cv ;line 6 on down

clslup2 lda cv ;clear to end of screen
 asl a ;cv := cv * 2
 tay
 lda LineAddress,y
 sta base
 iny
 lda LineAddress,y
 sta base+1

 ldy #39
 lda #$a0
:loop sta (base),y
 dey
 bpl :loop

 inc cv
 lda cv
 cmp #24
 bne clslup2

 lda #0 ;0,6
 sta ch
 lda #7
 sta cv
 rts

*-------------------------------

cleos stx cv
 jmp clslup2

cleol pha
 lda ch ; save location of cursor
 pha
 lda cv
 pha

cleol2 lda #' '
 jsr cout ; put space over char
 lda ch
 bne cleol2 ; go until it wraps to next line

 pla
 sta cv ; put cursor back
 pla
 sta ch
 pla
 rts

*-------------------------------

TopBox pha

 lda #0
 sta cv

 jsr doILine
 inc cv
 jsr doEdge
 inc cv
 jsr doEdge
 inc cv
 jsr doEdge
 inc cv
 jsr doEdge
 inc cv
 jsr doILine

 ldy #39
 lda #$20
 sta (base),y
 ldy #0
 sta (base),y

 pla
 rts

*-------------------------------

doEdge jsr makebase

 ldy #0
 lda #$20
 sta (base),y

 ldy #38
 lda #$a0
:loop sta (base),y
 dey
 bne :loop

 ldy #39
 lda #$20
 sta (base),y
 rts

*-------------------------------
* print an inverse line across the screen

doILine jsr makebase

 ldy #39
 lda #$DF
:loop sta (base),y
 dey
 bpl :loop
 rts

*-------------------------------

makebase lda cv
 asl a
 tay  ;setup indirect address
 lda LineAddress,y
 sta base
 iny
 lda LineAddress,y
 sta base+1
 rts

*-------------------------------

plotchr pha  ; save
 jsr makebase ;setup indirect for screen address
 ldy ch
 pla

 ora #$80 ;set high bit

* check for ][ plus

 stx x_save ; save x
 ldx $fbb3
 cpx #$ea ;][ plus?
 bne plotchr1 ;nope

* convert everything to uppercase

 cmp #"a" ;lower?
 bcc plotchr1 ;nope
 cmp #"z"+1 ;lower
 bcs plotchr1 ;nope
 sbc #$1f ;make upper

plotchr1 ldx x_save
 sta (base),y ;put it onto the screen
 rts

*-------------------------------
* output a character

cout stx x_save ; save everything
 sty y_save
 pha

 and #$7f ; clear high
 cmp #cr
 beq cout2
 cmp #lf
 beq cout3
 cmp #bs
 beq cout5
 cmp #' '
 bcc cout4

 jsr plotchr ; plot the sucker

 inc ch ; move over 1 space
 ldy ch
 cpy #40 ; wrap-around?
 bne cout4 ; nope

cout2 ldy #0 ; reset horiz
 sty ch

cout3 inc cv ; go down 1 line
 lda cv ; is it in range?
 cmp #24
 bne cout4 ; nope

 dec cv ; put it back

cout4 pla
 ldx x_save ; restore stuff
 ldy y_save
 rts

cout5 dec ch ; backup
 bpl cout4 ; all is well

 lda #40 ; move to end of line
 sta ch

 lda cv ; are we at the top
 cmp #0
 beq cout4 ; yep

 dec cv
 jmp cout4 ; ok, we are done

*-------------------------------

LineAddress dw $400
 dw $480
 dw $500
 dw $580
 dw $600 ;first 1/3 of text screen
 dw $680
 dw $700
 dw $780

 dw $428
 dw $4a8
 dw $528
 dw $5a8
 dw $628 ;second 1/3 of text screen
 dw $6a8
 dw $728
 dw $7a8

 dw $450
 dw $4d0
 dw $550
 dw $5d0
 dw $650 ;last 1/3 of text screen
 dw $6d0
 dw $750
 dw $7d0
