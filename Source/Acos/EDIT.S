            PAG
********************************
*                              *
*      MultiPro - Editor       *
*                              *
********************************
            DATE
*-------------------------------
* system editor
*-------------------------------

DO_EDIT     JSR   INPNARG                                      ;get arg
            CPX   #6
            BGE   :ED_ERR

            TXA
            ASL
            TAX
            LDA   EDJMP,X
            STA   TEMP
            LDA   EDJMP+1,X
            STA   TEMP+1
            JMP   (TEMP)                                       ;do it

:ED_ERR     JMP   SYNTAX

EDJMP       DA    ED_CLR
            DA    ED_STX
            DA    ED_SPC
            DA    ED_WIDTH
            DA    ED_MODE
            DA    ED_LOC

*-------------------------------
* entering the editor
*-------------------------------

ED_STX      TSX
            STX   EDSTACK                                      ;save stack
            TXA
            SBC   #32                                          ;move stack 32 levels down
            TAX
            TXS

            LDA   #0
            STA   PROMPT                                       ;turn off prompts
            STA   EXE_DOT                                      ;enable dot commands
            STA   INTBUF                                       ;don't allow int's
            STA   INTOUT                                       ;make sure output is on
            STA   DOT_E                                        ;make sure '.e' is not active
            STA   ERVAL

            LDA   #<COUT                                       ;point output to console/modem
            STA   VECTOR
            LDA   #>COUT
            STA   VECTOR+1

            JSR   FINDEND                                      ;setup end pointers
            LDA   EDBUF                                        ;check contents of buffer
            BEQ   ED_LNCR                                      ;nothing there

            JMP   ED_CMD                                       ;handle command line

*-------------------------------
* clear the editor
*-------------------------------

ED_CLR      LDA   #0
            STA   EDBUF                                        ;reset data pointer
            STA   EDLINE                                       ;zero line counter
            STA   EDLINE+1
            STA   EDPTR
            LDA   #>EDBUF
            STA   EDPTR+1
            RTS

*-------------------------------
* return bytes in editor
*-------------------------------

ED_SPC      JSR   FINDEND
            SEC
            LDA   EDPTR
            SBC   #<EDBUF                                      ;length = end - start
            TAX
            LDA   EDPTR+1
            SBC   #>EDBUF
            JMP   DO_MATH

*-------------------------------
* get location of USE buffer
*-------------------------------

ED_LOC      LDX   #<EDBUF                                      ;4k RAM area
            LDA   #>EDBUF
            JMP   DO_MATH

ED_WIDTH    BIT   IMMDEF                                       ;get cmd
            BMI   :WIDTH1                                      ;yep

            LDA   VIDLEN                                       ;return current width
            JMP   SVDATA

:WIDTH1     JSR   GOBEQU                                       ;gobble equ
            JSR   INPNUM                                       ;get video width
            TXA
            BEQ   WIDTH2                                       ;opps, problem

            STX   VIDLEN                                       ;save it
WIDTH2      RTS

*-------------------------------
* read or set backspace mode
*-------------------------------

ED_MODE BIT IMMDEF
 BMI :MODE1 setting it

 LDA NONBS
 JMP SVDATA return data

:MODE1 JSR GOBEQU gobble
 LDA #$40
 STA NONBS non-destruct bs mode
 JSR INPNUM get mode
 CPX #1
 BEQ WIDTH2 we were correct, return

 ASL NONBS set to destruct bs
 CPX #2
 BEQ WIDTH2 do it

 ASL NONBS unknown mode
 RTS

ED_LNCR JSR PRCRLF add a line feed
ED_LN LDA WWFLAG
 STA WWRAP get word-wrap status
:ED_LN0 LDX EDPTR get a line of text
 LDA EDPTR+1
 JSR GETEDLN

 STX EDPTR save new end address
 STA EDPTR+1
 LDA WWEXTRA
 BNE :ED_LN1

 LDA #0 add in end of editor
 TAY
 STA (EDPTR),Y
 BCC :ED_LN1 they did not type done

 LDA #0
 STA DOT_E
 JMP ED_CMD if they typed 'done'


:ED_LN1 INC EDLINE
 BNE :ED_LN2 add line to editor
 INC EDLINE+1

:ED_LN2 SEC
 LDA EDPTR+1 check for 3.75k
 SBC #>EBUFEND
 BNE ED_LN there is plenty

 LDA #0
 STA WWRAP turn off word-wrap
 LDA WWEXTRA is there word-wrap data?
 BNE :ED_LN0 yep
 LDX #thats4k
 JSR PREDMSG

ED_CMD LDA #<LNBUF point to line buffer
 STA ARGPTR
 LDA #>LNBUF
 STA ARGPTR+1

 LDX #editing
 JSR PREDMSG
 JSR ED_CMD2
 JMP ED_CMD

ED_CMD2 JSR GETCMD
 JSR MATCH
 DB -1
 DA ED_EX
 ASC '?'
 DA ED_HLP
 ASC 'A'
 DA ED_ABT
 ASC 'C'
 DA ED_CONT
 ASC 'D'
 DA ED_DEL
 ASC 'E'
 DA ED_ED
 ASC 'H'
 DA ED_HLP2
 ASC 'I'
 DA ED_INS
 ASC 'L'
 DA ED_LST
 ASC 'N'
 DA ED_NEW
 ASC 'O'
 DA ED_OK
 ASC 'S'
 DA ED_OK
 ASC 'Z'
 DA ED_USED
 DB 0

 BIT EXEC check for sysop
 BPL :ED_CMD3 nope

 JSR MATCH check the rest
 ASC 'R'
 DA ED_RD
 ASC 'W'
 DA ED_WRT
 DB 0

