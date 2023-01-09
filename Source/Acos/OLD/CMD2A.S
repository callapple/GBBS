 PAG
********************************
*                              *
*     ACOS.OBJ - Commands2     *
*                              *
********************************
 DATE
*-------------------------------
* check for keypress
*-------------------------------

DO_KEY JSR CHKDCD ;make key check for carrier
 LDA #0
 JSR COUT ;poll modem/keyboard

 JSR INPNARG ;gobble argument
 CPX #1
 BEQ :DO_KEY3 ;check for 'stop' char?
 CPX #2
 BEQ :DO_KEY4 ;check for 'next' char?
 CPX #3
 BEQ :DO_KEY1 ;check for any int taking place

 JSR GETCHR ;check buffer

:DO_KEY2 AND #clrhi
 JMP SVDATA

:DO_KEY3 LDX STPCHR ;check stop char
 BNE :DO_KEY5 ;-- always branch

:DO_KEY4 LDX NXTCHR ;check next char
:DO_KEY5 LDA #0
 CPX INTCHR
 BNE :DO_KEY2 ;did they hit it?, nope

 LDA #1 ;yep
 BNE :DO_KEY2 ;-- always branch

:DO_KEY1 LDA INTOUT ;has output been interupted?
 JMP SVDATA

*-------------------------------
* get width from index
*-------------------------------

DO_WID JSR INPNARG ;get arg
 CPX #5
 BGE WOK ;in range?, nope

 LDA WIDTH,X ;get width
 JMP SVDATA

WOK LDX #syntax ;syntax error
GO_ERR JMP BADERR

*-------------------------------
* handle for-next statement
*-------------------------------

DO_FOR LDA FORLVL
 LDX #forfull
 CMP #16
 BEQ GO_ERR ;for stack full error

 LDY #2 ;save variable name on stk
 LDA (PRGPTR),Y ;since DO_LET could return
 PHA  ;a possible second variable
 DEY  ;name
 LDA (PRGPTR),Y
 PHA
 JSR DO_LET ;do assign

 LDX FORLVL ;get level
 PLA  ;save var pointer
 STA FORVAR,X
 PLA
 STA FORVAR+1,X

 LDX #to ;gobble "TO" statement
 JSR GOBBLE

 JSR INPNUM
 LDY FORLVL ;get level
 STA FOREND+1,Y
 TXA
 STA FOREND,Y ;save end value

 LDA #<1
 STA FORSTP,Y ;save default step count (1)
 LDA #>1
 STA FORSTP+1,Y

 JSR CHKBYT ;did they specify a step?
 CMP #step
 BNE :DO_FOR1 ;nope

 JSR GETBYT ;gobble "step"
 JSR INPNUM ;get step
 LDY FORLVL
 STA FORSTP+1,Y ;save desired step
 TXA
 STA FORSTP,Y

 ORA FORSTP+1,Y ;did they try step 0?
 BEQ WOK ;the dolt! error out

:DO_FOR1 LDX FORLVL ;save address of 'FOR' section
 LDA PRGPTR
 STA FORLOC,X
 LDA PRGPTR+1
 STA FORLOC+1,X

 INC FORLVL ;inc level
 INC FORLVL
 RTS

*-------------------------------
* handle "next" part of for-next loop
*-------------------------------

DO_NXT LDX FORLVL ;check for next without for
 BEQ :DO_NXT6

 JSR CHKBYT ;check for specified variable
 CMP #number
 BNE :DO_NXT2 ;none, use next on stack

 JSR VARSET ;get variable
 LDX FORLVL ;find variable in stack
:DO_NXT1 DEX  ;back down 1 level
 DEX
 BMI :DO_NXT6

 LDA FORVAR,X
 CMP VNAME
 BNE :DO_NXT1

 LDA FORVAR+1,X
 CMP VNAME+1
 BNE :DO_NXT1

 INX  ;set the pointer into stack
 INX
 STX FORLVL
 BNE :DO_NXT3

