 PAG
********************************
*                              *
*     ACOS.OBJ - Commands      *
*                              *
********************************
 DATE
*-------------------------------
* print statement
*-------------------------------

ERR LDX #syntax
 JMP ERROR

NIL RTS

DO_PRNT LDA #0 ;PRINT
 JSR GETDEV
 JSR SETOVEC ;set output vector
 JMP :DO_PR0

:DO_PR0A JSR VIDWND
 JSR TOPSHOW
 LDX WNDTOP
 INX
 CPX CV
 BLT :DO_PR1
 STX CV

:DO_PR1 JSR INPTYP ;check for eol
 BNE :DO_PR0
 RTS

:DO_PR1A JSR INPNUM ;handle "@"
 DEX
 STX CH
 JSR CHKBYT
 CMP #","
 BNE :DO_PR0

 JSR GETBYT
 JSR INPNUM
 DEX
 STX CV
 JMP :DO_PR0

:DO_PR9 LDA #cr ;print cr/lf
 JMP DO_OUT

:DO_PR1B LDA #cr ;handle "\"
 AND #clrhi
:DO_PR1C JSR DO_OUT

:DO_PR0 JSR INPTYP ;get data
 BEQ :DO_PR9 ;eol?

 CMP #1
 BEQ :DO_PR5 ;token?
 CMP #2
 BEQ :DO_PR2 ;hard-coded text?
 CMP #3
 BEQ :DO_PR4 ;number?
 CMP #5
 BEQ :DO_PR5 ;string variable?
 CMP #6
 BEQ :DO_PR4 ;numeric variable?

 JSR GETBYT ;must be control
 CMP #","
 BEQ :DO_PR1C ;print it
 CMP #";"
 BEQ :DO_PR1 ;no cr
 CMP #"@"
 BEQ :DO_PR1A ;position
 CMP #"\"
 BEQ :DO_PR1B ;cr/lf
 CMP #"^"
 BEQ :DO_PR0A ;display top

 LDX #syntax ;syntax error
 JMP BADERR

:DO_PR2 JSR GETBYT
:DO_PR3 JSR GETBYT
 BEQ :DO_PR0 ;if eol

 CMP #"""
 BEQ :DO_PR0 ;gobble
 JSR DO_OUT
 JMP :DO_PR3 ;and loop

:DO_PR4 JSR INPNUM ;get number
 JSR DECOUT
 JMP :DO_PR0

:DO_PR5 JSR ARGTYP
 BCC :DO_PR4 ;if it is a number

 JSR INSTR2 ;set up pointers
 TYA
 TAX
 INX
 LDY #0

:DO_PR6 DEX
 BEQ :DO_PR0 ;print out string

 LDA (STRLOC),Y
 JSR DO_OUT
 INY
 JMP :DO_PR6

DO_OUT JMP (VECTOR)

*-------------------------------
* goto statement
*-------------------------------

DO_GOTO JSR GETRAW ;get address
 PHA
 JSR GETRAW
DO_GT2 STA PRGPTR+1 ;put into program counter
 PLA
 STA PRGPTR
 RTS

*-------------------------------
* gosub statement
*-------------------------------

DO_GSB JSR TST_GSB ;make sure there is room
 JSR GETRAW ;get address
 PHA
 JSR GETRAW
 PHA

 LDA PRGPTR
 STA GSBSTK,X ;put current address onto gosub stack
 INX
 LDA PRGPTR+1
 STA GSBSTK,X
 INX
 STX GSBLVL
 PLA
 JMP DO_GT2 ;do the goto

TST_GSB LDX GSBLVL
 CPX #32
 BNE :TSTGSB3 ;there's enough room

 LDX #0
:TSTGSB2 LDA GSBSTK+3,X
 STA GSBSTK+1,X ;kill oldest gosub
 LDA GSBSTK+2,X
 STA GSBSTK,X
 INX
 INX
 CPX #30
 BNE :TSTGSB2

:TSTGSB3 RTS

*-------------------------------
* push a level onto the stack
*-------------------------------

DO_PUSH JSR TST_GSB ;make sure there is room
 JSR GETRAW ;put data onto stack
 STA GSBSTK,X
 INX
 JSR GETRAW
 STA GSBSTK,X
 INX
 STX GSBLVL
 RTS

*-------------------------------
* pop a level off the gosub stack
*-------------------------------