:ED_CMD3 LDX #badcmd
 JMP PREDMSG

ED_HLP LDX #edithelp show the help stuff
 JMP PREDMSG

ED_HLP2 LDA #<HLPFILE point to filename
 STA STRLOC
 LDA #>HLPFILE
 STA STRLOC+1
 LDA #11
 STA STRLEN
 JSR MOVNM0 move name
 JSR IFOPEN open into a unused channel
 BCS :ED_HLP5

 JSR DO_SED make spacebar work
:ED_HLP3 JSR RDBYTE get data
 BCS :ED_HLP4 end of data

 JSR COUT show data
 BIT INTOUT did they interupt?
 BPL :ED_HLP3 nope

 INC INTOUT re-enable output
:ED_HLP4 INC INTBUF
 JMP CLOSE close file

:ED_HLP5 LDX #nofile system error
 JMP PRMSG

HLPFILE ASC 'b:hlp.edit'

ED_ABT LDX #abort?
 JSR PREDMSG
 JSR GETCMD
 CMP #'Y'
 BNE ED_RTS

 JSR ED_CLR clear editor
 LDX #aborted
ED_CON1 JSR PREDMSG
 JMP ED_EX return

ED_CONT LDX #aborted thats 4k message
 SEC
 LDA EDPTR+1 enough space?
 SBC #>EBUFEND
 BEQ ED_CON1 yep

 JSR CONT continue...
 PLA
 PLA
 JMP ED_LN get more stuff

ED_RTS RTS

ED_DEL LDX #delete?
 JSR PREDMSG
 JSR INPLN
 JSR CHKLIST do list?
 BCS ED_DEL yes we did

DOT_DEL JSR XYARG get arg's
 BEQ ED_RTS
 BCS ED_ERR

 LDX X_ARG get line number
 LDA X_ARG+1
 JSR FINDLN find the line
:ED_DEL2 JSR FNDLEN get the length
 TAY
 INY  kill CR
 LDX TEMP
 LDA TEMP+1
 JSR DEL_TXT delete the line

 LDA EDLINE decrease line count
 BNE :ED_DEL3
 DEC EDLINE+1

:ED_DEL3 DEC EDLINE
 JSR INCXARG
 BCC :ED_DEL2 loop until done
CR_RET2 RTS

ED_ERR JMP CR_ERR link to error routine

DOT_E1 BIT EXE_DOT
 BPL CR_RET2

 PLA  handle the '.e' option
 PLA
 LDY #0
 STY EXE_DOT no dot command

 DEC DOT_E
 JMP EDLNCR2

ED_ED LDX #edit?
 JSR PREDMSG
 JSR INPLN
 JSR CHKLIST do a list?
 BCS ED_ED we did

DOT_ED JSR XARG get line number
 BEQ DOT_E1 just a return (was BEQ CR_RTS2)
 BCS ED_ERR opps, a problem

 JSR PRCRLF
 LDX X_ARG get line number
 LDA X_ARG+1
 JSR FINDLN get address
 JSR FNDLEN get length
 STA TEMP2
 PHA  save orig length
 TAX
 BEQ :ED_ED3

 LDY #0
:ED_ED2 LDA (TEMP),Y
 STA LNBUF,Y move data to lnbuf
 INY
 DEX
 BNE :ED_ED2

:ED_ED3 LDA TEMP save address
 PHA
 LDA TEMP+1
 PHA

 LDA #<LNBUF point at lnbuf
 STA TEMP
 LDA #>LNBUF
 STA TEMP+1
 JSR SHOWLN show line number
 JSR LSTLINE print line
 BIT NONBS check bs mode
 BVC :ED_ED8 print line again

 JSR EDLN7 back up
 JMP :ED_ED7 do edit

:ED_ED8 JSR PRCRLF add a return
 JSR SHOWLN show the line number
 LDY #0
 STY TEMP2 kill line, reset line

:ED_ED7 INC WWRAP toggle word wrap off
 JSR GETEDL2 edit line
 DEC WWRAP put word wrap to old state

 PLA
 STA TEMP3+1 save old line address
 PLA
 STA TEMP3

 PLA
 BCS CR_RET if they typed 'done'

:ED_ED7A SEC
 SBC TEMP2 find out length
 BEQ :ED_ED5 hmm, same length!
 BCC :ED_ED4

 TAY
 JSR DEL_TX0 make room
 JMP :ED_ED5

:ED_ED4 EOR #-1 make positive
 TAY
 INY
 JSR INS_TX0 insert

:ED_ED5 LDY #0
 LDX TEMP2 get length
 INX
:ED_ED6 LDA LNBUF,Y
 STA (TEMP3),Y copy line back
 INY
 DEX
 BNE :ED_ED6
 JMP PRCRIF add extra lf (maybe)

CR_RET RTS

CR_ERR LDX #badln
 JSR PREDMSG
 JMP PRCRIF add extra lf (maybe)

ED_INS LDX #insert?
 JSR PREDMSG
 JSR INPLN
 JSR CHKLIST do a list?
 BCS ED_INS

DOT_INS JSR XARG
 BEQ CR_RET
 BCS CR_ERR
 LDX #insert
 JSR PREDMSG

:ED_INS0 LDX #<LNBUF point to line
 LDA #>LNBUF
 JSR GETEDLN get a line of stuff
 BCS :ED_INS2

 LDY TEMP2 save length
 INY  add 1 for CR
 STY SAVE_Y
 LDX X_ARG
 LDA X_ARG+1
 JSR FINDLN locate line
 LDY SAVE_Y
 JSR INS_TXT insert text

 LDY #0