:DO_NXT2 DEX  ;get next variable in stack
 DEX
 LDA FORVAR,X
 STA VNAME
 LDA FORVAR+1,X
 STA VNAME+1
 JSR VARSET3 ;find variable in memory
:DO_NXT3 LDX FORLVL ;back down to it
 DEX
 DEX
 LDA VPTR
 STA TEMP ;restore var pointer
 LDA VPTR+1
 STA TEMP+1

 LDY #1
 LDA FORSTP+1,X ;doing negative step?
 BMI :DO_NXT7 ;yes, do it

 LDA (TEMP),Y ;check high - are we done?
 CMP FOREND+1,X
 BLT :DO_NXT9 ;no, loop
 BEQ :DO_NXT4 ;hmmm, check low byte
 BGE :DO_NXT5 ;yes, we are done

:DO_NXT4 DEY  ;check low - are we done?
 LDA (TEMP),Y
 CMP FOREND,X
 BLT :DO_NXT9 ;no, loop

:DO_NXT5 DEC FORLVL ;conclude loop
 DEC FORLVL
:DO_NXT6 RTS

:DO_NXT7 LDA (TEMP),Y
 CMP FOREND+1,X ;check high - are we done?
 BEQ :DO_NXT8 ;maybe, check mid byte
 BLT :DO_NXT5 ;yes, finish up
 BGE :DO_NXT9 ;nope, loop

:DO_NXT8 DEY  ;Are we done with low byte?
 LDA (TEMP),Y
 CMP FOREND,X
 BEQ :DO_NXT5 ;yes, finish up
 BLT :DO_NXT5 ;if less, we are done

:DO_NXT9 LDA FORLOC,X
 STA PRGPTR ;point to "for" location
 LDA FORLOC+1,X
 STA PRGPTR+1
 CLC  ;add in step value
 LDY #0
 LDA FORSTP,X
 ADC (TEMP),Y
 STA (TEMP),Y ;do low
 INY
 LDA FORSTP+1,X
 ADC (TEMP),Y
 STA (TEMP),Y ;do high
 RTS

*-------------------------------
* move memory
*-------------------------------

DO_MOVE JSR INPNUM ;get source address
 STX TEMP2
 STA TEMP2+1

 JSR GOBCOM ;gobble comma
 JSR INPNUM ;get # of bytes to move
 TXA
 PHA

 LDX #to
 JSR GOBBLE ;gobble 'TO' statement

 JSR INPNUM ;get destination address
 STX TEMP
 STA TEMP+1

 PLA
 TAX  ;get back # of bytes to move

 LDY #0
:MOVE2 LDA (TEMP2),Y
 STA (TEMP),Y ;copy byte
 INY
 DEX
 BNE :MOVE2 ;count down, were done!
 RTS

*-------------------------------
* get location of scratch ram
*-------------------------------

DO_RAM LDX #<SCRATCH
 LDA #>SCRATCH
 JMP DO_MATH

*-------------------------------
* get location of aux scratch ram
*-------------------------------

DO_RAM2 LDX #<SCRATCH+64
 LDA #>SCRATCH+64
 JMP DO_MATH

*-------------------------------
* generate a random character
*-------------------------------

DO_RNDS LDA RND
 AND #$1F ;make in range [0-31]
 CMP #'Z'-ctrl
 BLT :DO_RND2 ;in range

 SBC #10 ;put into range
:DO_RND2 LDY #0
 ADC #'A'
 STA (VARSTR),Y ;save character
 LDA RND+1
 EOR #$B4
 ADC RND
 STA RND ;re-seed for next pass
 ROL
 ROL
 ROL
 STA RND+1

 LDX VARSTR ;point to random char
 LDA VARSTR+1
 INY

 INC VARSTR
 BNE :DO_RND3
 INC VARSTR+1
:DO_RND3 JMP SVSTR ;save location of char

