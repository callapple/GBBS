 PAG
********************************
*                              *
*      ACOS.OBJ - Routine      *
*                              *
********************************
 DATE
*-------------------------------
* get a line of input
*-------------------------------

INPLNA LDA #cr ;print cr before getting line
 JSR COUT

INPLN BIT INCHAT ;in chat?
 BMI :INPLN1C ;don't bug them

 JSR CHKTIME ;is time ok?
 BCC :INPLN1A ;opps, timeout!

:INPLN1C LDY #0
:INPLN1 JSR KEYIN
 BIT DOCHAT ;do chat?
 BPL :INPLN1A ;no

 BIT INCHAT ;in chat?
 BPL :INPLN1B ;no

 RTS  ;return early

:INPLN1B LDA #can ;do we need to del line?
 CPY #0
 BNE :INPLN2 ;yep

 DEC INCHAT ;set inchat mode
 JSR DO_CHAT ;do actual chat
 JMP INPLN

:INPLN1A BIT LOGOFF ;check for no carrier/timeout
 BMI :JINPLN8

 CMP #cr
 BEQ :JINPLN6 ;return
 CMP #bs
 BEQ :INPLN2 ;back space
 CMP #can
 BEQ :INPLN2 ;ctrl-x / cancel
 CMP #del
 BNE :INPLN3 ;delete

:INPLN2 CPY #0
 BEQ :INPLN1 ;can we back up?, nope

 PHA
 JSR PRBACK ;do backspace
 DEY ;decrease char count
 PLA
 CMP #can
 BEQ :INPLN2
 BNE :INPLN1 ;if its a cancel, keep going

:INPLN3 CMP #' '
 BLT :INPLN1 ;if its a control char...

 CPY VIDLEN
 BNE :INPLN4 ;check for max length

 STA LNBUF,Y ;save last character

 LDA INPMODE
 AND #%00010000 ;do word-wrap?
 BEQ :INPLN3E ;nope

 STY TEMP ;save line length
 LDA LNBUF,Y ;get last char
 CMP #' '
 BEQ INPLNA ;all is well, just restart

 LDX #0 ;setup for inpln3b
:INPLN3A LDA LNBUF,Y ;check data
 CMP #' '
 BEQ :INPLN3B ;we found a space
 DEY
 BNE :INPLN3A ;keep checking

 LDY TEMP ;get back length
 BNE :INPLN3E ;opps, cant do word-wrap

:INPLN3B INY
 JSR PRBACK ;back up
 LDA LNBUF,Y
 STA LNBUF,X
 INX
 CPY TEMP
 BNE :INPLN3B ;loop until all bs's and data copied

 STX TEMP ;save end pointer
 LDA #cr ;start a new line
 JSR COUT

 LDY #0
:INPLN3C LDA LNBUF,Y
 JSR COUT ;print data
 INY
 CPY TEMP
 BNE :INPLN3C
 JMP :INPLN1 ;go back for more input

:JINPLN8 BMI INPLN8
:JINPLN6 BEQ :INPLN6
*:JINPLN8 BMI INPLN8

:INPLN3E LDA #7
 JSR COUT ;beep the stupid bell
 JMP :INPLN1

:INPLN4 BIT INPMODE ;do we convert?
 BPL :INPLN4A ;nope

 JSR CONV ;convert to upper

:INPLN4A BIT INPMODE ;check the inpmode
 BVC :INPLN5
 CMP #','
 BEQ :INPLN5B ;don't accept a comma
 CMP #' '
 BNE :INPLN5 ;don't accept a space
 CPY #0
 BEQ :INPLN5B ;for first char of the line

:INPLN5 STA LNBUF,Y ;save char
 INY
 BIT VIDECHO ;special echo?
 BMI :INPLN5A ;nope

 LDA VIDECHO
:INPLN5A JSR COUT ;print it
:INPLN5B JMP :INPLN1 ;loop

:INPLN6 LDA #cr
 STA LNBUF,Y ;save the return
 CPY #0
 BNE INPLN7 ;was is just a return?, nope

 LDA INPMODE ;can we accept a blank line?
 AND #%00100000
 BNE CROUT ;yep

 JMP INPLN ;don't take, cr, start over

CROUT LDA #cr
INPLN7 JMP COUT ;print the return and exit

INPLN8 LDA #cr
 STA LNBUF ;return blank line
 RTS

*-------------------------------
* print a backspace
*-------------------------------

PRBACK LDA #bs ;print bs - space - bs
 JSR COUT
 LDA #' '
 JSR COUT
 LDA #bs
 JMP COUT

*-------------------------------
* get a character
*-------------------------------

KEYIN JSR GETCHR ;get char from buffer
 BNE KEYIN5 ;(if present)

KEYIN2 LDA #"_"
 JSR VIDCOUT ;print cursor
 LDA #bs
 JSR VIDCOUT

 LDA TOVAL
 STA TIMEOUT+2 ;[32=1 minute] - 5 minutes
 LDA #0
 STA TIMEOUT+1 ;reset medium counter

 LDA #150 ;local time constant
 BIT REMOTE ;don't change anything
 BPL :KEYIN2B

 LDA #36 ;get modem time constant