DO_POP LDY GSBLVL ;make sure there is something to pop
 BEQ :DO_POP2 ;nothing to pop -- give error

 DEY
 DEY
 STY GSBLVL
:DO_POP2 RTS

*-------------------------------
* return to the address on the stack
*-------------------------------

DO_RET LDX #nogosub
 LDY GSBLVL ;make sure there is a return address
 BEQ DO_RET3 ;nothing to return to -- give error

 DEY
 LDA GSBSTK,Y
 STA PRGPTR+1 ;return to caller
 DEY
 LDA GSBSTK,Y
 STA PRGPTR
 STY GSBLVL
DO_RET2 RTS

DO_RET3 JMP BADERR ;No gosubs

*-------------------------------
* clear a device
*-------------------------------

CLRDEV JSR GETBYT ;gobble
 JSR INPNUM
 CPX #8
 BEQ :CLR_ED ;clear editor?

 CPX #9
 BEQ :JCLRTOP ;clear screen top?

 CPX #10
 BNE DO_RET2 ;clear ram drive?

 LDA #0
 STA RAMPTR ;clear ram drive
 STA RAMDRV
 RTS

*-------------------------------
* clear the editor
*-------------------------------

:CLR_ED JMP ED_CLR ;clear editor

*-------------------------------
* clear user stats at screen top
*-------------------------------

:JCLRTOP JMP CLRTOP

*-------------------------------
* clear the gosub stack
*-------------------------------

CLRSTK LDA #0
 STA GSBLVL ;reset gosub stack
 JMP GETBYT ;gobble!

*-------------------------------
* clear the keyboard buffer
*-------------------------------

CLRKEY LDA #0
 STA TYPIN ;reset type-ahead buffer
 STA TYPOUT
 JMP GETBYT ;gobble!

*-------------------------------
* clear command
*-------------------------------

DO_CLR JSR CHKBYT
 CMP #"#"
 BEQ CLRDEV ;clear a device
 CMP #gosub
 BEQ CLRSTK ;clear the stack
 CMP #key
 BEQ CLRKEY ;clear the type-ahead buffer

*-------------------------------
* clear statement
*-------------------------------

CLEAR LDA #<ENDMOD ;save ending address
 STA HIMEM
 LDA #>ENDMOD
 STA HIMEM+1

 LDY HIMEM ;clear out pointers
 STY TEMP
 LDY HIMEM+1
 DEY
 STY TEMP+1
 LDY #$FA
 LDA #0
 STA FORLVL ;reset for-next level
 STA (TEMP),Y
 LDA LOMEM ;reset string space
 STA VARSTR
 LDA LOMEM+1
 STA VARSTR+1

 SEC
 LDA HIMEM+1 ;midmem = lomem+(himem-lomem)/2
 SBC LOMEM+1
 LSR
 CLC
 ADC LOMEM+1
 STA MIDMEM+1 ;compute initial midmem value
 LDA #0
 STA MIDMEM

 STA FROMERR
 STA FROMERR+1
 RTS

*-------------------------------
* let statement
*-------------------------------

DO_LET JSR CHKBYT ;doing a string?
 CMP #string
 BNE :DO_LET0 ;nope

 JSR CHKFRE ;free old strings
:DO_LET0 JSR VARSET ;set up pointers to variable
 JSR GOBEQU

 LDA VNAME
 PHA
 LDA VPTR ;save var address
 PHA
 LDA VPTR+1
 PHA

 LDA VNAME ;check name to see if string
 BPL :DO_LET2 ;or number

 JSR INPSTR ;get string address and length
 JMP :DO_LET3

:DO_LET2 JSR INPNUM
:DO_LET3 STX TEMP ;save a
 STA TEMP+1
 STY SAVE_Y

 PLA
 STA VPTR+1 ;point back at var
 PLA
 STA VPTR
 PLA
 BPL :DO_LET5 ;if numeric

 LDY #0
 LDA (VPTR),Y
 STA TEMP2
 INY
 LDA (VPTR),Y
 STA TEMP2+1 ;see if variable is in low memory
 BEQ :DO_LET5 ;if new var...

 CMP #>CODEND
 BGE :DO_LET5 ;nope

 INY
 LDA (VPTR),Y ;get length
 TAX

 LDY #0
:DO_LET4 LDA (TEMP),Y
 STA (TEMP2),Y ;copy string
 INY
 DEX
 BNE :DO_LET4
 RTS