*-------------------------------
* get a random number
*-------------------------------

DO_RND JSR INPNARG ;get range
 STX TEMP ;save range
 STA TEMP+1
 TAY  ;is it below 256?
 BEQ :DO_RN0 ;yep, just get 8 bit seed
 LDA RND+1
:DO_RN0 LDX RND ;get seed

:DO_RN2 CMP TEMP+1
 BEQ :DO_RN4 ;check low
 BGE :DO_RN5 ;kill number
:DO_RN3 JMP DO_MATH ;return number

:DO_RN4 CPX TEMP
 BEQ :DO_RN3 ;check low byte
 BLT :DO_RN3 ;all is well, return

:DO_RN5 PHA
 SEC
 TXA
 SBC TEMP ;(AX) = (AX) - range
 TAX
 PLA
 SBC TEMP+1
 BCS :DO_RN2 ;loop and check

*-------------------------------
* fill a range of memory
*-------------------------------

DO_FILL JSR INPNUM
 STX TEMP ;point to fill location
 STA TEMP+1
 JSR GOBCOM ;gobble

 JSR INPNUM ;get number of bytes to fill
 STX TEMP2
 JSR GOBCOM ;gobble

 JSR INPNUM ;get byte to fill with
 TXA

 LDY #0
:FILL2 STA (TEMP),Y ;fill
 INY
 DEC TEMP2
 BNE :FILL2 ;repeat
 RTS

*-------------------------------
* setup no carrier vector
*-------------------------------

DO_NOCD LDA #0
 STA NOCDFLG ;reset carrier vector
 JSR GETBYT ;see if it has a vector
 CMP #goto
 BNE :DO_NOC2 ;was it goto?

 JSR GETBYT ;get low byte of routine
 STA NOCDVEC
 JSR GETBYT ;get high byte of routine
 STA NOCDVEC+1
 DEC NOCDFLG
:DO_NOC2 RTS

*-------------------------------
* return error numer
*-------------------------------

DO_ERRNO LDA ERRNO
 JMP SVDATA

*-------------------------------
* setup error vector
*-------------------------------

DO_ONERR LDA #0
 STA ONERRFLG ;reset onerr vector
 JSR GETBYT ;see if it has a vector
 CMP #goto
 BNE :DO_ERR2 ;was it goto?

 JSR GETBYT ;get low byte of routine
 STA ONERRVEC
 JSR GETBYT ;get high byte of routine
 STA ONERRVEC+1
 DEC ONERRFLG
:DO_ERR2 RTS

*-------------------------------
* resume command
*-------------------------------

DO_RESUM LDA FROMERR ;was there an error?
 ORA FROMERR+1
 BEQ :NOERR ;no error occurred

 LDA FROMERR ;replace error location
 STA PRGPTR
 LDA FROMERR+1
 STA PRGPTR+1

 JSR CHKBYT ;get the byte there
 JMP :TSTIT

]LOOP JSR GETBYT ;get next byte
:TSTIT CMP #chain2 ;end of line?
 BEQ :DONE ;yes, continue with pgm
 CMP #goto ;a goto?
 BEQ :DO_LBL
 CMP #gosub ;a gosub?
 BEQ :DO_LBL
 CMP #push ;a push?
 BNE ]LOOP ;nope, next byte
:DO_LBL JSR GETRAW ;skip label address
 JSR GETRAW
 JMP ]LOOP

:DONE RTS

:NOERR LDA #0 ;don't trap this one
 STA ONERRFLG
 LDX #$19 ;no error message
 JMP BADERR

*-------------------------------
* get general system to program
*-------------------------------

DO_INFO JSR INPNARG ;get arg number
 CPX #7
 BGE :DO_INF2

 TXA
 ASL  ;a = a * 2
 TAX

 LDA INFOJMP,X
 STA TEMP ;execute routine
 LDA INFOJMP+1,X
 STA TEMP+1
 BIT IMMDEF
 JMP (TEMP)

