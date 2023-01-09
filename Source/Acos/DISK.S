 PAG
********************************
*                              *
*       ACOS.OBJ - Disk        *
*                              *
********************************
 DATE
*-------------------------------
* open a text file [actually, any type of file!]
*-------------------------------

DO_OPEN LDX #"#"
 JSR GOBBLE ;gobble "#"
 JSR INPNUM ;get channel to open
 DEX
 STX TEMP2 ;save buffer number
 CPX #2
 BGE :DO_OPN4 ;make sure it's in range [1-2]

 LDA DEVUSE+1,X ;see if channel in use
 BMI :DO_OPN3

 JSR GOBCOM ;gobble comma
 JSR MOVNAME ;move file name
 LDY TEMP2 ;get buffer number
 JSR BFOPEN

 LDX TEMP2
 LDA #0 ;save refnum or 0 if none
 BCS :DO_OPN2

 LDA REFNUM
:DO_OPN2 STA REFTAB,X ;save ref number
 DEC DEVUSE+1,X ;put "in use"
 RTS

:DO_OPN3 LDX #badfn ;bad file name
 BNE :DO_OPN5

:DO_OPN4 LDX #baddev ;bad device number
:DO_OPN5 JMP BADERR

*-------------------------------
* try to open in a non-used channel
*-------------------------------

IFOPEN LDY #0 ;check channel 1
 LDA DEVUSE+1,Y
 BPL :IFOPEN2 ;it's open

 INY
 LDA DEVUSE+1,Y ;try channel 2
 BMI :IFOPEN3 ;hmm, no open channel

:IFOPEN2 JSR BFOPEN ;open file
 BCS :IFOPEN3 ;opps, file didn't open
 RTS  ;clc = all is well

:IFOPEN3 SEC  ;opps, couldn't open
 RTS

*-------------------------------
* append to a file
*-------------------------------

DO_APP JSR GETDEV ;get device
 JSR CHKDSK ;make sure device is a file
 LDA REFTAB,Y
 STA REFNUM ;get refnum
 JMP APPEND ;append to file

*-------------------------------
* close a file
*-------------------------------

DO_CLOS JSR GETDEV ;get device
 CPX #0
 BEQ DO_CL3 ;if there wasn't one (or dev0) close all

 JSR CHKDSK ;make sure device is a file
 TYA
 TAX  ;x = y
 LDA #0
 STA DEVUSE+1,X ;"un use" it
 LDA REFTAB,X ;get refnum
 BEQ DO_CL6 ;opps, not really open

 STA REFNUM
 JMP CLOSE ;close the correct file(s)

*-------------------------------
* close open files
*-------------------------------

DO_CL3 LDA DEVUSE+1 ;check channel 1
 BPL :DO_CL4

 LDA REFTAB ;close channel 1
 BEQ :DO_CL4 ;opps, not really open

 STA REFNUM
 JSR CLOSE

:DO_CL4 LDA DEVUSE+2 ;check channel 2
 BPL :DO_CL5

 LDA REFTAB+1 ;close channel 2
 BEQ :DO_CL5 ;opps, not really open

 STA REFNUM
 JSR CLOSE

:DO_CL5 LDA #0
 STA DEVUSE+1 ;close both channels
 STA DEVUSE+2
DO_CL6 RTS

*-------------------------------
* get input from the file
*-------------------------------

DISKIN1 LDA REFTAB ;use channel 1
 STA REFNUM
 JMP RDBYTE

DISKIN2 LDA REFTAB+1 ;use channel 2
 STA REFNUM
 JMP RDBYTE

*-------------------------------
* output to a file
*-------------------------------

DSKOUT1 PHA
 LDA REFTAB ;use channel 1
 STA REFNUM
 PLA
 JMP WRBYTE

DSKOUT2 PHA
 LDA REFTAB+1
 STA REFNUM ;use channel 2
 PLA
 JMP WRBYTE

REFTAB DS 2 ;reference numbers

*-------------------------------
* get the device number
*-------------------------------

GETDEV JSR CHKBYT
 LDX #0
 LDY #0
 CMP #"#"
 BNE :GETDEV1 ;device indicator?, nope

 JSR GETBYT ;gobble '#'
 LDA #0
 STA DEVCLR ;reset device byte
 JSR CHKBYT
 CMP #msg
 BEQ :GETMSG ;check for message

 JSR INPNUM
 CMP #0
 BNE GETDEV2 ;if > 255

 BIT MSGINIT ;is channel 6 setup?
 BMI :GETMSG2 ;yep

 CPX #6
 BEQ GETDEV2 ;trying to use channel 6?, yes, stop them

:GETMSG2 JSR CHKBYT
 CMP #","
 BNE :GETDEV0

 JSR GETBYT ;gobble comma
:GETDEV0 LDA DEVUSE,X ;is channel in use
 BPL GETDEV2 ;nope

 TXA
 TAY  ;y = x
 ASL  ;x = x * 2
 TAX
:GETDEV1 RTS

:GETMSG JSR GETBYT ;gobble
 JSR INPNUM ;get msg number
 STX MSGNUM ;save
 STA MSGNUM+1
 LDA #0
 STA MSGINIT ;init message
 LDX #6 ;return channel
 JMP :GETMSG2 ;finish up

GETDEV2 LDX #baddev ;bad device #
 JMP BADERR

CHKDSK DEY  ;make sure device is a file
 CPY #2
 BGE GETDEV2 ;if it's not a file...

 RTS

*-------------------------------
* get the size of the open file
*-------------------------------

DO_SIZE JSR INPNARG ;get volume number
 CPX #3
 BGE GETDEV2 ;bad device

 LDA REFTAB-1,X ;get refnum
 STA REFNUM
 JSR GETSIZ ;get the file size
 JMP DO_MATH

*-------------------------------
* check for end of file
*-------------------------------

DO_EOF JSR INPNARG ;get channel number
 CPX #3
 BGE GETDEV2 ;bad device

 LDA REFTAB-1,X ;move refnum
 STA REFNUM
 JSR CHKEOF ;check for eof
 TXA
 JMP SVDATA ;return results

