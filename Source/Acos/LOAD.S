 PAG
********************************
*                              *
*     ACOS.OBJ - Load          *
*                              *
********************************
 DATE
*-------------------------------
* -- read module into memory --
*-------------------------------

LD_MOD LDA #0 ;reset no carrier and on error vectors
 STA NOCDFLG
 STA ONERRFLG

 LDX FLNAME
 CPX #14
 BGE LD_MOD1 ;too long!

 INX
 LDA #'.'
 STA FLNAME,X ;tack on '.C' extension
 INX
 LDA #'C'
 STA FLNAME,X
 STX FLNAME

 JSR OPEN ;is there a compiled module?
 BCS LD_MOD2 ;nope

 LDA MSGREF ;save msg refnum
 PHA
 LDA REFNUM
 STA MSGREF

 LDA #0
 STA LNBUF+140
 STA LNBUF+141

 LDX #<LNBUF+128 ;read label info
 LDA #>LNBUF+128
 LDY #1
 JSR RDBLK

 LDA LNBUF+142 ;set up variable space
 STA LOMEM
 LDA LNBUF+143
 STA LOMEM+1

 LDX #<CODEND ;read in rest of module
 LDA #>CODEND
 LDY #128
 JSR RDBLK

 JSR CLOSE
 PLA
 STA MSGREF ;restore msg refnum

 LDA LNBUF+140 ;is first i/d byte ok?
 CMP #'G'
 BNE LD_MOD2 ;nope, compile

 LDA LNBUF+141 ;is second i/d byte ok?
 CMP #'S'
 BNE LD_MOD2 ;nope, compile

 RTS ;and we are done!

LD_MOD1 LDX #badfn ;illegal filename (>14 chars)
 JMP BADERR

LD_MOD2 LDX FLNAME ;change name back to source
 LDA #'S'
 STA FLNAME,X ;'.S' for source
 JSR OPEN ;open source file
 BCS LD_MOD1 ;opps, problem

 JSR RDLNSET ;setup for rdline
 LDA #>CODEND ;point to module space
 STA TEMP+1
 LDA #<CODEND
 STA TEMP
 LDA #0
 STA LBLNUM
 STA SYMNUM ;zero sym/lbl counters
 LDX #compile1
 JSR PRCMPMSG
 JMP :STATE0

*-------------------------------
* ----- pass 1 ------
*-------------------------------

:JSTATE4 JMP STATE4

:STATE0A LDA LNCNT ;was it just a blank cr?
 CMP #2
 BLT :STATE0 ;yep

 LDA #chain2 ;insert a chain command
 LDY #0
 STA (TEMP),Y
 JSR INCTMP

:STATE0 LDA #0
 STA LNCNT ;reset line pointer
 JSR RDLINE ;get line of input
 BCS :JSTATE4 ;eof?

 LDA LNBUF ;gobble up comments
 CMP #';'
 BEQ :STATE0

 JSR TST_ALF ;check for label
 BCS :STATE1

 JSR ADD_SYM ;add to symbol table
 BCC :STATE0

 LDX #symfull ;give error
 JSR SHERR
 JMP :STATE0

:JSTATE3 STA TEMP2 ;save delimiter char for text/block mode
 LDA #"""
 JMP :STATE3A

:STATE2A JSR ADD_LBL ;add label to table
 JMP :STATE1

:STATE1A INC LNCNT ;advance pointer
:STATE1 LDY LNCNT
 LDA LNBUF,Y
 CMP #cr
 BEQ :STATE0A ;if end of line

 CMP #'!'
 BLT :STATE1A ;go until a legal character of some sort

 CMP #'"'
 BEQ :JSTATE3 ;check for text mode

 CMP #'''
 BEQ :JSTATE3 ;check for block text mode

 JSR TOKEN ;get token type
 CMP #"Z"+1
 BGE :STATE1S

 CMP #"A"
 BGE :STATE1D ;check for variable

 LDY #0
 STY LSTTOK

:STATE1S CMP #public
 BEQ :STATE2A ;is it public?, yep

 LDY #0 ;save into memory
 STA (TEMP),Y
 JSR INCTMP

 CMP #goto
 BEQ :STATE2
 CMP #push
 BEQ :STATE2

 CMP #gosub
 BNE :STATE1Z ;check to see if label follows

 LDY LSTTOK
 CPY #clear
 BNE :STATE2

:STATE1Z STA LSTTOK
 JMP :STATE1

:STATE1C JMP :STATE0A ;restart with state 0

*-------------------------------
* ----- handle variables -----
*-------------------------------