:ED_INS1 LDA LNBUF,Y
 STA (TEMP3),Y copy in new line
 INY
 DEC SAVE_Y
 BNE :ED_INS1

 LDX #0
 CPX WWEXTRA
 BEQ :ED_IN1B word-wrap?, nope

:ED_IN1A LDA LNBUF,Y get next bit of data
 INY
 STA LNBUF,X move back
 INX
 CPX WWEXTRA
 BNE :ED_IN1A done?, nope

:ED_IN1B INC X_ARG
 BNE :ED_IN1C inc line to insert at
 INC X_ARG+1

:ED_IN1C INC EDLINE
 BNE :ED_INS0 inc line count
 INC EDLINE+1
 BNE :ED_INS0

:ED_INS2 BIT EXE_DOT is it .i command?
 BPL CR_RET nope, return
 JMP CONT continue

CR_ERR0 JMP CR_ERR goto error routine

ED_LST LDX #list?
 JSR PREDMSG
 JSR INPLN

DOT_LST LDY #0
 STY SHWLN reset line # bit
 LDA (ARGPTR),Y
 JSR CONV
 CMP #'Y'
 BNE ED_LST1 show numbers?, nope

 LDA #-1
 STA SHWLN show line numbers
 INC ARGPTR
 BNE ED_LST1 point to next char
 INC ARGPTR+1

ED_LST1 JSR XYARG
 BCS CR_ERR0

 JSR PRCRLF
ED_SHLN LDX X_ARG get line number
 LDA X_ARG+1
 JSR FINDLN locate it

:ED_LST2 BIT SHWLN show line numbers?
 BPL :ED_LST3 nope

 JSR SHOWLN add the line number
:ED_LST3 JSR FNDLEN get the length
 STA TEMP2
 JSR LSTLINE list the line

 SEC  advance pointer to next line
 LDA TEMP2
 ADC TEMP
 STA TEMP temp = temp + temp2 + 1
 LDA #0
 ADC TEMP+1
 STA TEMP+1

 JSR PRCRLF add cr
 JSR INCXARG
 BCC :ED_LST2
 RTS

ED_NEW LDX #new?
 JSR PREDMSG
 JSR GETCMD
 CMP #'Y'
 BNE :ED_NEW2

 JSR ED_CLR clear editor
 LDX #enter
 JSR PREDMSG enter message now...
 LDA #0
 STA EXE_DOT allow dot commands
 JMP ED_LN get message

:ED_NEW2 RTS

ED_USED LDA #cr
 JSR COUT
 JSR ED_SPC
 LDA DATA+2
 LDX DATA+1
 JSR DECOUT
 LDX #bytsused
 JMP PREDMSG

DOT_PMT LDA PROMPT
 EOR #-1 toggle prompt status
 STA PROMPT
 BEQ ED_NEW2 dont show prompts

 LDA #'>' show first prompt
 JSR COUT

ED_NEW2 RTS
; common read/write

ED_RW JSR INPLN input data
 LDA #<LNBUF point to string
 STA STRLOC
 LDA #>LNBUF
 STA STRLOC+1
 LDA #19
 STA STRLEN save max length
 JMP MOVNM0 move the name

ED_RD LDX #readfn?
 JSR PREDMSG
 JSR ED_RW
 JSR IFOPEN try and open
 BCS ED_RD4 error, no go

 LDA #<EDBUF point to date
 STA EDPTR
 LDA #>EDBUF
 STA EDPTR+1

:ED_RD2 JSR RDBYTE read in file
 PHP
 JSR EDOUT
 PLP
 BCC :ED_RD2

ED_RD3 JSR CLOSE finish up
 JMP FINDEND fix pointers

ED_RD4 LDX #nofile print no buffers
 JMP PRMSG

ED_WRT LDX #writefn?
 JSR PREDMSG
 JSR ED_RW setup for work
 JSR DELFILE delete existing file
 LDY #txt
 LDA #0
 LDX #0
 JSR CREATE create a text file
 JSR IFOPEN
 BCS ED_RD3 error

 LDA #0
 STA DEVCLR reset device

:ED_WR2 JSR EDINP get data
 CMP #0
 BEQ ED_RD3 thats the end

 JSR WRBYTE write out byte
 BCC :ED_WR2 all is well
 LDX #badwrite
 JSR PRMSG show message
 JMP ED_RD3 finish up

DOT_OK LDA #0 add in eof char
 TAY
 STA (TEMP),Y

ED_OK BIT EXEC exec user online?
 BPL :FILT0
 JMP ED_EX yes, exit

:FILT0 LDA FILTER is filter in place?
 BEQ :XCHECK nope, check for .X's

 LDA #<EDBUF point to editor buffer
 STA TEMP
 LDA #>EDBUF
 STA TEMP+1

 JMP :FILT7 start routine

:FILT1 LDA FILTER,X go to next entry
 INX
 ASL A at last char?
 BCC :FILT1 nope

 LDY #0 start at first byte
:FILT3 LDA FILTER,X get filter char
 BEQ :FILT5 end of table

 STA TEMP2 save it
 LDA (TEMP),Y get byte in question
 JSR CONV convert to upper
 EOR TEMP2 check against filter - save hi bit
 ASL A put high into carry
 BNE :FILT1 no match, keep checking

 INX  inc pointers
 INY
 BCC :FILT3 keep checking for rest of string

 LDA #'*' change text into *'s