*-------------------------------
* set/get the mark for a file
*-------------------------------

DO_MARK JSR INPNARG
 CPX #10
 BEQ :DO_MRK5 ;ram drive?

 DEX
 CPX #2
 BGE :DO_MRK3 ;make sure it's a valid channel

 LDA DEVUSE+1,X ;not current in use
 BPL :DO_MRK3

 LDA REFTAB,X
 TAY  ;get refnum

 BIT IMMDEF ;see if mark was exec'ed
 BPL :DO_MRK2

 JSR GOBEQU ;possible syntax error
 STY SAVE_Y ;set the mark
 JSR INPNUM
 LDY SAVE_Y
 JMP SETMARK

:DO_MRK2 JSR GETMARK ;get the mark
 BCC :DO_MRK4 ;all is well

 LDA #1 ;error
 JMP SVDATA

:DO_MRK4 JMP DO_MATH ;return location

:DO_MRK3 LDX #baddev ;bad device #
 JMP BADERR

:DO_MRK5 BIT IMMDEF ;did they exec command?
 BPL :DO_MRK6 ;nope

 JSR GOBEQU
 JSR INPNUM ;get pointer
 STX RAMPTR ;save
 RTS

:DO_MRK6 LDA RAMPTR ;return pointer
 JMP SVDATA

*-------------------------------
* link to another segment
*-------------------------------

DO_LINK JSR DO_FRE ;compact variables
 JSR DO_CL3 ;close all open files
 JSR MOVNAME ;move filename
 LDA #0
 STA LNKLBL
 JSR CHKBYT
 CMP #","
 BNE :LINK4 ;check for link label, nope

 JSR GOBCOM ;gobble comma
 JSR INPSTR ;get link label

 LDY #0
:LINK2 LDA (STRLOC),Y ;copy label name
 JSR CONV
 INY
 CPY STRLEN
 BNE :LINK3 ;is this the last char?

 ORA #hibit
:LINK3 STA LNKLBL-1,Y ;save char
 CPY #8
 BNE :LINK2

 ORA #hibit ;mark last char
 STA LNKLBL-1,Y

:LINK4 JSR COMPRES ;compress variables
 JSR LD_MOD ;load in module
 JSR UNCOMP ;un-compress variables

 LDA #<CODEND ;were finally done!
 STA PRGPTR
 LDA #>CODEND
 STA PRGPTR+1
 LDA LNKLBL ;link to a label?
 BEQ :LINK9 ;nope, just return

 LDX #128 ;start table pointer
:LINK5 LDY #0 ;start string pointer
:LINK6 LDA LNBUF,X ;get first char
 BEQ :LINK8 ;opps, end of table

 INX
 CMP LNKLBL,Y
 BNE :LINK7 ;check it, no match
 INY
 ASL  ;are we done?
 BCC :LINK6 ;nope, keep checking

 TXA
 AND #$F0 ;round down X
 TAX

 LDA LNBUF+8,X
 STA PRGPTR ;get address and save
 LDA LNBUF+9,X
 STA PRGPTR+1
:LINK9 RTS  ;return

:LINK7 TXA  ;round down X
 AND #$F0
 CLC
 ADC #$10 ;go to next label
 TAX
 BCC :LINK5 ;keep going if more data

:LINK8 LDX #nolink ;link label not found
 JMP BADERR

LNKLBL DS 9 ;location of link label

*-------------------------------
* store current variables to a disk file
*-------------------------------

DO_STOR JSR DO_CL3 ;close any open files
 JSR MOVNAME ;move filename
 LDY #a2data
 LDA #>packfile
 LDX #<packfile
 JSR CREATE ;create file
 JSR OPEN ;open file

 JSR COMPRES ;compress memory

 LDA DATA ;point to old lomem location
 JSR WRBYTE
 LDA DATA+1
 JSR WRBYTE

 LDA FREMEM ;save # of string pages
 JSR WRBYTE

 LDA MIDMEM ;point to address of strings
 JSR WRBYTE
 LDA MIDMEM+1
 JSR WRBYTE

 SEC
 LDA HIMEM+1
 SBC MIDMEM+1
 CLC
 ADC #1 ;write # pages of data
 JSR WRBYTE

 ASL
 TAY
 LDX MIDMEM ;write data out to disk
 LDA MIDMEM+1
 JSR WRBLK

 JSR CLOSE ;close file
 JSR UNCOMP ;fix memory
 RTS

*-------------------------------
* recall a set of variables from disk to memory
*-------------------------------

DO_RCAL JSR DO_CL3 ;close all open files

 JSR MOVNAME ;get filename
 JSR CLEAR
 JSR OPEN
 BCC :RCALL2 ;all is fine
 LDX #badfn
 JMP BADERR ;illegal filename

:RCALL2 JSR RDBYTE ;restore old lomem position
 STA DATA
 JSR RDBYTE
 STA DATA+1

 JSR RDBYTE ;restore # pages of strings
 STA FREMEM

 JSR RDBYTE
 STA MIDMEM
 TAX  ;get address of data
 JSR RDBYTE
 STA MIDMEM+1
 PHA

 JSR RDBYTE ;get length of data
 ASL
 TAY
 PLA
 JSR RDBLK ;read in data

 JSR CLOSE ;close file

 LDA #1 ;make sure it uncompresses
 STA CPASS

 JSR UNCOMP ;un-compress
 RTS

*-------------------------------
* compress variables at top of memory
* at exit: data points to data
*-------------------------------

COMPRES JSR DO_FRE ;clear up memory
 LDA HIMEM ;point to var-pointers
 STA TEMP
 LDA HIMEM+1
 STA TEMP+1
 LDA #0 ;flag for pass through
 STA CPASS

