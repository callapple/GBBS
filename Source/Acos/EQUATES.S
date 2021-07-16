 ORG $800
********************************
*                              *
*   ACOS.OBJ Equates File      *
*                              *
********************************
 DATE
*-------------------------------

ctrl = $40
eot = 'D'-ctrl
ff = 'L'-ctrl

chat = 'A'-ctrl
bol = 'B'-ctrl
ctr = 'C'-ctrl
dc = 'D'-ctrl
eol = 'E'-ctrl
ic = 'F'-ctrl
bel = 'G'-ctrl
bs = 'H'-ctrl
tab = 'I'-ctrl
lf = 'J'-ctrl
toglpw = ']'-ctrl
logout = 'L'-ctrl
cr = 'M'-ctrl
bartog = 'O'-ctrl
prnscr = 'P'-ctrl
lwd = 'Q'-ctrl
xon = 'Q'-ctrl
revtop = 'R'-ctrl
xoff = 'S'-ctrl
hak = 'T'-ctrl
fs = 'U'-ctrl
execon = 'V'-ctrl
nwd = 'W'-ctrl
can = 'X'-ctrl
clb = '^'-ctrl
pass = '_'-ctrl
del = $7F
clrhi = $7F
hibit = $80
LABEL = 0
QUIT = $7F

*-------------------------------
* addresses
*-------------------------------

ENDMOD = $9E00

EDBUF = ENDMOD ;editor buffer
EDSIZE = $1000 ;$1000   4k
EBUFEND = EDBUF+EDSIZE-1

LBLTAB = ENDMOD ;compiler labels
SYMTAB = LBLTAB+$800 ;compiler symbols

FBUF2 = $AE00 ;file 2 buffer
FBUF1 = $B200 ;file 1 buffer

INTBUF = $B600 ;interrupt char flags
RAMDRV = $B680 ;ram drive area
TYPBUF = $B700 ;type ahead buffer
BITBUF = $B780 ;msg file bitmap buffer
BLKBUF = $B800 ;msg file block buffer 1
BLKBUF2 = $B880 ;msg file block buffer 2
DIRBUF = $B900 ;msg file directory buffer
MSGBUF = $BB00 ;msg file data buffer
RAMCARD = $D500 ;in 1st lc bank

*-------------------------------
* general offsets
*-------------------------------

L0 = 0 ;label offsets
L1 = $100
L2 = $200
L3 = $300
L4 = $400
L5 = $500
L6 = $600
L7 = $700
L8 = $800
L9 = $900

*-------------------------------
* disk file stuff
*-------------------------------

txt = 4 ;txst file
a2obj = $2B ;standard file
a2data = $2D ;data file

* file sub types

notype = 0 ;no sub type

comfile = $8001 ;compiled program/variables
usefile = $8002 ;USE files

stdfile = $8001 ;text or data files
packfile = $8002 ;packed message files

*-------------------------------
* message equates
*-------------------------------

nostart = 1 ;Starting Module Not Found
seg2big = 2 ;Module Too Large
lblnf = 3 ;Label Not Found
symfull = 4 ;Symbol Table Full
syntax = 5 ;Syntax Error
nosymbol = 6 ;Missing Symbol
nolabel = 7 ;Undefined Label
nodata = 8 ;Missing Data
badtype = 9 ;Type Mismatch
num2big = 10 ;Overflow > 32767
divby0 = 11 ;Division By 0
str2big = 12 ;String Too Long
gsbfull = 13 ;Gosub Stack Full
nogosub = 14 ;Return Without Gosub
baddev = 15 ;Bad Device Number
badfn = 16 ;Illegal Filename
forfull = 17 ;For Stack Full
nofor = 18 ;Next Without For
nolink = 19 ;Link Label Not Found
nomsg = 20 ;Message File Not Found
endprog = 21 ;END of Program
baddrive = 22 ;Bad Drive Specifier
badxtrn = 23 ;Unable to Load External
noquote = 24 ;Unclosed quote at EOF......

sysopon = 1 ;Sysop is on-line...
sysopoff = 2 ;Sysop is off-line...
timeup = 3 ;Sorry, time limit exceeded
hangon = 4 ;...please wait...
exitexec = 5 ;...exiting exec mode...
nofile = 6 ;Error: Help file could not be opened
badwrite = 7 ;File Write Error
onesec = 8 ;One moment please...

*-------------------------------
* editor messages
*-------------------------------

editing = 1 ;Editing (?=Help):
thats4k = 2 ;That is 4k worth
badcmd = 3 ;Illegal Command
abort? = 4 ;Abort: Are you sure?'
aborted = 5 ;Aborted
continue = 6 ;Continue message now...
delete? = 7 ;Delete Line (L,x-y):
edit? = 8 ;Edit Line (L,x):
badln = 9 ;Illegal line number
insert? = 10 ;Insert Line (L,x):
list? = 11 ;List Line (x-y):
insert = 12 ;Insert text: Type 'DONE' when finished
new? = 13 ;New: Erase and start over?'
enter = 14 ;Enter message now...
readfn? = 15 ;Read File (name):'
writefn? = 16 ;Write File (name):'
edithelp = 17 ;A)bort, C)ontinue, D)elete, E)dit
;H)elp, I)nsert, L)ist, N)ew, S)ave
;Z) Space Used
legaldot = 18 ;Valid editor commands:
;("/commmand" and ".command" acceptable)
; A = Abort  Dx-y = Delete line(s) x-y  N = New
; H = Help     Ix = Insert at line x    S = Save
; Z = Space    Ex = Edit line x      Lx-y = List line(s) x-y
bytsused = 19 ;Bytes Used.

