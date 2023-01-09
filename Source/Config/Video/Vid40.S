********************************
*                              *
*    Apple 40 Column Driver    *
*                              *
********************************

*-------------------------------
* Date: 01/03/86
*-------------------------------
 lst off

 rel
 dsk rel/apple40


cr equ $0d
lf equ $0a
bs equ $08

wndlft equ $20
wndwdth equ $21
wndtop equ $22
wndbtm equ $23
ch equ $24
cv equ $25
blink equ $26
oldcv equ $27
base equ $28
base2 equ $2a
x_save equ $2c
y_save equ $2d
invflg equ $32

vid40 ent
 org $0900
 jmp :init
 jmp :cls
 jmp :cout
 jmp :scroll
 jmp :banner
 jmp :clrlast
 jmp :rdinit
 jmp :rdkey
 jmp :rdend
 jmp :window
 jmp :read
 jmp :keyin
 jmp :xypos
 jmp :shchat

; init 40 col video

:init lda $c30b
 cmp #1
 bne :init_2

 lda $c30c
 cmp #$82
 bne :init_1

 lda $c058
 clc
 bcc :init_2

:init_1 cmp #$87
 bne :init_2

 lda #0
 sta $c0b2

:init_2 lda #0 ; reset screen
 sta blink
 sta wndlft
 sta wndtop
 sta invflg
 lda #40
 sta wndwdth
 sta oldcv ; make sure it is different!
 lda #24
 sta wndbtm

; ...fall through to cls...

:cls ldx wndtop
:cls1 jsr :setbase ; setup base address
 ldy #39
 lda #" "
:cls2 sta (base),y ; clear screen
 dey
 bpl :cls2

 inx
 cpx wndbtm ; is there more?
 bne :cls1 ; yep

; ...fall through to home routine...

:home lda #0 ; home cursor
 sta ch
 lda wndtop ; top of window
 sta cv
 tax

; ...fall through to setbase routine

:setbase cpx oldcv ; do we have the base already?
 beq :setbas2 ; yep

 pha
 txa
 asl a ; x = x * 2
 tax
 lda :scrnadr,x ; get and save address
 sta base
 lda :scrnadr+1,x
 sta base+1
 txa
 lsr a ; x = x / 2
 tax
 stx oldcv ; update old cv value
 pla

:setbas2 rts

; output a character
:cout stx x_save ; save everything
 sty y_save
 pha

 and #$7f ; clear high
 cmp #cr
 beq :cout2
 cmp #lf
 beq :cout3
 cmp #bs
 beq :cout5
 cmp #' '
 bcc :cout4

 ldx cv ; set base
 jsr :setbase

 ldy ch ; get offset
 ora #$80
 cmp #"a" ; lower?
 bcc :cout0 ; nope

 cmp #"z"+1 ; lower?
 bcs :cout0 ; nope

 sbc #$1f ; make upper

:cout0 bit invflg ; inverse?
 bpl :cout1 ; nope

 and #$3f ; inverse upper 

:cout1 sta (base),y ; save character

 inc ch ; move over 1 space
 ldy ch
 cpy #40 ; wrap-around?
 bne :cout4 ; nope

:cout2 ldy #0 ; reset horiz
 sty ch

:cout3 inc cv ; go down 1 line
 lda cv ; is it in range?
 cmp wndbtm
 bne :cout4 ; nope

 dec cv ; put it back
 jsr :scroll
:cout4 pla
 ldx x_save ; restore stuff
 ldy y_save
 rts

:cout5 dec ch ; backup
 bpl :cout4 ; all is well

 lda #39 ; move to end of line
 sta ch

 lda cv ; are we at the top
 cmp wndtop
 beq :cout4 ; yep

 dec cv
 jmp :cout4 ; ok, we are done


; scroll the screen down 1 line
:scroll ldx wndtop ; get first line to scroll

:scroll2 jsr :setbase ; get the first base
 lda base
 sta base2 ; move to second
 lda base+1
 sta base2+1
 inx
 jsr :setbase ; get other base

 ldy #39 ; copy line