:COMP2 SEC  ;walk through pointers
 LDA TEMP
 SBC #6
 STA TEMP
 LDA TEMP+1
 SBC #0
 STA TEMP+1

 LDY #0
 LDA (TEMP),Y
 BEQ :COMP5 ;were done copying
 PHP
 LDA #-1
 STA CPASS
 PLP
 BPL :COMP2 ;only do strings

 LDY #2
 LDA (TEMP),Y
 STA VPTR ;point to string
 INY
 LDA (TEMP),Y
 STA VPTR+1
 INY
 LDA (TEMP),Y
 TAX
 BEQ :COMP2 ;if 0 long...

 LDA VPTR+1 ;find out if string is in tokanized
 CMP LOMEM+1 ;program segment
 BEQ :COMP3 ;if so, move it to ram
 BGE :COMP2 ;ok, it's in memory

 CMP #>CODEND ;make sure it's really in program
 BLT :COMP2 ;good thing we checked

:COMP3 LDA VPTR
 CMP LOMEM
 BGE :COMP2 ;it's ok

 LDY #0
:COMP4 LDA (VPTR),Y
 STA (VARSTR),Y ;copy string along with other strings
 INY
 DEX
 BNE :COMP4

 TYA  ;x = y
 TAX
 LDY #2
 LDA VARSTR
 STA (VPTR),Y ;point to new string
 INY
 LDA VARSTR+1
 STA (VPTR),Y

 CLC
 TXA
 ADC VARSTR ;move up pointers
 STA VARSTR
 LDA #0
 ADC VARSTR+1
 STA VARSTR+1
 JMP :COMP2

:COMP5 LDA CPASS ;anything done?
 BEQ COMP8 ;no, just exit

 LDA TEMP ;save pointer to end of var pointers
 STA TEMP3
 LDA TEMP+1
 STA TEMP3+1

 LDA LOMEM
 CMP VARSTR
 BGE :COMP6 ;make pointers point to a boundry

 INC VARSTR+1
:COMP6 STA VARSTR
 DEC TEMP+1
 DEC VARSTR+1

 LDY #0
 STY FREMEM

:COMP7 LDA (VARSTR),Y
 STA (TEMP),Y ;copy a page
 INY
 BNE :COMP7

 LDA VARSTR+1
 INC FREMEM
 DEC TEMP+1
 DEC VARSTR+1 ;go until we are done
 CMP LOMEM+1
 BNE :COMP7

 LDX TEMP
 STX MIDMEM ;save location of strings
 LDX TEMP+1
 INX
 STX MIDMEM+1

 LDA LOMEM ;point to variables/tables
 STA DATA
 LDA LOMEM+1
 STA DATA+1
COMP8 RTS

*-------------------------------
* un-compress memory into variables
*-------------------------------

UNCOMP LDA CPASS ;anything compressed?
 BEQ COMP8 ;no, do nothing

 SEC
 LDA LOMEM
 SBC DATA
 STA DATA ;compute offset

 LDA LOMEM+1
 SBC DATA+1
 STA DATA+1 ;compute offset

 LDA LOMEM ;point at strings
 STA TEMP
 LDA LOMEM+1
 STA TEMP+1

 LDX FREMEM
 LDY #0
:UNCOMP2 LDA (MIDMEM),Y
 STA (TEMP),Y ;copy a page
 INY
 BNE :UNCOMP2

 INC MIDMEM+1
 INC TEMP+1 ;count the page
 DEX
 BNE :UNCOMP2

 LDA TEMP ;set up varstr [approx...]
 STA VARSTR
 LDA TEMP+1
 STA VARSTR+1

 LDA HIMEM
 STA TEMP
 LDA HIMEM+1
 STA TEMP+1

:UNCOMP3 SEC
 LDA TEMP
 SBC #6
 STA TEMP ;count down through strings
 LDA TEMP+1
 SBC #0
 STA TEMP+1

 LDY #0
 LDA (TEMP),Y
 BEQ :UNCOMP4 ;were done
 BPL :UNCOMP3 ;don't fool with numbers

 LDY #4 ;check length of string
 LDA (TEMP),Y ;is it an empty string?
 BEQ :UNCOMP3 ;yep

 DEY
 LDA (TEMP),Y ;get address of string
 CMP #>CODEND
 BLT :UNCOMP3 ;don't touch it

 DEY
 CLC
 LDA DATA
 ADC (TEMP),Y
 STA (TEMP),Y ;fix pointers
 INY
 LDA DATA+1
 ADC (TEMP),Y
 STA (TEMP),Y
 JMP :UNCOMP3

:UNCOMP4 SEC
 LDA TEMP+1
 SBC LOMEM+1 ;fix midmem pointer
 LSR A
 CLC
 ADC LOMEM+1
 STA MIDMEM+1

 LDA #0
 STA MIDMEM
SHWRTS RTS

*-------------------------------
* copy a file from device to device
*-------------------------------

DO_SHOW LDA #0
 STA SHW_CNT ;reset line count
 JSR CHKBYT ;check for # of lines
 CMP #"("
 BNE :SHOW0A

 JSR INPNARG ;get argument
 STX SHW_CNT ;save count

:SHOW0A JSR GETDEV ;get input source
 STY SHWIN

 LDA INPVEC,X ;save vector
 STA VECTOR2
 LDA INPVEC+1,X
 STA VECTOR2+1

 LDA REFTAB-1,Y
 STA REFNUM ;save possible refnum
 TYA
 BNE :SHOW0 ;if using device, skip

 JSR MOVNAME ;get filename

:SHOW0 JSR CHKBYT
 CMP #","
 BNE :SHOW1

 JSR GOBCOM ;gobble
:SHOW1 JSR GETDEV
 STY SHWOUT

 LDA OUTVEC,X ;save output vectors
 STA VECTOR
 LDA OUTVEC+1,X
 STA VECTOR+1

 LDA SHWIN ;get input device
 CMP #3
 BGE :SHOW3
 CMP #0
 BNE :SHOW2 ;is file open?, yep

 JSR OPEN ;open the file
 BCS SHWRTS ;we are done (that was quick!)

:SHOW2 JSR RDLNSET ;setup for rdline
 LDA REFNUM
 STA SHWREF ;save refnum

* input line of data from a disk file

:SHOW3 BIT XTERNAL ;use external?
 BMI :SHOW3X ;yep

 LDA SHWIN
 CMP #3
 BGE :SHOW3A ;char device?, yep