:FILT4 DEY
 STA (TEMP),Y
 CPY #0
 BNE :FILT4

:FILT5 INC TEMP
 BNE :FILT7 go to next byte
 INC TEMP+1

:FILT7 LDX #0 start both index's off at 0
 LDY #0
 LDA (TEMP),Y get byte
 BEQ :XCHECK end

 CMP #'A'
 BGE :FILT3 is it good data, check it
 BLT :FILT5 goto next byte

:XCHECK LDA #<EDBUF look for external file cmd
 STA TEMP
 LDA #>EDBUF start at beginning
 STA TEMP+1

 LDY #0 Y is 0 on first pass only
:XCK1 LDA (TEMP),Y all other passes, Y is 1
 BEQ ED_EX no data
 CMP #'.' command?
 BNE :XCK2 no, skip to next line

 INY  check the command
 LDA (TEMP),Y
 JSR CONV
 CMP #'X' is it an X?
 BNE :XCK2 no, skip to next line

 INY  check if space follows
 LDA (TEMP),Y
 CMP #' ' is there a space?
 BNE :XCK2 no, skip to next line

 LDA #'*' replace '.X ' (kills external)
 STA (TEMP),Y    with '.X*' (see DO_SHOW)
 STA ERVAL

:XCK2 LDY #0 set Y back to 0
:XCK3 INC TEMP search for end of line
 BNE :XCK4 or end of text
 INC TEMP+1
:XCK4 LDA (TEMP),Y
 BEQ ED_EX no more text
 CMP #cr
 BNE :XCK3 end of line?, look some more
 INY  Y is now 1
 BNE :XCK1 branch always

ED_EX LDX EDSTACK
 TXS
 RTS

*-------------------------------
* ----- editor routines -----
*-------------------------------

GETEDLN LDY #0 line length
 STY TEMP2
 STX TEMP point to data
 STA TEMP+1

 BIT PROMPT are prompts on?
 BPL :GETEDL1 nope

 LDA #'>' display prompt
 JSR COUT

:GETEDL1 LDA WWEXTRA word-wrap?
 BEQ GETEDL2 nope

 STY WWEXTRA reset word-wrap
 STA TEMP2 save length
 JSR LSTLINE list the partial line and fall through
 JMP GETED1 don't want to reset to 0!

GETEDL2 LDY #0

GETED1 JSR RDKEY get input
 JSR GETED2
 JMP GETED1

GETED2 JSR MATCH
 DB -1
 DA ED_EX carrier lost
 DB cr
 DA EDLNCR handle [return]
 DB tab
 DA EDLN0 handle [tab]
 DB bs
 DA EDLN1 handle [backspace, ctrl-h]
 DB del
 DA EDLN12 handle [delete]
 DB can
 DA EDLN4 handle [cancel, ctrl-x]
 DB ctr
 DA EDLN11 handle [center, ctrl-c]
 DB 0 finish this set

 BIT NONBS good bs mode
 BVC :GETED2H no

 JSR MATCH
 DB fs
 DA EDLN2 handle [forward space, ctrl-u]
 DB hak
 DA EDLN3 handle [truncate, ctrl-t]
 DB dc
 DA EDLN5 handle [delete char, ctrl-d]
 DB ic
 DA EDLN6 handle [insert char, ctrl-f]
 DB bol
 DA EDLN7 handle [begin line, ctrl-b]
 DB eol
 DA EDLN8 handle [end of line, ctrl-e]
 DB lwd
 DA EDLN9 handle [last word, ctrl-l]
 DB nwd
 DA EDLN10 handle [next word, ctrl-n]
 DB 0

:GETED2H CMP #' '
 BLT :GETED2C control?, yes

 CPY VIDLEN
 BEQ :GETED3
 STA (TEMP),Y store it.
 JSR COUT output it
 CPY TEMP2
 BNE :GETED2B at end of line?, nope

 INC TEMP2 inc end of line pointer
:GETED2B INY  inc data pointer
:GETED2C RTS

:GETED2Z TXA  restore Y
 TAY
:GETED2X LDA #bel ring bell
 JMP COUT

:GETED3 BIT WWRAP is word wrap on?
 BPL :GETED2X nope

 CMP #' '
 BEQ EDLNCR was it an even break?, yes

 STA (TEMP),Y save char
 TYA  save Y
 TAX
:GETED3A DEY
 BEQ :GETED2Z count down, no spaces in line!

 LDA (TEMP),Y check for space
 CMP #' '
 BNE :GETED3A nope, keep looking

 STY TEMP2 save new length
 LDY #0

:GETED3B INY  count number of extra's
 DEX  first char doesn't count
 JSR PRBS backup
 CPX TEMP2
 BNE :GETED3B we done?, keep looping

 STY WWEXTRA remember extra

EDLNCR LDY TEMP2 get line length
 LDA #cr
 STA (TEMP),Y save return at end
 JSR COUT show it

 LDY #0
 LDA (TEMP),Y
 STA DOT_SAVE
 CMP #'.'
 BEQ EDLNCR0 dot command?, yes
 CMP #'/'
 BNE EDLNCR2 slash command?, no

EDLNCR0 LDA #0
 STA DOT_E

 BIT EXE_DOT dot commands allowed?
 BMI EDLNCR2 nope
 DEC EXE_DOT exec a dot command

 CLC
 LDA TEMP
 STA EDPTR set up arg pointer
 ADC #2
 STA ARGPTR

 LDA TEMP+1
 STA EDPTR+1
 ADC #0
 STA ARGPTR+1

 LDY #0
 TYA  end text
 STA (TEMP),Y
 INY
 LDA (TEMP),Y get command
 JSR EDLNCR1

 JSR FINDEND get new end pointer

 LDY #0
 STY EXE_DOT get a new line
 STY TEMP2 no in dot command

 LDA EDPTR point back to data
 STA TEMP
 LDA EDPTR+1
 STA TEMP+1
 RTS