*-------------------------------
* compiler messages
*-------------------------------

compile1 = 1 ;One moment, compiling segment.
compile2 = 2 ;..
compwipe = 3

ERVAL = 10

*-------------------------------
* Zero Page Locations
*-------------------------------

 DUM 0

TEMP DW 0 ;0
TEMP2 DW 0 ;2
PRGPTR DW 0 ;4   pointer into program
SAVE_X DB 0 ;6
SAVE_Y DB 0 ;7
VARSTR DW 0 ;8   top of string space
PRN DW 0 ;$A  print pointer
CMD DB 0 ;$C
STRLOC DW 0 ;$D  current string location
STRLEN DB 0 ;$F  current string length
TTLLEN DB 0 ;$10 concat total length
LSTPTR DW 0 ;$11 token list pointer
TEMP3 DW 0 ;$13
VECTOR DW 0 ;$15 output vector
WHNPTR DW 0 ;$17 pointer to when word
EDPTR DW 0 ;$19 editor buffer pointer
LASTIN DB 0 ;$1B
EXEC DB 0 ;$1C exec user flag
ARGPTR DW 0 ;$1D
DEVCLR DB 0 ;$1F reset device flag

WNDLFT DB 0 ;$20 window left
WNDWDTH DB 0 ;$21 window width
WNDTOP DB 0 ;$22 window top
WNDBTM DB 0 ;$23 window bottom
CH DB 0 ;$24 cursor column
CV DB 0 ;$25 cursor row
 DW 0 ;$26 GBAS, Used by graphics
 DW 0 ;$28  BAS, Used by video
 DW 0 ;$2A BAS2, Used by video
 DW 0 ;$2C
 DB 0 ;$2E
LSTTOK DB 0 ;$2F token storage for list
 DB 0 ;$30
 DB 0 ;$31
INVFLG DB 0 ;$32 video inverse flag
PWHIDE DB 0 ;$33 password hide flag
INTOUT DB 0 ;$34 output interrupt flag

 ORG $4E

MONRND DW 0 ;$4E

X_ARG DW 0 ;$50 editor X argument
Y_ARG DW 0 ;$52 editor Y argument
EDLINE DW 0 ;$54 editor line number
VECTOR2 DW 0 ;$56 input routine vector
MSG_X DB 0 ;$58
MSG_Y DB 0 ;$59
OLDCH DB 0 ;$5A
OLDCV DB 0 ;$5B
LASTCHR DB 0 ;$5C
DOCHAT DB 0 ;$5D do chat next flag
INCHAT DB 0 ;$5E chatting flag
 DW 0 ;$5F
LOGOFF DB 0 ;$61 carrier loss flag
BUF_X DB 0 ;$62
TYPIN DB 0 ;$63 type ahead input flag
TYPOUT DB 0 ;$64 type ahead out flag
NIBPTR DW 0 ;$65 pointer to nibbles
BYTPTR DW 0 ;$67 pointer to bytes

********************************
*                              *
*     Applesoft Locations      *
*                              *
********************************

LOMEM DW 0 ;$69
IMMDEF DB 0 ;$6B immediate/deferred flag
LSTTXT DB 0 ;$6C
MIDMEM DW 0 ;$6D
CLKBASE DW 0 ;$6F starting seconds
TIMEON DW 0 ;$71 seconds used
HIMEM DW 0 ;$73
RAMPTR DB 0 ;$75 ramdisk pointer
SHOW_X DB 0 ;$76
SHW_CNT DB 0 ;$77 copy line count
GSBLVL DB 0 ;$78 gosub stack level
FORLVL DB 0 ;$79 for stack level
 DS 7 ;$7A - $80

VNAME DW 0 ;$81 variable name
VPTR DW 0 ;$83 variable pointer

 ORG $C9
RND DW 0
 DEND

ERRNO = $DE

LNBUF = $200 ;input buffer
SCRATCH = $300 ;ram area
RESETVEC = $3F2 ;reset vector
SOFTEV = $3F4
USERVEC = $3F5
TOPRIGHT = $427

KBDSTRB = $C010 ;clear keyboard strobe
RD80VID = $C01F ;80/40 column switch flag
SPKR = $C030 ;toggle speaker
LORESMD = $C056 ;set lores mode
PDLS = $C064 ;game controls
PTRIG = $C070 ;game control trigger
SETROM = $C082
SETRAM = $C083
ANU_ON = $C05B ;annunc 1 ON
ANU_OFF = $C05A ;annunc 1 OFF
MLBUS = $C063 ;button 2 Multiline Status BUS

*-------------------------------
* addresses
*-------------------------------

MLI = $BF00 ;ProDOS MLI entry point
MLIDATE = $BF90 ;ProDOS date storage
MLITIME = $BF92 ;ProDOS time storage
BITMAP = $BF58 ;ProDOS memory protect map

ENTRMON = $FF59 ;monitor entry point
IRQVECT = $FFFE ;IRQ vector