:SHOW3X LDA SHWREF
 STA REFNUM ;make sure refnum is correct

 JSR RDLINE ;get char
 BCC :SHOW4
 JMP :SHOW5 ;opps, end of data

* input a line of data from a character device

:SHOW3A LDX #0 ;start pointer
:SHOW3B TXA
 PHA
 JSR DO_INP ;get data
 CMP #eot
 BNE :SHOW3C ;end of section?, nope

 LDA #0 ;mark it

:SHOW3C STA LNBUF,X ;save
 TAY
 PLA
 TAX
 INX

 CPY #0
 BEQ :SHOW4 ;are we done?, yep
 CPY #cr
 BNE :SHOW3B ;end of line?, nope

* check for and handle ".x" external

 LDA SHWOUT ;is it to the crt?
 CMP #6
 BGE :SHOW4 ;nope

 LDA LNBUF ;is it a dot?
 AND #clrhi
 CMP #'.'
 BNE :SHOW4 ;nope

 LDA LNBUF+1 ;check for "X"
 JSR CONV
 CMP #'X'
 BNE :SHOW4 ;nope

 LDA LNBUF+2 ;is it a space?
 AND #clrhi
 CMP #' '
 BNE :SHOW4 ;nope

 JSR EXTERN ;set up external file
 BIT XTERNAL
 BMI :SHOW2 ;ok, file is open

* output a line of data to a device

:SHOW4 LDX #0 ;start pointer
:SHOW4A STX SHOW_X
 LDA LNBUF,X ;get data
 BEQ :SHOW5 ;we are done with file

 AND #clrhi
 CMP #lf
 BEQ :SHOW4B ;strip all lf's
 PHA
 JSR DO_OUT ;output it
 PLA

:SHOW4B LDX SHOW_X ;get back pointer
 INX
 CMP #cr
 BNE :SHOW4A ;done with line?, nope

* handle end of line of output

 LDA SHW_CNT ;is there a line limit?
 BEQ :SHOW4C ;nope

 DEC SHW_CNT
 BEQ :SHOW5 ;count down lines, opps, that is all

:SHOW4C LDA SHWIN ;is this a read mail?
 CMP #7
 BEQ :JSHOW3 ;yep

 LDA SHWOUT ;is output to the crt?
 BNE :JSHOW3 ;nope

 BIT INTOUT ;stop output?
 BPL :JSHOW3 ;nope

* handle end of output and return

:SHOW5 BIT XTERNAL ;external on?
 BMI :SHOW5B ;yep, close it

 LDA SHWIN ;is this from a disk file?
 BNE :SHOW6 ;nope

:SHOW5B LDA SHWREF
 STA REFNUM ;get correct refnum
 JSR CLOSE ;close file
 BIT XTERNAL
 BPL :SHOW6

 INC XTERNAL ;turn off external
:JSHOW3 JMP :SHOW3 ;and continue

:SHOW6 LDA SHWOUT ;check destination
 CMP #4 ;is it console, disk 1 or 2?
 BLT EXTERN2 ;yep, don't send null, just return

 LDA #0 ;were finished
 JMP DO_OUT

EXTERN LDA #<LNBUF+3 ;point to filename
 STA STRLOC
 LDA #>LNBUF+3
 STA STRLOC+1
 LDA #19
 STA STRLEN ;save max string length
 JSR MOVNM0 ;move the filename

 JSR IFOPEN ;open file
 BCS EXTERN2 ;opps, file didn't open

 DEC XTERNAL ;flag that external read is on
EXTERN2 RTS

SHWIN DB 0
SHWOUT DB 0
SHWREF DB 0
XTERNAL DB 0

*-------------------------------
* position into a file
*-------------------------------

DO_POS JSR GETDEV ;get device
 JSR CHKDSK ;make sure it's a file

 LDA REFTAB,Y
 STA REFNUM ;save the reference number

 JSR INPNUM ;get record length
 STX FLPOS ;save rec length
 STA FLPOS+1

 JSR GOBCOM ;gobble comma
 JSR INPNUM ;get record number
 STX FLPOS+2 ;save rec number
 STA FLPOS+3

 LDA #0
 STA FLPOS+4 ;default offset to 0
 JSR CHKBYT
 CMP #","
 BNE :DO_POS2 ;check for last arg...

 JSR GOBCOM ;gobble comma
 JSR INPNUM
 STX FLPOS+4 ;save byte offset

:DO_POS2 LDX FLPOS ;set up for multiply
 LDA FLPOS+1
 JSR SAVNUMB

 LDA FLPOS+2
 STA DATA+1
 LDA FLPOS+3
 STA DATA+2

 JSR DO_MUL0

 CLC
 LDA FLPOS+4
 ADC RESULT
 TAX  ;save low (X)
 LDA #0 ;compute med (A)
 ADC RESULT+1
 LDY RESULT+2 ;get high (Y)
 JMP SETPOS

*-------------------------------
* read data from device into memory
*-------------------------------

DO_READ JSR GETDEV
 LDA INPVEC,X ;point to vector
 STA VECTOR2
 LDA INPVEC+1,X
 STA VECTOR2+1

 JSR INPNUM ;point to data
 STX TEMP2
 STA TEMP2+1

 JSR GOBCOM ;gobble comma
 JSR INPNUM ;get length of read

 LDY #0
:DO_RD2 JSR DO_INP ;read data into memory
 STA (TEMP2),Y
 INY
 DEX
 BNE :DO_RD2
 RTS

*-------------------------------
* write data to a device
*-------------------------------

DO_WRIT JSR GETDEV
 LDA OUTVEC,X ;set up vectors
 STA VECTOR
 LDA OUTVEC+1,X
 STA VECTOR+1

 JSR INPNUM ;point to data
 STX TEMP2
 STA TEMP2+1

 JSR GOBCOM ;gobble comma
 JSR INPNUM ;get length

 LDY #0
:DO_WR2 LDA (TEMP2),Y ;write data
 JSR DO_OUT
 INY
 DEX
 BNE :DO_WR2
 RTS