EDLNCR1 JSR CONV make upper
 JSR MATCH
 ASC 'A'
 DA ED_ABT
 ASC 'D'
 DA DOT_DEL
 ASC 'E'
 DA DOT_ED
 ASC 'H'
 DA DOT_HLP
 ASC 'I'
 DA DOT_INS
 ASC 'L'
 DA DOT_LST
 ASC 'N'
 DA ED_NEW
 ASC 'O'
 DA DOT_OK
 ASC 'S'
 DA DOT_OK
 ASC 'P'
 DA DOT_PMT
 ASC 'Z'
 DA ED_USED
 DB 0
 PLA
 PLA

 LDY #0
 STY EXE_DOT no dot command
 LDA DOT_SAVE
 STA (TEMP),Y restore the dot

EDLNCR2 PLA  return from getline
 PLA

 BIT DOT_E is it a '.e'?
 BMI :EDLNCR5 yes, so handle it

 LDA TEMP2 was length correct?
 CMP #4
 BNE :EDLNCR4 nope

 LDX #0 was it 'DONE'?
 JSR CMPSTR
 BCS :EDLNCR5 yes

:EDLNCR4 SEC  return with end address of line
 LDA TEMP2 address = start + length + 1 (for CR)
 ADC TEMP
 TAX
 LDA #0
 ADC TEMP+1
 CLC  return status: clc = all well
 RTS

:EDLNCR5 LDX TEMP get old address
 LDA TEMP+1
 RTS  return status: sec = exit edit mode

*-------------------------------
* handle a tab
*-------------------------------

EDLN0 CPY VIDLEN
 BEQ :EDLN0A at end of line?, no more

 LDA #' ' do a space
 JSR GETED2
 TYA
 AND #7 are we at a 1/8 inc?
 BNE EDLN0 nope
:EDLN0A RTS

*-------------------------------
* go forward 1 space
*-------------------------------

EDLN2 SEC  cant do fs
 CPY TEMP2
 BEQ :EDLN2A at end of line?, yes

 LDA (TEMP),Y get char
 JSR COUT output it
 INY  move pointer
 CLC  can do fs
:EDLN2A RTS

*-------------------------------
* truncate contents of line
*-------------------------------

EDLN3 LDX #0 kill 0 chars
:EDLN3A CPY TEMP2
 BEQ :EDLN3B are we done, yes

 LDA #' '
 JSR COUT
 INX  count it
 INY
 BNE :EDLN3A move forward

:EDLN3B CPX #0
 BEQ :EDLN3C done?, yes

 JSR BSOUT do bs
 DEC TEMP2 move back line count
 DEY  move back data pointer
 DEX
 BNE :EDLN3B count down, loop if not done

:EDLN3C RTS

*-------------------------------
* delete entire line
*-------------------------------

EDLN4 JSR EDLN3 hack line
 LDA TEMP2 no data to kill
 BEQ :EDLN4B

:EDLN4A JSR PRBS destructive bs
 DEY  back up data pointer
 DEC TEMP2
 BNE :EDLN4A decrease line length

:EDLN4B RTS

*-------------------------------
* delete 1 character
*-------------------------------

EDLN5 CPY TEMP2
 BEQ :EDLN5D at end of line?

 STY SAVE_Y
 DEC TEMP2 decrease line count
 LDX #1
:EDLN5A CPY TEMP2
 BEQ :EDLN5B done

 INY
 LDA (TEMP),Y move each char back
 DEY
 STA (TEMP),Y
 INY
 INX
 JSR COUT show char
 JMP :EDLN5A

:EDLN5B LDA #' ' delete last char
 JSR COUT
 LDY SAVE_Y

:EDLN5C JSR BSOUT
 DEX
 BNE :EDLN5C

:EDLN5D RTS

*-------------------------------
* insert 1 character
*-------------------------------

EDLN6 CPY TEMP2
 BEQ :EDLN6C at the end of the line?

 LDA TEMP2 are we at max line width?
 CMP VIDLEN
 BEQ :EDLN6C yes

 STY SAVE_Y
 LDX #0 start counter
 LDA #' ' show a space first
:EDLN6A JSR COUT
 INX  inc count

 PHA
 LDA (TEMP),Y
 STA TEMP2+1 get new char and save
 PLA
 STA (TEMP),Y save old char
 LDA TEMP2+1

 INY
 CPY TEMP2
 BLT :EDLN6A
 BEQ :EDLN6A done?

 INC TEMP2 add 1 to line count
 LDY SAVE_Y
:EDLN6B JSR BSOUT backup
 DEX
 BNE :EDLN6B

:EDLN6C RTS  done

*-------------------------------
* goto beginning of line
*-------------------------------

EDLN7 CPY #0
 BEQ EDLN7B at beginning?, yes

:EDLN7A JSR BSOUT back up
 DEY
 BNE :EDLN7A

EDLN7B RTS

*-------------------------------
* list a line
*-------------------------------

LSTLINE LDY #0 use show to eol

*-------------------------------
* goto end of line
*-------------------------------

EDLN8 CPY TEMP2
 BEQ EDLN7B at end of line?, yes

 LDA (TEMP),Y
 JSR COUT print char (move forward)
 INY  keep checking
 JMP EDLN8

