* ------------------------------
* apple 80 col driver
* ------------------------------
 lst off

 rel
 dsk rel/apple80

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

vid80 ent
 org $900

 jmp init
 jmp cls
 jmp cout
 jmp scroll
 jmp banner
 jmp clrlast
 jmp rdinit
 jmp rdkey
 jmp rdend
 jmp window
 jmp read
 jmp keyin
 jmp xypos
 jmp shchat

; init 80 col video

init sta $c00d ; turn on 80 cols
 sta $c001 ; turn on 80 store
 sta $c00f ; turn on aux chrset

 lda #0 ; reset screen
 sta blink
 sta wndlft
 sta wndtop
 sta invflg ; set to 'normal' mode
 lda #80
 sta wndwdth
 sta oldcv ; make sure it is different!
 lda #24
 sta wndbtm

; ___fall through to cls___

cls ldx wndtop
cls1 jsr setbase ; setup base address
 ldy #39
 lda #" "
cls2 sta $c055 ; clear screen 1
 sta (base),y
 sta $c054 ; clear screen 2
 sta (base),y
 dey
 bpl cls2

 inx
 cpx wndbtm ; is there more?
 bne cls1 ; yep

; ___fall through to home routine___

home lda #0 ; home cursor
 sta ch
 lda wndtop ; set to top margin
 sta cv
 tax

; ___fall through to setbase routine

setbase cpx oldcv ; do we have the base already?
 beq setbas2 ; yep

 pha
 txa
 asl a ; x = x * 2
 tax
 lda scrnadr,x ; get and save address
 sta base
 lda scrnadr+1,x
 sta base+1
 txa
 lsr a ; x = x / 2
 tax
 stx oldcv ; update old cv value
 pla

setbas2 rts

; output a character
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

 ldx cv ; set base
 jsr setbase

 ora #$80
 bit invflg ; inverse?
 bpl cout1a ; nope

 and #$7f ; is it a symbol?
 cmp #'@'
 bcc cout1a ; yep

 cmp #'a'-1 ; lowercase?
 bcs cout1a ; yep

 and #$3f ; put into $00-$1f range if upper

cout1a sec  ; save char
 ldy y_save
 jsr setscrn ; set proper screen

 inc ch ; move over 1 space
 ldy ch
 cpy #80 ; wrap-around?
 bne cout4 ; nope

cout2 ldy #0 ; reset horiz
 sty ch

cout3 inc cv ; go down 1 line
 lda cv ; is it in range?
 cmp wndbtm
 bne cout4 ; nope

 dec cv ; put it back
 jsr scroll
cout4 pla
 ldx x_save ; restore stuff
 ldy y_save
 rts

cout5 dec ch ; backup
 bpl cout4 ; all is well

 lda #79 ; move to end of line
 sta ch

 lda cv ; are we at the top
 cmp wndtop
 beq cout4 ; yep

 dec cv
 jmp cout4 ; ok, we are done


; setup the proper screen and setup Y
setscrn sty y_save ; save offset
 php
 pha
 lda ch
 lsr a ; get screen offset into Y
 tay
 sta $c055
 bcc *+5 ; select text page
 sta $c054
 pla

 plp  ; get command status
 bcc setscr1 ; opps, read char
 sta (base),y ; save char
 bcs setscr2
setscr1 lda (base),y
setscr2 sta $c054 ; select main memory
 ldy y_save ; restore Y
 rts


; scroll the screen down 1 line
scroll ldx wndtop ; get first line to scroll

scroll2 jsr setbase ; get the first base
 lda base
 sta base2 ; move to second
 lda base+1
 sta base2+1
 inx
 jsr setbase ; get other base

 ldy #39 ; copy line
scroll3 sta $c055 ; do screen 1
 lda (base),y
 sta (base2),y
 sta $c054 ; do screen 2
 lda (base),y
 sta (base2),y
 dey
 bpl scroll3

 txa
 tay
 iny
 cpy wndbtm ; done?
 bne scroll2 ; nope

; ___fall through into clear last line routine___

clrlast ldx wndbtm ; get line to clear
 dex
 lda #" " ; clear to spaces

clrlst2 pha
 jsr setbase ; point to last line
 pla

 ldy #39
clrlst3 sta $c055 ; fill screen 1
 sta (base),y
 sta $c054 ; fill screen 2
 sta (base),y
 dey
 bpl clrlst3
 rts


; scroll a character across the bottom line
banner pha
 txa
 pha
 ldx #0
 sta $c054 ; start with screen 2 on
banner2 lda $7d2,x
 sta $c055 ; turn on screen 1
 sta $7d2,x

 lda $7d3,x
 sta $c054 ; turn on screen 2
 sta $7d2,x

 inx
 cpx #$26
 bne banner2

 pla
 tax
 pla
 sta $7f7
 rts


; get a character -- non destructable
rdkey pha
 clc  ; read screen
 jsr setscrn
 sta y_save ; save data

 lda #$df ; underline
 cmp y_save ; is it in underline phase?
 bne rdkey2 ; nope, put it there

 lda blink ; put into character phase
rdkey2 sec
 jsr setscrn ; put charcter there
 pla
 rts


; init rdkey routine
rdinit pha
 stx x_save
 ldx cv ; setup vertical base
 jsr setbase

 clc
 jsr setscrn
 sta blink ; save blink character
 ldx x_save
 pla
 rts


; finish up rdkey routine
rdend pha
 lda blink ; restore old character
 sec
 jsr setscrn
 pla
 rts


; set up window for top of screen display
window ldx #0
 lda #'-' ; print a line of "-"
 jsr clrlst2
 ldx #3
 jsr clrlst2 ; do the other line of "-"
 dex
 lda #' '
 jsr clrlst2 ; print a blank line
 dex
 jsr clrlst2
 lda #4 ; print another blank line
 sta wndtop
 rts


; read the data off a line of the screen
read stx x_save ; save X
 jsr setbase ; x = line to read

 lda ch
 ldx ch
 sty ch ; use Y for offset

 clc
 jsr setscrn ; get data on screen
 and #$7f
 cmp #' ' ; convert inverse
 bcs read3

 adc #'@' ; make normal

read3 stx ch ; restore ch
 ldx x_save
 rts


; check the local keyboard
keyin lda $c000 ; gads, we do a whole lot!
 rts


; do x-y positioning
xypos stx ch ; set position
 sty cv
 tya
 tax
 jmp setbase ; setup base


; show that chat has been selected
shchat tax
 lda wndtop ; are we full screen?
 beq shchat5 ; yep, dont display

 lda ch ; save location
 pha
 lda cv
 pha
 txa
 beq shchat3 ; cover it up

 pha
 ldy #0
 ldx #33 ; position cursor
 jsr xypos
 lda #-1
 sta invflg ; set inverse mode
 pla

 tay
 ldx msgoff-1,y
shchat2 lda chatmsg,x ; print chat message
 inx
 pha
 jsr cout
 pla
 bpl shchat2

 lda #0 ; set normal mode
 sta invflg
 beq shchat4 ; finish up

shchat3 ldx #0 ; fix top line
 lda #'-'
 jsr clrlst2

shchat4 pla
 tay
 pla  ; move back
 tax
 jsr xypos
shchat5 rts

msgoff db 0,12

chatmsg dci '[ Page: On ]'
 dci '[ Exec: On ]'


; handle any incoming interupts
irq pha
 lda $c099 ; clear int
 lda $c0a9
 pla
 rti


; table of screen address
scrnadr dw $400 ; first 1/3 decoding
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

 end