:KEYIN2B STA TIMEOUT
 STA TIMEOUT+3

:KEYIN3 DEC TIMEOUT
 BNE :KEYIN3A ;count down

 LDA TIMEOUT+3
 STA TIMEOUT ;reset low-byte constant

 INC TIMEOUT+1
 BNE :KEYIN3A ;cycle 256 counter

 LDA TIMEOUT+2 ;check time
 AND #$1F ;do bell?
 BNE :KEYIN3B

 LDA #7 ;beep bell
 JSR COUT2

:KEYIN3B BIT NOCDFLG ;if no carrier vector
 BPL :KEYIN3A ;don't bother

 BIT EXEC ;check for exec user
 BMI :KEYIN3A ;skip logoff

 DEC TIMEOUT+2
 BNE :KEYIN3A ;count down minutes, still time left

 LDA #-1 ;signal logoff
 STA LOGOFF
 RTS

:KEYIN3A JSR GET ;wait for keypress
 BNE :KEYIN4 ;got one!

 BIT DOCHAT ;check chat flag
 BPL :KEYIN3

 LDA #0 ;return early
:KEYIN4 PHA
 LDA #" "
 JSR VIDCOUT ;remove cursor
 LDA #bs
 JSR VIDCOUT
 PLA
KEYIN5 RTS

TIMEOUT DS 4 ;timeout counters

*-------------------------------
* get a character -- non destructable
*-------------------------------

RDKEY JSR GETCHR ;get char from buffer
 BNE :RDKEY5 ;(if present)
 JSR VIDRDST

:RDKEY2 JSR VIDRDKY

 BIT REMOTE ;we are local
 BPL :RDKEY3

 JSR CHKTIME
 BCS :RDKEY3

 JSR VIDRDFN
 JSR MDM1_2
 LDA #-1 ;return without carrier
 STA LOGOFF
 RTS

:RDKEY3 INC MONRND
 BNE :RDKEY4 ;count down time
 INC MONRND+1

 LDA MONRND+1 ;count down high?
 AND #%00001111 ;blink?
 BEQ :RDKEY2 ;yep

:RDKEY4 JSR GET ;check for keypress
 BEQ :RDKEY3 ;nope
 JSR VIDRDFN ;put back original char

:RDKEY5 RTS

*-------------------------------
* do a screen dump
*-------------------------------

SDUMP TXA
 PHA ;save x & y
 TYA
 PHA

 LDX #0 ;start at line 0
:SDUMP2 LDY #0 ;start at char zero
:SDUMP3 JSR VIDRD ;read char from screen
 JSR PRCOUT ;print char on printer
 INY
 CPY WNDWDTH
 BNE :SDUMP3 ;at window width?

 LDA #cr ;add cr to line
 JSR PRCOUT
 INX
 CPX #24
 BNE :SDUMP2 ;at last line?, nope

 JSR PRCOUT ;add extra cr
 PLA
 TAY ;restore x & y
 PLA
 TAX
 JMP GET2 ;go back to get

GET5 LDA PWHIDE ;toggle hide password flag
 EOR #-1
 STA PWHIDE
 JMP GET6A ;show screen top

GET6 LDA WNDWDTH ;show other half of top
 CMP #80
 BEQ JGET2

 DEC TOPSEG
 BNE GET6A

 LDA #3
 STA TOPSEG

GET6A LDA WNDTOP ;show user stats
 BEQ JGET2
 JSR TOPSHOW
JGET2 JMP GET2 ;go back to get

GET7 LDA #$FF
 STA DOCHAT ;signal chat is needed
 JMP GET2 ;finish up

GET8 LDA #-1
 STA LOGOFF ;signal logoff
 RTS ;return no carrier status

GET9 LDA #$80
 STA DOCHAT ;signal exec mode is wanted
 JMP GET2

GET4 JMP SDUMP ;go to get4 (screen dump)

*-------------------------------
* scan modem / keyboard for chars
*-------------------------------

GET INC RND
 BNE :GET0 ;setup random seed
 INC RND+1

:GET0 JSR VIDKEY ;check local keyboard
 BPL GET2 ;nope

 AND #clrhi
 STA LASTIN ;last char from local
 STA KBDSTRB ;get char
 CMP #execon
 BEQ GET9 ;exec mode?
 CMP #logout
 BEQ GET8 ;quick logoff?
 CMP #chat
 BEQ GET7 ;chat?
 CMP #revtop
 BEQ GET6
 CMP #toglpw
 BEQ GET5
 CMP #prnscr
 BEQ GET4 ;print screen?
 CMP #bartog
 BNE GET3 ;toggle bottom bar?

 BIT SHWTXT ;go into program trace mode?
 BMI GET8A ;yep

 BIT SHWTRC ;exit program trace mode?
 BPL :NO8B
 JMP GET8B ;yep

:NO8B DEC SHWTXT ;show user input

 TYA
 PHA
 LDY CV
 CPY #22
 BLT :GET1A ;do we need to scroll?, nope
 DEY ;move cursor up 2 lines
 DEY
 STY CV ;save new cursor position
 JSR VIDSCRL ;scroll data
 JSR VIDSCRL