*-------------------------------
* back up to last word
*-------------------------------

EDLN9 CPY #0
 BEQ :EDLN9A at beginning?, yes

 JSR BSOUT back up
 DEY
 LDA (TEMP),Y back 1 word?
 CMP #' '
 BNE EDLN9 no

:EDLN9A RTS

*-------------------------------
* goto next word
*-------------------------------

EDLN10 CPY TEMP2
 BEQ :EDLN10A at end?, yes

 LDA (TEMP),Y move forward
 JSR COUT
 INY
 LDA (TEMP),Y
 CMP #' '
 BNE EDLN10 at end of word?, no

:EDLN10A RTS

*-------------------------------
* center line of text
*-------------------------------

EDLN11 LDA TEMP2 any data?, no
 BEQ EDLN11B

 JSR EDLN7 move cursor to first char
 JSR CENTER center text
 BCS EDLN11B problem

 LDA TEMP2
 PHA
 LDA TEMP2+1
 STA TEMP2 save new length
 JSR LSTLINE show the line
 PLA
 STA TEMP2

 LDA TEMP2+1
 CMP TEMP2
 BGE EDLN11A is new line smaller?, no
 JSR EDLN3 hack rest of line

EDLN11A LDA TEMP2+1
 STA TEMP2
EDLN11B RTS

*-------------------------------
* back up 1 char
*-------------------------------

EDLN1 CPY #0
 BEQ EDLN11B at beginning of line?, yes

 BIT NONBS destruct bs mode
 BMI EDLN13
 BVC EDLN13 unknown mode

 DEY
 JMP BSOUT do bs

*-------------------------------
* handle delete character
*-------------------------------

EDLN12 CPY #0
 BEQ EDLN11B at beginning?

 DEY  backup
 JSR BSOUT
 JMP EDLN5 delete char

EDLN13 DEY
 DEC TEMP2
 JMP PRBS

EDSTACK DB 0
EXE_DOT DB 0
SHWLN DB 0
WWRAP DB 0
WWFLAG DB -1
WWEXTRA DB 0
NONBS DB 0
VIDLEN DB 39
PROMPT DB 0
DOT_SAVE DB 0
DOT_E DB 0
QTEXT DCI 'DONE'

*-------------------------------
* easy dispatch routine [must save Y]
*-------------------------------

MATCH STA SAVE_X save match char
 STY SAVE_Y
 PLA
 STA TEMP3 get address of data-1
 PLA
 STA TEMP3+1

 LDY #1
:MATCH2 LDA (TEMP3),Y
 BEQ :MATCH4

 CMP SAVE_X
 BEQ :MATCH3

 INY  y = y + 3
 INY
 INY
 BNE :MATCH2 loop

:MATCH3 INY
 LDA (TEMP3),Y
 TAX
 INY
 LDA (TEMP3),Y
 JMP :MATCH5 do it

:MATCH4 INY  increase count
 CLC
 TYA
 ADC TEMP3 add in offset
 TAX
 LDA #0
 ADC TEMP3+1

:MATCH5 STX TEMP3 save address
 STA TEMP3+1
 LDY SAVE_Y
 LDA SAVE_X
 JMP (TEMP3) return to caller

*-------------------------------
* center a line of text
*-------------------------------

CENTER LDX #0 start index's

 LDY #-1
:CENTER2 INY
 CPY TEMP2
 BEQ :CENTER8

 LDA (TEMP),Y gobble leading spaces
 CMP #' '
 BEQ :CENTER2

:CENTER3 LDA (TEMP),Y
 STA LNBUF+128,X get data and save
 INX
 INY
 CMP #' '
 BEQ :CENTER4

 STX TEMP2+1 update length
:CENTER4 CPY TEMP2
 BNE :CENTER3 done?, no

 SEC
 LDA VIDLEN find number of spaces to add
 SBC TEMP2+1
 LSR A
:CENTER8 PHP
 LDY #0 go to beginning of line
 PLP
 SEC
 BEQ CENTER7 don't add any

 TAX
 CLC
 ADC TEMP2+1 get new total length
 STA TEMP2+1

 LDA #' '
:CENTER5 STA (TEMP),Y add in leading spaces
 INY
 DEX
 BNE :CENTER5

:CENTER6 LDA LNBUF+128,X
 STA (TEMP),Y copy data back
 INX
 INY
 CPY TEMP2+1
 BNE :CENTER6 done?, no

 CLC
CENTER7 RTS

*-------------------------------
* print small help file
*-------------------------------

DOT_HLP LDX #legaldot
 JMP PREDMSG

*-------------------------------
* input a command
*-------------------------------

GETCMD LDA #%10000000
 STA INPMODE set upper, no blank line
 JSR INPLN get input
 LDA #%10100000
 STA INPMODE upper, blanks ok
 LDA LNBUF
 BIT LOGOFF any problems?
 BPL CENTER7 no
 JMP ED_EX quit editor

*-------------------------------
* find a line number
*-------------------------------

FINDLN STX TEMP2 save line number
 STA TEMP2+1
 LDY #<EDBUF point to editor
 STY TEMP
 LDA #>EDBUF
 STA TEMP+1

:FINDLN2 LDA TEMP2 count down lines
 BNE :FNDLN2A temp2 = temp2 - 1
 DEC TEMP2+1 count down high
:FNDLN2A DEC TEMP2
 LDA TEMP2
 ORA TEMP2+1 are we done?
 BNE :FINDLN3 no

 STY TEMP
 LDX TEMP get address of line
 LDA TEMP+1
 RTS