:DO_INF2 LDX #syntax ;syntax error
 JMP BADERR

INFOJMP DW INF0 ;get remote flag
 DW INF1 ;msg board capacity
 DW INF2 ;get users baud rate
 DW INF3 ;get/set nulls
 DW INF4 ;display chat mode
 DW INF5 ;get/set exec flags
 DW INF6 ;number of blocks free

*-------------------------------
* return online status
*-------------------------------

INF0 LDA REMOTE ;pass remote flag
 JMP SVDATA

INF1 LDA #0
 STA TEMP ;zero temp
 LDA MSGINFO+1 ;multiple by 32
 LUP 5
 ASL A
 ROL TEMP
 --^
 TAX
 LDA TEMP
 JMP DO_MATH ;return # of entries

*-------------------------------
* return users baud rate
*-------------------------------

INF2 LDA SPCINIT ;get caller speed
 JMP SVDATA

*-------------------------------
* read, or set nulls
*-------------------------------

INF3 BMI :INF3_0 ;do set, not read
 LDA NULLS ;return current null setting
 JMP SVDATA

:INF3_0 JSR GOBEQU ;set new null value
 JSR INPNUM
 STX NULLS
 RTS

INF4 JSR GOBEQU ;set chat mode
 JSR INPNUM
 TXA
 JMP VIDCHAT ;carry through

*-------------------------------
* read or set EXEC mode
*-------------------------------

INF5 BMI :EXEC1 ;opps, do set, not read
 LDA EXEC
 JMP SVDATA ;return current exec mode

:EXEC1 JSR GOBEQU
 LDA #%10111111
 STA EXEC ;set exec flag
 JSR INPNUM ;set new exec mode
 CPX #0
 BNE :EXEC2 ;it is already set

 STX EXEC ;set exec to 0
:EXEC2 RTS

INF6 LDA MSGINFO
 ASL
 ASL
 STA TEMP ;save total # of bit blocks

 SEC  ;new code for fixing the bug found
 LDA TEMP ;by someone in a document named
 SBC MSGINFO+2 ;sodapatches
 TAX
 LDA TEMP
 SBC MSGINFO+3

 AND #clrhi ;kill high bit
 JMP DO_MATH ;return results

*-------------------------------
* get date from 2 byte binary
*-------------------------------

DO_WHEN BCC :DO_WH2 ;get data

 JSR GOBEQU ;gobble equal's
 JSR ARGTYP ;find out data type
 BCS :DO_WH1

 JSR INPNUM ;get location
 STX WHNPTR ;and save
 STA WHNPTR+1
 RTS

:DO_WH1 JSR INPSTR ;gobble
 JSR GETDATE ;get date

 LDY #0
 PHA
 TXA
 STA (WHNPTR),Y ;save compacted date
 INY
 PLA
 STA (WHNPTR),Y
 RTS

:DO_WH2 LDY #0
 LDA (WHNPTR),Y ;get compressed date
 TAX
 INY
 LDA (WHNPTR),Y
 JMP DO_DT2 ;translate

*-------------------------------
* get date
*-------------------------------

DO_DATE BCC :DO_DT1 ;get the date

 JSR GOBEQU ;gobble equ
 JSR INSTR2 ;get string w/o using memory
 LDX STRLOC
 LDA STRLOC+1
 LDY STRLEN
 JMP SETDATE ;set the date

:DO_DT1 JSR GETDATE
DO_DT2 STA TEMP ;save date data
 STX TEMP+1 ;date format: YYYYYYYMMMMDDDDD

 LDA TEMP+1
 AND #$1F
 JSR BINDEC8 ;save day
 STA DATESTR+3
 STX DATESTR+4

 LDA TEMP+1 ;get most of month
 LSR TEMP ;shift last bit into carry
 ROR  ;move bit in
 LUP 4
 LSR
 --^
 JSR BINDEC8
 STA DATESTR ;save month
 STX DATESTR+1

 LDA TEMP ;get year
 JSR BINDEC8 ;make ascii
 STA DATESTR+6
 STX DATESTR+7

 LDX #<DATESTR ;point to string
 LDA #>DATESTR
 LDY #8