:DO_LET5 LDY #0 ;save low address or byte
 LDA TEMP
 STA (VPTR),Y
 INY
 LDA TEMP+1
 STA (VPTR),Y ;save high address or byte
 INY
 LDA SAVE_Y
 STA (VPTR),Y ;save length
 LDA #0
 STA TTLLEN
DO_IF4 RTS

*-------------------------------
* if statement
*-------------------------------

DO_IF JSR INPNUM ;evaluate expression
 STX TEMP
 ORA TEMP
 BNE DO_IF4

:DO_IF2 JSR IFGOB ;loop until a chain
 CMP #chain2
 BEQ DO_IF3
 CMP #else
 BNE :DO_IF2 ;is there an else clause?

DO_IF3 BIT SHWTRC
 BPL DO_IF4 ;just return
 JMP LIST

*-------------------------------
* else statement
*-------------------------------

DO_ELSE JSR IFGOB ;loop until a chain
 CMP #chain2
 BNE DO_ELSE
 BEQ DO_IF3 ;link back to code

*-------------------------------
* gobble program bytes
*-------------------------------

IFGOB JSR GETRAW
 CMP #goto
 BEQ :IFGOB1 ;is byte followed by data?
 CMP #gosub
 BEQ :IFGOB1
 CMP #push
 BNE DO_IF4 ;else, return

:IFGOB1 JSR GETRAW
 JMP GETRAW

*-------------------------------
* handle modem calls
*-------------------------------

DO_MDM JSR INPNARG
 CPX #3
 BGE :DO_MDM2

 TXA
 ASL
 TAX
 LDA MDMJMP,X
 STA TEMP
 LDA MDMJMP+1,X
 STA TEMP+1
 JMP (TEMP) ;go to routine

:DO_MDM2 RTS

MDMJMP DA MDM0 ;wait for call
 DA MDM1 ;hang up
 DA MDM2 ;dud command for now

*-------------------------------
* handle waiting for a call
*-------------------------------

MDM0 LDA #0
 STA REMOTE
 JSR MDMHANG ;hang up phone
 JSR MDMRSET ;setup for answer
 LDX #0
 STX NULLS ;reset nulls
 STX EXEC ;reset possible exec mode
 STX DOCHAT ;reset chat mode

 DEX
 STX REMOTE ;setup for local only
 STX VIDECHO ;turn off any echo

:MDM0_1 LDA #'A'-ctrl
 STA TOPRIGHT

:MDM0_2 JSR VIDKEY ;check for keypress
 BPL :MDM0_3

 STA KBDSTRB ;clear keyboard
 AND #$1F ;make into [0-31] range
 CMP #'G'-ctrl
 BEQ :MDM0_5 ;do local
 CMP #'Q'-ctrl
 BEQ :MDM0_4 ;quit
 CMP #'A'-ctrl
 BNE :MDM0_3 ;keep checking

 JSR MDMANS ;answer phone

:MDM0_3 JSR MDMRING ;check for connect
 BCS :MDM0_6 ;we got a connect

 JSR USERVEC ;do user sub-routine
 LDA TOPRIGHT
 CMP #'Z'-ctrl
 BEQ :MDM0_1
 INC TOPRIGHT
 JMP :MDM0_2

:MDM0_4 JMP RESTART1 ;quit

:MDM0_5 JSR MDMHANG ;hang up (disable AA)
 LDA #0
 STA REMOTE ;set to local
 STA SPCINIT
 JMP CLRBUF ;clear keyboard buffer

:MDM0_6 JSR MDMIN ;get modem input
 BCS :MDM0_6 ;and gobble until gone
 JMP CLRBUF ;clear keyboard buffer

*-------------------------------
* hang up
*-------------------------------
* this code centers the copyright message
* but kevin does not like it so we removed it
*
*MDM1 LDA #20 ;default to 40 columns
* BIT RD80VID ;in 80 column mode?
* BPL :CENTER ;nope
* LDA #40 ;reset for 80 columns
*
*:CENTER SEC ;subtract length/2
* SBC #COPEND-COPNOT/2
* TAY
* LDA #' ' ;print spaces to center
*]LOOP JSR COUT
* DEY
* BPL ]LOOP

MDM1 LDA #<COPNOT ;point to data to print
 STA TEMP
 LDA #>COPNOT
 STA TEMP+1
 LDY #COPEND-COPNOT ;set length
 DEY
