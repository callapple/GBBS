 PAG
********************************
*                              *
*     ACOS.OBJ - Init Code     *
*                              *
********************************
 DATE
*-------------------------------

START1 JSR MOVECODE ;do memory move
 JSR FATAL ;init stuff
 JSR FATAL5 ;move file name (no return)
 JMP FATAL6

START2 JSR MOVECODE ;move memory
 JMP FATAL1 ;init w/o doing modem

*-------------------------------
* do memory move and setup
*-------------------------------

MOVECODE LDA SETRAM ;select main lc bank
 LDA SETRAM

 LDA #<ZDATA ;point to data
 STA TEMP
 LDA #>ZDATA
 STA TEMP+1

 LDA #<SYMTXT ;point to dest
 STA TEMP2
 LDA #>SYMTXT
 STA TEMP2+1

 LDY #0 ;start offset
 LDX #>END_MV+$256
:DO_IN2 LDA (TEMP),Y
 STA (TEMP2),Y ;copy byte
 INY
 BNE :DO_IN2

 INC TEMP+1
 INC TEMP2+1
 DEX
 BNE :DO_IN2 ;count down

 LDY #80
:INIT3 LDA PG3JMP,Y
 STA ENTPOINT,Y ;copy jump table into place
 DEY
 BPL :INIT3

*            LDA   #<IRQ_FIX
*            STA   IRQVECT
*            LDA   #>IRQ_FIX
*            STA   IRQVECT+1
 RTS

ZDATA ORG RAMCARD

*-------------------------------
* ----- actual tokens -----
*-------------------------------

SYMTXT DB -1 ;reserved
 DB -1 ;reserved
 DB -1 ;reserved
 DCI 'END' ;end of module
 DCI 'GOTO' ;goto statement
 DCI 'GOSUB' ;gosub statement
 DCI 'PUSH' ;push statement
 DCI 'PUBLIC' ;public directive

 DCI ':' ;colon
 DB -1 ;reserved

 DCI 'CLEAR' ;use ascii with hi-bit clear
 DCI 'LINK' ;on text, set on last char
 DCI 'HOME' ;home cmd, used wierd ways
 DCI 'PRINT' ;print statement
 DCI 'COPY' ;copy a file
 DCI 'GET' ;get a character
 DCI 'INPUT' ;input a line
 DCI 'SETINT' ;set interupt keys
 DCI 'ADDINT' ;add interupt keys
 DCI 'FLAG' ;user flags
 DCI 'NIBBLE' ;nibble function
 DCI 'BYTE' ;byte function
 DCI 'IF' ;if statement
 DCI 'THEN' ;then statement
 DCI 'ELSE' ;else statement
 DCI 'RETURN' ;return statement
 DCI 'POP' ;pop statement
 DCI 'MODEM' ;modem statement
 DCI 'LEN' ;string length
 DCI 'ECHO' ;set video echo
 DCI 'LOG' ;log to a drive
 DCI 'OPEN' ;open a file
 DCI 'CLOSE' ;close a file
 DCI 'MARK' ;get/set function
 DCI 'VAL' ;val function
 DCI 'FREE' ;free statement
 DCI 'POSITION' ;position statement
 DCI 'SET' ;set statement
 DCI 'READY' ;ready statement
 DCI 'READ' ;read statement
 DCI 'WRITE' ;write statement
 DCI 'NOT' ;not statement
 DCI 'KEY' ;key function
 DCI 'EDIT' ;edit statement
 DCI 'MSG' ;msg function
 DCI 'REWIND' ;rewind statement
 DCI 'TONE' ;tone function
 DCI 'WIDTH' ;width function
 DCI 'FOR' ;for statement
 DCI 'TO' ;to statement
 DCI 'STEP' ;step statement
 DCI 'NEXT' ;next statement
 DCI 'INSTR' ;instr function
 DCI 'KILL' ;kill statement
 DCI 'MOVE' ;move statement
 DCI 'RAM2' ;ram2 value
 DCI 'RAM' ;ram value
 DCI 'CREATE' ;create statement
 DCI 'CRUNCH' ;crunch statement
 DCI 'UPDATE' ;update statement
 DCI 'TEXT' ;text command
 DCI 'APPEND' ;append statement
 DCI 'FILL' ;fill statement
 DCI 'ON NOCAR' ;on no carrier
 DCI 'ON ERROR' ;on error
 DCI 'ERR' ;error number
 DCI 'RESUME' ;resume from error
 DCI 'INFO' ;info function
 DCI 'CLOCK' ;time function
 DCI 'USE' ;use statement
 DCI 'POKE' ;poke statement
 DCI 'PEEK' ;peek function
 DCI 'EOF' ;eof function
 DCI 'SIZE' ;size function
 DCI 'PDL' ;pdl function
 DCI 'RANDOM' ;random function
 DCI 'ASC' ;ascii function
 DCI 'CALL' ;call statement
 DCI 'STORE' ;store statement
 DCI 'RECALL' ;recall statement
 IF NET
 DCI 'LOCK' ;lock statement
 DCI 'UNLOCK' ;unlock statement
 FIN

 DCI 'CHR$' ;chr$ statement
 DCI 'DATE$' ;date statement
 DCI 'TIME$' ;time$ statement
 DCI 'FMTDATE$' ;formatted date statement
 DCI 'WHEN$' ;when$ statement
 DCI 'LEFT$' ;left$ statement
 DCI 'RIGHT$' ;right$ statement
 DCI 'MID$' ;mid$ statement
 DCI 'STR$' ;str$ statement
 DCI 'RND$' ;rnd$ function

 DCI '<>' ;<>
 DCI '><' ;><
 DCI '<=' ;<=
 DCI '>=' ;>=
 DCI '=<' ;=<
 DCI '=>' ;=>
 DCI '=' ;=
 DCI '<' ;<
 DCI '>' ;>

 DCI 'AND' ;and operand
 DCI 'OR' ;or operand
 DCI 'EOR' ;eor operand

 DCI '+' ;plus
 DCI '-' ;minus
 DCI '*' ;multiplication
 DCI '/' ;division
 DCI 'MOD' ;mod
 DCI 'ABS' ;absolute value
 DB 0

