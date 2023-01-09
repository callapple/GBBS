* --------------------------
*     videx 80 col bios
* --------------------------
 lst off

 rel
 dsk rel/videx

cr equ $0d
lf equ $0a
bs equ $08
syn equ $16
esc equ $1b

slot equ 3

shift equ $20
wndwdth equ $21
wndtop equ $22
wndbtm equ $23
ch equ $24
cv equ $25
testbyt equ $26
base equ $28
start equ $2a
x_save equ $2c
y_save equ $2d
z_save equ $2e
yoffset equ $2f
invflg equ $32
hdrhide equ $33

softon equ $c059
dev0 equ $c080+slot*16
dev1 equ $c081+slot*16
disp0 equ $cc00
disp1 equ $cd00

videx ent
 org $0900

begin jmp init
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

init ldx #0 ; do 16 byte init
 stx start
 stx start+1
init_1 stx dev0 ; select reg to init
 lda crtinit,x
 sta dev1 ; init it
 inx
 cpx #16
 bne init_1

 sta softon ; turn on soft switch

init_2 lda #0 ; reset screen
 sta shift
 sta wndtop
 sta invflg ; set to 'normal' mode

 lda #80 ; set window width
 sta wndwdth

 lda begin-$100+12
 sta update3+1 ; point to top of screen data
 lda begin-$100+13
 sta update3+2

; ___fall through to cls___

cls ldx wndtop
cls1 jsr clrlst1 ; clear each line
 inx
 cpx #24 ; is there more?
 bne cls1 ; yep

; ___fall through to home routine___

home ldx #0 ; home cursor
 stx ch
 ldx wndtop
 stx cv

; ___fall through to setbase routine

setbase pha
 txa
 pha
 asl a
 tax

 clc
 lda start ; get base address
 adc scrnadr,x
 sta base
 lda start+1
 adc scrnadr+1,x ; update address
 sta base+1

 pla
 tax
 pla
 rts


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

 ldx cv ; point to data
 jsr setbase
 bit invflg
 bpl cout1
 ora #$80 ; make inverse

cout1 ldy ch
 jsr dataout

 inc ch ; move over 1 space
 ldy ch
 cpy #80 ; wrap-around?
 bne cout4 ; nope

cout2 ldy #0 ; reset horiz
 sty ch

cout3 inc cv ; go down 1 line
 lda cv ; is it in range?
 cmp #24
 bne cout4 ; nope

 dec cv ; put it back
 jsr scroll
cout4 pla
 cmp #syn+128
 bne cout4a

 pha
 ldx #0 ; go to top line
 jsr setbase
 lda $427
 clc
 adc #"@" ; make into legal range
 ldy #79
 jsr dataout ; display on screen
 pla

cout4a ldx x_save ; restore stuff
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


; scroll the screen down 1 line
scroll clc
 lda start ; advance screen pointer
 adc #80
 sta start

 ldx #13
 stx dev0 ; save low byte of address
 sta dev1

 lda start+1
 adc #0
 sta start+1

 dex
 stx dev0 ; save high byte of address
 sta dev1
 jsr update ; posible top of screen update

; ___fall through into clear last line routine___

clrlast ldx #23 ; get line to clear
clrlst1 lda #' ' ; clear to spaces

clrlst2 stx x_save
 pha
 jsr setbase ; position to last line
 pla

 ldx #0
 stx yoffset
clrlst3 jsr quicksv ; clear last line
 inx
 cpx #80
 bne clrlst3
 ldx x_save
banner rts


; init rdkey routine
rdinit pha
 stx x_save
 sty y_save
 ldx cv
 jsr setbase ; setup base

 clc
 lda base ; point to low byte
 adc ch
 ldx #15
 stx dev0
 sta dev1

 lda base+1 ; point to high byte
 adc #0
 ldx #14
 stx dev0
 sta dev1

 ldx #10
 stx dev0
 lda #$48 ; blink cursor
 sta dev1
 ldx x_save
 ldy y_save
 pla
rdkey rts


; finish up rdkey routine
rdend pha
 lda #10
 sta dev0 ; remove cursor
 lda #$28
 sta dev1
 pla
 rts


; read the data off a line of the screen
read jsr setbase ; x = line to read

 lda #$b9 ; change STA to LDA
 sta dataot1

 jsr dataout ; get data
 and #$7f

 lda #$99 ; change LDA back to STA
 sta dataot1
 rts