:PRNTCPY LDA (TEMP),Y
 EOR #COPEND-COPNOT ;translate
 ROR
 JSR COUT
 DEY
 BPL :PRNTCPY

MDM1_2 LDA #0
 STA REMOTE ;set local modem
 JMP MDMHANG ;hang up phone

*-------------------------------
* dud command for now
*-------------------------------

MDM2 LDA #0
 STA REMOTE
 JMP MDMDTR ;raise DTR so that we can talk to the modem

*-------------------------------
* get the length of a string
*-------------------------------

DO_LEN JSR INPSARG ;point to string
 LDA STRLEN ;get length
SVDATA STA DATA+1
 LDX #0
 STX DATA+2
 INX
 STX DATA
 RTS

*-------------------------------
* input a line of text or data
*-------------------------------

DO_IN JSR CHKFRE ;check the free memory
 LDA #%10000001
 STA INPMODE ;default input mode
 LDA #0
 STA INTOUT ;reset output interrupt
 STA INTBUF

 JSR GETDEV ;setup dev pointer
 JSR SETIVEC ;set input vector
 STX SHWIN ;save channel #

:DO_IN2D JSR CHKBYT
 CMP #"""
 BEQ :DO_IN2C ;check for string
 CMP #"\"
 BEQ :DO_IN2E
 CMP #"@"
 BNE :DO_IN3

 JSR GETBYT ;gobble "@"
 JSR GETBYT
 AND #$F ;see if its all ligit
 TAY
 CPY #5
 BGE :DO_IN3

 LDA MODEBYT,Y
 STA INPMODE ;set new mode
 JMP :DO_IN2D

:DO_IN2E LDA #cr ;handle "\"
 JSR COUT
 JSR GETBYT
 JMP :DO_IN2D

:DO_IN2C JSR GETBYT ;gobble up
:DO_IN2A JSR GETBYT
 CMP #"""
 BEQ :DO_IN2B ;are we done?, yep

 JSR COUT
 JMP :DO_IN2A

:DO_IN2B JSR CHKBYT
 CMP #";"
 BNE :DO_IN3 ;possible gobble

 JSR GETBYT ;gobble colon

:DO_IN3 LDX SHWIN ;get back channel #
 CPX #0
 BEQ :DO_IN3D ;use console input routine

 LDX #0
:DO_IN3A JSR DO_INP ;get input line
 AND #clrhi
 CMP #lf
 BEQ :DO_IN3A ;gobble lf

 TAY ;set zero/non-zero bit
 BNE :DO_IN3B

 LDA #cr
:DO_IN3B STA LNBUF,X ;save char
 INX
 CMP #cr
 BNE :DO_IN3A
 BEQ :DO_IN3C ;nope, yep

:DO_IN3D JSR INPLN ;get console input line

:DO_IN3C LDA #0
 STA LNCNT ;reset pointer to start of line

:DO_IN4 JSR VARSET
 JSR CHKBYT ;see if there's more input
 LDX #cr
 CMP #","
 BNE :DO_IN5

 JSR GOBCOM ;gobble up char
 LDX #','
:DO_IN5 STX TEMP2 ;save ending character

 LDA VNAME ;input a number?
 BPL :DO_IN8 ;yep

 LDY #1
 LDA VARSTR+1
 STA (VPTR),Y ;point at new string
 DEY
 LDA VARSTR
 STA (VPTR),Y
 STY TEMP2+1 ;zero counter

 LDX LNCNT
:DO_IN7 LDA LNBUF,X ;get input
 CMP #cr
 BEQ :DO_IN7A

 INX
 CMP TEMP2
 BEQ :DO_IN7A ;are we done?

 STA (VARSTR),Y ;copy
 INC TEMP2+1 ;inc length counter

 INC VARSTR
 BNE :DO_IN7
 INC VARSTR+1
 BNE :DO_IN7

:DO_IN7A STX LNCNT
 LDY #2
 LDX TEMP2+1 ;get the length
 BEQ :DO_IN7C ;length 0

 LDA INPMODE
 AND #2
 BEQ :DO_IN7C

 LDX #1 ;use length 1
:DO_IN7C TXA
 STA (VPTR),Y

:DO_IN7B LDA TEMP2 ;are we done?
 CMP #cr
 BNE :DO_IN4 ;nope

 JSR CHKBYT
 CMP #"\"
 BNE :DO_IN7D ;get another line?, nope

 JSR GETBYT ;gobble
 JMP :DO_IN3