:STATE1D STA TEMP2 ;save first char of name
 LDX LNCNT
 LDA LNBUF,X ;see if there is another
 JSR TST_ALF
 BCC :STATE1E

 JSR TST_NUM
 BCC :STATE1E

 DEC LNCNT ;nope, only 1 digit
 LDA #' '
:STATE1E STA TEMP2+1 ;save second char of name

 LDX LNCNT
:STATE1F INX
 LDA LNBUF,X ;gobble rest of name
 JSR TST_ALF
 BCC :STATE1F

 JSR TST_NUM
 BCC :STATE1F

 STX LNCNT
 LDX #number
 CMP #'$'
 BNE :STATE1G ;find out whether it is a number

 INC LNCNT ;or a string
 LDX #string

:STATE1G LDY #0 ;save variable type
 TXA
 STA (TEMP),Y
 JSR INCTMP

 LDA TEMP2
 JSR CONV
 STA (TEMP),Y ;save first char
 JSR INCTMP

 LDA TEMP2+1
 JSR CONV
 STA (TEMP),Y ;save second char
 JSR INCTMP
 JMP :STATE1

:STATE2 LDY #0
 LDA #LABEL
 STA (TEMP),Y
 JSR INCTMP

 JSR ADD_LBL ;add label to table 2
 BCS :STATE1C

 LDY #0
 STA (TEMP),Y
 JSR INCTMP
 JMP :STATE1

*-------------------------------
* do text/block mode processing
*-------------------------------

:STATE3 LDY LNCNT
 LDA LNBUF,Y ;get byte
 CMP TEMP2
 BEQ :STATE3C ;check for delimiter, were done

:STATE3A CMP #cr
 BNE :STATE3B ;end of line?, nope

 LDA TEMP2 ;in text or block?
 CMP #'"'
 BEQ :STATE3D ;text, do finish up

 LDA #cr ;stick in cr if in block
:STATE3B LDY #0 ;save byte
 STA (TEMP),Y
 PHA
 JSR INCTMP
 INC LNCNT
 PLA
 CMP #cr
 BNE :STATE3 ;check byte

 LDA #0
 STA LNCNT ;reset line counter
 JSR RDLINE ;read new line

 BCC :STATE3 ;keep checking

 LDX #noquote ;Unclosed quote at EOF
 JSR ERROR ;print in text warning
 JMP STATE4 ;were done

:STATE3C INC LNCNT
:STATE3D LDA #"""
 LDY #0 ;save last quote
 STA (TEMP),Y
 JSR INCTMP
 JMP :STATE1

*-------------------------------
* ----- pass 2 -----
*-------------------------------

STATE4 LDX #compile2
 JSR PRCMPMSG

 LDY #0
 LDA #end
 STA (TEMP),Y
 JSR INCTMP

 LDA #QUIT save end pointer
 STA (TEMP),Y
 JSR CLOSE

 LDA #0 ;mark end of tables
 LDX SYMNUM
 STA SYMTAB,X
 LDX LBLNUM
 STA LBLTAB,X

 JSR INCTMP

 LDA TEMP ;setup pointers to variable space
 STA LOMEM
 STA LNBUF+142 ;save for compiled segments
 LDA TEMP+1
 STA LNBUF+143
 STA LOMEM+1

 LDX #128 ;start counters
 LDY #0
:STATE4A LDA #>LBLTAB
 STA :STATE4B+2 ;changes code
:STATE4B LDA LBLTAB,Y ;*** self-modified
 INC :STATE4B+2 ;changes code
 STA LNBUF,X ;save data
 INX
 TXA
 AND #%00001000 ;have we done 8 yet?
 BEQ :STATE4B ;nope

 INY ;ready for next
 CLC
 TXA
 ADC #8 ;add it up.
 TAX
 BCC :STATE4A ;keep going

 LDX #-1 ;start at beginning of table
:STATE5 INX
 LDA LBLTAB,X
 BNE :STATE5D
 JMP :STATE6 ;are we done?

:STATE5D LDY #-1
:STATE5F INY
 LDA SYMTAB,Y
 BNE :STATE5C ;keep checking

 TXA
 PHA
 LDX #lblnf ;label not found
 JSR ERROR
 PLA
 TAX
 LDA #>LBLTAB
 STA :STATE5E+2 ;start at first char
 LDA #"["
 JSR COUT

:STATE5E LDA LBLTAB,X
 PHP
 JSR COUT ;print char
 INC :STATE5E+2 ;get ready for next
 PLP
 BPL :STATE5E ;loop until finished

 LDA #"]"
 JSR COUT
 LDA #<NOLBLDEF
 STA LBLTAB,X ;put bad branch error routine
 LDA #>NOLBLDEF
 STA LBLTAB+L1,X ;address into table
 JMP :STATE5

