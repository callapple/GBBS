 PAG
********************************
*                              *
*     ACOS.OBJ - Variables     *
*                              *
********************************
 DATE
*-------------------------------
* set up pointers to variables
*-------------------------------

VARSET JSR GETBYT ;get string or number indicator
 PHA
 JSR GETBYT ;get name
 STA VNAME
 JSR GETBYT
 STA VNAME+1
 PLA
 CMP #number
 BEQ VARSET3 ;handle number

 CMP #string
 BEQ :VARSET2 ;handle string

 LDX #syntax
 JMP BADERR ;syntax error!

:VARSET2 LDA VNAME ;show it's a string
 ORA #hibit
 STA VNAME ;point to start of pointers
VARSET3 LDA HIMEM
 STA TEMP
 LDA HIMEM+1
 STA TEMP+1
:VARSET5 SEC ;temp = temp - 6
 LDA TEMP
 SBC #6
 STA TEMP
 LDA TEMP+1
 SBC #0
 STA TEMP+1

 LDY #0
 LDA (TEMP),Y ;check low byte
 BEQ :VARSET8 ;create new var

 CMP VNAME
 BNE :VARSET5 ;no match

 INY
 LDA (TEMP),Y ;check high byte
 CMP VNAME+1
 BNE :VARSET5 ;no match

:VARSET7 CLC ;vptr = temp + 2
 LDA #2
 ADC TEMP
 STA VPTR
 TAX ;return with A & X pointing at var
 LDA #0
 ADC TEMP+1
 STA VPTR+1
 RTS

:VARSET8 SEC
 LDA TEMP+1
 SBC LOMEM+1 ;find total string space
 LSR
 CLC
 ADC LOMEM+1 ;find boundary
 STA MIDMEM+1 ;save high byte
 LDA #0 ;save low byte
 STA MIDMEM

 DEC TEMP+1
 LDY #$F9 ;do next entry also
 LDX #10 ;fill rest with 0's
 LDA #0
:VARSET9 INY
 BNE :VARSETA
 INC TEMP+1
:VARSETA STA (TEMP),Y
 DEX
 BNE :VARSET9

 LDY #0
 LDA VNAME
 STA (TEMP),Y ;save the var name
 INY
 LDA VNAME+1
 STA (TEMP),Y
 JMP :VARSET7 ;set up pointers

*-------------------------------
* input a number or expression
*-------------------------------

INPNUM LDA TEMP ;save temp var's
 PHA
 LDA TEMP+1
 PHA
 LDA TEMP2
 PHA
 LDA TEMP2+1
 PHA

 JSR INPNUM0 ;get initial number
:INPNUM3 JSR CHKBYT
 BMI :INPNM3A

 CMP #compare
 BGE :INPNUM5 ;don't do compare operands

:INPNM3A PLA
 STA TEMP2+1 ;restore stuff
 PLA
 STA TEMP2
 PLA
 STA TEMP+1
 PLA
 STA TEMP
 JMP GETNUMB

:INPNUM5 JSR INPNUM2 ;exec token
 JMP :INPNUM3

*-------------------------------
* input a number of expression for math operations
*-------------------------------

INPMATH JSR INPNUM0 ;get initial number
INPMTH1 JSR CHKBYT
 BMI GETNUMB

 CMP #math
 BLT GETNUMB ;check for math operand, we're done

 JSR INPNUM2
 JMP INPMTH1

*-------------------------------
* input a paren
*-------------------------------

INPPAR JSR GETBYT ;get the byte
 JSR INPNUM
 JSR SAVNUMB ;save number

 JSR GETBYT
 CMP #")"
 BEQ INPPAR2 ;was close there?, yep

 LDX #syntax ;syntax error
 JMP BADERR

*-------------------------------
* finish up here
*-------------------------------

GETNUMB LDX NUMB
 LDA NUMB+1
INPPAR2 RTS

SAVNUMB STX NUMB
 STA NUMB+1
 RTS

*-------------------------------
* input a number
*-------------------------------

INPNUM0 LDA #0 ;init number
 TAX
 JSR SAVNUMB
 JSR CHKBYT ;get next token
 CMP #chain
 BEQ :INPNM0A ;missing data
 CMP #chain2
 BEQ :INPNM0A

 CMP #number
 BEQ :INPNM0 ;check if var
 CMP #string
 BEQ :INPNM1
 CMP #"""
 BEQ :INPNM1

 CMP #"("
 BEQ INPPAR ;if an expression

 CMP #strtyp
 BLT INPNUM2 ;check if other token
 CMP #compare
 BLT :INPNM1 ;is it a string?
 CMP #0
 BPL INPNUM2 ;is it a token?

 JSR TST_NUM
 BCC :INPNUM1

 LDX #syntax ;syntax error
 JMP BADERR

