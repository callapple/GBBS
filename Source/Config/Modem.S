*-------------------------------
* Date: 3/11/88
*-------------------------------

*-------------------------------
* modems

nullmdm ext  ;null modem driver
cat103 ext  ;300 baud cat driver
cat212 ext  ;1200 baud cat driver
mm2 ext  ;micromodem II driver
ssc ext  ;super serial driver
gsport1 ext  ;location for gs port driver
gsport2 ext  ;loc for gs port slot #2
gs1hst ext  ;location for GS Port1 HST
gs2hst ext  ;location for GS Port2 HST
ultra1 ext  ;location for GS Port1 Ultra
ultra2 ext  ;location for GS Port2 Ultra
singlespd ext  ;single speed driver
multispd ext  ;multi-speed <return> driver
nocar ext  ;no carrier driver

*-------------------------------
* init strings

usr2400 ext  ;init string for usr 2400
usr9600 ext  ;init string for usr 9600
apl1200 ext
hayes1200 ext
hayes2400 ext
hayes9600 ext
pro2400 ext
generic ext
epic ext
datalink24 ext
ultra9600 ext

*-------------------------------
* Reconfigure modem
*-------------------------------

re_mdm bit init
 bmi re_mdmx

 ldx #<start ; setup esc handler
 lda #>start
 jsr escape
 jmp re_mdm0

re_mdmx ldx #<doinit
 lda #>doinit ; setup aux esc handler
 jsr escape

re_mdm0 lda #1 ; set input length at 1
 sta maxlen
 lda #%10010000
 sta inpmode

re_mdm3 jsr TopBox
 jsr print
 db 1,3,6
 asc '- Reconfigure Modem Driver -',00

 jsr cls
 jsr print
 db 1,7,0
 asc ' 1 - No Modem/Local mode',0d,0d
 asc ' 2 - Apple-Cat 103 - 300 baud',0d
 asc ' 3 - Apple-Cat 212 - 300/1200 baud',0d
 asc ' 4 - DC Hayes Micromodem II',0d
 asc ' 5 - Zoom Modem IIe',0d,0d
 asc ' 6 - Epic 2400 Classic II',0d
 asc ' 7 - Applied Engineering DataLink 2400',0d,0d
 asc ' 8 - Super Serial Card driver',0d
 asc ' 9 - Apple IIgs Serial Port driver',0d
 asc '10 - Single Speed SSC driver',0d
 asc '11 - Multiple Spd SSC driver (IIc port)',0d
 asc '12 - No Carrier SSC driver',0d,0d
 asc 'Which? [1-12] ',00

 ldx #12 ; get serial device
 jsr inpnum
 sta serialtype ;save the device type

 asl a ;point0 points to the
 tax  ;serial device driver
 lda devtable,x
 sta point0
 inx
 lda devtable,x
 sta point0+1

 lda #<mdmdrv ;tell it to move the modem
 sta point1 ;driver
 lda #>mdmdrv
 sta point1+1

 lda #12 ;default is generic
 asl a ;point init string to the
 tax  ;right place
 lda strtable,x
 sta point3
 inx
 lda strtable,x
 sta point3+1

 lda serialtype ;is it internal?
 cmp #8
 bcs getinit ;nope, get an init string
 cmp #7 ;was it AE Datalink 2400?
 beq :dl24 ;use DL init string
 cmp #6 ;was it the Epic internal?
 beq :epic24 ;yes, set for epic string
 cmp #1 ;nullmodem?
 bne :internal ;nope, just internal
 pha  ;push garbage data
 pha
 jmp movepage ;move & fix into place

:internal jmp getslot ;must have been internal, skip next

:dl24 lda #14 ;datalink string is #14
 hex 2c ;skip next instruction

:epic24 lda #1 ;default for epic is &s1&d2
 jmp getinit1 ;move init sting into right place

*-------------------------------
* get the init string for the modem