*-------------------------------
* kill a file (or message)
*-------------------------------

DO_KILL JSR CHKBYT
 CMP #"#"
 BEQ :KILL2 ;kill message?, yep

 JSR MOVNAME ;get filename
 JMP DELFILE ;delete file

:KILL2 JSR GETDEV ;get msg number
 LDX MSGNUM
 LDA MSGNUM+1
 JSR MSG

 LDY #2 ;get first block into A & X
 LDA (TEMP),Y
 PHA
 INY
 LDA (TEMP),Y
 PHA

 LDA #0
 STA (TEMP),Y ;zero pointers
 DEY
 STA (TEMP),Y
 DEY
 STA (TEMP),Y
 DEY
 STA (TEMP),Y
 JSR WRTDIR ;write dir back to disk

 PLA  ;get high
 TAY
 PLA  ;get low
 TAX
 TYA

:KILL3 STX MSGNUM ;save block number
 STA MSGNUM+1
 ORA MSGNUM ;done?
 BEQ :KILL4 ;yep

 LDA MSGNUM+1
 JSR DEALLOC ;de-alloc block

 LDX MSGNUM ;get block number
 LDA MSGNUM+1
 JSR SETBLK ;position to block

 LDX #<LNBUF ;read in block
 LDA #>LNBUF
 LDY #1
 JSR RDBLK

 LDX LNBUF+126 ;get next block number
 LDA LNBUF+127
 JMP :KILL3 ;and repeat

:KILL4 JSR WRTBIT ;update bitmap
 JMP FINISH ;write out dir info

*-------------------------------
* ready a message file
*-------------------------------

DO_RDY JSR CHKBYT ;do they want to ready a message?
 CMP #"#"
 BNE :DO_RDY0 ;nope

 JMP GETDEV ;fix message

:DO_RDY0 LDA MSGREF ;get back old refnum
 STA REFNUM
 BEQ :DO_RDY1 ;file is closed

 JSR CLOSE ;close old msgfile

:DO_RDY1 JSR MOVNAME ;get msg-file name
 LDA FLNAME
 BEQ :DO_RDY3 ;they are done with it

 LDY #2 ;use msgfile buffer
 JSR BFOPEN ;open file
 BCS :DO_RDY4 ;hmmm, thats bad!

 LDA REFNUM
 STA MSGREF ;save refnum

 LDY #0
:DO_RDY2 JSR RDBYTE ;read in info
 STA MSGINFO,Y
 INY
 CPY #8
 BNE :DO_RDY2

 LDA #-1
 STA DIRSEG ;no dir or bit seg loaded
 STA BITSEG
 STA DEVUSE+6
 STA DEVUSE+7
:DO_RDY3 RTS

:DO_RDY4 LDX #nomsg ;message file not found
 JMP BADERR

FINISH LDA MSGREF ;get refnum
 STA REFNUM
 LDX #0
 TXA
 JSR SETMARK

 LDY #0
:FINISH2 LDA MSGINFO,Y ;write the info
 JSR WRBYTE
 INY
 CPY #8
 BNE :FINISH2
 RTS

*-------------------------------
* get new message info (or number of messages)
*-------------------------------

DO_MSG JSR INPNARG ;what message do they want to know about?

 BIT IMMDEF ;is this an assignment [msg(x)=] ?
 BMI :DO_MSG4 ;yep

 CPX MSGINFO+4
 BNE :DO_MSG2 ;is it the last message?, nope
 CMP MSGINFO+5
 BNE :DO_MSG2 ;nope

 LDX MSGINFO+6 ;we don't need to load the dir to find out
 LDA MSGINFO+7
 JMP DO_MATH

:DO_MSG2 ORA NUMB ;do they want the number of files?
 BNE :DO_MSG3 ;nope

 LDX MSGINFO+4 ;get number of files
 LDA MSGINFO+5
 JMP DO_MATH

:DO_MSG3 JSR GETNUMB ;get message number
 JSR MSG ;get info

 LDY #0
 LDA (TEMP),Y ;get new message # into a & x
 TAX
 INY
 LDA (TEMP),Y
 JMP DO_MATH ;finish up

:DO_MSG4 PHA  ;save msg number
 TXA
 PHA

 JSR GOBEQU ;gobble
 JSR INPNUM ;get number

 PLA  ;get back msg number
 TAX
 PLA

 CPX MSGINFO+4
 BNE :DO_MSG5 ;is this last message?, nope

 CMP MSGINFO+5
 BNE :DO_MSG5 ;check high, nope

 PHA  ;save a and x
 TXA
 PHA

 JSR GETNUMB ;update highest new message
 STX MSGINFO+6
 STA MSGINFO+7
 JSR FINISH ;write info to disk

 PLA  ;restore a and x
 TAX
 PLA

:DO_MSG5 JSR MSG ;position to info

 JSR GETNUMB ;get the new number
 LDY #1
 STA (TEMP),Y ;save new message number
 DEY
 TXA
 STA (TEMP),Y
 JMP WRTDIR ;write dir back to disk

*-------------------------------
* position and load directory for needed segment
* and setup pointers for needed entry
*-------------------------------

MSG DEX  ;msg = msg - 1
 CPX #-1
 BNE :MSG1

 SEC
 SBC #1

:MSG1 STX TEMP ;save msg number
 STX TEMP2

 ASL TEMP2 ;compute dir section number
 ROL
 ASL  ;a = a * 4
 ASL  ;make A into actual block number
 CMP DIRSEG
 BEQ :MSG2

 STA DIRSEG ;save loaded dir seg number
 CLC
 ADC MSGINFO ;add in dir offset

 TAX
 LDA #0 ;we have starting block
 JSR POSMSG ;position for read

 LDX #<DIRBUF ;point to buffer
 LDA #>DIRBUF
 LDY #4 ;read 4 blocks
 JSR RDBLK