*-------------------------------
* token jump table
*-------------------------------

SYMADR DW 0 ;00
number = *-SYMADR/2
 DW DO_LET ;01
string = *-SYMADR/2
 DW DO_LET ;02
end = *-SYMADR/2
 DW DO_END ;03
goto = *-SYMADR/2
 DW DO_GOTO ;04
gosub = *-SYMADR/2
 DW DO_GSB ;05
push = *-SYMADR/2
 DW DO_PUSH ;06
public = *-SYMADR/2
 DW ERR ;07

chain = *-SYMADR/2
 DW NIL ;08
chain2 = *-SYMADR/2
 DW NIL ;09

clear = *-SYMADR/2
 DW DO_CLR ;0A
 DW DO_LINK ;0B
 DW DO_HOME ;0C
 DW DO_PRNT ;0D
 DW DO_SHOW ;0E
 DW DO_GET ;0F
 DW DO_IN ;10
 DW DO_SINT ;11
 DW DO_AINT ;12
 DW DO_FLAG ;13
 DW DO_NIB ;14
 DW DO_BYT ;15
 DW DO_IF ;16
 DW NIL ;17
else = *-SYMADR/2
 DW DO_ELSE ;18
 DW DO_RET ;19
 DW DO_POP ;1A
 DW DO_MDM ;1B
 DW DO_LEN ;1C
 DW DO_ECHO ;1D
 DW MOVNAME ;1E
 DW DO_OPEN ;1F
 DW DO_CLOS ;20
 DW DO_MARK ;21
 DW DO_VAL ;22
 DW DO_FRE ;23
 DW DO_POS ;24
 DW DO_SET ;25
 DW DO_RDY ;26
 DW DO_READ ;27
 DW DO_WRIT ;28
 DW DO_NOT ;29
