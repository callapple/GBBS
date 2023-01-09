********************************
*                              *
*   ACOS Loader Version 2.2    *
*                              *
********************************

 LST OFF

*-------------------------------
* Date: 12/21/86
*-------------------------------
 TYP $FF
 DSK ACOS

 ORG $2000

cr = $D
lf = $A

MLI = $BF00
LASTDEV = $BF30
HOME = $FC58
COUT = $FDF0
VTAB = $FC22
INPLN = $FD6F
RDKEY = $FD35

LNBUF = $200
FLNAME = $300
ACOSOBJ = $800
DRIVEA = $815

DIRINFO = $5C00
DIRBUF = $5E00
PREFIX = $6000
FLBUF = $6100
FLBUF1 = $6500

RUNADR = $6900

TEMP = 0
TEMP2 = 2
NUMFLS = 4
BLKCNT = 6
PRN = 8

Read_Blk = $80
ATCall = $42 ;appletalk MLI call
NODESAVE = $DE ;location to pass node # to ACOS
Prefix = $C6
; relocate code up to $800

 LDA 1 ;force a turnkey startup
 PHA
 LDA 2
 PHA

 LDA #<OBJCODE ; to obj code
 STA TEMP
 LDA #>OBJCODE
 STA TEMP+1

 LDA #<RUNADR ; point to dest address
 STA TEMP2
 LDA #>RUNADR
 STA TEMP2+1

 LDX #$10 ; move $10 pages
 LDY #0
DOMOVE LDA (TEMP),Y ; move a byte
 STA (TEMP2),Y
 INY
 BNE DOMOVE

 INC TEMP+1 ; go to the next page
 INC TEMP2+1
 DEX
 BNE DOMOVE

 PLA
 STA STARTUP+1 ; save startup bytes
 PLA
 STA STARTUP
 JMP RUNADR ; execute code

 DS \ ; fill space

OBJCODE ORG RUNADR

INIT LDA #0
 STA NODESAVE

 LDA LASTDEV ;get the device we just lauched from
 STA UNITNUM ;save it

 JSR MLI ;do a block read (invalid under AppleTalk)
 DB Read_Blk
 DA R_BLOCK

 CMP #$88
 BNE INIT_0 ;did not boot off server

 LDA #$80
 STA NODESAVE

 JSR MLI ;get the user directory...
 DB ATCall
 DA FIUSERPFX

 LDX COPYBUF
 BEQ INIT_0 ;no user directory found

 DEX
 LDA COPYBUF,X

 AND #$7F ;strip off any high bit that might be there
 CMP '9'+1 ;is it higher then a 9?
 BCS INIT_0 ;yes
 CMP '0' ;is it lower then a 0?
 BCC INIT_0 ;yes

 AND #$F ;strip of the $cx part of the ASCII eqiv.
 ORA NODESAVE ;and save it to the nodesave id area.

 INC R_FILE ;kick file length up a byte
 LDX R_FILE ;length of acos.obj
 LDA NODESAVE
 ORA #'0' ;make it an ascii #
 AND #$7F ;strip off the high bit
 STA R_FILE,X

; set to normal 40 col text mode
INIT_0 LDA $C30B
 CMP #1
 BNE INIT_2

 LDA $C30C
 CMP #$82
 BNE INIT_1

 LDA $C058
 CLC
 BCC INIT_2

INIT_1 CMP #$87
 BNE INIT_2

 LDA #0
 STA $C0B2

INIT_2 LDA #0 ; reset screen
 STA $20
 STA $22
 LDA #40
 STA $21
 LDA #24
 STA $23

 JSR HOME ; clear screen
 JSR PR ; show main screen
 ASC '########################################' ; 1
 ASC '# ACOS LOADER V2.2N #    ACOS FILES    #' ; 2
 ASC '# COPYRIGHT 86-2019 ####################' ; 3
 ASC '#  KEVIN SMALLWOOD  #                  #' ; 4
 ASC '#####################                  #' ; 5
 ASC '#    FILENAMES      #                  #' ; 6
 ASC '#####################                  #' ; 7
 ASC '#                   #                  #' ; 8
 ASC '#                   ####################' ; 9
 ASC '#                   #  DELETED FILES   #' ; 10
 ASC '#                   ####################' ; 11
 ASC '#                   #                  #' ; 12
 ASC '#                   #                  #' ; 13
 ASC '#                   #                  #' ; 14
 ASC '#                   #                  #' ; 15
 ASC '#                   ####################' ; 16
 ASC '#                   # STARTUP SEGMENT  #' ; 17
 ASC '#                   ####################' ; 18
 ASC '#                   #                  #' ; 19
 ASC '########################################' ; 20
 ASC '# STATUS:                              #' ; 21
 ASC '#   LOADING ACOS.OBJ                   #' ; 22
 ASC '########################################'00 ; 23

 JSR MLI
 DB $C7 ; get prefix
 DA P_PFX

 LDA PREFIX
 BNE GOTDEF ; we have a default

 LDA $BF30 ; save currently used disk
 STA P_ONLN+1

 JSR MLI
 DB $C5 ; get the online volume
 DA P_ONLN

 LDA PREFIX+1 ; get rid of drive specifier
 AND #$F
 TAX
 INX ; add 1 for '/'
 STX PREFIX

 LDA #'/' ; put in leading slash
 STA PREFIX+1

 JSR MLI
 DB $C6 ; set the prefix
 DA P_PFX