:DO_IN7D RTS

:DO_IN8 LDA LNCNT
 STA TEMP3
 LDA #>LNBUF
 STA TEMP3+1
 JSR ZNUMIN ;get number

 LDY #1
 STA (VPTR),Y
 DEY ;save it
 TXA
 STA (VPTR),Y

 LDX TEMP3
 STX LNCNT ;reset line counter
 LDA LNBUF,X
 CMP #cr
 BEQ :DO_IN7B ;keep going

 INC LNCNT
 JMP :DO_IN7B ;finish up

DO_INP JMP (VECTOR2) ;get a byte of input

NO_INP LDA #0 ;no input available
NO_OUT RTS

*-------------------------------
* set echo
*-------------------------------

DO_ECHO JSR GOBEQU ;gobble equal sign
 JSR INPSTR
 LDA #$FF
 LDY STRLEN ;see if it is legal 1 char
 CPY #1
 BNE :DO_ECH2

 LDY #0
 LDA (STRLOC),Y ;get char and save
 AND #clrhi
:DO_ECH2 STA VIDECHO

 RTS

VIDECHO DB -1

*-------------------------------
* get the instr()
*-------------------------------

DO_INST JSR INPSARG
 LDA STRLEN ;save address and length of string
 PHA
 LDA STRLOC
 PHA
 LDA STRLOC+1
 PHA

 JSR INPSARG ;get other string

 PLA
 STA TEMP+1 ;restore first string info
 PLA
 STA TEMP
 PLA
 STA TEMP2

 JSR CHKBYT ;Lane Roathe - support optional index [,start]
 LDX #0 ;default index is zero
 CMP #","
 BNE :DO_NSR0

 JSR GOBCOM ;eat ,
 JSR INPNUM ;get index in X
 JSR GETBYT ;eat )
:DO_NSR0
 CPX #0
 BEQ :DO_NSR1
 DEX
:DO_NSR1
 STX TEMP2+1

 LDX #1 ;def location is 1 for null match
 LDA TEMP2
 BEQ :DO_NSR7 ;if null string, always match

 SEC
 LDA STRLEN
 SBC TEMP2+1 ;how many chars to search after index?
 BCC :DO_NSR6 ; none!
 STA STRLEN

 CLC
 LDA STRLOC
 ADC TEMP2+1 ;advance source string past index
 STA STRLOC
 LDA STRLOC+1
 ADC #0
 STA STRLOC+1

 SEC
 LDA STRLEN ;how many chars to search?
 SBC TEMP2
 BCC :DO_NSR6 ;none!

 TAX
 INX
 STX TEMP2+1 ;save passes plus 1

 LDX #0 ;start at pass 0
:DO_NSR2 LDY #0 ;start checking at byte 0
:DO_NSR3 LDA (TEMP),Y ;get first byte
 JSR CONV ;make upper
 STA TEMP3 ;save
 LDA (STRLOC),Y ;get second byte
 JSR CONV ;make upper
 CMP TEMP3
 BNE :DO_NSR4 ;do they match?, nope

 INY ;inc pointer
 CPY TEMP2
 BNE :DO_NSR3 ;we done?, nope

 INX ;get pass+1
:DO_NSR7 TXA
 JMP SVDATA ;return

:DO_NSR4 INC STRLOC ;check against next byte
 BNE :DO_NSR5
 INC STRLOC+1
:DO_NSR5 INX ;count up passes
 CPX TEMP2+1
 BNE :DO_NSR2 ;are we done?, nope

:DO_NSR6 LDA #0 ;no match
 JMP SVDATA

 LDX #badtype ;type mismatch error
 JMP BADERR

*-------------------------------
* get the left$
*-------------------------------

DO_LFT JSR DO_ISTR ;get string and length
 JMP DO_XSTR ;we're done

*-------------------------------
* get the right$
*-------------------------------

DO_RGT JSR DO_ISTR
 SEC
 LDA TEMP2+1
 SBC TEMP2 ;find out how much is to be used
 BEQ :DO_RGT2

 CLC
 ADC TEMP ;get start of string
 STA TEMP
 LDA #0
 ADC TEMP+1
 STA TEMP+1
:DO_RGT2 JMP DO_XSTR ;finish up

*-------------------------------
* get the mid$
*-------------------------------