:GET1A LDA #23
 JSR SVCHCV ;save current horiz / very position

 JSR PR ;print message
 ASC 'INP:'00

 JSR LDCHCV ;restore position
 DEC WNDBTM ;shorten screen
 DEC WNDBTM
 PLA
 TAY

GET2 LDA #0 ;no data
 BIT REMOTE ;check modem?
 BPL GET3B ;nope

 JSR CHKDCD ;is there carrier?
 BCC GET3B ;nope!

 JSR MDMIN ;check modem
 BCC GET3B ;no data

 ROR LASTIN ;put carry [set] into high bit
 AND #clrhi ;strip high bit

GET3 BIT SHWTXT ;show input?
 BPL GET3B ;nope

 PHA
 ORA #hibit
 CMP #" "
 BGE :GET3A ;is it a control?, nope

 PHA
 LDA #"^" ;show control lead-in
 JSR VIDBAN
 PLA
:GET3A JSR VIDBAN
 PLA

GET3B CMP #0 ;set status
 RTS

GET8A INC SHWTXT ;select program trace
 DEC SHWTRC

 TYA
 PHA ;save Y
 LDA #23
 JSR SVCHCV ;save current horiz / vert

 JSR PR ;print message
 ASC 'PRG:'00

 JSR LDCHCV ;restore position
 PLA
 TAY ;restore Y
 JMP GET2

GET8B JSR SVCHCV
 INC SHWTRC ;select nothing
 INC WNDBTM ;select bottom 2 lines
 INC WNDBTM
 TYA
 PHA
 TXA
 PHA
 JSR VIDLST ;clear line 24
 JSR LDCHCV
 PLA
 TAX
 PLA
 TAY
 JMP GET2

INPMODE DB 0
SHWTXT DB 0 ;show users input
SHWTRC DB 0 ;show program trace

*-------------------------------
* save current ch / cv
*-------------------------------

SVCHCV PHA
 LDA CH
 STA OLDCH ;save old values
 LDA CV
 STA OLDCV

 LDA #0
 STA CH ;position to 0,[inparg]
 PLA
 STA CV
 RTS

*-------------------------------
* restore old ch / cv
*-------------------------------

LDCHCV TXA
 PHA ;save both x & y
 TYA
 PHA
 LDX OLDCH ;position
 LDY OLDCV
 JSR VIDPOS
 PLA
 TAY
 PLA
 TAX
 RTS

*-------------------------------
* get a program byte
*-------------------------------

GETRAW STY SAVE_Y
 LDY #0
 LDA (PRGPTR),Y ;get byte
 INC PRGPTR
 BNE :GETRAW2 ;inc pointers
 INC PRGPTR+1

:GETRAW2 LDY SAVE_Y
 RTS

*-------------------------------
* get a byte, test for text
*-------------------------------

GETBYT JSR GETRAW ;get raw data
 CMP #"""
 BNE :GETBYT3 ;is it text?, nope

 PHA
 EOR LSTTXT ;toggle text mode
 STA LSTTXT
 PLA

:GETBYT3 BIT SHWTRC ;show trace?
 BPL :GETBYT4

 JSR LIST ;show trace

:GETBYT4 CMP #0 ;set flags
 RTS

*-------------------------------
* check current program byte
* get program byte but
* dont inc pointers
*-------------------------------

CHKBYT STY SAVE_Y
 LDY #0
 LDA (PRGPTR),Y
 LDY SAVE_Y
 CMP #0 ;set flags
GOBBLE2 RTS

*-------------------------------
* gobble an equal's
*-------------------------------

GOBEQU LDX #equal
 BNE GOBBLE

*-------------------------------
* gobble a comma
*-------------------------------

GOBCOM LDX #","
GOBBLE STX GOBBYT ;save byte
 JSR GETBYT ;get data
 CMP GOBBYT
 BEQ GOBBLE2 ;all is well

 LDX #syntax
 JMP BADERR ;syntax error

GOBBYT DB 0

*-------------------------------
* increment temp
*-------------------------------

INCTMP INC TEMP
 BNE :INCTMP ;increment temp by 1
 INC TEMP+1
:INCTMP RTS

*-------------------------------
* check carrier
*-------------------------------

CHKDCD SEC
 BIT NOCDFLG ;bother to check?
 BPL :CHKDCD2 ;nope

 BIT REMOTE ;are we remote?
 BPL :CHKDCD2

 JSR MDMDCD ;is there carrier?
 BCS :CHKDCD2 ;yep

 JSR MDM1_2 ;hang up user
 LDA #-1 ;signal logoff needed
 STA LOGOFF
 CLC ;no carrier!
:CHKDCD2 RTS

*-------------------------------
* check for timeout (total time online)
*-------------------------------

CHKTIME BIT NOCDFLG ;bother to check?
 BPL :CHKTM5 ;nope

 BIT LOGOFF ;in logoff mode already?
 BMI :CHKTM4 ;yep

 LDA TIMEON ;is there a limit?
 ORA TIMEON+1
 BEQ :CHKTM5 ;nope

 JSR SECON ;get time on

 CMP TIMEON+1 ;check low byte
 BEQ :CHKTM2
 BGE :CHKTM3
 BLT :CHKTM5