key = *-SYMADR/2
 DW DO_KEY ;2A
 DW DO_EDIT ;2B
msg = *-SYMADR/2
 DW DO_MSG ;2C
 DW DO_RWD ;2D
 DW DO_TONE ;2E
 DW DO_WID ;2F
 DW DO_FOR ;30
to = *-SYMADR/2
 DW ERR ;31
step = *-SYMADR/2
 DW ERR ;32
 DW DO_NXT ;33
 DW DO_INST ;34
 DW DO_KILL ;35
 DW DO_MOVE ;36
 DW DO_RAM2 ;37
 DW DO_RAM ;38
 DW DO_MAKE ;39
 DW DO_CNCH ;3A
 DW DO_UP ;3B
 DW DO_TEXT ;3C
 DW DO_APP ;3D
 DW DO_FILL ;3E
 DW DO_NOCD ;3F
 DW DO_ONERR ;40
 DW DO_ERRNO ;41
 DW DO_RESUM ;42
 DW DO_INFO ;43
 DW DO_CLOK ;44
 DW DO_USE ;45
 DW DO_POKE ;46
 DW DO_PEEK ;47
 DW DO_EOF ;48
 DW DO_SIZE ;49
 DW DO_PDL ;4A
 DW DO_RND ;4B
 DW DO_ASC ;4C
 DW DO_CALL ;4D
 DW DO_STOR ;4E
 DW DO_RCAL ;4F
 IF NET
 DW DO_LOCK
 DW DO_UNLK
 FIN

strtyp = *-SYMADR/2
 DW DO_CHR ;50
 DW DO_DATE ;51
 DW DO_TIME ;52
 DW DO_FDATE ;53
 DW DO_WHEN ;54
 DW DO_LFT ;55
 DW DO_RGT ;56
 DW DO_MID ;57
 DW DO_STR ;58
 DW DO_RNDS ;59
compare = *-SYMADR/2
 DW CP_NOT ;5A
 DW CP_NOT ;5B
 DW CP_LTEQ ;5C
 DW CP_GTEQ ;5D
 DW CP_LTEQ ;5E
 DW CP_GTEQ ;5F
equal = *-SYMADR/2
 DW CP_EQ ;60
 DW CP_LT ;61
 DW CP_GT ;62

logic = *-SYMADR/2
 DW CP_AND ;63
 DW CP_OR ;64
 DW CP_EOR ;65

math = *-SYMADR/2
 DW DO_PLUS ;66
minus = *-SYMADR/2
 DW DO_SUB ;67
 DW DO_MULT ;68
 DW DO_DIVD ;69
 DW DO_MOD ;6A
 DW DO_ABS ;6B
 DW 0 ;6C

*-------------------------------
* system error messages
*-------------------------------

ERRMSGS DB -1
 DCI 'Starting Module Not Found'
 DCI 'Module Too Large'
 DCI 'Label Not Found'
 DCI 'Symbol Table Full'
 DCI 'Syntax Error'
 DCI 'Missing Symbol'
 DCI 'Undefined Label'
 DCI 'Missing Data'
 DCI 'Type Mismatch'
 DCI 'Overflow > 32767'
 DCI 'Division By 0'
 DCI 'String Too Long'
 DCI 'Gosub Stack Full'
 DCI 'Return Without Gosub'
 DCI 'Bad Device Number'
 DCI 'Illegal Filename'
 DCI 'For Stack Full'
 DCI 'Next Without For'
 DCI 'Link Label Not Found'
 DCI 'Message File Not Found'
 DCI 'END of Program'
 DCI 'Bad Drive Specifier'
 DCI 'Unable to Load External'
 DCI 'Unclosed quote at EOF......'

*-------------------------------
* misc. messages
*-------------------------------