DO_MID JSR DO_ISTR ;point to string
 DEC TEMP2

 CLC
 LDA TEMP2
 ADC TEMP
 STA TEMP ;get start of string
 LDA #0
 ADC TEMP+1
 STA TEMP+1

 JSR CHKBYT
 LDX #-1
 CMP #","
 BNE :DO_MID2 ;see if there is a length arg, nope

 JSR GOBCOM ;gobble
 JSR INPNUM ;get it
 JSR GETBYT ;gobble )

:DO_MID2 SEC
 LDA TEMP2+1
 SBC TEMP2 ;compute maximum length

 STX TEMP2+1
 CMP TEMP2+1
 BLT :DO_MID3 ;find out which to use

 TXA
:DO_MID3 STA TEMP2

DO_XSTR LDX TEMP ;return string loc & length
 LDA TEMP+1
 LDY TEMP2
 JMP SVSTR

DO_ISTR JSR INPARG ;get the string
 LDA STRLOC ;save string info
 STA TEMP
 LDA STRLOC+1
 STA TEMP+1
 LDA STRLEN
 STA TEMP2+1

 JSR INPNARG
 STX TEMP2 ;get the number
 CPX TEMP2+1
 BLT :DO_IST2 ;make length legal

 LDX TEMP2+1
:DO_IST2 STX TEMP2
 RTS

*-------------------------------
* handle the chr$() function
*-------------------------------

DO_CHR JSR INPNARG ;get char number
 TXA
 PHA

 JSR CHKBYT
 LDX #1 ;check for more data
 CMP #","
 BNE :DO_CHR2

 JSR INPNARG
:DO_CHR2 STX DATA+3 ;get number of chars

 LDA VARSTR ;point to string
 STA DATA+1
 LDA VARSTR+1
 STA DATA+2

 PLA
 LDY #0
:DO_CHR3 STA (VARSTR),Y ;create string
 INC VARSTR
 BNE :DO_CHR4
 INC VARSTR+1

:DO_CHR4 DEX
 BNE :DO_CHR3

 LDA #2
 STA DATA ;data type 2
 RTS

*-------------------------------
* get the value from a string
*-------------------------------

DO_VAL JSR GETBYT ;gobble (
 JSR INSTR2 ;don't use any space
 LDY STRLEN
 LDA #0
 STA LNBUF,Y ;terminate string
:DO_VAL2 DEY
 BMI :DO_VAL3

 LDA (STRLOC),Y
 STA LNBUF,Y ;copy string
 JMP :DO_VAL2

:DO_VAL3 LDA #<LNBUF ;point to string
 STA TEMP3
 LDA #>LNBUF
 STA TEMP3+1
 JSR ZNUMIN ;get number
 STX DATA+1
 STA DATA+2
 JSR GETBYT ;gobble )
 LDA #1
 STA DATA ;data type 1
 RTS

*-------------------------------
* set interupt key to spacevar (for editor)
*-------------------------------

DO_SED SEC ;set flag
 BCS XINT

*-------------------------------
* set interupt keys that can be used
*-------------------------------

DO_SINT CLC ;fall into aint routine
XINT PHP
 LDY #127
 LDA #0
 STA INTOUT ;reset output
:SINT2 STA INTBUF,Y ;clear int buffer
 DEY
 BPL :SINT2 ;loop and fall into "addint"
 PLP ;restore status
 BCS AINT0 ;just enable spacebar

*-------------------------------
* add interupt keys
*-------------------------------

DO_AINT JSR INPARG ;get arg
 LSR
 BCS AINT1 ;error, should be a string

 LDX NUMB
 CPX #1
 BEQ AINT0 ;fix stop char
 CPX #2
 BNE AINT3 ;there's a problem

 LDA #$FF
 LDX NXTCHR ;flag "next-message" char
 STA INTBUF,X

AINT0 LDA #$FF
 LDX STPCHR ;flag "stop-message" char
 STA INTBUF,X
 STA INTBUF ;enable int's
 STA INTBUF+127 ;special int flag
 LDA #0
 STA INTCHR ;clear int char
 RTS

AINT1 LSR ;put arg count into carry

 DEC STRLEN
 BNE AINT2
 PHP
 LDY #0
 LDA (STRLOC),Y ;get key
 JSR CONV

 TAY
 LDA #$FF
 STA INTBUF ;enable int
 STA INTBUF,Y ;mark as an int key
 PLP