getinit jsr cls
 jsr print
 db 1,7,0
 asc 'Choose Modem:',0d,0d
 asc ' 1 - Epic 2400 Plus',0d
 asc ' 2 - USRobotics Courier 2400',0d
 asc ' 3 - USRobotics Courier HST',0d
 asc ' 4 - Apple Modem 1200',0d
 asc ' 5 - Prometheus Promodem 1200',0d
 asc ' 6 - Prometheus Promodem 2400',0d
 asc ' 7 - Novation SmartCat',0d
 asc ' 8 - Novation Professional 2400',0d
 asc ' 9 - Hayes 1200',0d
 asc '10 - Hayes 2400',0d
 asc '11 - Hayes V-Series 9600',0d
 asc '12 - Hayes Ultra 9600/PP 9600sa'0d
 asc !13 - Generic 'AT' Compatible!,0d,0d
 asc 'Which? [1-13] ',00

 ldx #13
 jsr inpnum
 sta modemtype

getinit1 asl a ;point init string to the
 tax  ;right place
 lda strtable,x
 sta point3
 inx
 lda strtable,x
 sta point3+1

*-------------------------------

setinit jsr cls
 jsr print
 db 1,7,0
 asc 'The init string for this modem is:',0d,0d,00

 ldy #0
:loop lda (point3),y
 sta initbuf,y
 beq :done
 jsr cout
 iny
 bne :loop

:done jsr print
 hex 0d
 asc 'Press [RETURN] to accept this as'0d
 asc 'default, or enter a new init string.',0d
 asc ':',00

 lda #39 ; only allow 39 chars
 sta maxlen
 lda #%10100000
 sta inpmode ;ascii
 jsr inpln ; get the input
 ldy lnbuf
 cpy #cr
 beq getans ; use default

 ldy #-1
:loop2 iny  ;move the typed init string
 lda lnbuf,y
 sta initbuf,y
 cmp #cr
 bne :loop2

 iny
 lda #0
 sta initbuf,y

*-------------------------------
* get the answer string

getans jsr cls
 jsr print
 db 1,7,0
 asc 'The answer string for this modem is:',0d,0d,00

 ldy #0
:loop lda atastr,y
 sta ansbuf,y
 beq :done
 jsr cout
 iny
 bne :loop

:done jsr print
 hex 0d
 asc 'Press [RETURN] to accept this, or',0d
 asc 'enter a new answer string.',0d
 asc ':',00

 lda #15 ; only allow 15 chars
 sta maxlen
 jsr inpln ; get the input
 ldy lnbuf
 cpy #cr
 beq getdcd ; use default

 ldy #-1
:loop2 iny  ;move the typed answer string
 lda lnbuf,y
 sta ansbuf,y
 cmp #cr
 bne :loop2

 iny
 lda #0
 sta ansbuf,y

*-------------------------------
* get the dcd drop type

getdcd jsr print
 hex 0d,0d
 asc 'What type of carrier detect should'0d
 asc 'the modem driver use?',0d,0d
 asc ' 1 - DSR Carrier Detect [Normal]',0d
 asc ' 2 - DCD Carrier Detect',0d,0d
 asc 'Which? [1-2] ',00

 ldx #2
 jsr inpnum
 sta cdtype

*-------------------------------
* get the proper slot

getslot jsr cls
 lda serialtype
 cmp #9
 beq :gsport

 jsr print
 db 1,7,0
 asc 'Which slot should the modem driver use?'0d
 asc '[1-7] ',00
 ldx #7
 jmp :over

:gsport jsr print
 db 1,7,0
 asc 'Which Serial Port? [1-2] ',00

 ldx #2
:over jsr inpnum
 pha

 ldx serialtype
 cpx #9 ;was it the IIgs serial port?
 bne :notgsport ;nope

 cmp #1 ;was it port #1?
 bne :port2 ;nope, must be port 2

 lda #<gsport1 ;move gs port, slot 1
 sta point0
 lda #>gsport1
 sta point0+1
 jmp :hst

:port2 lda #<gsport2 ;move gs port slot 2
 sta point0
 lda #>gsport2
 sta point0+1

* CODE FOR HST GS MODEM PORT! *

:hst pla  ; get back slot #
 pha
 ldx modemtype
 cpx #3 ; did they pick HST?
 bne :ultra ; nope so go on

 cmp #1 ;was it port #1?
 bne :hst2

 lda #<gs1hst ;move gs port slot 2
 sta point0
 lda #>gs1hst
 sta point0+1
 jmp :notgsport