:CHKTM2 CPX TIMEON
 BLT :CHKTM5 ;check low, all is well

:CHKTM3 LDX #timeup
 JSR PRMSG
 LDA #-1
 STA LOGOFF
:CHKTM4 CLC ;no carrier / timeout
 RTS

:CHKTM5 SEC ;all is well
 RTS

*-------------------------------
* is byte a letter? clc=yep, sec=nope
*-------------------------------

TST_ALF PHA
 JSR CONV ;change to uppercase
 CMP #'A'
 BLT :TST_AL2

 CMP #'Z'+1
 BLT :TST_AL3

:TST_AL2 SEC
:TST_AL3 PLA
 RTS

*-------------------------------
* is byte a number? clc=yep, sec=nope
*-------------------------------

TST_NUM PHA
 AND #clrhi ;strip high bit
 CMP #'0'
 BLT :TST_NM2

 CMP #'9'+1
 BLT :TST_NM3

:TST_NM2 SEC
:TST_NM3 PLA
 RTS

*-------------------------------
* convert lower to upper and clear high bit
*-------------------------------

CONV AND #clrhi ;strip high bit
 CMP #'a'
 BLT CONV2

 CMP #'z'+1
 BGE CONV2

 SBC #$1F ;since carry is clear, -$20
CONV2 RTS

*-------------------------------
* output byte in A
*-------------------------------

COUT BIT INTOUT ;output interrupt?
 BMI CONV2 ;skip
 STA SAVE_X

 JSR GET ;check for a char
 BEQ COUT1B

 CMP #xoff
 BNE COUT0 ;check for ctrl-s

 JSR KEYIN2 ;get a char
 JMP COUT1B

COUT0A JSR KEYIN2 ;check for serial # show access
 CMP #pass
 BNE COUT0C

 JSR CHK4SN

COUT0C JMP COUT1B ;dont check for int

COUT0 BIT INTBUF ;see if int's enabled
 BPL COUT1A ;nope

 PHA
 JSR CONV ;convert to upper
 STA COUT1+1 ;point to parm [0-127]
 PLA
COUT1 BIT INTBUF ;*** self-modified
 BPL COUT1A

 LDA #0
 STA INTBUF ;no more int's
 DEC INTOUT ;turn on output interupt

 LDA #cr ;was last char a cr?
 CMP LASTCHR
 BEQ COUT1C ;nope

 JSR COUT2 ;print cr

COUT1C LDA COUT1+1
 STA INTCHR ;get converted byte
 BIT INTBUF+127 ;special flag for (ctrl-x,ctrl-n)
 BMI COUT3

COUT1A JSR PUTCHR ;save char in buffer

COUT1B LDA SAVE_X

COUT2 CMP #0
 BEQ COUT3 ;any data?, nope
 STA LASTCHR
 BIT REMOTE ;remote call?
 BPL :COUT2M ;nope

 JSR MDMOUT
 CMP #cr
 BNE :COUT2M

 LDA #lf
 JSR MDMOUT
 LDA NULLS ;add nulls?
 BEQ :COUT2N ;nope
 STX SAVE_X ;save x
 TAX
 LDA #0
]LOOP JSR MDMOUT ;send a null
 DEX
 BNE ]LOOP
 LDX SAVE_X ;restore x

:COUT2N LDA #cr
:COUT2M CMP #bel
 BEQ :DOIT

 CMP #ff
 BEQ :DO_CLS
 JMP VIDCOUT

:DO_CLS STX SAVE_X
 STY SAVE_Y
 JSR VIDCLS
 LDX SAVE_X
 LDY SAVE_Y
 RTS

:DOIT BIT LASTIN
 BMI COUT3
 JMP DO_BELL

COUT3 RTS

INTCHR DB 0

*-------------------------------
* save character in input buffer
*-------------------------------

PUTCHR CMP #clb
 BEQ CLRBUF ;clear the buffer?, yep

 STX BUF_X ;save X
 LDX TYPIN ;any room?
 STA TYPBUF,X ;save data
 INX
 BPL :PUTCHR1 ;all is well

 LDX #0 ;reset pointer
:PUTCHR1 CPX TYPOUT
 BEQ :PUTCHR2 ;overflow?, yep

 STX TYPIN ;save pointer
 LDX BUF_X ;restore X
 RTS

:PUTCHR2 LDX BUF_X ;restore X
 PHA
 LDA #7
 PLA
 RTS

*-------------------------------
* clear the input buffer
*-------------------------------

CLRBUF PHA
 LDA #0
 STA TYPIN ;zero pointers
 STA TYPOUT
 PLA
 RTS

*-------------------------------
* get a character from the input buffer
*-------------------------------

GETCHR LDA #0 ;default to no input
 STX BUF_X
 LDX TYPOUT ;get pointer
 CPX TYPIN
 BEQ :GETCHR2 ;any data?, nope

 LDA TYPBUF,X ;get character
 INX
 BPL :GETCHR1 ;inc pointer, still in range?

 LDX #0 ;reset pointer