:MSG2 LDA TEMP ;get msg number
 ASL
 ASL  ;a = a * 4
 STA TEMP
 LDA #0 ;put last bit into a
 ROL
 CLC
 ADC #>DIRBUF ;add in location of buffer
 STA TEMP+1
 RTS  ;all is set up

*-------------------------------
* read a mail file
*-------------------------------

RDMAIL BIT DEVCLR ;is this start?
 BMI :RDMAIL2 ;nope

 STX BUF_X ;save x
 LDX #4
:RDMAIL1 LDA MSGPTR,X
 STA RWDPTR,X ;copy all 5 bytes
 DEX
 BPL :RDMAIL1 ;loop

 LDX BUF_X
 DEC DEVCLR ;clear change
:RDMAIL2 JMP RDMSG

*-------------------------------
* rewind file to previous spot
*-------------------------------

DO_RWD LDX RWDBLK ;get old block number
 LDA RWDBLK+1

 CPX RMXBLK
 BNE :DO_RWD1 ;check low, nope

 CMP RMXBLK+1
 BEQ :DO_RWD2 ;check high, yep, it's the same

:DO_RWD1 STX RMXBLK ;update
 STA RMXBLK+1

 JSR SETBLK ;point to block
 LDX #<BLKBUF ;read block back in
 LDA #>BLKBUF
 LDY #1
 JSR RDBLK

:DO_RWD2 LDA RWDPTR
 STA MSGPTR ;move pointers
 LDA RWDBYT8
 STA BYTE8
 LDA RWDCHR8
 STA CHAR8
 RTS

* setup message for read

SETMSG LDA #-1
 STA MSGINIT ;init message base
 LDX MSGNUM ;get message number
 LDA MSGNUM+1
 JSR MSG ;locate message

 LDY #2 ;get starting block number
 LDA (TEMP),Y
 TAX
 INY
 ORA (TEMP),Y ;check for no data...
 BNE SETMSGX
 JMP SETMSG2

SETMSGX LDA (TEMP),Y
SETMSG1 STX RMXBLK ;save current block number
 STA RMXBLK+1
 JSR SETBLK ;position and translate

 LDA #0
 STA RDEND ;reset end pointer
 STA BLKBUF
 LDX #<BLKBUF ;and read data
 LDA #>BLKBUF
 LDY #1
 JSR RDBLK

 LDY #0
 STY MSGPTR ;reset pointer
 LDA #6
 STA BYTE8 ;reset hidden byte counter
 LDX MSG_X ;get back x and y
 LDY MSG_Y

* ... fall through and read a byte ...

*-------------------------------
* read a byte of message
*-------------------------------

RDMSG STX MSG_X ;save both x and y
 STY MSG_Y

 BIT MSGINIT ;is read in progress?
 BPL SETMSG ;nope, start it

 BIT RDEND ;at end of data?
 BMI SETMSG2 ;yep

 BIT BYTE8 ;check for hidden byte
 BMI RDMSG2 ;do it

 LDY MSGPTR ;get index
 CPY #126
 BEQ RDMSG3 ;need more data?, yep

 LDA BLKBUF,Y ;get byte
 ASL  ;put extra bit into carry
 BEQ RDMSG4 ;opps, end of data
 ROR CHAR8 ;put carry into hidden byte
 LSR  ;fix byte
 INC MSGPTR ;inc pointer
 DEC BYTE8 ;count down for hidden byte
 JMP SETMSG3

RDMSG2 LDA CHAR8 ;get hidden byte
 LSR  ;fix
 BEQ RDMSG4

 LDX #6
 STX BYTE8 ;reset hidden byte counter
 JMP SETMSG3

RDMSG3 LDA BLKBUF+126
 TAX
 ORA BLKBUF+127 ;is next block 0?
 BEQ RDMSG4 ;yep

 LDA BLKBUF+127
 JMP SETMSG1 ;read next block

RDMSG4 DEC RDEND ;at end of data

SETMSG2 LDA #0 ;opps, no data
SETMSG3 LDX MSG_X ;get back data
 LDY MSG_Y
 RTS

*-------------------------------
* setup message for write
*-------------------------------

WRTMSG LDX MSGNUM ;get msg number
 LDA MSGNUM+1

 CMP MSGINFO+5
 BEQ WRTMSG0
 BLT WRTMSG1
 BGE WRTMSG5 ;is the meessage file this big?

WRTMSG0 CPX MSGINFO+4
 BLT WRTMSG1

WRTMSG5 STX MSGINFO+4 ;update message count
 STA MSGINFO+5

WRTMSG1 JSR MSG ;locate message
 LDY #2
 LDA (TEMP),Y
 INY
 ORA (TEMP),Y
 BNE WRTMSG2

 JSR ALLOC ;allocate new block

 STX WRKBLK ;update block number
 STA WRKBLK+1

 LDY #3
 STA (TEMP),Y
 DEY
 TXA
 STA (TEMP),Y
 JSR WRTDIR ;write dir back to disk

 LDX MSG_X
 DEC MSGINIT ;init msg
 LDA #6
 STA BYTE82 ;init byte counter
 LDA #0
 STA MSGPTR2 ;init message pointer
 BEQ WRTMSG4

WRTMSG2 LDA BITSEG ;bitmap loaded?
 CMP #-1
 BNE WRTMSG2A ;yes

 LDY #2 ;read in bitmap
 LDA (TEMP),Y
 TAX
 INY
 LDA (TEMP),Y
 JSR GETBITS

WRTMSG2A JSR SWPBLK ;swap pointers
 LDX MSG_X ;restore x and y
 LDY MSG_Y

WRTMSG3 JSR RDMSG ;do append to current data
 CMP #0
 BNE WRTMSG3

 JSR SWPBLK ;swap back
WRTMSG4 LDY MSG_Y
 LDA #0
 STA WRTEND ;let them write data

WRTMSG6 LDX MSG_X ;get back parms
 LDY MSG_Y
 PLA

* ... fall througn and write byte ...

*-------------------------------
* write a byte to a message
*-------------------------------

WRMSG PHA
 STX MSG_X ;save x and y
 STY MSG_Y

 BIT MSGINIT ;have we started?
 BMI WRMSG0A
 JMP WRTMSG ;nope