MISCMSGS DB -1
 DB cr,cr
 ASC 'Sysop is on-line...'0D8D
 DB cr
 ASC 'Sysop is off-line...'0D8D
 DB cr,cr
 ASC 'Sorry, time limit exceeded'8D
 ASC '...please wait...'0D8D
 ASC '...exiting exec mode...'0D8D
 DB cr
 ASC 'Error: Help file could not be opened'8D
 DB cr
 ASC 'File Write Error'8D
 DB cr
 ASC 'One moment please...'8D

*-------------------------------
* editor messages
*-------------------------------

EDMSGS DB -1
 DB cr
 DCI 'Editing (?=Help):'
 DB cr
 ASC 'That is 4k worth'8D
 DB cr
 ASC 'Illegal Command'8D
 DB cr
 DCI 'Abort: Are you sure?'
 DB cr
 ASC 'Aborted'8D
 DB cr
 ASC 'Continue message now...'0D8D
 DB cr
 DCI 'Delete Line (L,x-y):'
 DB cr
 DCI 'Edit Line (L,x):'
 DB cr
 ASC 'Illegal line number'8D
 DB cr
 DCI 'Insert Line (L,x):'
 DB cr
 DCI 'List Line (x-y):'
 DB cr
 ASC 'Insert text:'
 DB cr
 DCI 'New: Erase and start over?'
 DB cr
 ASC 'Enter message now...'0D8D
 DB cr
 DCI 'Read File (name):'
 DB cr
 DCI 'Write File (name):'
 DB cr
 ASC 'A)bort, C)ontinue, D)elete, E)dit'0D
 ASC 'H)elp, I)nsert, L)ist, N)ew, S)ave'0D
 ASC 'Z) Space Used'8D
 ASC 'Valid editor commands: ("/commmand" and'
 ASC '".command" acceptable)'0D0D
 ASC ' A = Abort '
 ASC ' Dx-y = Delete line(s) x-y '
 ASC ' N = New'0D
 ASC ' H = Help    '
 ASC ' Ix = Insert at line x   '
 ASC ' S = Save'0D
 ASC ' Z = Space   '
 ASC ' Ex = Edit line x     '
 ASC ' Lx-y = List line(s) x-y'0D8D
 ASC ' Bytes Used.'0D8D

*-------------------------------
* compiler messages
*-------------------------------

COMPMSGS DB -1
 DCI 'One moment, compiling segment.'
 DCI '..'
 DS 32,bs
 DS 32,' '
 DS 31,bs
 DB bs+hibit

MODEBYT DB %10000011 ;default, get 1 byte only
 DB %11000001 ;upper / no blanks / no comma
 DB %10100000 ;upper and return
 DB %00100000 ;accept all and return
 DB %01100000 ;no blanks / no comma / return

INPVEC DW KEYIN ;console keyboard
 DW DISKIN1 ;disk channel 1
 DW DISKIN2 ;disk channel 2
 DW NO_INP ;console input
 DW MDMIN ;modem input
 DW NO_INP ;line printer
 DW RDMSG ;msg input
 DW RDMAIL ;read mail
 DW EDINP ;editor input
 DW NO_INP ;no input from screen
 DW RAMIN ;ram drive input

OUTVEC DW COUT ;console output
 DW DSKOUT1 ;disk channel 1
 DW DSKOUT2 ;disk channel 2
 DW VIDCOUT ;local console
 DW ZMDMOUT ;modem output
 DW PRCOUT ;line printer
 DW WRMSG ;msg output
 DW NO_OUT ;read mail [none]
 DW EDOUT ;editor output
 DW TOPPRINT ;print user stats
 DW RAMOUT ;ram drive output

JSTRCP DA ST_NOT
 DA ST_NOT
 DA ST_LTEQ
 DA ST_GTEQ
 DA ST_LTEQ
 DA ST_GTEQ
 DA ST_EQ
 DA ST_LT
 DA ST_GT

DEVTBL HEX FF0000FFFFFF0000FFFFFF
 ASC 'GP214182' ;fake serial number for peepers