:INPNM0 JSR VARSET

 LDY #0 ;get value of variable in X,A
 LDA (VPTR),Y
 TAX
 INY
 LDA (VPTR),Y
 JMP SAVNUMB ;save it

:INPNM1 JSR STRCMP ;get value of expression
 LDA #0 ;save the number
 JMP SAVNUMB

:INPNM0A LDX #nodata ;missing data
 JMP BADERR

:INPNUM1 JSR NUMIN
 JSR SAVNUMB ;save number
 CMP #0
 BPL GETNUMB
 LDX #nosymbol
 JMP BADERR

INPNUM2 LDA #0
 STA DATA ;reset data
 JSR GETBYT
 CLC ;call from somewhere else
 JSR EX_TOK ;exec the token
 LDA DATA
 AND #1 ;did we get valid data?
 BNE INPNM2 ;yep

INPNM3 LDX #badtype ;type mismatch error
 JMP BADERR

INPNM2 LDX DATA+1 ;transfer data
 LDA DATA+2
 JMP SAVNUMB

*-------------------------------
* input a numeric argument
*-------------------------------

INPNARG JSR INPARG ;do input
 AND #1
 BNE INPNM3 ;if string, error
 JMP GETNUMB ;return values

*-------------------------------
* input a string argument
*-------------------------------

INPSARG JSR INPARG ;do input
 AND #1
 BEQ INPNM3 ;if number, error
 RTS

*-------------------------------
* input a argument
*-------------------------------

INPARG JSR GETBYT ;get data
 CMP #"("
 BEQ :INPARG2 ;check for start or continuation
 CMP #","
 BEQ :INPARG2 ;of an argument

:INPARG1 LDX #nodata ;missing data
 JMP BADERR

:INPARG2 JSR ARGTYP ;find out type (number or string)
 PHP
 BCS :INPARG3

 JSR INPNUM
 JMP :INPARG4

:INPARG3 JSR INPSTR
:INPARG4 JSR CHKBYT ;check next byte
 LDX #1
 CMP #","
 BEQ :INPARG5 ;is there more?, yep

 JSR GETBYT ;get the rest
 LDX #0
 CMP #")"
 BNE :INPARG1 ;of arg, nope, error

:INPARG5 TXA ;bit 0 : clear = number  set = string
 PLP ;bit 1 : clear = done    set = more args
 ROL
 CMP #0
 RTS

*-------------------------------
* find out type of data/token
*-------------------------------

ARGTYP JSR CHKBYT
 CMP #"""
 BEQ :ARGTYP1 ;if it's text

 CMP #"("
 BEQ :ARGTYP2 ;if it's an expression

 CMP #0
 BMI :ARGTYP2 ;if it's other than text

 CMP #string
 BEQ :ARGTYP1 ;if it's a string var

 CMP #strtyp
 BLT :ARGTYP2 ;if it's a string, set the carry

 CMP #compare
 BGE :ARGTYP2 ;make sure it's in range

:ARGTYP1 SEC ;it's a string
 RTS

:ARGTYP2 CLC ;it's a number
 RTS

*-------------------------------
* input a string without allocating memory
*-------------------------------

INSTR2 LDA VARSTR
 PHA
 LDA VARSTR+1
 PHA
 JSR INPSTR
 PLA
 STA VARSTR+1
 PLA
 STA VARSTR
 RTS

*-------------------------------
* input a string
*-------------------------------

INPSTR JSR INPSTR0
 STA STRLOC+1 ;save length and location
 STX STRLOC
 STY STRLEN

 JSR CHKBYT
 CMP #math
 BNE GTSTRINF ;a quick exit point

 LDA VARSTR+1 ;save the new pointer
 PHA
 LDA VARSTR
 PHA
 TYA
 PHA

 JSR GETBYT ;save start of working string space
 JSR STRCOPY