GOTDEF LDX $280 ; get length of path
GOTDEF2 DEX
 BEQ LOADG ; we have the path set

 LDA $280,X
 CMP #'/' ; find path?
 BNE GOTDEF2 ; nope

 STX $280 ; set new length

 JSR MLI
 DB $C6 ; set prefix
 DA P_PFX2

LOADG LDA #0
 STA $BF94
 JSR MLI ; close ALL open files
 DB $CC
 DA R_CLOSE

 JSR MLI
 DB $C8 ; open a file
 DA R_OPEN

 LDA R_OPEN+5 ; move refnum
 STA R_READ+1

 JSR MLI
 DB $CA ; read in acos.obj
 DA R_READ

 JSR MLI
 DB $CC ; close file
 DA R_CLOSE

; check for turnkey run
 LDA STARTUP ; is first i/d byte ok?
 CMP #1
 BNE SNAME ; nope

 LDA STARTUP+1
 STA STARTUP ; make sure they dont match again
 CMP #2
 BEQ SNAME4

; get name of starting segment
SNAME LDA ACOSOBJ+2 ; point to filename
 STA TEMP
 LDA ACOSOBJ+3
 STA TEMP+1

 JSR PRSTAT
 ASC 'SOURCE MODULE ['00
 LDY #0
 LDA (TEMP),Y

 TAX
SNAME2 INY
 LDA (TEMP),Y ; print filename
 ORA #$80
 JSR COUT
 DEX
 BNE SNAME2

 JSR PR ; finish off string
 ASC ']: '00

 JSR INPLN
 CPX #0 ; cr?
 BEQ SNAME4 ; yep
 CPX #14 ; 14 or over?
 BCS SNAME ; yep

 TXA
 TAY
SNAME3 LDA LNBUF-1,Y ; copy filename
 STA (TEMP),Y
 DEY
 BNE SNAME3

 TXA ; save length
 STA (TEMP),Y
 JMP SNAME ; go back

SNAME4 LDX ACOSOBJ+2
 LDA ACOSOBJ+3 ; display in window 3
 LDY #3
 JSR PRWIND

 LDA #<DRIVEA ; point to pathname
 STA P_GINFO+1
 LDA #>DRIVEA
 STA P_GINFO+2

CHKPRG JSR MLI
 DB $C4 ; get file info
 DA P_GINFO
 BEQ DOCHECK

 JSR PRSTAT
 ASC 'INSERT SYSTEM DISK INTO OTHER DRIVE'0D00
 JSR GETCR
 JMP CHKPRG

; get a directory and look for ".s" files.
; if any exist, check to see if they have
; been changed. If so, kill the ".c" file.

DOCHECK JSR PRSTAT
 ASC 'STATUS:'0D
 ASC '  CHECKING FILES...'00

LOGPRG JSR MLI
 DB $C7 ; get the current prefix
 DA P_PFX

 LDY DRIVEA
LOGPRG1 LDA DRIVEA,Y ; are these 2 paths the same?
 EOR PREFIX,Y
 AND #%11011111
 BNE LOGPRG2 ; nope

 DEY
 BNE LOGPRG1 ; keep checking

LOGPRG2 JSR MLI ; open the current prefix
 DB $C8
 DA P_OPEN

 LDA P_OPEN+5 ; get refnum
 STA P_RDINF+1
 STA P_RDDIR+1
 STA P_POS+1

 JSR MLI ; read dir info
 DB $CA
 DA P_RDINF

 JSR MLI ; set to byte 0
 DB $CE
 DA P_POS

 LDX #0
 STX NUMFLS ; 0 files processed
 STX NUMFLS+1
 DEX
 STX BLKCNT ; start at file 1 in block