* screen top mask

TOPMASK ASC '#..... ...............................  '
 ASC 'Stats: CT=.. CM=... UP=.. DL=... BP=... '
 ASC 'Ph: ............ ........ ....-******** '
 ASC 'Flg: .................................. '

DAYINDEX DB 0,3,6,9,12,15,18

DAYS ASC 'Sun'
 ASC 'Mon'
 ASC 'Tue'
 ASC 'Wed'
 ASC 'Thu'
 ASC 'Fri'
 ASC 'Sat'

MTHINDEX DB 0,3,6,9,12,15,18,21,24,27,30,33

MONTHS ASC 'Jan'
 ASC 'Feb'
 ASC 'Mar'
 ASC 'Apr'
 ASC 'May'
 ASC 'Jun'
 ASC 'Jul'
 ASC 'Aug'
 ASC 'Sep'
 ASC 'Oct'
 ASC 'Nov'
 ASC 'Dec'

TOPBUF DB 0

DUMMY = * ;standard memory allocation

 DUM DUMMY

 DS 159 ;finish up TOPBUF

GSBSTK DS $20 ;gosub stack area

FORVAR DS $10 ;for stack area
FOREND DS $10
FORSTP DS $10
FORLOC DS $10

DEVUSE DS 11

NUM DS 7
TXTNUM DS 6
FLPOS DS 6

DATA DS 4
NUMB DA 0
NEGFLG DB 0
FREMEM DB 0

NOCDFLG DB 0
NOCDVEC DA 0

ONERRFLG DB 0
ONERRVEC DA 0
FROMERR DA 0 ;where error occurred

NULLS DB 0
REMOTE DB 0

SYMNUM DB 0
LBLNUM DB 0
LNCNT DB 0
LNCNT2 DB 0
TOKTYP DB 0

CPASS DB 0

REMAIN DA 0
SIGN DB 0
RESULT DS 3

MSGREF DB 0 ;is message file ready to go?

MSGINFO DB 0 ;# of bit blocks (512k each)
 DB 0 ;# of dir blocks (32 entries each)
 DW 0 ;# of free blocks
 DW 0 ;# of files
 DW 0 ;# of newest message

MSGPTR DB 0 ;point to message data
BYTE8 DB 0 ;7 -> 8 conversion counter
CHAR8 DB 0 ;7 -> 8 conversion data
RMXBLK DW 0 ;read mail block
RDEND DB 0 ;at end of data?

MSGPTR2 DB 0 ;for write data
BYTE82 DB 0 ;second set of pointers
 DB 0 ;second char8 buffer - not needed for write
WRKBLK DW 0 ;current working write block num
WRTEND DB 0 ;at end of data?

RWDPTR DB 0 ;point to rewind data
RWDBYT8 DB 0
RWDCHR8 DB 0
RWDBLK DW 0

DIRSEG DA 0 ;current directory segment
BITSEG DB 0 ;current bit-map segment

MSGNUM DW 0 ;current message number
POSBLK DW 0 ;postion block counter

MSGINIT DB 0 ;is message currently being read?

CHATBUF DS 90 ;storage area for chat routine

LASTBYT
 DEND
 ORG
END_MV = *-ZDATA

PG3JMP ORG $380

ENTPOINT JMP GETBYT
 JMP CHKBYT
 JMP GOBCOM
 JMP INPNUM
 JMP INPSTR
 JMP MOVNAME
 JMP BADERR
 JMP SETIVEC
 JMP GET
 JMP GETCHR
 JMP INPLN
 JMP SETOVEC
 JMP COUT
 JMP DECOUT0
 JMP CREATE
 JMP OPEN
 JMP CLOSE
 JMP RDBYTE
 JMP WRBYTE
 JMP RDBLK
 JMP WRBLK
 JMP RDLINE
 JMP GETMARK
 JMP SETMARK
 JMP LOGSPEC

 DA FLNAME
REFNUM DB 0
 DA FBUF2
