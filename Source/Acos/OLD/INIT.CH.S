 PAG
********************************
*                              *
*     ACOS.OBJ - Init Code     *
*                              *
********************************
 DATE
*-------------------------------

START1 JSR MOVECODE do
 JSR FATAL init
 JSR FATAL5 move
 JMP FATAL6

START2 JSR MOVECODE move
 JMP FATAL1 init

*-------------------------------
* do memory move and setup
*-------------------------------

MOVECODE LDA SETRAM select
 LDA SETRAM

 LDA #<ZDATA point
 STA TEMP
 LDA #>ZDATA
 STA TEMP+1

 LDA #<SYMTXT point
 STA TEMP2
 LDA #>SYMTXT
 STA TEMP2+1

 LDY #0 start
 LDX #>END_MV+$256
:DO_IN2 LDA (TEMP),Y
 STA (TEMP2),Y copy
 INY
 BNE :DO_IN2

 INC TEMP+1
 INC TEMP2+1
 DEX
 BNE :DO_IN2 count

 LDY #80
:INIT3 LDA PG3JMP,Y
 STA ENTPOINT,Y copy
 DEY
 BPL :INIT3
 LDA #<IRQ_FIX
 STA IRQVECT
 LDA #>IRQ_FIX
 STA IRQVECT+1
 RTS

ZDATA ORG RAMCARD

*-------------------------------
* ----- actual tokens -----
*-------------------------------

SYMTXT DB -1 reserved
 DB -1 reserved
 DB -1 reserved
 DCI 'END' end
 DCI 'GOTO' goto
 DCI 'GOSUB' gosub
 DCI 'PUSH' push
 DCI 'PUBLIC' public

 DCI ':' colon
 DB -1 reserved

 DCI 'CLEAR' use
 DCI 'LINK' on
 DCI 'HOME' home
 DCI 'PRINT' print
 DCI 'COPY' copy
 DCI 'GET' get
 DCI 'INPUT' input
 DCI 'SETINT' set
 DCI 'ADDINT' add
 DCI 'FLAG' user
 DCI 'NIBBLE' nibble
 DCI 'BYTE' byte
 DCI 'IF' if
 DCI 'THEN' then
 DCI 'ELSE' else
 DCI 'RETURN' return
 DCI 'POP' pop
 DCI 'MODEM' modem
 DCI 'LEN' string
 DCI 'ECHO' set
 DCI 'LOG' log
 DCI 'OPEN' open
 DCI 'CLOSE' close
 DCI 'MARK' get/set
 DCI 'VAL' val
 DCI 'FREE' free
 DCI 'POSITION' position
 DCI 'SET' set
 DCI 'READY' ready
 DCI 'READ' read
 DCI 'WRITE' write
 DCI 'NOT' not
 DCI 'KEY' key
 DCI 'EDIT' edit
 DCI 'MSG' msg
 DCI 'REWIND' rewind
 DCI 'TONE' tone
 DCI 'WIDTH' width
 DCI 'FOR' for
 DCI 'TO' to
 DCI 'STEP' step
 DCI 'NEXT' next
 DCI 'INSTR' instr
 DCI 'KILL' kill
 DCI 'MOVE' move
 DCI 'RAM2' ram2
 DCI 'RAM' ram
 DCI 'CREATE' create
 DCI 'CRUNCH' crunch
 DCI 'UPDATE' update
 DCI 'TEXT' text
 DCI 'APPEND' append
 DCI 'FILL' fill
 DCI 'ON NOCAR' on
 DCI 'ON ERROR' on
 DCI 'ERR' error
 DCI 'RESUME' resume
 DCI 'INFO' info
 DCI 'CLOCK' time
 DCI 'USE' use
 DCI 'POKE' poke
 DCI 'PEEK' peek
 DCI 'EOF' eof
 DCI 'SIZE' size
 DCI 'PDL' pdl
 DCI 'RANDOM' random
 DCI 'ASC' ascii
 DCI 'CALL' call
 DCI 'STORE' store
 DCI 'RECALL' recall

 DCI 'CHR$' chr$
 DCI 'DATE$' date
 DCI 'TIME$' time$
 DCI 'FMTDATE$' formatted
 DCI 'WHEN$' when$
 DCI 'LEFT$' left$
 DCI 'RIGHT$' right$
 DCI 'MID$' mid$
 DCI 'STR$' str$
 DCI 'RND$' rnd$

 DCI '<>' <>
 DCI '><' ><
 DCI '<=' <=
 DCI '>=' >=
 DCI '=<' =<
 DCI '=>' =>
 DCI '=' =
 DCI '<' <
 DCI '>' >

 DCI 'AND' and
 DCI 'OR' or
 DCI 'EOR' eor

 DCI '+' plus
 DCI '-' minus
 DCI '*' multiplication
 DCI '/' division
 DCI 'MOD' mod
 DCI 'ABS' absolute
 DB 0

