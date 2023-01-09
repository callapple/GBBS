 PAG
********************************
*                              *
*   ACOS.OBJ - ProDOS Drive    *
*                              *
********************************
 DATE
*-------------------------------
* move the name into the filename field
*-------------------------------

MOVNAME JSR INSTR2 ;get name (dont use memory)
MOVNM0 LDA STRLEN
 BEQ :MOVNAM4

 LDY #0
 STY DRVCHD ;init change drive string
 STY DRVOFF0
 STY DRVOFF1

 LDA (STRLOC),Y ;get first byte
 JSR CONV
 STA DRVNUM ;save it as a drive spec
 CMP #'L'+1
 BGE :MOVNAM2 not

 JSR TST_ALF
 BCS :MOVNAM2 ;opps, not legal

 INY
 LDA (STRLOC),Y ;are we done?
 CMP #':'
 BEQ :MOVNAM3 ;yep, get filename

 JSR TST_NUM ;is it a legal sub-drive?
 BCS :MOVNAM2 ;nope

 STA DRVOFF0 ;save sub-drive byte 1
 INY
 LDA (STRLOC),Y ;are we done?
 CMP #':'
 BEQ :MOVNAM3 ;yep, get filename

 JSR TST_NUM ;is it a legal sub-drive?
 BCS :MOVNAM2 ;nope

 STA DRVOFF1 ;save sub-drive byte 2
 INY
 LDA (STRLOC),Y ;is there a terminator?
 CMP #':'
 BEQ :MOVNAM3 ;yep, get filename

:MOVNAM2 LDY #$FF ;no drive parm, just get name
 STY DRVCHD ;init change drive flag

:MOVNAM3 INY
 LDX #0
 CPY STRLEN
 BEQ :MOVNAM5 ;is there any data?, hmmm

:MOVNAM4 LDA (STRLOC),Y ;copy filename
 JSR CONV ;convert to upper
 CMP #'.'
 BLT :MOVNAM5 ;we are done [anything less, illegal]

 STA FLNAME+1,X ;save name
 INX
 INY
 CPY STRLEN
 BEQ :MOVNAM5 ;done yet?

 CPX #15
 BNE :MOVNAM4 ;have we done 15 chars (the max), nope

:MOVNAM5 STX FLNAME ;save length
 LDA DRVCHD ;change drive first?
 BPL SETDRV ;yep
 RTS

*-------------------------------
* log to drive A, offset X
*-------------------------------

LOGSPEC LDY #0 ;reset offsets
 STY DRVOFF0
 STY DRVOFF1

 STA DRVNUM ;save drive number [A-L]
 TXA
 BEQ SETDRV ;no offset

 JSR BINDEC8 ;translate to two-byte number
 STX DRVOFF0 ;save offset
 CMP #'0'
 BEQ SETDRV ;1 byte offset?, yep
 STA DRVOFF0
 STX DRVOFF1 ;save offset

SETDRV LDA #<DEVNAM ;point to pathnames
 STA TEMP
 LDA #>DEVNAM
 STA TEMP+1

 LDA DRVNUM ;turn drive num into offset
 AND #$F
 STA LNBUF

:SETDRV0 DEC LNBUF
 BEQ :SETDRV1 ;count down drives

 LDY #0
 LDA (TEMP),Y ;get length of pathname

 SEC
 ADC TEMP
 STA TEMP ;point to next entry
 LDA #0
 ADC TEMP+1
 STA TEMP+1
 JMP :SETDRV0 ;set drive number

:SETDRV1 LDY #0
 LDA (TEMP),Y ;get length of string
 BEQ :MOVNAM7 ;pathname not in use

 TAY
 TAX  ;save length

:SETDRV2 LDA (TEMP),Y
 STA LNBUF,Y ;move pathname to lnbuf
 DEY
 BPL :SETDRV2

 LDA DRVOFF0 ;was there an offset?
 BEQ :SETDRV4 nope

 INX increase length
 STA LNBUF,X save

 LDA DRVOFF1 was
 BEQ :SETDRV4 ;nope

 INX  ;increase length
 STA LNBUF,X ;save offset

:SETDRV4 INX
 LDA #'/'
 STA LNBUF,X ;add '/' to end of string
 STX LNBUF ;update length

 JSR MLI ;get current prefix
 DB $C7
 DA GETPFX

 LDX LNBUF ;are the length's the same?
 CMP LNBUF+64
 BNE :SETDRV6 ;nope, change to new prefix

:SETDRV5 LDA LNBUF,X ;is data the same?
 CMP LNBUF+64,X
 BNE :SETDRV6 ;nope, change to new prefix

 DEX
 BPL :SETDRV5
 RTS  ;they are the same, just return

:SETDRV6 JSR MLI ;set to the new prefix
 DB $C6
 DA SETPFX
 BNE :MOVNAM7 ;opps, error
 RTS

:MOVNAM7 LDX #baddrive ;bad drive specifier
 JMP BADERR

DRVCHD DB 0
DRVNUM DB 0
DRVOFF0 DB 0
DRVOFF1 DB 0

FLNAME DS 16

GETPFX DB 1
 DA LNBUF+64

SETPFX DB 1
 DA LNBUF