:FINDLN3 LDA (TEMP),Y get byte
 INY
 BNE :FINDLN4
 INC TEMP+1

:FINDLN4 CMP #cr
 BNE :FINDLN3
 BEQ :FINDLN2 done?..

*-------------------------------
* get length of line
*-------------------------------

FNDLEN LDY #-1
:FNDLEN2 INY
 LDA (TEMP),Y count length of line
 CMP #cr
 BNE :FNDLEN2

 TYA
CMPSTR3 CLC  no match
 RTS

*-------------------------------
* compare data with string
*-------------------------------

CMPSTR LDY #0 start at byte 0
CMPSTR2 LDA (TEMP),Y
 INY
 JSR CONV make into upper
 EOR QTEXT,X check against exit text
 INX
 ASL A
 BNE CMPSTR3 no match
 BCC CMPSTR2 keep checking
 RTS

*-------------------------------
* handle single argument
*-------------------------------

XARG LDA EDLINE is there data?
 ORA EDLINE+1
 BEQ XYCLR no

 JSR CHKLAST

 LDA ARGPTR set up pointers
 STA TEMP3
 LDA ARGPTR+1
 STA TEMP3+1

 JSR ZNUMIN get number
 STX X_ARG save
 STA X_ARG+1

 JMP CHKRNG get legality

XYCLR SEC
 RTS

*-------------------------------
* handle arguments
*-------------------------------

XYARG LDA #<1 first pointer to 1
 STA X_ARG
 LDA #>1
 STA X_ARG+1

 JSR CHKLAST

 LDA EDLINE second pointer to last line #
 STA Y_ARG
 LDA EDLINE+1
 STA Y_ARG+1

 ORA Y_ARG check for no data
 BEQ XYCLR problem

 LDA ARGPTR point to data
 STA TEMP3
 LDA ARGPTR+1
 STA TEMP3+1

 LDY #0
 LDA (TEMP3),Y blank line?
 CMP #cr
 BEQ :XYARG7 yes
 CMP #','
 BEQ :XYARG2 check separator
 CMP #'-'
 BEQ :XYARG2

 JSR ZNUMIN get first number
 STX X_ARG
 STX Y_ARG
 STA X_ARG+1
 STA Y_ARG+1
 JSR CHKRNG
 BCS :XYARG6 out of range

 LDY #0
 LDA (TEMP3),Y any more?
 CMP #','
 BEQ :XYARG2 yes
 CMP #'-'
 BNE :XYARG5 no

:XYARG2 INC TEMP3
 BNE :XYARG4 inc pointer
 INC TEMP3+1

:XYARG4 LDA EDLINE save ending editor line
 STA Y_ARG
 LDA EDLINE+1
 STA Y_ARG+1

 LDY #0 is it xx- format?
 LDA (TEMP3),Y
 CMP #cr
 BEQ :XYARG5 yes

 JSR ZNUMIN
 STX Y_ARG save second number
 STA Y_ARG+1
 JSR CHKRNG
 BCS :XYARG6

 LDA X_ARG+1 check high byte
 CMP Y_ARG+1
 BLT :XYARG5 all is ok

 LDA Y_ARG check low byte
 CMP X_ARG
 BGE :XYARG5 if =>, ok

 SEC
 BCS :XYARG6 x_arg > y_arg

:XYARG5 CLC
:XYARG6 LDA #1 not just a return
 RTS

:XYARG7 CLC
 LDA #0 just a return
 RTS

*-------------------------------
* make sure line number is in range
*-------------------------------

CHKRNG STX SAVE_X save data
 STA SAVE_Y
 ORA SAVE_X is there a number?
 BEQ CHKRNG2 no, it's 0

 LDA EDLINE+1 check high
 CMP SAVE_Y
 BLT CHKRNG2 its out of range

 LDX EDLINE check low
 CPX SAVE_X
 BLT CHKRNG2 its out of range

 CLC  all's well
 LDA #1 clear return flag
 RTS

CHKRNG2 SEC  out of range
 RTS

*-------------------------------
* check for 'last line' reference
*-------------------------------

CHKLAST BIT EXE_DOT execing dot command?
 BPL CHKRNG2 no
 LDY #0
 LDA (ARGPTR),Y get byte
 JSR CONV
 CMP #'L'
 BNE CHKRNG2 no match, return

 PLA
 PLA
 LDX EDLINE
 STX X_ARG
 STX Y_ARG
 LDA EDLINE+1
 STA X_ARG+1
 STA Y_ARG+1
 JMP CHKRNG make sure line is legal

 RTS

*-------------------------------
* move up xarg pointer and see if were done
*-------------------------------

INCXARG LDA X_ARG done?
 CMP Y_ARG
 BNE :INCXA2 no

 LDA X_ARG+1 done?
 CMP Y_ARG+1
 BNE :INCXA2 no

 SEC  we are done
 RTS

:INCXA2 INC X_ARG
 BNE :INCXA3 move counter
 INC X_ARG+1

:INCXA3 CLC  still ok
INCXA4 RTS

*-------------------------------
* show last 3 lines
*-------------------------------

SHWLAST LDA EDLINE point to last line
 STA Y_ARG
 LDA EDLINE+1
 STA Y_ARG+1
 ORA Y_ARG
 BEQ INCXA4 no data

 SEC
 LDA Y_ARG
 SBC #2
 STA X_ARG get X line number
 TAX
 LDA Y_ARG+1
 SBC #0
 STA X_ARG+1
 JSR CHKRNG is it ok?
 BCC :SHWLST2 yes

 LDX #1
 STX X_ARG start at line 1
 DEX
 STX X_ARG+1