:hst2 lda #<gs2hst ;move gs port slot 2
 sta point0
 lda #>gs2hst
 sta point0+1
 jmp :notgsport

:ultra ldx modemtype
 cpx #13 ; did they pick ULTRA/PP?
 bne :notgsport ; nope so go on

 cmp #1 ;was it port #1?
 bne :ult2

 lda #<ultra1 ;move gs port slot 2
 sta point0
 lda #>ultra1
 sta point0+1
 jmp :notgsport

:ult2 lda #<ultra2 ;move gs port slot 2
 sta point0
 lda #>ultra2
 sta point0+1

:notgsport
 lda serialtype ;was it an internal?
 cmp #7
 bcs :external ;no, init baud needed
 jmp :internal ;yes, init spd not needed

:external jsr print
 db 1,10,0
 asc 'At what baud rate should the port/card',0d
 asc 'be initialized?  (Choose the maximum',0d
 asc 'baud rate of your modem)',0d,0d
 asc ' 1 -   300 baud',0d
 asc ' 2 -  1200 baud',0d
 asc ' 3 -  2400 baud',0d
 asc ' 4 -  4800 baud',0d
 asc ' 5 -  9600 baud',0d
 asc ' 6 - 19200 baud',0d
 asc ' 7 - 38400 baud (only for v.32 modems)',0d,0d
 asc 'Which? [1-6] ',00

 ldx #7
 jsr inpnum
:internal pha

movepage ldx #3 ;move 3 illustrious pages
:loop2 ldy #0
:loop lda (point0),y ;source
 sta (point1),y ;destination
 iny
 bne :loop
 inc point0+1
 inc point1+1
 dex
 bne :loop2

 pla  ;get init speed
 tax
 dex  ;one less
 stx mdmdrv+1 ;save it

 pla  ;get the slot
 asl a
 asl a
 asl a
 asl a ;a := a*16
 sta mdmdrv ;store the slot

 dec cdtype
 lda serialtype
 cmp #9 ;was it the gs?
 bne :notgs ;nope, go there, SSC

 lda cdtype ;get drop type
 bne :notgsdsr ;dcd wanted, so stick it
 lda #$20 ;else use dsr drop
 sta cdbyte
 bne copyans

:notgsdsr lda #$08 ;setup for dcd drop
 sta cdbyte
 bne copyans

:notgs lda cdtype ;ssc
 bne :notdsr ;dcd drop wanted, go there
 lda #%01000000 ;check only dsr (normal)
 sta cdbyte
 bne copyans

:notdsr lda #%00100000 ;otherwise check DCD
 sta cdbyte

*-------------------------------

copyans ldy #0
:loop lda ansbuf,y ;copy the answer string
 sta ansstr,y
 beq copyinit
 iny
 bne :loop

copyinit ldy #0 ;copy the init string
:loop lda initbuf,y
 sta initstr,y
 beq :writeit
 iny
 bne :loop

:writeit jsr chinit ; check for init
 jmp wrtchg ; write the changes

*-------------------------------
* modem drivers

devtable dw 0 ;extra for offset 0
 da nullmdm ;null modem driver
 da cat103 ;300 baud cat driver
 da cat212 ;1200 baud cat driver
 da mm2 ;micromodem II driver
 da mm2 ;Zoom Modem
 da ssc ;AE DataLink 2400
 da ssc ;epic 2400 classic
 da ssc ;super serial driver
 da gsport2 ;location for gs port driver
 da singlespd ;single speed driver
 da multispd ;multi-speed <return> driver
 da nocar ;no carrier 300 baud driver

strtable dw 0
 da epic ;1
 da usr2400 ;2
 da usr9600 ;3
 da apl1200 ;4
 da usr2400 ;5
 da usr2400 ;6
 da hayes2400 ;7
 da pro2400 ;8
 da hayes1200 ;9
 da hayes2400 ;10
 da hayes9600 ;11
 da ultra9600 ;12
 da generic ;13
 da datalink24 ;14

atastr asc 'ATA',0d,00