WRMSG0A BIT WRTEND ;has end been written?
 BMI WRMSG1B ;yep, take no more

 BIT BYTE82 ;check for hidden byte
 BMI WRMSG2 ;add it

 LDY MSGPTR2 ;get index
 CPY #126
 BEQ WRMSG1 ;allocate new block?, yep

 STA BLKBUF2,Y ;save data and continue
 INC MSGPTR2
 DEC BYTE82 ;count down hidden byte
 CMP #0
 BNE WRMSG4

WRMSG0 LDX #0
 STX BLKBUF2+126 ;no link
 STX BLKBUF2+127
 JMP WRMSG1A ;skip around link setup

WRMSG1 JSR ALLOC ;allocate new block
 STX BLKBUF2+126
 STA BLKBUF2+127

WRMSG1A LDX WRKBLK ;translate and position block
 LDA WRKBLK+1
 JSR SETBLK

 LDX #<BLKBUF2 ;write the block
 LDA #>BLKBUF2
 LDY #1
 JSR WRBLK

 LDA #0
 STA MSGPTR2 ;reset pointer
 LDA #6
 STA BYTE82 ;reset hidden counter

 LDA BLKBUF2+126 ;save new block number
 STA WRKBLK
 LDA BLKBUF2+127
 STA WRKBLK+1
 ORA WRKBLK ;is there another block?
 BNE WRTMSG6 ;yep

 JSR WRTBIT ;write out bitmap
 JSR FINISH ;write out info
 DEC WRTEND ;end has been written
 LDX MSG_X
 LDY MSG_Y
WRMSG1B PLA
 RTS

WRMSG2 LDX MSGPTR2
 LDY #7
 ASL
WRMSG3 DEX
 ROL BLKBUF2,X ;add in bit 7
 ASL
 ROR BLKBUF2,X
 DEY
 BNE WRMSG3

 LDX #6
 STX BYTE82
 PLA  ;get back byte
 PHA
 BEQ WRMSG0

WRMSG4 LDX MSG_X ;restore x and y
 LDY MSG_Y
 PLA
 RTS

*-------------------------------
* allocate a block for data
*-------------------------------

ALLOC LDA BITSEG ;fresh start?
 CMP #$FF
 BEQ :ALLOC4 ;yep

 LDY #0 ;start count
:ALLOC2 LDX #0
:ALLOC3 LDA BITBUF,Y ;search for free block
 AND BITVAL,X
 BEQ :ALLOC5 ;found one

 INX  ;done with byte?
 CPX #8
 BNE :ALLOC3 ;nope
 INY
 BPL :ALLOC2 ;done with buffer?, nope

 JSR WRTBIT ;write bit map back to disk

:ALLOC4 INC BITSEG ;is there more space?
 JSR RDBIT ;read in bit map segment
 JMP ALLOC ;start (keep) looking

:ALLOC5 LDA BITBUF,Y
 ORA BITVAL,X ;mark byte
 STA BITBUF,Y

 STY TEMP2 ;shift Y into 16 bits
 LDA #0 ;bit16 = y * 8
 ASL TEMP2
 ROL
 ASL TEMP2
 ROL
 ASL TEMP2
 ROL
 STA TEMP2+1

 TXA  ;add in x
 SEC  ;special (+1)
 ADC TEMP2 ;bit16 = bit16 + x + 1
 TAX
 LDA #0
 ADC TEMP2+1
 STA TEMP2+1

 LDA BITSEG ;add in segment
 ASL
 ASL  ;a = a * 4
 CLC
 ADC TEMP2+1 ;bit16 = bit16 + a

 INC MSGINFO+2
 BNE :ALLOC6 ;add 1 to used blocks
 INC MSGINFO+3
:ALLOC6 RTS

*-------------------------------
* de-alloc
*-------------------------------

DEALLOC JSR GETBITS

 LDA TEMP ;shift down temp 3 bits into A
 LSR TEMP+1
 ROR
 LSR TEMP+1
 ROR
 LSR
 TAY

 LDX TEMP2 ;get bit offset
 LDA BITVAL,X
 EOR #$FF
 AND BITBUF,Y ;clear bit
 STA BITBUF,Y ;and save

 LDA MSGINFO+2 ;used blocks = used blocks -1
 BNE :DEALL3
 DEC MSGINFO+3
:DEALL3 DEC MSGINFO+2
 RTS

* read in bitmap, save old one (if any)

GETBITS SEC
 PHA
 TXA
 SBC #1
 STA TEMP
 AND #%00000111
 STA TEMP2 ;save offset (in bits)
 PLA
 SBC #0
 STA TEMP+1 ;temp = (AX)-1

 LSR
 LSR  ;a = a / 4

 CMP BITSEG
 BEQ :DEALL2 ;are we in position?, yep

 PHA
 LDA BITSEG ;first access to bitmap?
 CMP #$FF
 BEQ :DEALL1 ;yep, done write

 JSR WRTBIT ;hmmm, write out current bitmap
:DEALL1 PLA
 STA BITSEG ;update segment
 JSR RDBIT ;read bit map
:DEALL2 RTS

* read bit map from disk

RDBIT LDX BITSEG
 LDA #0
 JSR POSMSG ;position to block

 LDX #<BITBUF ;read in block
 LDA #>BITBUF
 LDY #1
 JMP RDBLK

* write bit map back to disk

WRTBIT LDX BITSEG ;position to block
 LDA #0
 JSR POSMSG

 LDX #<BITBUF ;write current block out
 LDA #>BITBUF
 LDY #1
 JMP WRBLK

*-------------------------------
* position to false block number
*-------------------------------

SETBLK STX POSBLK ;save block number
 STA POSBLK+1
 CLC
 LDA MSGINFO ;a = msginfo + msginfo(1)
 ADC MSGINFO+1
 SEC  ;a = a - 1
 SBC #1
 CLC
 ADC POSBLK ;blk = blk + a
 TAX
 LDA POSBLK+1
 ADC #0
 JMP POSMSG