RDLOOP LDA #<DIRBUF+4 ; point to buf
 STA TEMP
 LDA #>DIRBUF+4
 STA TEMP+1

 JSR MLI ; read block
 DB $CA
 DA P_RDDIR
 BNE RDLOOP1 ; opps, error

 LDA BLKCNT ; first pass?
 BPL RDLOOP2 ; nope

 INC BLKCNT ; set to 0
 JMP RDLOOP5 ; go to next entry

RDLOOP2 LDA NUMFLS ; we done?
 CMP DIRINFO+$25
 BNE RDLOOP3 ; nope

 LDA NUMFLS+1 ; check high
 CMP DIRINFO+$26
 BNE RDLOOP3 ; were done

RDLOOP1 JMP FINISH

RDLOOP3 LDY #0
 LDA (TEMP),Y ; get length and type
 AND #$F
 STA (TEMP),Y ; get rid of extra stuff
 STA TEMP2
 BNE RDLP3A

 JMP RDLOOP5

RDLP3A INC NUMFLS ; inc file count
 BNE RDLOOP4
 INC NUMFLS+1

RDLOOP4 LDX TEMP
 LDA TEMP+1 ; display filename in window 0
 LDY #0
 JSR PRWIND

 LDY DRIVEA ; get length of path
 TYA
 TAX ; save length
MVPATH LDA DRIVEA,Y
 STA FLNAME,Y ; move pathname
 DEY
 BPL MVPATH

 LDA #'/' ; add in slash
 INX
 STA FLNAME,X

 LDY #0
MVPATH2 INX
 INY
 LDA (TEMP),Y ; get name of file
 STA FLNAME,X
 CPY TEMP2
 BNE MVPATH2

 LDA #'C' ; make into '.c'
 STA FLNAME,X
 STX FLNAME ; update length

 LDA TEMP2 ; get length
 CMP #3 ; is it a possible '.s' file?
 BCC RDLOOP5 ; nope

 TAY
 LDA (TEMP),Y ; check for 's' in '.s'
 CMP #'S'
 BNE RDLOOP5

 DEY
 LDA (TEMP),Y ; check for '.' in '.s'
 CMP #'.'
 BNE RDLOOP5

RDLOOP4C LDX TEMP
 LDA TEMP+1
 LDY #1 ; display .s source file
 JSR PRWIND

 LDA TEMP ; point at filename
 STA P_GINFO+1
 STA P_OPEN2+1
 LDA TEMP+1
 STA P_GINFO+2
 STA P_OPEN2+2

 LDA #10 ; setup for get.info
 STA P_GINFO

 JSR MLI ; get file info
 DB $C4
 DA P_GINFO
 BNE RDLOOP5 ; hmmm, error

 LDA P_GINFO+5 ; check backup bit
 BNE RDLOP4A ; all is well

 LDA #1
 STA P_GINFO+5 ; set bit in mod.time

 LDA #7 ; setup for set.file.info
 STA P_GINFO

 JSR MLI ; set info
 DB $C3
 DA P_GINFO

 LDY #0
 LDA (TEMP),Y ; change file into .C
 TAY
 LDA #'C'
 STA (TEMP),Y

 LDX TEMP
 LDA TEMP+1
 LDY #2 ; display in window 2
 JSR PRWIND

 LDY #0
 LDA (TEMP),Y
 TAY ; change file back to .S
 LDA #'S'
 STA (TEMP),Y

 JSR MLI ; delete '.c' file
 DB $C1
 DA P_DEL

RDLOP4A JSR FLCOPY ; copy over the file

RDLOOP5 CLC
 LDA TEMP ; go to next entry
 ADC DIRINFO+$23
 STA TEMP
 LDA TEMP+1
 ADC #0
 STA TEMP+1

 INC BLKCNT ; INC place within block
 LDA BLKCNT
 CMP DIRINFO+$24
 BEQ RDLOOP6 ; go to next block

 JMP RDLOOP2 ; do next entry within this block

RDLOOP6 LDA #0 ; reset count
 STA BLKCNT
 JMP RDLOOP ; do another block

FINISH LDA #0
 STA P_CLOSE+1

 JSR MLI ; close file
 DB $CC
 DA P_CLOSE

 LDA $C000 ; did they want to pause?
 CMP #" "
 BEQ WAIT2C ; yep, wait to see

 JMP EXEACOS

