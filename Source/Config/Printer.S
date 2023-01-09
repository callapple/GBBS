* Printer re-configuration
*-------------------------------

nullprint ext  ;null printer driver
serial ext  ;serial/cout printer driver
grappler ext  ;parallel grappler printer driver
parallel ext  ;parallel printer driver

re_pr jsr TopBox
 jsr print
 db 1,3,10
 asc '- Printer Interfaces -',00

 jsr cls
 ldx #<start ; setup esc handler
 lda #>start
 jsr escape

 jsr print
 db 1,7,0
 asc ' 1 - Apple //c built-in port',0d
 asc ' 2 - Apple Super Serial Card (SSC)',0d
 asc ' 3 - Apple IIgs built-in port',0d
 asc ' 4 - Generic Printer Driver',0d
 asc ' 5 - Star Micronics Grafstar',0d
 asc ' 6 - Orange Micro Grappler card',0d
 asc ' 7 - Apple Parallel interface',0d
 asc ' 8 - Epson APL printer card',0d
 asc ' 9 - Appricorn Parallel card',0d
 asc '10 - Tyvec Printer Interface',0d
 asc '11 - No Printer in system',0d,0d
 asc 'Which? [1-11] ',00

 ldx #11 ;get printer #
 jsr inpnum

 cmp #5
 blt :serial
 cmp #7
 blt :grappler
 cmp #11
 blt :parallel

:null lda #<nullprint
 sta point0
 lda #>nullprint
 sta point0+1
 jmp :noslot

:serial lda #<serial
 ldx #>serial
 jmp :getslot

:grappler lda #<grappler
 ldx #>grappler
 jmp :getslot

:parallel lda #<parallel
 ldx #>parallel

:getslot sta point0
 stx point0+1

 jsr print
 db 1,20,0
 asc 'Which slot/port does your printer',0d
 asc 'use? [1-7] ',00

 ldx #7 ; get slot
 jsr inpnum
 asl a
 asl a
 asl a
 asl a
:noslot pha  ;save slot

 ldy #0 ;move the single page
:loop lda (point0),y ;source
 sta prdrv,y ;destination
 iny
 bne :loop

 pla  ;get the slot back
 sta prdrv

 jsr chinit ; check for init
 jmp wrtchg ; write the changes