AINT2 BCS DO_AINT
 RTS

AINT3 LDX #badtype ;type mismatch error
 JMP BADERR

*-------------------------------
* get a single character
*-------------------------------

DO_GET JSR CHKFRE ;make sure enough memory
 LDA #0
 STA INTOUT ;reset output
 STA INTBUF
 JSR VARSET ;setup var
 LDA VNAME
 BPL AINT3 ;its a number

 JSR CHKTIME ;check for timeout
 BCC :DO_GET3 ;opps, timeout!

:DO_GET0 JSR KEYIN ;get the char
 BIT DOCHAT
 BPL :DO_GET2 ;all is well

 DEC INCHAT
 JSR DO_CHAT ;handle chat
 JMP :DO_GET0

:DO_GET2 JSR CONV
 LDY #0
 STA (VARSTR),Y ;save character

 LDA VARSTR
 STA (VPTR),Y ;point to char
 INY
 LDA VARSTR+1
 STA (VPTR),Y
 INY
 LDA #1
 STA (VPTR),Y ;length 1

 INC VARSTR
 BNE :DO_GET3 ;inc string space
 INC VARSTR+1

:DO_GET3 RTS

*-------------------------------
* set up variable pointers
*-------------------------------

DO_SET JSR VARSET ;set up pointers
 JSR GOBEQU

 JSR CHKBYT ;set to null?
 CMP #"""
 BNE :SET2 ;nope

 JSR GETBYT ;gobble quotes
 JSR GETBYT

 LDA VARSTR ;point at empty space
 STA TEMP
 LDA VARSTR+1
 STA TEMP+1
 LDX #0 ;set length to zero
 BEQ :SET3

:SET2 LDA VPTR
 PHA
 LDA VPTR+1 ;save current pointers
 PHA

 JSR INPNUM ;get address of string
 PHA
 TXA
 PHA
 JSR GOBCOM
 JSR INPNUM ;get length of string

 PLA
 STA TEMP ;restore address of string
 PLA
 STA TEMP+1

 PLA
 STA VPTR+1 ;restore pointers to orig var
 PLA
 STA VPTR

:SET3 LDY #2
 TXA ;save file length
 STA (VPTR),Y
 DEY

 LDA TEMP+1
 STA (VPTR),Y ;save high byte of address
 DEY
 LDA TEMP
 STA (VPTR),Y ;save low byte of address
 RTS

*-------------------------------
* get a number in string form
*-------------------------------

DO_STR JSR INPNARG ;get arg

 LDA VECTOR ;save current vector value
 PHA
 LDA VECTOR+1
 PHA

 LDA #<NIL ;suppress output
 STA VECTOR
 LDA #>NIL
 STA VECTOR+1

 JSR GETNUMB ;print number to memory
 JSR DECOUT

 PLA
 STA VECTOR+1 ;restore vector
 PLA
 STA VECTOR

 LDA VARSTR ;point to string
 STA DATA+1
 LDA VARSTR+1
 STA DATA+2

 LDA TXTNUM
 STA DATA+3 ;save length

 LDY #0
 LDX #1
:DO_STR2 LDA TXTNUM,X
 STA (VARSTR),Y ;copy byte
 INX
 INC VARSTR
 BNE :DO_STR3 ;point to next byte
 INC VARSTR+1

:DO_STR3 DEC TXTNUM
 BNE :DO_STR2 ;count the digits

 LDA #2
 STA DATA ;we're done
 RTS

*-------------------------------
* "not" a value
*-------------------------------

DO_NOT JSR INPNUM ;get value
 STX TEMP
 LDX #1
 ORA TEMP ;see if its zero or non-zero
 BEQ :DO_NOT2

 DEX
:DO_NOT2 TXA
 JMP SVDATA ;save result

*-------------------------------
* check a flag
*-------------------------------

DO_FLAG JSR CHKBYT
 CMP #"("
 BEQ :FLAG2 ;is there an arg?, yep

 BIT IMMDEF ;was it an assignment?
 BPL :FLAG1 ;nope

 JSR GOBEQU ;gobble equal's
 JSR INPNUM ;get location
 STX FLGPTR ;that's it!
 STA FLGPTR+1
 RTS

:FLAG1 LDX FLGPTR ;get current pointer
 LDA FLGPTR+1
 JMP DO_MATH ;and return