SVSTR STX DATA+1
 STA DATA+2
 STY DATA+3
 LDA #2
 STA DATA
 RTS

DATESTR ASC '06/20/85'

*-------------------------------
* get time
*-------------------------------

DO_TIME JSR GETTIME ;read clock
 LDY #11
 BNE SVSTR ;return string

DO_FDATE LDX #0
 STX DATEPTR ;zero date text pointer

 JSR GETDATE ;get date in ProDOS format
 STA TEMP ;save year * 2
 TXA
 PHA
 AND #$1F
 STA TEMP2 ;save day of month
 PLA
 LSR TEMP ;divide year by 2
 ROR  ;move high bit of month into A
 AND #$F0
 LUP 4
 LSR
 --^
 STA TEMP2+1 ;save extracted month
 TAX
 LDA MTH_CNST-1,X
 STA TEMP3 ;get month constant

 LDX TEMP ;get year
 TXA
 SEC
 SBC #85 ;subtract 85 from year
 LSR  ;multiply by 2
 LSR

 CLC
 ADC TEMP ;add in year again
 SBC #83 ;subtracrt 83
 JSR WEEK_MOD ;a = a mod 7

 TAY  ;save in Y
 TXA  ;put year in A
 LDX #0
 AND #3 ;leap year?
 BEQ :FDATE1
 DEX
:FDATE1 STX TEMP+1 ;save leap year flag

 TYA  ;get interm day of week back
 CLC
 ADC TEMP3 ;add in month constant
 ADC TEMP2 ;add in day of month

 LDY TEMP2+1 ;get month number
 CPY #3
 BLT :FDATE2
 ADC TEMP+1 ;add in leap year flag
:FDATE2 JSR WEEK_MOD ;a = a mod 7

 TAX  ;move day to X
 LDY DAYINDEX,X ;get index to day text
 LDX #4 ;4 characters
:FDATE3 LDA DAYS,Y ;move the text
 DEX
 BEQ :FDATE4
 JSR PUTA
 INY
 BNE :FDATE3

:FDATE4 LDA #'.' ;insert ". "
 LDX #' '
 JSR PUTAX

 LDA TEMP2+1 ;get the month number
 TAX
 LDY MTHINDEX-1,X ;get index into month text
 LDX #4
:FDATE5 LDA MONTHS,Y ;move month text to string
 DEX
 BEQ :FDATE6
 JSR PUTA
 INY
 BNE :FDATE5

:FDATE6 LDA #' ' ;put in a space
 JSR PUTA

 LDA TEMP2 ;get day of month number
 JSR BINDEC8 ;make it text
 CMP #'0'
 BNE :FDATE7 ;change leading 0 to space
 LDA #' '
:FDATE7 JSR PUTAX ;save day of month

 LDA #',' ;add in a ", "
 LDX #' '
 JSR PUTAX

 LDA #'1' ;put in the leading 19
 LDX #'9'
 JSR PUTAX

 LDA TEMP ;get year - 1900
 JSR BINDEC8 ;convert to text
 JSR PUTAX ;save it

 LDX #<FMTDATE ;point to string
 LDA #>FMTDATE
 LDY DATEPTR ;get the length
 JMP SVSTR ;put it to program

PUTAX JSR PUTA ;put the text in A
 TXA  ;move X to A
PUTA STX X_DATE ;save X
 LDX DATEPTR ;get text pointer
 STA FMTDATE,X ;store the character
 INC DATEPTR ;bump the length pointer
 LDX X_DATE ;get back X
 RTS

X_DATE DB 0

WEEK_MOD SEC  ;subtract 7 till < 0
:MOD SBC #7
 BCS :MOD
 ADC #7 ;add back in 7 for MOD
 RTS