:STATE5A JMP :STATE5F ;extension from branches

:STATE5C LDA LBLTAB,X ;check each byte
 CMP SYMTAB,Y
 BNE :STATE5A ;opps, no match
 ASL
 BCS :STATE5B ;high bit means were done

 LDA LBLTAB+L1,X
 CMP SYMTAB+L1,Y
 BNE :STATE5A
 ASL
 BCS :STATE5B

 LDA LBLTAB+L2,X
 CMP SYMTAB+L2,Y
 BNE :STATE5A
 ASL
 BCS :STATE5B

 LDA LBLTAB+L3,X
 CMP SYMTAB+L3,Y
 BNE :STATE5A
 ASL
 BCS :STATE5B

 LDA LBLTAB+L4,X
 CMP SYMTAB+L4,Y
 BNE :STATE5A
 ASL
 BCS :STATE5B

 LDA LBLTAB+L5,X
 CMP SYMTAB+L5,Y
 BNE :STATE5A
 ASL
 BCS :STATE5B

 LDA LBLTAB+L6,X
 CMP SYMTAB+L6,Y
 BNE :STATE5A
 ASL
 BCS :STATE5B

 LDA LBLTAB+L7,X
 CMP SYMTAB+L7,Y
 BNE :STATE5A

:STATE5B LDA SYMTAB+L8,Y
 STA LBLTAB,X ;copy label address
 LDA SYMTAB+L9,Y
 STA LBLTAB+L1,X
 JMP :STATE5

*-------------------------------
* ----- pass 3 -----
*-------------------------------

:STATE6 LDX #128 ;start counters
 LDY #0
:STATE6D LDA LBLTAB,Y
 STA LNBUF+8,X ;move first address
 LDA LBLTAB+L1,Y
 STA LNBUF+9,X
 INY ;inc address #
 CLC
 TXA
 ADC #16 ;move dest pointer
 TAX
 BCC :STATE6D ;more data, keep going

 LDA #<CODEND ;point at module
 STA TEMP
 LDA #>CODEND
 STA TEMP+1

:STATE6A LDY #0
 LDA (TEMP),Y
 CMP #QUIT
 BEQ :STATE6C

 CMP #LABEL
 BNE :STATE6B

 INY
 LDA (TEMP),Y ;get label address
 TAX ;and insert into code
 LDA LBLTAB+L1,X
 STA (TEMP),Y
 DEY
 LDA LBLTAB,X
 STA (TEMP),Y

 INC TEMP
 BNE :STATE6B ;inc pointers
 INC TEMP+1

:STATE6B INC TEMP
 BNE :STATE6A
 INC TEMP+1
 BNE :STATE6A

:STATE6C LDX FLNAME ;add '.C' back on
 LDA #'C'
 STA FLNAME,X

 LDY #a2obj ;user defined filetype
 LDA #>comfile
 LDX #<comfile
 JSR CREATE

 JSR OPEN
 BCS :STATE6E ;if problem

 LDA MSGREF ;save msg refnum
 PHA
 LDA REFNUM
 STA MSGREF ;and replace with current

 LDA #'G' ;save i/d bytes
 STA LNBUF+140
 LDA #'S'
 STA LNBUF+141

 LDX #<LNBUF+128 ;write out header (with label info)
 LDA #>LNBUF+128
 LDY #1
 JSR WRBLK

 SEC
 LDA LOMEM+1
 SBC #>CODEND ;find # of pages in module
 ASL ;multiply by 2 into blocks
 TAY
 INY ;add in extra page just in case
 INY

 LDX #<CODEND ;write rest of data
 LDA #>CODEND
 JSR WRBLK

 JSR CLOSE ;finish up
 PLA
 STA MSGREF ;and restore

:STATE6E LDX #compwipe
 JSR PRCMPMSG
 JMP PAUSE ;were done

*-------------------------------
* ----- add to symbol table ----
*-------------------------------

ADD_SYM LDY #-1
:ADD_SM2 INY ;find last char of label
 LDA LNBUF,Y
 JSR CONV ;convert to uppercase
 STA LNBUF,Y
 CMP #' '
 BEQ :ADD_SM3
 CMP #':'
 BEQ :ADD_SM3
 CMP #cr
 BNE :ADD_SM2

