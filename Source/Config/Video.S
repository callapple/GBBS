* Video Driver re-configuration
*-------------------------------

vid40 ext
vid80 ext
vid40pl ext
videx ext

re_vid jsr TopBox
 jsr print
 db 1,3,7
 asc '- Configure Video Driver -',00

 jsr cls
 ldx #<start ; setup esc handler
 lda #>start
 jsr escape

 jsr print
 db 1,7,0
 asc ' 1 - Apple ][+ w/o lower case',0d
 asc ' 2 - Apple ][+ w/ lower case',0d
 asc ' 3 - Apple ][+ w/ Videx 80 col',0d
 asc ' 4 - Apple //e in 40 col mode',0d
 asc ' 5 - Apple //e in 80 col mode',0d
 asc ' 6 - Apple //c in 40 col mode',0d
 asc ' 7 - Apple //c in 80 col mode',0d
 asc ' 8 - Apple IIgs in 40 col mode',0d
 asc ' 9 - Apple IIgs in 80 col mode',0d,0d
 asc 'Which? [1-9] ',00

 ldx #9 ;get printer #
 jsr inpnum

 asl a ;point0 points to the
 tax  ;video device driver
 lda :vidtable,x
 sta point0
 inx
 lda :vidtable,x
 sta point0+1

 lda #<viddrv ;tell it to move the video
 sta point1 ;driver
 lda #>viddrv
 sta point1+1

 ldx #3 ;move 3 illustrious pages
:loop2 ldy #0
:loop lda (point0),y ;source
 sta (point1),y ;destination
 iny
 bne :loop
 inc point0+1
 inc point1+1
 dex
 bne :loop2

 jsr chinit ; check for init
 jmp wrtchg ; write the changes

:vidtable dw 0
 da vid40
 da vid40pl
 da videx
 da vid40
 da vid80
 da vid40
 da vid80
 da vid40
 da vid80