*-------------------------------
* token jump table
*-------------------------------

SYMADR DW 0 00
number = *-SYMADR/2
 DW DO_LET 01
string = *-SYMADR/2
 DW DO_LET 02
end = *-SYMADR/2
 DW DO_END 03
goto = *-SYMADR/2
 DW DO_GOTO 04
gosub = *-SYMADR/2
 DW DO_GSB 05
push = *-SYMADR/2
 DW DO_PUSH 06
public = *-SYMADR/2
 DW ERR 07

chain = *-SYMADR/2
 DW NIL 08
chain2 = *-SYMADR/2
 DW NIL 09

clear = *-SYMADR/2
 DW DO_CLR 0A
 DW DO_LINK 0B
 DW DO_HOME 0C
 DW DO_PRNT 0D
 DW DO_SHOW 0E
 DW DO_GET 0F
 DW DO_IN 10
 DW DO_SINT 11
 DW DO_AINT 12
 DW DO_FLAG 13
 DW DO_NIB 14
 DW DO_BYT 15
 DW DO_IF 16
 DW NIL 17
else = *-SYMADR/2
 DW DO_ELSE 18
 DW DO_RET 19
 DW DO_POP 1A
 DW DO_MDM 1B
 DW DO_LEN 1C
 DW DO_ECHO 1D
 DW MOVNAME 1E
 DW DO_OPEN 1F
 DW DO_CLOS 20
 DW DO_MARK 21
 DW DO_VAL 22
 DW DO_FRE 23
 DW DO_POS 24
 DW DO_SET 25
 DW DO_RDY 26
 DW DO_READ 27
 DW DO_WRIT 28
 DW DO_NOT 29
key = *-SYMADR/2
 DW DO_KEY 2A
 DW DO_EDIT 2B
msg = *-SYMADR/2
 DW DO_MSG 2C
 DW DO_RWD 2D
 DW DO_TONE 2E
 DW DO_WID 2F
 DW DO_FOR 30
to = *-SYMADR/2
 DW ERR 31
step = *-SYMADR/2
 DW ERR 32
 DW DO_NXT 33
 DW DO_INST 34
 DW DO_KILL 35
 DW DO_MOVE 36
 DW DO_RAM2 37
 DW DO_RAM 38
 DW DO_MAKE 39
 DW DO_CNCH 3A
 DW DO_UP 3B
 DW DO_TEXT 3C
 DW DO_APP 3D
 DW DO_FILL 3E
 DW DO_NOCD 3F
 DW DO_ONERR 40
 DW DO_ERRNO 41
 DW DO_RESUM 42
 DW DO_INFO 43
 DW DO_CLOK 44
 DW DO_USE 45
 DW DO_POKE 46
 DW DO_PEEK 47
 DW DO_EOF 48
 DW DO_SIZE 49
 DW DO_PDL 4A
 DW DO_RND 4B
 DW DO_ASC 4C
 DW DO_CALL 4D
 DW DO_STOR 4E
 DW DO_RCAL 4F

strtyp = *-SYMADR/2
 DW DO_CHR 50
 DW DO_DATE 51
 DW DO_TIME 52
 DW DO_FDATE 53
 DW DO_WHEN 54
 DW DO_LFT 55
 DW DO_RGT 56
 DW DO_MID 57
 DW DO_STR 58
 DW DO_RNDS 59