WAIT2C LDA #1
 STA $20
 STA $22
 LDA #38
 STA $21
 LDA #22
 STA $23
 JSR HOME ; clear screen
 JSR PR
 DB cr
 ASC ' MAKE SURE THESE DISKS ARE IN PLACE:'0D00


 LDY #0 ; move A:
 LDX #<LNBUF
 LDA #>LNBUF
 JSR MOVPATH ; move pathname

 LDY #1 ; move B:
 LDX #<LNBUF+128
 LDA #>LNBUF+128
 JSR MOVPATH ; move pathname

 LDY LNBUF ; get pathname length
 INY
SHOW2 DEY ; count down
 BMI SHOW3 ; they match

 LDA LNBUF,Y
 CMP LNBUF+128,Y ; are they the same?
 BEQ SHOW2 ; yep

 JSR PR
 DB cr
 ASC ' BOOT DISK     -- '00
 LDY LNBUF
 LDX #<LNBUF+1
 LDA #>LNBUF+1
 JSR PRSTR ; show pathname

SHOW3 JSR PR
 DB cr
 ASC ' SYSTEM DISK   -- '00
 LDY LNBUF+128
 LDX #<LNBUF+129
 LDA #>LNBUF+129
 JSR PRSTR ; show pathname

 LDY #5
 LDX #<LNBUF ; move pathname
 LDA #>LNBUF
 JSR MOVPATH

 JSR PR
 DB cr
 ASC ' BULLETIN DISK -- '00
 LDY LNBUF
 LDX #<LNBUF+1
 LDA #>LNBUF+1
 JSR PRSTR ; show pathname

 LDY #6
 LDX #<LNBUF+128
 LDA #>LNBUF+128 ; move pathname
 JSR MOVPATH

 LDY LNBUF ; get length of path
 INY
SHOW4 DEY
 BMI SHOW5 ; the path's match

 LDA LNBUF,Y ; are they the same?
 CMP LNBUF+128,Y
 BEQ SHOW4 ; yep

 JSR PR
 DB cr
 ASC ' MAIL DISK     -- '00
 LDY LNBUF+128
 LDX #<LNBUF+129
 LDA #>LNBUF+129
 JSR PRSTR

SHOW5 JSR PR
 DB cr,cr
 ASC ' ONCE THESE DISKS ARE IN PLACE'0D0D
 ASC ' '00
 JSR GETCR

EXEACOS LDA #0
 STA $BF94 ; set level to 0

 JSR MLI
 DB $CC ; close all open files
 DA R_CLOSE ; specifically EXEC files

 LDA ACOSOBJ+6
 STA TEMP
 LDA ACOSOBJ+7
 STA TEMP+1

 BIT NODESAVE
 BPL NOATLK ;the system did not boot from appleshare

 LDA NODESAVE ;get back the node number
 STA $800 ;and patch it into ACOS

NOATLK JMP (TEMP) ; start acos running


; sub-routines
; print a line of status
PRSTAT LDA #2
 STA $20
 LDA #36
 STA $21
 LDA #20 ; set window
 STA $22
 LDA #22
 STA $23
 JSR HOME ; clear window

PR PLA ; point to string
 STA PRN
 PLA
 STA PRN+1

PR2 INC PRN ; get next byte
 BNE PR3
 INC PRN+1

PR3 LDY #0 ; get byte
 LDA (PRN),Y
 ORA #$80
 CMP #"#" ; inverse block?
 BNE PR3A ; nope
 LDA #' '

PR3A JSR COUT ; print
 ASL
 BNE PR2 ; keep going

 INC PRN ; make into correct address
 BNE PR4
 INC PRN+1

PR4 JMP (PRN) ; return


; get a return
GETCR JSR PR
 ASC 'PRESS [RETURN] TO CONTINUE...'00
GETCR2 JSR RDKEY
 CMP #$8D
 BNE GETCR2
 RTS


; print a filename within a window
PRWIND STX PRN ; point to filename
 STA PRN+1
 LDA WNDLFT,Y ; define text window
 STA $20
 STA $24
 LDA WNDRGT,Y
 STA $21
 LDA WNDTOP,Y
 STA $22
 LDA WNDBTM,Y
 STA $23
 SEC ; make into vtab
 SBC #1
 STA $25
 JSR VTAB ; vtab down
 LDA #$8D
 JSR COUT ; scroll down

 LDY #0
 LDA (PRN),Y ; get filename length
 TAX
PRWIND2 INY
 LDA (PRN),Y ; print name
 ORA #$80
 JSR COUT
 DEX
 BNE PRWIND2
 RTS

WNDLFT DB 02,22,22,22
WNDRGT DB 16,16,16,16
WNDTOP DB 07,03,11,18
WNDBTM DB 19,08,15,19


