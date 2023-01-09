 PAG
********************************
*                              *
*  ACOS.OBJ - ProDOS disk I/O  *
*                              *
********************************
 DATE
*-------------------------------

CREATE STY P_CREAT+4 ;save filetype
 STA P_CREAT+6
 STX P_CREAT+5
 JSR MLI
 DB $82
 DA 0
 LDA MLIDATE
 STA P_CREAT+8
 LDA MLIDATE+1
 STA P_CREAT+9
 LDA MLITIME
 STA P_CREAT+10
 LDA MLITIME+1
 STA P_CREAT+11
 JSR MLI
 DB $C0
 DA P_CREAT
 RTS

OPEN LDY #0
BFOPEN LDA BUFADR,Y ;point at buffer
 STA P_OPEN+4

 JSR MLI
 DB $C8
 DA P_OPEN
 BNE :OPEN2

 LDA P_OPEN+5 ;save refnum
 STA REFNUM
 CLC
 RTS

:OPEN2 LDA #-1 ;make sure refnum is illegal
 STA REFNUM
 SEC
 RTS

BUFADR DB >FBUF1,>FBUF2,>MSGBUF

CLOSE LDA REFNUM
 STA P_CLOSE+1
 JSR MLI
 DB $CC
 DA P_CLOSE
 RTS

FLUSH LDA REFNUM
 STA P_CLOSE+1
 JSR MLI
 DB $CD
 DA P_CLOSE
 RTS

*-------------------------------
* setup for single line read
*-------------------------------

RDLNSET LDA REFNUM
 STA P_NEW1+1 ;save refnum
 STA P_RDLN+1
 JSR MLI
 DB $C9
 DA P_NEW1 ;enable newline
 RTS

*-------------------------------
* read a line from a file
*-------------------------------

RDLINE JSR MLI
 DB $CA
 DA P_RDLN
 BNE :RDLINE2 ;read error

 LDX P_RDLN+6 ;is there a cr at end of line?
 LDA LNBUF-1,X
 AND #clrhi
 CMP #cr
 BNE :RDLINE2 ;no more stuff
 CLC
 RTS

:RDLINE2 LDA #0
 STA LNBUF ;no data in line
 SEC  ;eof
 RTS

*-------------------------------
* read a single byte
*-------------------------------

RDBYTE LDA REFNUM ;save refnum
 BEQ :RDBYTE2

 STA P_RBYT+1
 JSR MLI
 DB $CA
 DA P_RBYT ;read 1 byte
 BNE :RDBYTE2

 LDA P_BYTE ;get byte
 CLC  ;were done
 RTS

:RDBYTE2 LDA #0 ;fake data
 SEC
 RTS

*-------------------------------
* write a block for the msg routines
*-------------------------------

WRBLK PHA
 LDA #$CB
 STA RWTYPE
 PLA
 JMP RWBLK ;use write call

*-------------------------------
* read a block for the msg routines
*-------------------------------

RDBLK PHA
 LDA #$CA
 STA RWTYPE ;use read call
 PLA

RWBLK STX P_RDBLK+2 ;save read address
 STA P_RDBLK+3

 LDA #0
 STA P_RDBLK+4 ;save number of blocks to read
 STY P_RDBLK+5

 LSR P_RDBLK+5 ;divide by 2
 ROR P_RDBLK+4

 LDA REFNUM
 STA P_RDBLK+1 ;get refnum

 JSR MLI ;call mli
RWTYPE DB $CA ;*** modified ***
 DA P_RDBLK
 RTS

*-------------------------------
* write a byte of data
*-------------------------------

WRBYTE STA P_BYTE ;save data
 PHA
 LDA REFNUM
 BEQ :WRBYTE2 ;if no refnum

 STA P_RBYT+1
 JSR MLI
 DB $CB
 DA P_RBYT ;write byte
 CLC
 BEQ :WRBYTE3 ;all is well

:WRBYTE2 SEC  ;opps, problem
:WRBYTE3 PLA  ;get back data
 RTS

*-------------------------------
* position file
*-------------------------------

POSMSG LDY MSGREF
 STY REFNUM ;save refnum

 LSR  ;setup Y,A,X w/exact byte
 TAY
 TXA
 ROR
 PHA
 LDA #$10
 ROR
 TAX
 PLA
 JMP SETPOS

*-------------------------------
* find the end of file
*-------------------------------

GETEOF LDA REFNUM
 STA P_MARK+1 ;save refnum
 JSR MLI
 DB $D1
 DA P_MARK ;get eof
 LDX P_MARK+2 ;get length
 LDA P_MARK+3
 LDY P_MARK+4
 RTS

*-------------------------------
* check for end of file
*-------------------------------

CHKEOF JSR GETMARK ;get the current place
 PHA
 TXA
 PHA
 JSR GETEOF ;get the end of file
 PLA
 TAY

 PLA
 LDX #0
 CPY P_MARK+2
 BNE :CHKEOF2 ;are they the same?, nope
 CMP P_MARK+3
 BNE :CHKEOF2 ;nope
 INX  ;yep, mark it
:CHKEOF2 RTS

*-------------------------------
* check end of file
*-------------------------------

GETSIZ JSR GETEOF ;get the end of file
 LDX P_MARK+3 ;get # of sectors
 LDA P_MARK+4
 RTS

*-------------------------------
* append data to file
*-------------------------------

APPEND JSR GETEOF ;get end of file
 JMP SETPOS ;append

*-------------------------------
* set a mark into a file
*-------------------------------

SETMARK LDY #0 ;do actual position set within file
SETPOS STX P_MARK+2 ;point to new location
 STA P_MARK+3
 STY P_MARK+4

 LDA REFNUM
 STA P_MARK+1 ;save refnum

SETPOS2 JSR MLI
 DB $CE
 DA P_MARK ;set mark
 CMP #$4D
 BNE :SETPOS3 ;check for out-of-range

 JSR MLI
 DB $D0
 DA P_MARK ;set eof
 BEQ SETPOS2 ;position again

:SETPOS3 RTS

*-------------------------------
* get current file marker
*-------------------------------

GETMARK LDA REFNUM
 STA P_MARK+1 ;save refnum
 JSR MLI
 DB $CF
 DA P_MARK ;get mark
 SEC
 BNE :GETMRK2 ;opps, error

 CLC
 LDX P_MARK+2 ;all is well
 LDA P_MARK+3
:GETMRK2 RTS

*-------------------------------
* delete file
*-------------------------------

DELFILE JSR MLI
 DB $C1
 DA P_DEL ;delete file
 RTS

*-------------------------------
* ------ parms ------
*-------------------------------

P_OPEN DB 3
 DA FLNAME
 DA FBUF1
 DB 0

P_CLOSE DB 1
 DB 0

P_RBYT DB 4
 DB 0
 DA P_BYTE
 DA 1
 DA 0

P_BYTE DB 0

P_MARK DB 2
 DB 0
 DS 3

P_NEW1 DB 3
 DB 0
 DB clrhi
 DB cr

P_RDLN DB 4
 DB 0
 DA LNBUF
 DA 255
 DA 0

P_RDBLK DB 4
 DB 0
 DA 0
 DA 128
 DA 0

P_DEL DB 1
 DA FLNAME

P_CREAT DB 7
 DA FLNAME
 HEX E3
 DB 0
 DA 0
 DB 1
 DA 0
 DA 0