compare = *-SYMADR/2
 DW CP_NOT 5A
 DW CP_NOT 5B
 DW CP_LTEQ 5C
 DW CP_GTEQ 5D
 DW CP_LTEQ 5E
 DW CP_GTEQ 5F
equal = *-SYMADR/2
 DW CP_EQ 60
 DW CP_LT 61
 DW CP_GT 62

logic = *-SYMADR/2
 DW CP_AND 63
 DW CP_OR 64
 DW CP_EOR 65

math = *-SYMADR/2
 DW DO_PLUS 66
minus = *-SYMADR/2
 DW DO_SUB 67
 DW DO_MULT 68
 DW DO_DIVD 69
 DW DO_MOD 6A
 DW DO_ABS 6B
 DW 0 6C

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
 ASC .Insert text:
 DB cr
 DCI 'New: Erase and start over?'
 DB cr
 ASC 'Enter message now...'0D8D
 DB cr
 DCI 'Read File (name):'
 DB cr
 DCI 'Write File (name):'
 DB cr
 ASC 'A=Abort, C=Continue, D=Delete, E=Edit'0D
 ASC 'H=Help, I=Insert, L=List, N=New'0D
 ASC 'O=Ok to send, Z=Space Used'8D
 ASC .Valid editor
 ASC +'.command' acceptable)+0D0D
 ASC ' A = Abort  Dx-y = Delete line(s) x-y  N = New'0D
 ASC ' H = Help     Ix = Insert at line x    S = Save'0D
 ASC ' Z = Space    Ex = Edit line x      Lx-y = List line(s) x-y'0D8D
 ASC ' Bytes Used.'0D8D

*-------------------------------
* compiler messages
*-------------------------------

COMPMSGS DB -1
 DCI 'One moment, compiling segment.'
 DCI '..'
 DS 32,bs
 ASC '                                '
 DS 31,bs
 DB bs+hibit

MODEBYT DB %10000011 default,
 DB %11000001 upper
 DB %10100000 upper
 DB %00100000 accept
 DB %01100000 no

INPVEC DW KEYIN console
 DW DISKIN1 disk
 DW DISKIN2 disk
 DW NO_INP console
 DW MDMIN modem
 DW NO_INP line
 DW RDMSG msg
 DW RDMAIL read
 DW EDINP editor
 DW NO_INP no
 DW RAMIN ram

OUTVEC DW COUT console
 DW DSKOUT1 disk
 DW DSKOUT2 disk
 DW VIDCOUT local
 DW ZMDMOUT modem
 DW PRCOUT line
 DW WRMSG msg
 DW NO_OUT read
 DW EDOUT editor
 DW TOPPRINT print
 DW RAMOUT ram

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
 ASC 'GP200001' fake

; screen top mask

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

DUMMY = * standard

 DUM DUMMY

 DS 159 finish

GSBSTK DS $20 gosub

FORVAR DS $10 for
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
FROMERR DA 0 where

NULLS DB 0
REMOTE DB 0

SYMNUM DB 0
LBLNUM DB 0
LNCNT DB 0
LNCNT2 DB 0
TOKTYP DB 0

REMAIN DA 0
SIGN DB 0
RESULT DS 3

MSGREF DB 0 is

MSGINFO DB 0 #
 DB 0 #
 DW 0 #
 DW 0 #
 DW 0 #

MSGPTR DB 0 point
BYTE8 DB 0 7
CHAR8 DB 0 7
RMXBLK DW 0 read
RDEND DB 0 at

MSGPTR2 DB 0 for
BYTE82 DB 0 second
 DB 0 second
WRKBLK DW 0 current
WRTEND DB 0 at

RWDPTR DB 0 point
RWDBYT8 DB 0
RWDCHR8 DB 0
RWDBLK DW 0

DIRSEG DA 0 current
BITSEG DB 0 current

MSGNUM DW 0 current
POSBLK DW 0 postion

MSGINIT DB 0 is

CHATBUF DS 90 storage

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