:GETCHR1 STX TYPOUT ;update
:GETCHR2 LDX BUF_X ;restore X
 CMP #0
 RTS

*-------------------------------
* print user stats at top of screen
*-------------------------------

TOPPRINT STX SAVE_X
 PHA
 LDX TOPSEGNO
 CMP #'M'-ctrl
 BEQ :TOPPR2
 CMP #","
 BNE PRTOPL3
:TOPPR2 DEX
:TOPPR3 INX
 LDA TOPBUF,X
 BEQ PRTOPL2
 CMP #'.'
 BEQ :TOPPR4
 CMP #'*'
 BNE :TOPPR5

:TOPPR4 LDA #' '
 STA TOPBUF,X
 BNE :TOPPR3

:TOPPR5 PLA

PRTOPLN PHA
:PRTOPL1 INX
 LDA TOPBUF,X
 BEQ PRTOPL2
 CMP #'.'
 BEQ PRTOPL2
 CMP #'*'
 BNE :PRTOPL1

PRTOPL2 STX TOPSEGNO
 PLA
 LDX SAVE_X
 RTS

PRTOPL3 PLA
 AND #clrhi
 PHA
 LDA TOPBUF,X
 BEQ PRTOPL5
 CMP #'.'
 BEQ :PRTOPL4
 CMP #'*'
 BNE PRTOPL5
 PLA
 ORA #hibit
 PHA
:PRTOPL4 PLA
 STA TOPBUF,X
 INC TOPSEGNO
 LDX SAVE_X
 RTS

PRTOPL5 PLA
 LDX SAVE_X
 RTS

CLRTOP STX SAVE_X
 PHA
 LDX #1
 STX TOPSEG
 DEX
 STX TOPSEGNO

 LDY #160
:CLRTOP2 LDA TOPMASK,X
 STA TOPBUF,X
 INX
 DEY
 BNE :CLRTOP2

 LDX #$FF
 JSR PRTOPLN
 PLA
 LDX SAVE_X
 RTS

TOPSEGNO DB 0

TOPSHOW TYA
 PHA
 LDA #1
 JSR SVCHCV
 LDY #0
 JSR SHOWLINE
 LDY TOPSEG
 JSR SHOWLINE

 LDA WNDWDTH
 CMP #80
 BNE :TOP2

 LDY #2
 JSR SHOWLINE
 LDY #3
 JSR SHOWLINE

:TOP2 PLA
 TAY
 JMP LDCHCV

SHOWLINE TXA
 PHA
 DEC INVFLG
 LDX TOPSEGS,Y
 LDY #40

:SHOW1 LDA TOPBUF,X
 BPL :SHOW2
 BIT PWHIDE
 BPL :SHOW2
 LDA #'*'
:SHOW2 JSR VIDCOUT
 INX
 DEY
 BNE :SHOW1

 INC INVFLG
 PLA
 TAX
 RTS

TOPSEGS DB 0,40,80,120

TOPSEG DB 1

*-------------------------------
* jsr pr data 0 -- quick print routine
*-------------------------------

PR PLA
 STA PRN ;save calling address
 PLA
 STA PRN+1
 TYA
 PHA ;save Y

:PR2 INC PRN
 BNE :PR3 ;get next byte
 INC PRN+1

:PR3 LDY #0
 LDA (PRN),Y ;get byte
 BEQ :PR6 ;we're done
 BMI :PR4 ;if high bit set use banner print

 JSR VIDCOUT ;otherwise use normal
 JMP :PR5

:PR4 JSR VIDBAN ;print it
:PR5 JSR PAUSE
 JMP :PR2

:PR6 INC PRN
 BNE :PR7 ;inc for return
 INC PRN+1

:PR7 PLA
 TAY ;restore Y
 JMP (PRN)

*-------------------------------
* execute a token
*-------------------------------

EX_TOK PHP
 ROR IMMDEF ;save execution status
 ASL ;a = a * 2
 BCS :EX_TOK2 ;opps, not a token!
 TAY ;move to index
 LDA SYMADR,Y
 STA TEMP
 LDA SYMADR+1,Y
 STA TEMP+1
 PLP ;restore run state
 JMP (TEMP) ;exec command

:EX_TOK2 PLP ;remove from stack
 LDX #seg2big
 JMP BADERR ;syntax error

*-------------------------------
* show an error message
*-------------------------------

SHERR JSR ERROR ;show error message
 LDA #'>'
 JSR VIDCOUT
 LDA LNCNT
 PHA
 LDX #0 ;reset line count
:SHERR2 LDA LNBUF,X ;print line
 INX
 JSR VIDCOUT
 CMP #cr
 BNE :SHERR2
 PLA
 STA LNCNT
 RTS

*-------------------------------
* print an error message
*-------------------------------

ERROR STX SAVE_X
 CPX #0
 BEQ ERROR2 ;error?, nope
 LDA #cr
 JSR VIDCOUT
 JSR VIDCOUT
 LDA #<ERRMSGS ;point to error messages
 STA PRN
 LDA #>ERRMSGS
 STA PRN+1
 LDX SAVE_X
 JSR PRMSG2
 LDA #cr ;print cr/lf
 JSR VIDCOUT
 LDX SAVE_X
