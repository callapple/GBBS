MLI = $BF00
Read_Blk = $80
ATCall = $42 ;appletalk MLI call
NodeSave = $DE ;location to pass node # to ACOS
Prefix = $c6
LastDev = $BF30

init LDA LastDev ;get the device we just lauched from
 STA UnitNum ;save it

 JSR MLI ;do a block read (invalid under AppleTalk)
 DB Read_Blk
 DA r_block

 CMP #$88
 BNE init_0 ;did not boot off server

 JSR MLI ;get the user directory...
 DB ATCall
 DA FIUserPFX

 LDX copybuf
 BEQ init_0 ;no user directory found

 DEX
 LDA copybuf,x
 AND #$0F ;strip of the $cx part of the ASCII eqiv.
 STA NodeSave

 INC r_file ;kick file length up a byte
 LDX r_file ;length of acos.obj
 LDA NodeSave
 ORA #$c0 ;make it an ascii #
 STA r_file,x

init_0 RTS



r_file STR 'ACOS.OBJ'
 DS 2

r_block DB 3
UnitNum DS 1
 DA copybuf+$200
 DA 0

FIUserPFX DB $00 ;Synchronous Only
 DB $2A ;Command
Result DW $0 ;Result Code
 DB $00 ;Reserved
 ADRL copybuf ;pointer to Pathname

 ds \
copybuf