:FLAG2 BIT IMMDEF ;check exec status
 PHP ;and save it

 JSR INPNARG ;get arg
 TXA
 AND #%00000111 ;save bit number
 TAX
 LDA BITVAL,X
 STA TEMP2 ;convert to bit value
 LUP 3 ;shift down 3 bits
 LSR NUMB+1
 ROR NUMB
 --^
 CLC
 LDA NUMB
 ADC FLGPTR
 STA TEMP ;add in start
 LDA NUMB+1
 ADC FLGPTR+1
 STA TEMP+1

 PLP
 BMI :FLAG4 ;yep

 LDY #0
 LDA (TEMP),Y ;get byte
 AND TEMP2 ;and value
 BEQ :FLAG3

 LDA #1 ;return flag setting
:FLAG3 JMP SVDATA

:FLAG4 JSR GOBEQU ;gobble equal's
 JSR INPNUM
 LDY #0
 LDA NUMB ;check for zero
 ORA NUMB+1
 BNE :FLAG5 ;non-zero

 LDA TEMP2 ;get bit
 EOR #$FF ;make into mask
 AND (TEMP),Y ;kill bit
 STA (TEMP),Y ;save
 RTS

:FLAG5 LDA TEMP2 ;get bit
 ORA (TEMP),Y ;add in
 STA (TEMP),Y ;save
 RTS

BITVAL HEX 0102040810204080

FLGPTR DA 0

*-------------------------------
* get value of a nibble
*-------------------------------

DO_NIB JSR CHKBYT ;do they want to check data?
 CMP #"("
 BEQ :NIB2 ;yep

 BIT IMMDEF ;get address
 BPL :NIB1

 JSR GOBEQU ;gobble
 JSR INPNUM
 STX NIBPTR ;save pointer
 STA NIBPTR+1
 RTS

:NIB1 LDX NIBPTR ;get point to nibble
 LDA NIBPTR+1
 JMP DO_MATH

:NIB2 BIT IMMDEF ;is this an assignment?
 PHP
 JSR INPNARG ;get arg
 PLP
 BMI :NIB4 ;yep

 TXA
 LSR ;divide by 2
 TAY
 LDA (NIBPTR),Y ;get byte

 BCS :NIB3 ;nope

 LUP 4
 LSR
 --^
:NIB3 AND #$F ;get rid of any extra
 JMP SVDATA

:NIB4 TXA
 PHA

 JSR GOBEQU ;gobble
 JSR INPNUM

 PLA ;get back offset
 LSR ;divide
 TAY ;save

 PHP
 TXA ;get data
 CMP #16
 BLT :NIB4A ;in range?, yep

 LDA #15 ;set to max
:NIB4A STA TEMP ;save
 LUP 4
 ASL
 --^
 STA TEMP+1 ;save x 16

 PLP
 BCS :NIB5 ;do appropriate save

 LDA (NIBPTR),Y ;get orig byte
 AND #$F ;kill old stuff
 ORA TEMP+1 ;insert new
 STA (NIBPTR),Y ;save
 RTS

:NIB5 LDA (NIBPTR),Y ;get orig byte
 AND #$F0 ;kill old
 ORA TEMP ;insert new
 STA (NIBPTR),Y ;save
 RTS

*-------------------------------
* get value of a byte (like peek)
*-------------------------------

DO_BYT JSR CHKBYT ;set the pointer?
 CMP #"("
 BEQ :BYT2 ;nope

 BIT IMMDEF ;do they want to know what it is?
 BPL :BYT1 ;yep

 JSR GOBEQU ;gobble
 JSR INPNUM
 STX BYTPTR ;save new pointer
 STA BYTPTR+1
 RTS

:BYT1 LDX BYTPTR ;return current pointer
 LDA BYTPTR+1
 JMP DO_MATH

:BYT2 BIT IMMDEF ;is this an assignment?
 PHP
 JSR INPNARG ;get arg
 PLP
 BMI :BYT3 ;yep -- ^^^^

 LDY NUMB ;get index
 LDA (BYTPTR),Y ;get data
 JMP SVDATA

:BYT3 TXA
 PHA ;save arg
 JSR GOBEQU ;gobble
 JSR INPNUM ;get value
 CMP #0
 BEQ :BYT3A ;in range?, yep

 LDX #255 ;use max

:BYT3A PLA
 TAY ;restore offset

 TXA
 STA (BYTPTR),Y ;save value
 RTS