ERROR2 RTS

*-------------------------------
* print an editor message
*-------------------------------

PREDMSG LDA #<EDMSGS ;point to editor messages
 STA PRN
 LDA #>EDMSGS
 STA PRN+1
 JMP PRMSG2

*-------------------------------
* print compiler messages
*-------------------------------

PRCMPMSG LDA #<COMPMSGS ;point to compiler messages
 STA PRN
 LDA #>COMPMSGS
 STA PRN+1
 JMP PRMSG2

*-------------------------------
* print misc messages
*-------------------------------

PRMSG LDA #<MISCMSGS ;point to misc messages
 STA PRN
 LDA #>MISCMSGS
 STA PRN+1

*-------------------------------
* print error messages
*-------------------------------

PRMSG2 LDY #0 ;get data
:PRMSG3 LDA (PRN),Y
 INY
 BNE :PRMSG4 ;move pointers
 INC PRN+1
:PRMSG4 ASL ;done?
 BCC :PRMSG3 ;nope

 DEX
 BNE :PRMSG3 ;done?, nope

:PRMSG5 LDA (PRN),Y ;get data
 PHP
 AND #clrhi
 JSR COUT ;show char
 INY
 BNE :PRMSG6
 INC PRN+1
:PRMSG6 PLP
 BPL :PRMSG5 ;end, nope, loop
 RTS

*-------------------------------
* get next type of input
*-------------------------------

INPTYP LDY #0
 LDA (PRGPTR),Y ;get current program byte
 BPL :INPTYP3 ;if some sort of token

 LDX #1
 CMP #"("
 BEQ :INPTYP2 ;is it an expression

 INX
 CMP #"""
 BEQ :INPTYP2 ;is it data?

 INX
 JSR TST_NUM ;is it a number?
 BCC :INPTYP2 ;yep

:INPTYP1 INX
:INPTYP2 TXA
 RTS

:INPTYP3 LDX #6
 CMP #number
 BEQ :INPTYP2 ;is it a var number?

 DEX
 CMP #string
 BEQ :INPTYP2 ;is it a var string?

 LDX #0
 CMP #chain
 BEQ :INPTYP2 ;is it a statement separator?
 CMP #chain2 ;is it an eol (chain2)?
 BEQ :INPTYP2
 BNE :INPTYP1 ;must be a token

*-------------------------------
* translate a binary to text [0-99]
*-------------------------------

BINDEC8 LDY #0 ;start 10's counter
:BIN8A CMP #10
 BLT :BIN8B ;less than 10, were done

 SBC #10 ;minus 10
 INY
 BNE :BIN8A ;add 1 to the 10's counter, loop

:BIN8B ORA #'0' ;make 1's into text
 TAX ;save
 TYA
 ORA #'0' ;make 10's into text
 RTS  ;done

*-------------------------------
* decimal output without negative translation
*-------------------------------

DECOUT0 STX NUM ;save number
 STA NUM+1
 JMP DECOUT1 ;do normal output

*-------------------------------
* display a decimal number [-32767 to +32767]
*-------------------------------

DECOUT PHA ;save status
 JSR DO_ABS1 ;make positive
 STX NUM ;save number
 STA NUM+1
 PLA
 BPL DECOUT1 ;display negative sign?

 LDA #'-' ;show it is negative
 JSR DO_OUT

DECOUT1 LDA #0
 STA NUM+2
 STA NUM+3
 STA NUM+5
 STA NUM+6
 SED

 LDY #16 ;use decimal mode
:DECOUT2 ASL NUM
 ROL NUM+1
 LDA NUM+2
 ADC NUM+2
 STA NUM+2 ;do actual 'woz' conversion
 LDA NUM+3
 ADC NUM+3
 STA NUM+3 ;do actual 'woz' conversion
 ROL NUM+4
 DEY
 BNE :DECOUT2 ;loop down

 CLD ;done with decimal
 LDY #4 ;print 5 digits

:DECOUT3 LDA NUM+4 ;get digit
 AND #$F
 BNE :DECOUT4 ;is it zero?

 BIT NUM+5 ;is this a leading zero?
 BPL :DECOUT5 ;yep

:DECOUT4 DEC NUM+5
 ORA #'0' ;print digit
 LDX NUM+6
 STA TXTNUM+1,X ;save number to memory
 INC NUM+6
 JSR DO_OUT

:DECOUT5 LDX #3 ;move up next digit
:DECOUT6 ASL NUM+1
 ROL NUM+2
 ROL NUM+3
 ROL NUM+4
 DEX
 BPL :DECOUT6

 DEY
 BMI :DECOUT7
 BNE :DECOUT3 ;count down digits

 STX NUM+5 ;print last zero for sure
 BPL :DECOUT3
:DECOUT7 LDA NUM+6
 STA TXTNUM ;save number length
 RTS

*-------------------------------
* input a number from memory of from program [0-65535]
*-------------------------------