:INPSTRB LDA VARSTR+1 ;save current pointer
 PHA
 LDA VARSTR
 PHA

 JSR INPSTR0 ;get new string
 STA STRLOC+1 ;save length and location
 STX STRLOC
 STY STRLEN

 PLA
 STA VARSTR ;restore var pointers
 PLA
 STA VARSTR+1
 PLA
 STA TTLLEN ;update length
 JSR STRCOPY ;copy the new string
 LDA TTLLEN
 PHA

 JSR CHKBYT
 CMP #math
 BNE :INPSTRC ;if there more, do it

 JSR GETBYT ;gobble and continue
 JMP :INPSTRB

:INPSTRC PLA
 STA STRLEN ;put back data
 PLA
 STA STRLOC
 PLA
 STA STRLOC+1

GTSTRINF LDA STRLOC+1 ;get back stuff
 LDX STRLOC
 LDY STRLEN
 RTS

*-------------------------------
* actually get the string
*-------------------------------

INPSTR0 JSR CHKBYT
 CMP #"""
 BEQ :INPSTR1 ;if text

 CMP #string
 BNE :INPSTR5 ;handle token

 JSR VARSET ;point to var
 LDY #1
 LDA (VPTR),Y ;get the high-byte of pointer
 PHA
 DEY
 LDA (VPTR),Y ;get the low-byte of pointer
 TAX
 LDY #2
 LDA (VPTR),Y ;get the length
 TAY
 PLA
 RTS

:INPSTR1 JSR GETBYT ;and gobble first quote
 LDX PRGPTR ;save string location
 LDA PRGPTR+1
 PHA
 LDY #0
:INPSTR2 JSR GETBYT ;calc string length
 CMP #"""
 BEQ :INPSTR4 ;check for end

 INY
 BNE :INPSTR2

 PLA
 LDX #str2big ;string overflow
:INPSTR3 JMP BADERR

:INPSTR4 PLA ;a,x,y now have string data
 RTS

:INPSTR5 LDA #0
 STA DATA ;reset data type
 JSR GETBYT
 CLC ;called from somewhere else
 JSR EX_TOK ;exec token
 LDA DATA
 LDX #badtype
 AND #2
 BEQ :INPSTR3 ;string overflow

 LDX DATA+1 ;get data
 LDA DATA+2
 LDY DATA+3
 RTS

*-------------------------------
* copy a string from pointers to current varstr
*-------------------------------

STRCOPY LDY #0
:STRCOP2 CPY STRLEN
 BEQ :STRCOP3 ;go until done

 LDA (STRLOC),Y
 STA (VARSTR),Y ;copy byte
 INC TTLLEN ;increase total length
 BEQ :STR2BIG ;now it's too big
 INY
 BNE :STRCOP2

:STRCOP3 TYA ;add in bytes copied
 CLC
 ADC VARSTR
 STA VARSTR
 LDA #0
 ADC VARSTR+1
 STA VARSTR+1
 RTS

:STR2BIG LDX #str2big ;String too long
 JMP BADERR

*-------------------------------
* compare 2 strings
*-------------------------------

STRCMP LDA VARSTR ;don't gobble any space
 PHA
 LDA VARSTR+1
 PHA

 JSR INPSTR ;get string 1
 LDA STRLOC ;save pointers to data
 STA TEMP3
 LDA STRLOC+1
 STA TEMP3+1
 LDA STRLEN
 STA TEMP2 ;save length of data

 JSR CHKBYT
 CMP #compare
 BLT :STRCMP8 ;see if there is actually a compare

 CMP #logic
 BGE :STRCMP8

 JSR GETBYT ;gobble token
 SEC
 SBC #compare
 ASL
 PHA
 JSR INPSTR ;get second string
 PLA
 TAX

 LDA JSTRCP,X
 STA TEMP
 LDA JSTRCP+1,X
 STA TEMP+1
 JMP (TEMP)

:STRCMP8 LDX #0 ;if length = 0, not valid
 LDA TEMP2 ;if length > 0, return valid
 BEQ STRCMP9

 LDX #1
STRCMP9 PLA
 STA VARSTR+1 ;restore stuff
 PLA
 STA VARSTR
 LDA #0
 RTS

ST_EQ JSR STREQ
 JMP STRCMP9

ST_NOT JSR STREQ
 JSR INVERT
 JMP STRCMP9

ST_LT JSR STRLT
 JMP STRCMP9

ST_GT JSR STRGT
 JMP STRCMP9

ST_LTEQ JSR STRGT
 JSR INVERT
 JMP STRCMP9

ST_GTEQ JSR STRLT
 JSR INVERT
 JMP STRCMP9

*-------------------------------
* ----- compare algorithms -----
*-------------------------------

STREQ LDX TEMP2 ;check string length's
 CPX STRLEN
 BNE :STREQ0

 LDY #-1