:ADD_SM3 DEY
 LDA LNBUF,Y ;set high-bit of last char
 ORA #hibit
 STA LNBUF,Y

 LDA LNBUF+7 ;mark last char just in case
 ORA #hibit
 STA LNBUF+7

 LDX SYMNUM ;check for overflow
 CPX #$FF
 BEQ :ADD_SM6

 LDA #>SYMTAB
 STA :ADD_SM5+2 ;set up table
 LDY #-1
:ADD_SM4 INY
 LDA LNBUF,Y
 PHP
:ADD_SM5 STA SYMTAB,X ;*** self-modified ***
 INC :ADD_SM5+2
 PLP
 BPL :ADD_SM4 ;loop until done

 LDA TEMP
 STA SYMTAB+L8,X ;save label location
 LDA TEMP+1
 STA SYMTAB+L9,X
 INC SYMNUM ;add to table
 CLC
 RTS

:ADD_SM6 SEC ;symbol tabel overflow
 RTS

*-------------------------------
* ----- add to label table -----
*-------------------------------

ADD_L12 LDX #nosymbol
 JSR SHERR ;missing symbol
 SEC
 RTS

ADD_LBL LDY LNCNT
 DEY
:ADD_LB1 INY
 LDA LNBUF,Y
 CMP #cr
 BEQ ADD_L12 ;eol?, opps, error

 JSR TST_ALF ;gobble until a legal char
 BCS :ADD_LB1
 STY LNCNT ;save new location
 DEY
 LDX #8
:ADD_LB2 INY ;find last char of label
 LDA LNBUF,Y
 CMP #' '
 BEQ :ADD_LB3
 CMP #':'
 BEQ :ADD_LB3
 CMP #cr
 BEQ :ADD_LB3

 JSR CONV ;convert to upper
 DEX
 BNE :ADD_L2A

 ORA #hibit ;always fix 8th char
:ADD_L2A STA LNBUF,Y
 JMP :ADD_LB2

:ADD_LB3 STY LNCNT2 ;save new line count
 DEY
 LDA LNBUF,Y ;set high-bit of last char
 ORA #hibit
 STA LNBUF,Y

 LDX LBLNUM ;check for overflow
 CPX #$FF
 BEQ ADD_L11

 LDX #-1 ;go through and add to table
:ADD_LB4 INX
 CPX LBLNUM
 BEQ :ADD_LB7 ;add new label

 LDA #>LBLTAB
 STA :ADD_LB6+2 ;set up table

 LDY LNCNT
:ADD_LB5 LDA LNBUF,Y
:ADD_LB6 CMP LBLTAB,X ;*** self-modified ***
 PHP
 INC :ADD_LB6+2
 INY
 PLP
 BNE :ADD_LB4

 ASL ;put high-bit into carry
 BCC :ADD_LB5 ;loop until done
 BCS :ADD_L10 ;we already have label in table

:ADD_LB7 LDA #>LBLTAB
 STA :ADD_LB9+2 ;move label into new location
 LDY LNCNT
:ADD_LB8 LDA LNBUF,Y
 PHP
:ADD_LB9 STA LBLTAB,X
 INC :ADD_LB9+2
 INY
 PLP
 BPL :ADD_LB8

 INC LBLNUM ;increment count
:ADD_L10 LDY LNCNT2
 STY LNCNT
 TXA ;return label number
 CLC
 RTS

ADD_L11 LDX #symfull
 JSR SHERR
 SEC ;symbol tabel overflow
 RTS

*-------------------------------
* ----- get a token -----
*-------------------------------

TOKEN LDA #<SYMTXT ;point at token table
 STA TEMP2
 LDA #>SYMTXT
 STA TEMP2+1
 LDY #0
 STY TOKTYP ;start token count
 BEQ :TOKEN4 ;try and find a match

:TOKEN1 INC TOKTYP ;try next token
:TOKEN2 LDA (TEMP2),Y
 INY
 BNE :TOKEN3

 INC TEMP2+1
:TOKEN3 ASL ;put into carry
 BCC :TOKEN2 ;was high bit set?

:TOKEN4 LDX LNCNT ;get line offset
:TOKEN5 LDA (TEMP2),Y ;were done, no match
 BEQ :TOKEN7

 STA PRN
 LDA LNBUF,X ;check it
 JSR CONV
 EOR PRN ;match bits
 ASL ;move bit 7
 BNE :TOKEN1 ;no match

 INX ;increment pointers
 INY
 BNE :TOKEN6
 INC TEMP2+1

:TOKEN6 BCC :TOKEN5 ;keep checking

 STX LNCNT ;save new text pointer
 LDA TOKTYP
 RTS

:TOKEN7 LDA LNBUF,X ;get char
 INC LNCNT
 JSR CONV ;make uppercase
 ORA #hibit
 RTS