MTH_CNST DB 0,3,3,6,1,4,6,2,5,0,3,5

DATEPTR DB 0

FMTDATE ASC 'Fri. Jan 13, 1989'

*-------------------------------
* do time computations
*-------------------------------

DO_CLOK JSR INPNARG ;get function number
 CPX #3
 BGE CLKRTN

 TXA
 ASL  ;x = x * 2
 TAX

 LDA CLKJMP,X
 STA TEMP ;setup address for jump
 LDA CLKJMP+1,X
 STA TEMP+1
 JMP (TEMP)

CLKJMP DA CLK0
 DA CLK1
 DA CLK2

*-------------------------------
* reset timer
*-------------------------------

CLK0 JSR CONVSEC ;get base in seconds
 STX CLKBASE
 STA CLKBASE+1
CLKRTN RTS

*-------------------------------
* get connect time in seconds
*-------------------------------

CLK1 JSR SECON
CLK1A JMP DO_MATH ;save time

*-------------------------------
* get time limit
*-------------------------------

CLK2 LDX TIMEON
 LDA TIMEON+1
 BIT IMMDEF ;check exec status
 BPL CLK1A

 JSR GOBEQU ;gobble
 JSR INPNUM ;get time limit
 STX TIMEON ;save time limit
 STA TIMEON+1
 RTS

*-------------------------------
* find time on in seconds
*-------------------------------

SECON JSR CONVSEC ;get current time in seconds
 SEC
 PHA
 TXA
 SBC CLKBASE ;time on = current - base
 TAX
 PLA
 SBC CLKBASE+1
 BCS :SECON1

 PHA
 TXA
 ADC #<ROLTIME ;time past midnight
 TAX  ;add in rolover
 PLA
 ADC #>ROLTIME
:SECON1 RTS

ROLTIME = 43200 ;# seconds in 12 hours

CONVSEC JSR GETTIME
 STX TEMP3 ;point to time string
 STA TEMP3+1

 LDA #60
 STA DATA+1 ;set up multiplier
 LDA #0
 STA DATA+2
 STA DATA+3

 JSR ZNUMIN ;get hour
 TXA
 BNE :CONVSC2 ;not 0 hours

 LDA #24 ;make 0 hundred into 24 hundred

:CONVSC2 CMP #13
 BLT :CONVSC3 ;is it out of range?, nope

 SBC #12 ;make into 1-12 range

:CONVSC3 TAX  ;save result
 LDA #0
 JSR SAVNUMB
 JSR DO_MUL0 ;multiply into minutes

 INC TEMP3
 JSR ZNUMIN ;get minute

 CLC
 TXA
 ADC RESULT ;add in minutes
 TAX
 LDA #0
 ADC RESULT+1
 JSR SAVNUMB

 LDA #60
 STA DATA+1 ;multiply by 60
 JSR DO_MUL0

 INC TEMP3 ;position to seconds
 JSR ZNUMIN

 CLC
 TXA
 ADC RESULT ;add in seconds
 TAX
 LDA #0
 ADC RESULT+1
 RTS

CHK4SN JSR KEYIN2 ;check for serial # access
 CMP #'?'
 BEQ :SHOWSN

 JMP :NOSHOW

:SHOWSN LDA #<SERNUM ;print serial #
 STA TEMP
 LDA #>SERNUM
 STA TEMP+1

 LDY #SEREND-SERNUM ;point to data to print
 DEY

]LOOP LDA (TEMP),Y
 EOR #SEREND-SERNUM
 ROR A
 JSR COUT
 DEY
 BPL ]LOOP

:NOSHOW RTS

*-------------------------------
* poke a value
*-------------------------------

DO_POKE JSR INPNUM ;get place to poke
 STX TEMP
 STA TEMP+1
 JSR GOBCOM ;gobble
 JSR INPNUM ;get value
 TXA
 LDY #0
 STA (TEMP),Y ;no offset
 RTS