:STREQ2 INY
 CPY STRLEN
 BEQ :STREQ1 ;are we done?, yep

 LDA (TEMP3),Y
 CMP (STRLOC),Y
 BEQ :STREQ2 ;do check, keep going

:STREQ0 LDX #0
 RTS

:STREQ1 LDX #1
 RTS

STRLT LDX TEMP2 ;save smaller length
 CPX STRLEN
 BGE :STRLT2

 LDX STRLEN
 STX TEMP2

:STRLT2 LDY #-1
:STRLT3 INY
 CPY TEMP2
 BEQ :STRLT0

 LDA (TEMP3),Y
 CMP (STRLOC),Y
 BEQ :STRLT3
 BLT :STRLT1
 BGE :STRLT0

 LDA TEMP2
 CMP STRLEN
 BCS :STRLT0

:STRLT1 LDX #1
 RTS

:STRLT0 LDX #0
 RTS

STRGT LDX STRLEN ;save smaller length
 CPX TEMP2
 BGE :STRGT2

 LDX TEMP2
 STX STRLEN

:STRGT2 LDY #-1
:STRGT3 INY
 CPY STRLEN
 BEQ :STRGT0

 LDA (STRLOC),Y
 CMP (TEMP3),Y
 BEQ :STRGT3
 BLT :STRGT1
 BGE :STRGT0

 LDA STRLEN
 CMP TEMP2
 BCS :STRGT0

:STRGT1 LDX #1
 RTS

:STRGT0 LDX #0
STRRTS RTS

*-------------------------------
* check and see if we need to clear up
*-------------------------------

CHKFRE LDX VARSTR+1 ;get high of current pointer
 INX
 CPX MIDMEM+1
 BLT STRRTS ;are we ok?, all is well

*-------------------------------
* clean up strings in memory
*-------------------------------

DO_FRE LDA HIMEM ;point to pointers
 STA TEMP
 LDA HIMEM+1
 STA TEMP+1

 LDA MIDMEM ;point to working space
 STA TEMP3
 LDA MIDMEM+1
 STA TEMP3+1

 SEC
 LDA MIDMEM
 SBC LOMEM
 STA TEMP2 ;compute offset
 LDA MIDMEM+1
 SBC LOMEM+1
 STA TEMP2+1

 LDA #1
 STA FREMEM ;move minimum of 1 page

:FRE2 SEC
 LDA TEMP
 SBC #6
 STA TEMP ;move pointers
 LDA TEMP+1
 SBC #0
 STA TEMP+1

 LDY #0
 LDA (TEMP),Y
 BEQ :FRE4 ;we are done
 BPL :FRE2 ;don't do numbers

 LDY #2
 LDA (TEMP),Y
 STA VPTR ;point to string
 INY
 LDA (TEMP),Y
 STA VPTR+1
 BEQ :FRE2 ;new string

 CMP #>CODEND
 BLT :FRE2 ;if protected string, don't move it

 INY
 LDA (TEMP),Y
 TAX
 BEQ :FRE2 ;if empty...

 LDY #2 ;put in new pointer

 SEC
 LDA TEMP3
 SBC TEMP2
 STA (TEMP),Y
 INY
 LDA TEMP3+1
 SBC TEMP2+1
 STA (TEMP),Y

 LDY #0
:FRE3 LDA (VPTR),Y
 STA (TEMP3),Y
 INY
 DEX
 BNE :FRE3

 CLC
 TYA
 ADC TEMP3 ;move up pointer
 STA TEMP3
 LDA TEMP3+1
 BCC :FRE2 ;keep looping

 INC TEMP3+1
 INC FREMEM
 JMP :FRE2 ;keep going

:FRE4 SEC
 LDA TEMP3
 SBC TEMP2
 STA VARSTR ;compute new varstr
 LDA TEMP3+1
 SBC TEMP2+1
 STA VARSTR+1

 LDA LOMEM ;point at string space
 STA TEMP
 LDA LOMEM+1
 STA TEMP+1

 LDA MIDMEM ;point at fixed strings
 STA TEMP2
 LDA MIDMEM+1
 STA TEMP2+1

 LDX FREMEM ;number of pages to move
 LDY #0
:FRE5 LDA (TEMP2),Y
 STA (TEMP),Y
 INY
 BNE :FRE5

 INC TEMP+1
 INC TEMP2+1
 DEX
 BNE :FRE5 ;do the move
 RTS