NUMIN LDA #0 ;zero totals
 STA NUM
 STA NUM+1
 STA NEGFLG

 JSR CHKBYT ;is this negative?
 CMP #minus
 BNE NUMIN2 ;nope
 DEC NEGFLG ;flag as neg
 JSR GETBYT ;skip the -

NUMIN2 JSR CHKBYT ;get digit
 BPL NUMIN4

 JSR TST_NUM
 BCS NUMIN4

 JSR GETBYT ;get digit
 JSR XNUMIN ;process
 JMP NUMIN2 ;loop

NUMIN4 LDX NUM ;get the value
 LDA NUM+1
 BIT NEGFLG ;was it negative?
 BPL :POS ;nope

 JSR NEGXA ;invert it
:POS RTS

*-------------------------------
* process digit
*-------------------------------

XNUMIN AND #$F ;make into range 0..9
 STA NUM+2
 LDA #0
 STA NUM+3

 LDX #10 ;(num+2) = (num+2)+(num*10)
:XNUMIN3 CLC
 LDA NUM
 ADC NUM+2
 STA NUM+2
 LDA NUM+1
 ADC NUM+3
 STA NUM+3
 DEX
 BNE :XNUMIN3 ;num = num * 10

 LDA NUM+2
 STA NUM ;move new total
 LDA NUM+3
 STA NUM+1
 RTS ;keep going

*-------------------------------
* input a number from a pointer
*-------------------------------

ZNUMIN LDA #0 ;zero totals
 STA NUM
 STA NUM+1
 STA NEGFLG

 LDY #0
 LDA (TEMP3),Y ;is this negative?
 CMP #'-'
 BNE :ZNUMIN2 ;nope
 DEC NEGFLG ;flag as neg
 INC TEMP3 ;skip the -
 BNE :ZNUMIN2
 INC TEMP3+1

:ZNUMIN2 LDY #0
 LDA (TEMP3),Y ;get char
 JSR TST_NUM
 BCS NUMIN4 ;we're done

 INC TEMP3
 BNE :ZNUMIN3
 INC TEMP3+1

:ZNUMIN3 JSR XNUMIN ;process digit
 JMP :ZNUMIN2 ;loop

*-------------------------------
* show the program as it runs
*-------------------------------

LIST PHA
 STA LSTNUM ;save all registers
 TXA
 PHA
 TYA
 PHA

 LDA LSTNUM
 LDX LSTVAR ;are we showing a variable?
 BNE :LIST10 ;yep

 LDX LSTTXT ;are we in text mode?
 BNE :LIST11 ;yep

 CMP #0
 BMI :LIST11 ;is it a token?, nope

 LDX #"$"
 CMP #string
 BEQ :LIST3 ;is it a string?, nope

 LDX #"#"
 CMP #number
 BEQ :LIST3 ;is it a number?, nope

 CMP #chain2
 BEQ :LIST13 ;is it a statement link?, nope

 CMP #0
 BPL :LIST4 ;is it a token?, yes

:LIST11 ORA #hibit ;display text
 JSR VIDBAN

 JSR PAUSE
 PLA
 TAY ;restore & return
 PLA
 TAX
 PLA
 RTS

:LIST3 LDY #2 ;setup to show next 2 variable
 STY LSTVAR ;bytes
 TXA
 JMP :LIST11

:LIST10 DEC LSTVAR ;count down display time
 JMP :LIST11

:LIST4 TAX
 LDY #0
 LDA #<SYMTXT
 STA LSTPTR
 LDA #>SYMTXT
 STA LSTPTR+1
 DEX

:LIST5 LDA (LSTPTR),Y
 INY
 BNE :LIST5A ;goto next byte

 INC LSTPTR+1
:LIST5A ASL ;we done?
 BCC :LIST5 ;nope
 DEX
 BPL :LIST5 ;keep going

:LIST6 LDA (LSTPTR),Y ;get data
 PHA

 ORA #hibit ;display it
 JSR VIDBAN

 INY
 BNE :LIST6A ;inc pointers
 INC LSTPTR+1
:LIST6A PLA
 BPL :LIST6

 LDA LSTNUM ;check for tokens that use a label
 CMP #goto
 BEQ :LIST13
 CMP #push
 BEQ :LIST13
 CMP #gosub
 BNE :LIST8B

:LIST13 LDA #":" ;also do chain statement
 JSR VIDBAN

:LIST8B LDA #" "
 JMP :LIST11

LSTNUM DB 0
LSTVAR DB 0

*-------------------------------
* check to see if pause should go into effect
*-------------------------------

PAUSE JSR VIDKEY ;check local keyboard
 CMP #"Z"-ctrl
 BEQ :PAUSE1
 CMP #'Z'-ctrl
 BNE :PAUSE3

:PAUSE1 STA KBDSTRB
:PAUSE2 JSR GET ;wait for a keypress
 BEQ :PAUSE2
:PAUSE3 RTS

*-------------------------------
* repeat and print a character
*-------------------------------

PRCHR JSR VIDCOUT
 DEX
 BNE PRCHR
 RTS

*-------------------------------
* standard Apple beep
*-------------------------------

DO_BELL PHA
 TYA
 PHA
 LDY #$B0