:scroll3 lda (base),y ; move character
 sta (base2),y
 dey
 bpl :scroll3

 txa
 tay
 iny
 cpy wndbtm ; done?
 bne :scroll2 ; nope

; ...fall through into clear last line routine...

:clrlast ldx wndbtm
 dex
 lda #" " ; fill with spaces

:clrline pha
 jsr :setbase ; point to last line
 pla

 ldy #39
:clrlst3 sta (base),y ; clear the line
 dey
 bpl :clrlst3
 rts


; scroll a character across the bottom line
:banner pha  ; save eveything
 txa
 pha

 ldx #0
:banner2 lda $7d5,x ; move char
 sta $7d4,x
 inx
 cpx #$24 ; do all the chars
 bne :banner2

 pla
 tax
 pla
 pha
 cmp #"a" ; lower?
 bcc :banner3 ; nope

 cmp #"z"+1 ; lower?
 bcs :banner3 ; nope

 sbc #$1f ; make upper

:banner3 sta $7f7 ; save new char
 pla
 rts


; get a character -- non destructable
:rdkey pha
 sty y_save ; save Y
 ldy ch
 lda #$df ; underline
 cmp (base),y ; is it in underline phase?
 bne :rdkey2 ; nope, put it there

 lda blink ; put into character phase
:rdkey2 sta (base),y
 ldy y_save ; were done
 pla
 rts

; init rdkey routine
:rdinit pha
 stx x_save
 sty y_save
 ldx cv
 jsr :setbase ; setup base

 ldy ch ; select screen to work with
 lda (base),y
 sta blink ; save blink character
 ldx x_save
 ldy y_save
 pla
 rts

; finish up rdkey routine
:rdend pha
 sty y_save ; save A & Y
 ldy ch
 lda blink ; put back orig char
 sta (base),y
 ldy y_save ; restore
 pla
 rts


; set up window for top of screen display
:window ldx #0
 lda #'-'
 jsr :clrline ; fill line 1
 ldx #3
 jsr :clrline ; fill line 4
 dex
 lda #' '
 jsr :clrline ; fill line 3
 dex
 jsr :clrline ; fill line 2
 lda #4 ; set top of window
 sta wndtop
 rts


; read a line of data from the screen
:read jsr :setbase ; setup base
 lda (base),y ; get character
 and #$7f
 cmp #' '
 bcs *+4 ; make into ascii character
 adc #'@'
 rts


; check for local keyin
:keyin lda $c000
 rts


; do x-y positioning
:xypos stx ch ; save location
 sty cv
 tya
 tax
 jmp :setbase ; reset base


; show that chat has been selected
:shchat tax
 lda wndtop ; are we full screen?
 beq :shchat5 ; yep, dont display

 lda ch ; save location
 pha
 lda cv
 pha
 txa
 beq :shchat3 ; cover it up

 pha
 ldy #0
 ldx #13 ; position cursor
 jsr :xypos
 lda #-1
 sta invflg ; set inverse mode
 pla

 tay
 ldx :msgoff-1,y
:shchat2 lda :chatmsg,x ; print chat message
 inx
 pha
 jsr :cout
 pla
 bpl :shchat2

 lda #0 ; set normal mode
 sta invflg
 beq :shchat4 ; finish up

:shchat3 ldx #0 ; fix top line
 lda #'-'
 jsr :clrline

:shchat4 pla
 tay
 pla  ; move back
 tax
 jsr :xypos
:shchat5 rts

:msgoff db 0,12

:chatmsg dci '[ PAGE: ON ]'
 dci '[ EXEC: ON ]'


; table of screen address
:scrnadr dw $400 ; first 1/3 decoding
 dw $480
 dw $500
 dw $580
 dw $600
 dw $680
 dw $700
 dw $780

 dw $428 ; second 1/3 decoding
 dw $4a8
 dw $528
 dw $5a8
 dw $628
 dw $6a8
 dw $728
 dw $7a8

 dw $450 ; third 1/3 decoding
 dw $4d0
 dw $550
 dw $5d0
 dw $650
 dw $6d0
 dw $750
 dw $7d0