; quick data output routine
quicksv ldy yoffset
 bne quicks1

 pha
 jsr dataout
 sec
 lda #1
 sbc yoffset
 sta testbyt
 lda #1
 sbc #0
 sta testbyt+1
 pla
 rts

quicks1 sta disp0,y ; save data on screen
 inc yoffset ; save offset for next write
 bne quicks2

 pha
 clc
 lda base
 adc testbyt
 sta base
 lda base+1
 adc testbyt+1
 sta base+1
 pla
quicks2 rts


; special data output routine
dataout pha
 sty z_save

 clc
 tya
 adc base
 pha  ; save character offset
 lda #0
 adc base+1

 pha  ; save 1/2 number (0 or 1)
 asl a
 and #%00001100
 tay  ; select 512 byte paging
 lda dev0,y

 pla
 lsr a
 lda #>disp0
 adc #0 ; get page number in A
 sta dataot1+2
 sta quicks1+2

 pla
 tay  ; get index into page

 pla
 sta $cfff
 sta $c000+slot*256
dataot1 sta disp0,y
 iny
 sty yoffset ; save offset to next write
 ldy z_save
 rts


; do x-y positioning
xypos sty cv
 stx ch
 tya
 tax
 jmp setbase


; check for local keyin
keyin1 lda #$60
 eor shift ; toggle shift byte
 sta shift

keyin0 sta $c010
keyin lda $c000 ; check keyboard
 bpl keyin2 ; no data

 cmp #esc+128 ; change case?
 beq keyin1 ; nope

 cmp #"O"-$40 ; dont allow ctrl-O
 beq keyin0

 cmp #"@"
 bne *+4 ; translate @ --> P
 lda #"P"

 cmp #"]"
 bne *+4 ; translate ] --> M
 lda #"M"

 cmp #"^"
 bne *+4 ; translate ^ --> N
 lda #"N"

 cmp #"A" ; dont shift below this
 bcc keyin2

 bit $c063 ; check shift-key mod
 bpl keyin2 ; dont change data, they shifted

 ora shift ; possible shift

keyin2 cmp #0 ; reset all flags
 rts


; print top of screen window
window lda #4
 sta wndtop

; ___ fall through into update routine ___

; update top of screen display
update lda wndtop ; re-display top?
 beq update6 ; nope

update1 ldx #0
 stx yoffset
 jsr setbase ; point to top of screen
 ldy #0

 lda #"-"
 ldx #0
update2 jsr quicksv ; put top line
 inx
 cpx #80
 bne update2

 ldx #0
update3 lda $1234,x
 bpl update7 ; normal text

 bit hdrhide ; hide password?
 bpl update7 ; nope

 lda #"*" ; cover password

update7 ora #$80 ; display top of screen
 jsr quicksv
 inx
 cpx #160
 bne update3

 ldx #3
 jsr setbase
 ldx #0
 stx yoffset
 ldy #0

 lda #"-"
update4 jsr quicksv ; show bottom line
 inx
 cpx #80
 bne update4

 ldx #0
 jsr setbase
 ldy #32 ; htab 33
 lda #"-"
 jsr dataout

 ldx #12 ; save counter
 stx lnlen

 ldx chatoff ; get chat offset
 beq update6 ; no display
 lda msgoff-1,x
 tax

update5 lda chatmsg,x
 jsr quicksv ; put onto top line
 inx
 dec lnlen ; count down
 bne update5

update6 rts


; show that chat has been selected
shchat sta chatoff
 jmp update ; display new screen

chatoff db 0

msgoff db 0,12

chatmsg asc "[ Page: On ]"
 asc "[ Exec: On ]"


; table of screen address
scrnadr dw 0
 dw 80
 dw 160
 dw 240
 dw 320
 dw 400
 dw 480
 dw 560
 dw 640
 dw 720
 dw 800
 dw 880
 dw 960
 dw 1040
 dw 1120
 dw 1200
 dw 1280
 dw 1360
 dw 1440
 dw 1520
 dw 1600
 dw 1680
 dw 1760
 dw 1840

crtinit db $7b,$50,$5e,$29,$1b,$08,$18,$19
 db $00,$08,$28,$08,$00,$00,$00,$00

lnlen db 0

 end