*-------------------------------
* write the current directory segment back to disk
*-------------------------------

WRTDIR CLC
 LDA DIRSEG ;position to dir segment
 ADC MSGINFO
 TAX
 LDA #0
 JSR POSMSG

 SEC
 LDA MSGINFO+1 ;get # of dir blocks
 SBC DIRSEG ;subtract current pointer
 CMP #4
 BLT :WRTDIR1 ;there are less than 4 blocks left
 LDA #4 ;there are more - only write 4

:WRTDIR1 TAY  ;# of blocks to write
 LDX #<DIRBUF ;write it
 LDA #>DIRBUF
 JMP WRBLK

*-------------------------------
* switch block buffers
*-------------------------------

SWPBLK LDY #127
:SWPBLK2 LDA BLKBUF,Y ;get buf 1 char
 PHA  ;save
 LDA BLKBUF2,Y
 STA BLKBUF,Y ;get buf 2 char, put in buf 1
 PLA
 STA BLKBUF2,Y ;restore buf 1 char, put in buf 2
 DEY
 BPL :SWPBLK2 ;loop

 LDY #5
:SWPBLK3 LDA MSGPTR,Y ;swap pointers
 PHA
 LDA MSGPTR2,Y
 STA MSGPTR,Y
 PLA
 STA MSGPTR2,Y
 DEY
 BPL :SWPBLK3
 RTS

*-------------------------------
* create a file
*-------------------------------

DO_MAKE JSR MOVNAME ;get filename
 LDY #txt ;TEXT
 LDA #<notype
 LDX #>notype
 JMP CREATE ;create it

*-------------------------------
* crunch a message file
*-------------------------------

DO_CNCH LDX #$FF
 STX DIRSEG
 STX DIRSEG+1 ;load in first dir block
 INX
 STX MSGINFO+4 ;reset number of msg's
 STX MSGINFO+5
 LDX #128
 LDY #128

:CRUNCH2 CPX #128
 BEQ :CRUNCH3 ;at end of block?

 LDA DIRSEG ;more data?
 CMP MSGINFO+1
 BEQ :CRUNCH7 ;yep

 LDA DIRBUF+2,X ;is there any entry?
 ORA DIRBUF+3,X
 BNE :CRUNCH4 ;yep

 INX  ;x = x + 4
 INX
 INX
 INX
 BPL :CRUNCH2 ;keep going until 128 done

:CRUNCH3 INC DIRSEG
 LDX #0
 LDA DIRSEG ;are we done?
 CMP MSGINFO+1
 BEQ :CRUNCH2 ;yep

 STY SAVE_Y ;save Y
 CLC
 ADC MSGINFO ;add in bitmap offset
 TAX
 LDA #0
 JSR POSMSG ;position

 LDX #<DIRBUF ;read next dir block
 LDA #>DIRBUF
 LDY #1
 JSR RDBLK

 LDY SAVE_Y ;restore Y
 LDX #0
 BEQ :CRUNCH2 ;keep going

:CRUNCH7 LDX #0
 STX DIRBUF ;use 0 offset
 STX DIRBUF+1
 STX DIRBUF+2 ;zero pointers
 STX DIRBUF+3

:CRUNCH4 CPY #128
 BEQ :CRUNCH6 ;at end of block?, yep

:CRUNCH5 LDA DIRSEG ;are we at end?
 CMP MSGINFO+1
 BEQ :CRUNCH6 ;yep

 INC MSGINFO+4
 BNE :CRUNCH5A ;add one to message count
 INC MSGINFO+5

:CRUNCH5A LDA DIRBUF,X
 STA MSGINFO+6 ;copy byte
 STA DIRBUF+128,Y ;and save in new message field
 INX
 INY

 LDA DIRBUF,X
 STA MSGINFO+7 ;copy other byte
 STA DIRBUF+128,Y ;and save in new message field
 INX
 INY

 LDA DIRBUF,X
 STA DIRBUF+128,Y ;copy byte
 INX
 INY
 LDA DIRBUF,X
 STA DIRBUF+128,Y ;copy byte
 INX
 INY

 JMP :CRUNCH2

:CRUNCH6 LDA DIRSEG+1 ;do we want to write this?
 CMP #$FF
 BEQ :CRUNCH8 ;nope

 STX SAVE_X ;save x
 CLC
 ADC MSGINFO ;add in bitmap
 TAX
 LDA #0
 JSR POSMSG ;position

 LDX #<DIRBUF+128 ;write out dir segment
 LDA #>DIRBUF+128
 LDY #1
 JSR WRBLK

 LDX SAVE_X ;restore x
 LDY #128
:CRUNCH8 LDA #0
:CRUNCH9 STA DIRBUF+127,Y ;fill buffer with 0's
 DEY
 BNE :CRUNCH9

 INC DIRSEG+1 ;use next segment
 TAY
 LDA DIRSEG+1
 CMP MSGINFO+1
 BNE :CRUNCH5 ;are we at end?, nope

 JSR FINISH ;write out 8 byte header
 LDA #$FF
 STA DIRSEG ;reset dir segment
 RTS

*-------------------------------
* update a file back to disk
*-------------------------------

DO_UP LDA MSGREF ;use msg refnum
 STA REFNUM
 JMP FLUSH ;flush file back to disk

*-------------------------------
* use an external command
*-------------------------------

DO_USE LDA MSGREF ;get back old refnum
 STA REFNUM
 BEQ :DO_USE1 ;file is closed

 JSR CLOSE ;close old msgfile

 LDA #0
 STA MSGREF

:DO_USE1 LDY #0
 JSR SETIVEC ;set to default input/output
 JSR SETOVEC

 JSR MOVNAME ;setup filename
 JSR OPEN ;open file
 BCS :DO_USE2

 LDX #<ENDMOD
 LDA #>ENDMOD
 LDY #32 ;read 32 - 128 byte pages (4k)
 JSR RDBLK

 JSR CLOSE ;finish up
 JMP ENDMOD ;exec external routine

:DO_USE2 LDX #badxtrn ;unable to load external
 JMP BADERR