:BELL2 LDA #$C
 JSR WAIT
 LDA SPKR
 DEY
 BNE :BELL2
 PLA
 TAY
 PLA
 RTS

*-------------------------------
* copy of monitor wait routine
*-------------------------------

WAIT SEC
:WAIT2 PHA
:WAIT3 SBC #1
 BNE :WAIT3
 PLA
 SBC #1
 BNE :WAIT2
 RTS

*-------------------------------
* save current line into buffer
*-------------------------------

SVLINE LDX CV
 LDY WNDWDTH
 DEY
:SVLINE2 JSR VIDRD ;read character
 STA CHATBUF+2,Y
 DEY
 BPL :SVLINE2 ;save entire line

 LDA CH
 STA CHATBUF ;save current ch position
 LDA INPMODE
 STA CHATBUF+1 ;save current input mode
 RTS

*-------------------------------
* restore current line in buffer
*-------------------------------

RSTLINE LDX CHATBUF ;get length
 BEQ :RSTLN3 ;no data

 LDY #0
:RSTLN2 LDA CHATBUF+2,Y
 JSR COUT ;print line
 INY
 DEX
 BNE :RSTLN2

:RSTLN3 LDA CHATBUF+1
 STA INPMODE
 RTS

*-------------------------------
* set exec mode to verify users, etc...
*-------------------------------

DO_EXEC LDA #2
 JSR VIDCHAT ;show exec on message

 LDA EXEC
 STA OLDEXEC ;save old status
 LDA REMOTE
 STA OLDRMT

 LDA #$FF
 STA EXEC ;set exec mode on

 LDX #hangon ;show ...please wait... msg
 JSR PRMSG

 LDA #0
 STA REMOTE ;set to local input/output mode
 STA DOCHAT ;reset chat flag
 STA INCHAT ;no actually in chat
 JMP RSTLINE ;restore copy of line

EXEC2 LDA #0 ;get rid of exec mode flag
 JSR VIDCHAT

 LDX #exitexec ;print ...exiting.. msg
 JSR PRMSG

 LDA OLDEXEC
 STA EXEC ;restore exec state
 LDA OLDRMT
 STA REMOTE ;restore remote state

 JSR RSTLINE ;put back extra

 BIT DOCHAT ;check chat mode
 BVS CHAT2 ;go directly into chat

 LDA #0
 STA DOCHAT ;reset all modes
 STA INCHAT
 RTS

OLDEXEC DB 0
OLDRMT DB 0

*-------------------------------
* chat with user routine
*-------------------------------

DO_CHAT JSR SVLINE ;save current line
 BIT EXEC ;exit exec mode
 BVS EXEC2

 BIT DOCHAT
 BVC DO_EXEC ;opps, we really want exec mode

CHAT2 LDX #sysopon ;sysop online msg
 JSR PRMSG
 LDA #$30
 STA INPMODE ;accept u/l, cr, word-wrap, etc
 LDA #0
 STA DOCHAT ;reset chat
 JSR VIDCHAT ;turn off chat message

:CHAT4 JSR INPLN ;get a line of type
 BIT LOGOFF
 BMI :CHAT6

 BIT DOCHAT ;exit?
 BPL :CHAT4 ;nope

 LDX #sysopoff ;sysop offline msg
 JSR PRMSG
 JSR RSTLINE ;restore line

 BIT DOCHAT ;do they want to exec?
 BVS :CHAT6
 JMP DO_EXEC ;yep

:CHAT6 LDA #0
 STA DOCHAT ;clear chat flag
 STA INCHAT
 RTS

*-------------------------------
* handle ram drive input
*-------------------------------

RAMIN STY SAVE_Y
 LDA #0 ;default to no data
 LDY RAMPTR ;get pointer
 BMI :RAMIN2 ;opps, out of range

 LDA RAMDRV,Y ;get data
 INC RAMPTR ;move pointer
:RAMIN2 LDY SAVE_Y
 RTS ;we are done

*-------------------------------
* handle ram drive output
*-------------------------------

RAMOUT STY SAVE_Y
 LDY RAMPTR ;is pointer in range?
 BMI :RAMOUT2 ;nope

 STA RAMDRV,Y ;save data
 INC RAMPTR ;move pointer
:RAMOUT2 LDY SAVE_Y
 RTS

*-------------------------------
* setup input vector
*-------------------------------

SETIVEC TYA
 ASL
 TAX
 LDA INPVEC,X
 STA VECTOR2
 LDA INPVEC+1,X
 STA VECTOR2+1
 RTS

*-------------------------------
* setup output vector
*-------------------------------

SETOVEC TYA
 ASL
 TAX
 LDA OUTVEC,X
 STA VECTOR
 LDA OUTVEC+1,X
 STA VECTOR+1
 RTS

*-------------------------------
* send to modem only
*-------------------------------

ZMDMOUT JSR MDMOUT ;send data
 CMP #cr ;add LF to CR?, nope
 BNE :ZMDM2

 LDA #lf ;send LF
 JSR MDMOUT
 LDA #cr ;set back to CR
:ZMDM2 RTS
