 PAG
********************************
*                              *
* ACOS.OBJ - Copyright Encode  *
*                              *
********************************

 ORG $300

COPCODE LDA #<COPNOT
 STA TEMP
 LDA #>COPNOT
 STA TEMP+1
 LDY #COPEND-COPNOT
 DEY
:LOOP LDA (TEMP),Y
 ROL A
 EOR #COPEND-COPNOT
 STA (TEMP),Y
 DEY
 BPL :LOOP

 LDA #<SERNUM
 STA TEMP
 LDA #>SERNUM
 STA TEMP+1
 LDY #SEREND-SERNUM
 DEY
:LOOP2 LDA (TEMP),Y
 ROL A
 EOR #SEREND-SERNUM
 STA (TEMP),Y
 DEY
 BPL :LOOP2
 RTS