*-------------------------------
* peek a location
*-------------------------------

DO_PEEK JSR INPNARG ;get arg
 STX TEMP
 STA TEMP+1
 LDY #0
 LDA (TEMP),Y ;get value
 JMP SVDATA ;return in

*-------------------------------
* produce a tone with apple speaker
*-------------------------------

DO_TONE LDA #$FF
 STA TEMP2+1 ;default to 1 tone

 JSR INPNARG ;get tone argument
 STX TEMP2

 JSR INPNARG ;get duration/tone2 argument
 STX TEMP+1 ;save as duration
 BCC :TONE2 ;last argument -- everything is correct

 JSR CHKBYT ;check for last argument
 CMP #","
 BNE :TONE6 ;do normal single tone

 STX TEMP2+1 ;save second tone
 JSR INPNARG ;get real duration
 STX TEMP+1 ;save duration

:TONE2 LSR TEMP+1 ;correct timing to match old routine
 LDA TEMP2+1
 STA TEMP3+1 ;reset second tone

:TONE3 LDA TEMP2
 STA TEMP3 ;reset first tone
 LDA SPKR ;click speaker

:TONE4 DEX
 BNE :TONE5 ;time down
 DEC TEMP+1
 BMI :TONE8 ;done with tone

:TONE5 PHA
 PLA
 DEC TEMP3
 BEQ :TONE3 ;count down first tone

 PHA
 PLA  ;count down second tone
 DEC TEMP3+1
 BNE :TONE4 ;nope, do main loop

 LDA TEMP2+1
 STA TEMP3+1 ;reset second tone
 LDA SPKR ;click speaker
 JMP :TONE4 ;go main loop

:TONE6 DEX
 BNE :TONE7

 LDX TEMP2
 LDA SPKR ;modified from "keeper" code
:TONE7 DEY
 BNE :TONE6

 DEC TEMP+1
 BNE :TONE6
:TONE8 RTS

DO_TEXT LDA #0
 STA WNDTOP ;set to full screen
DO_HOME JMP VIDCLS ;clear the local screen

*-------------------------------
* read status of a paddle
*-------------------------------

DO_PDL JSR INPNARG ;get paddle number
 LDA PTRIG ;toggle paddle trigger
 LDY #0
 NOP  ;give delay so we dont
 NOP  ;get a false read
:DO_PDL2 LDA PDLS,X ;check paddle flag
 BPL :DO_PDL3 ;we are done
 INY
 BNE :DO_PDL2 ;keep counting
 DEY  ;change 0 to 255
:DO_PDL3 TYA
 JMP SVDATA ;return value

*-------------------------------
* get ascii value of a string
*-------------------------------

DO_ASC JSR INPSARG ;read string
 LDA #-1
 LDX STRLEN ;any string there?
 BEQ :DO_ASC2 ;nope, return value of 255

 LDY #0
 LDA (STRLOC),Y
:DO_ASC2 JMP SVDATA ;return byte

*-------------------------------
* call a machine-language rotine
*-------------------------------

DO_CALL JSR INPNUM ;get address
 STX TEMP
 STA TEMP+1
 JMP (TEMP) ;transfer control

;lock out other computer writing
DO_LOCK pha  ; save a reg
 txa
 pha  ; save x reg
 tya
 pha
lock1 lda MLBUS
 asl a ; shift status to carry
 bcs lock2
 ldy #1 ; get node #
lock1a ldx $ff ; set up loop
lock1b dex
 bne lock1b ; count down inner loop
 dey
 beq lock1 ;done yet? Yes, check again
 bne lock1a ;No
lock2 sta ANU_OFF
 lda #$0c
 sta $427
 pla
 tay
 pla
 tax
 pla
 rts

;enable other computer writing
DO_UNLK sta ANU_ON
 pha
 lda #$15
 sta $427
 pla
 rts