:SHWLST2 JMP ED_SHLN show last 3 lines...

*-------------------------------
* delete Y bytes of text
*-------------------------------

DEL_TXT STX TEMP3 save pointer
 STA TEMP3+1
DEL_TX0 STY SAVE_Y save # of chars to kill

 LDA TEMP3 save old pointer
 PHA
 LDA TEMP3+1
 PHA

:DEL_TX2 LDY SAVE_Y
 LDA (TEMP3),Y get char
 LDY #0
 STA (TEMP3),Y save char

 INC TEMP3
 BNE :DEL_TX3
 INC TEMP3+1

:DEL_TX3 CMP #0
 BNE :DEL_TX2 loop till end of editor

 PLA
 STA TEMP3+1 restore old pointer
 PLA
 STA TEMP3
DEL_TX4 RTS

*-------------------------------
* insert Y bytes of text
*-------------------------------

INS_TXT STX TEMP3 save pointer
 STA TEMP3+1
INS_TX0 STY SAVE_Y save # of chars to insert

 LDY #0
 LDA (TEMP3),Y flag last char
 ORA #hibit
 STA (TEMP3),Y

:INS_TX2 LDA (TEMP3),Y at end of data?
 BEQ :INS_TX3 yes

 INC TEMP3
 BNE :INS_TX2 move through data
 INC TEMP3+1
 BNE :INS_TX2

:INS_TX3 LDY #0
 LDA (TEMP3),Y get byte
 PHA
 LDY SAVE_Y
 AND #clrhi
 STA (TEMP3),Y move it
 PLA
 BMI DEL_TX4

 LDA TEMP3
 BNE :INS_TX4
 DEC TEMP3+1 count back
:INS_TX4 DEC TEMP3
 JMP :INS_TX3

*-------------------------------
* find end of editor
*-------------------------------

FINDEND LDA #>EDBUF point to start of editor
 STA EDPTR+1
 LDY #<EDBUF
 STY EDPTR
 STY EDLINE
 STY EDLINE+1 zero line counter

:FINDEN2 LDA (EDPTR),Y done?
 BEQ :FINDEN4 yes

 CMP #cr
 BNE :FINDEN3 end of line?, no

 INC EDLINE
 BNE :FINDEN3 inc number of lines
 INC EDLINE+1

:FINDEN3 INY
 BNE :FINDEN2
 INC EDPTR+1
 BNE :FINDEN2 search through

:FINDEN4 STY EDPTR
 RTS

*-------------------------------
* print a backspace
*-------------------------------

PRBS LDA #bs
 BIT NONBS is it a destruct bs?
 BMI PRNONBS yes

 JSR COUT print bs
 LDA #' '
 JSR COUT
BSOUT LDA #bs
PRNONBS JMP COUT do non-destruct bs

PRCRIF BIT EXE_DOT
 BPL CHKLST2 dont do it

PRCRLF LDA #cr print return
 BNE PRNONBS

*-------------------------------
* show the line number
*-------------------------------

SHOWLN LDX X_ARG print line number
 LDA X_ARG+1
 JSR DECOUT
 LDA #'>' show prompt
 JSR COUT
 JMP PRCRLF add a return

*-------------------------------
* check and see if they want to list
*-------------------------------

CHKLIST LDA LNBUF get input
 JSR CONV make upper
 CMP #'L'
 CLC
 BNE CHKLST2 they dont want to list
 LDX #list?
 JSR PREDMSG
 JSR INPLN read input

 LDA #-1
 STA SHWLN show line numbers

 JSR ED_LST1 do list
 SEC  show list done
CHKLST2 RTS

*-------------------------------
* continue message
*-------------------------------

CONT LDX #continue
 JSR PREDMSG
 LDA #0
 STA SHWLN dont show line numbers
 JSR SHWLAST show last 3 lines
 JMP FINDEND reset pointers

*-------------------------------
* ---- editor i/o routines -----
*-------------------------------

EDIN3 LDA #<EDBUF
 STA EDPTR reset pointers
 LDA #>EDBUF
 STA EDPTR+1 reset pointers
 DEC DEVCLR clear flag

*-------------------------------
* get a character from the edit buffer
*-------------------------------

EDINP BIT DEVCLR reset?
 BPL EDIN3 yes

 STY SAVE_Y save Y
 LDY #0
 LDA (EDPTR),Y
 BEQ :EDIN2 if eof

 INC EDPTR
 BNE :EDIN2 point to next byte
 INC EDPTR+1
:EDIN2 LDY SAVE_Y restore Y
 RTS

*-------------------------------
* add a character to editor buffer
*-------------------------------

EDOUT STY SAVE_Y save Y

 LDY EDPTR are we at end?
 CPY #<EBUFEND
 BNE :EDOUT2 no

 LDY EDPTR+1 at end?
 CPY #>EBUFEND
 BEQ :EDOUT3 yes

:EDOUT2 LDY #0
 STA (EDPTR),Y save byte
 INY

 PHA  save end marker
 LDA #0
 STA (EDPTR),Y
 PLA

 INC EDPTR
 BNE :EDOUT3 inc pointers to next byte
 INC EDPTR+1

:EDOUT3 LDY SAVE_Y restore and return
 RTS

SERNUM REV 'GP2140002'
SEREND

COPNOT HEX 0D0D
 REV 'GBBS Pro (C)86-2019 Kevin Smallwood V2.20n'
COPEND
 DS \