; print a string pointed to by X & A, length Y
PRSTR STX PRN
 STA PRN+1 ; point at string
 TYA
 TAX ; save length
 LDY #0
PRSTR2 LDA (PRN),Y ; get data
 ORA #$80
 JSR COUT
 INY
 DEX
 BNE PRSTR2 ; do entire string
 RTS


; move a pathname into a buffer
MOVPATH STX TEMP ; point to buffer
 STA TEMP+1

 LDX #0
MOVE2 DEY ; count down
 BMI MOVE3 ; all finished

 TXA
 SEC
 ADC DRIVEA,X ; add in next offset
 TAX
 JMP MOVE2

MOVE3 LDA DRIVEA,X ; get path length
 STA TEMP2 ; save as counter

 LDY #0
MOVE4 LDA DRIVEA,X
 STA (TEMP),Y ; save in buffer
 INX
 INY
 DEC TEMP2 ; count down length
 BPL MOVE4
 RTS


; copy over a source file
FLCOPY JSR MLI
 DB $C8 ; does '.c' file exist?
 DA P_OPEN1
 BNE FLCOPY1 ; nope, copy source

 LDA P_OPEN1+5
 STA P_CLOSE+1
 JSR MLI ; close compiled file
 DB $CC
 DA P_CLOSE
FLCOPY2 RTS ; all is well

FLCOPY1 LDX FLNAME ; change '.c' back to '.s'
 LDA #'S'
 STA FLNAME,X

 JSR MLI
 DB $C0 ; create new file
 DA P_CREAT
 BNE FLCOPY2 ; file must already exist

 JSR MLI
 DB $C8 ; open old file
 DA P_OPEN2

 LDA P_OPEN2+5 ; save refnum
 STA P_READ+1
 STA P_CLOSE+1

 JSR MLI
 DB $CA ; read in file
 DA P_READ

 JSR MLI
 DB $CC ; close source file
 DA P_CLOSE

 JSR MLI
 DB $C8 ; open new file
 DA P_OPEN1

 LDA P_OPEN1+5 ; setup write routine
 STA P_WRITE+1
 STA P_CLOSE+1
 LDA P_READ+6 ; setup write length
 STA P_WRITE+4
 LDA P_READ+7
 STA P_WRITE+5

 JSR MLI
 DB $CB ; write out segment
 DA P_WRITE

 JSR MLI ; close file 2
 DB $CC
 DA P_CLOSE
 RTS ; we are done


; prodos parmlist
STARTUP DW 0

P_CREAT DB 7
 DA FLNAME
 DB $C3
 DB 4
 DW 0
 DB 1
 DW 0
 DW 0

P_OPEN DB 3
 DA PREFIX
 DA FLBUF
 DB 0

P_OPEN1 DB 3
 DA FLNAME
 DA FLBUF1
 DB 0

P_OPEN2 DB 3
 DA 0
 DA FLBUF1
 DB 0

P_RDINF DB 4
 DB 0
 DA DIRINFO
 DW $100
 DW 0

P_RDDIR DB 4
 DB 0
 DA DIRBUF
 DW $200
 DW 0

P_READ DB 4
 DB 0
 DA COPYBUF
 DW COPYLEN
 DW 0

P_WRITE DB 4
 DB 0
 DA COPYBUF
 DW COPYLEN
 DW 0

P_CLOSE DB 1
 DB 0

P_GINFO DB $A
 DA 0
 DB 0
 DB 0
 DW 0
 DB 0
 DW 0
 DW 0
 DW 0
 DW 0
 DW 0

P_DEL DB 1
 DA FLNAME

P_POS DB 2
 DB 0
 DB 0,0,0

P_PFX DB 1
 DA PREFIX

P_PFX2 DB 1
 DA $280

P_ONLN DB 2
 DB 0
 DA PREFIX+1

; data for relocated code
R_OPEN DB 3
 DA R_FILE
 DA FLBUF1 ; use last possible buffer
 DB 0

R_READ DB 4
 DB 0
 DA ACOSOBJ
 DW $6000
 DW 0

R_CLOSE DB 1
 DB 0

R_FILE STR 'ACOS.OBJ'
 DS 2

R_BLOCK DB 3
UNITNUM DS 1
 DA COPYBUF+$200
 DA 0

FIUSERPFX DB 0 ;Synchronous Only
 DB $2A ;Command
RESULT DW 0 ;RESULT Code
 DB 0 ;Reserved
 ADRL COPYBUF ;pointer to Pathname

 DS \

COPYBUF = *
COPYLEN = MLI-COPYBUF
