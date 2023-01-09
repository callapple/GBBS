*-------------------------------
* reconfigure clocks
*-------------------------------

gsclock ext  ;gs clock driver
serialpro ext  ;serialpro  driver
thunder ext  ;thunderclock/timemaster driver
iicsys ext  ;iic system clock
mountain ext  ;mountain clock
prodos ext  ;standard prodos stuff
nullclk ext  ;no clock
noslot ext  ;no slot clock
versa ext  ;prometheus versacard
ultra ext  ;ultra clock driver



re_clk jsr TopBox
 jsr print
 db 1,3,10
 asc '- Reconfigure Clock -',00

 jsr cls

* sec           ;remove asteriks to make IIgs
* jsr $fe1f     ;clock self-installing
* bcs IIeClk
* jmp gsclk

IIeClk jsr print
 db 1,7,0
 asc ' 1 - Thunderclock Compatible',0d
 asc ' 2 - A.E. Timemaster II H.O.',0d
 asc ' 3 - A.E. Serial Pro',0d
 asc ' 4 - A.E. Ultra Clock',0d
 asc ' 5 - A.E. //c System Clock',0d
 asc ' 6 - SMT No-Slot Clock',0d
 asc ' 7 - ProDOS Compatible Clock',0d
 asc ' 8 - Mountain Hardware Clock',0d
 asc ' 9 - Prometheus Versacard',0d
 asc '10 - IIgs Built-in Clock',0d
 asc '11 - No Clock in System',0d,0d
 asc 'Which? [1-11] ',00

 ldx #11
 jsr inpnum

 pha
 asl a
 tax
 lda :clktable,x
 sta point0
 inx
 lda :clktable,x
 sta point0+1

 pla
 cmp #4 ;ultra
 beq :noslot
 cmp #6 ;no slot clock
 beq :noslot
 cmp #7 ;prodos compatable
 beq :noslot
 cmp #10 ;iigs built in
 beq :noslot
 cmp #11 ;no clock
 beq :noslot

 jsr print
 db 1,21,0
 asc 'Which slot/port does the clock use?'0d
 asc '[1-7] '00

 ldx #7 ; get slot
 jsr inpnum
 asl a
 asl a
 asl a
 asl a
:noslot pha  ;save slot

 jsr cls
 jsr print
 db 1,7,0
 asc 'What time format do you want?',0d,0d
 asc ' 1 - 12 hour',0d
 asc ' 2 - 24 hour',0d,0d
 asc 'Which? [1-2]: ',00

 ldx #2 ; get mode
 jsr inpnum
 ldx #$80
 cmp #1
 beq :24hr
 ldx #$00

:24hr txa  ;put mode in accum.
 pha  ;save mode


 ldy #0 ;move the single page
:loop lda (point0),y ;source
 sta clkdrv,y ;destination
 iny
 bne :loop

 pla  ;get the mode back
 sta clkdrv+1
 pla  ;get the slot back
 sta clkdrv

 jsr chinit ; check for init
 jmp wrtchg ; write the changes

:clktable dw 0
 da thunder
 da thunder
 da serialpro
 da ultra
 da iicsys
 da noslot
 da prodos
 da mountain
 da versa
 da gsclock
 da nullclk

*-------------------------------
* IIgs clock is installed by itself

gsclk jsr print
 db 1,7,0
 asc 'IIgs Clock installed automatically...',00
 jsr getcr

 ldy #0
:loop lda gsclock,y
 sta clkdrv,y
 iny
 bne :loop

 jsr chinit
 jmp wrtchg


