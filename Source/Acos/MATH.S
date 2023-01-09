 PAG
********************************
*                              *
*       ACOS.OBJ - Math        *
*                              *
********************************
 DATE
*-------------------------------

DO_PLUS LDA NUMB+1 ;save old number
 PHA
 LDA NUMB
 PHA
 JSR INPMATH ;get next part
 CLC
 PLA
 ADC NUMB ;do add
 TAX
 PLA
 ADC NUMB+1
 JMP DO_MATH ;finish up

DO_SUB LDA NUMB+1 ;save initial value
 PHA
 LDA NUMB
 PHA
 JSR INPMATH ;get other amount
 SEC
 PLA
 SBC NUMB ;do actual subtraction
 TAX
 PLA
 SBC NUMB+1

DO_MATH STX DATA+1 ;save result
 STA DATA+2
 LDY #1
 STY DATA ;set data type 1
 RTS

*-------------------------------
* do multiply
*-------------------------------

DO_MULT JSR DO_MLDV ;command mult/divd
 JSR DO_MUL0 ;do multiply

*-------------------------------
* finish up routine for signed operands
*-------------------------------

DO_MLD2 LDX RESULT
 LDA RESULT+1
 BPL :DO_MLD3

 LDX #num2big
 JMP BADERR ;overflow > 32767

:DO_MLD3 BIT SIGN
 BPL DO_MATH

 JSR NEGXA
 JMP DO_MATH

DO_MLDV JSR GETNUMB ;get first number
 STA SIGN ;save this sign
 JSR DO_ABS1 ;make it positive
 STX DATA+1 ;save it
 STA DATA+2

 JSR INPNUM0 ;get next number
 EOR SIGN ;make into result sign
 STA SIGN
 LDA NUMB+1 ;get this sign
 JSR DO_ABS1 ;make this positive too
 STX NUMB ;save it
 STA NUMB+1
 RTS

*-------------------------------
* actual multiply routine
*-------------------------------

DO_MUL0 LDA #0
 STA RESULT
 STA RESULT+1
 STA RESULT+2
 STA DATA+3
 LDX #16
:DO_MUL1 LSR NUMB+1
 ROR NUMB ;put bit 0 into carry
 BCC :DO_MUL2

 CLC
 LDA DATA+1
 ADC RESULT
 STA RESULT ;add in multiplyer

 LDA DATA+2
 ADC RESULT+1
 STA RESULT+1 ;add in multiplyer

 LDA DATA+3
 ADC RESULT+2
 STA RESULT+2

:DO_MUL2 ASL DATA+1 ;multiply all 16 bits
 ROL DATA+2
 ROL DATA+3
 DEX
 BNE :DO_MUL1
 RTS

*-------------------------------
* divide routine
*-------------------------------

DO_DIVD JSR DO_DIV1 ;do divide
 JMP DO_MLD2

DO_MOD JSR DO_DIV1 ;do divide
 LDA REMAIN ;get remainder
 STA RESULT
 LDA REMAIN+1
 STA RESULT+1
 JMP DO_MLD2 ;finish up

DO_DIV1 JSR DO_MLDV
 LDA NUMB
 ORA NUMB+1
 BEQ :DO_DIV5

 LDA #0
 STA REMAIN ;clear remainder
 STA REMAIN+1
 CLC

 LDX #16
:DO_DIV2 ROL DATA+1 ;shift up the carry bit
 ROL DATA+2
 ROL REMAIN
 ROL REMAIN+1

 SEC
 LDA REMAIN ;check for remainder > divisor
 SBC NUMB
 TAY
 LDA REMAIN+1
 SBC NUMB+1
 BCC :DO_DIV3 ;nope, skip subtract

 STY REMAIN ;allow subtract to take place
 STA REMAIN+1

:DO_DIV3 DEX
 BNE :DO_DIV2

 ROL DATA+1 ;shift in quotent
 ROL DATA+2

 LDA DATA+1
 STA RESULT
 LDA DATA+2
 STA RESULT+1
 RTS

:DO_DIV5 LDX #divby0 ;division by zero
 JMP BADERR

*-------------------------------
* absolute value
*-------------------------------

DO_ABS JSR INPARG
 JSR GETNUMB ;get number
 JSR DO_ABS1 ;get abs
 JMP DO_MATH ;finish up

DO_ABS1 CMP #0
 BPL DO_ABS2 ;if it is already ok

NEGXA PHA
 TXA
 EOR #-1
 TAX  ;make positive
 PLA
 EOR #-1

 INX
 BNE DO_ABS2 ;and add 1

 CLC
 ADC #1
DO_ABS2 RTS

*-------------------------------
* ----- compare routines -------
*-------------------------------

CP_EQ JSR CP_ST ;compare for equal
 JSR CMPEQ
 JMP CP_END

CP_NOT JSR CP_ST ;compare if not equal
 JSR CMPEQ ;just inverse compare equal
 JSR INVERT
 JMP CP_END

CP_LT JSR CP_ST ;compare if less than
 JSR CP_LTGT
 JSR CMPLT
 JMP CP_END

CP_GT JSR CP_ST ;compare if greater than
 JSR CP_LTGT
 JSR CMPGT
 JMP CP_END

CP_LTEQ JSR CP_ST ;compare if less than or equal
 JSR CP_LTGT
 JSR CMPGT ;just inverse compare greater than
 JSR INVERT
 JMP CP_END

CP_GTEQ JSR CP_ST ;compare if greater than or equal
 JSR CP_LTGT
 JSR CMPLT ;just inverse compare less than
 JSR INVERT
 JMP CP_END

CP_AND JSR CP_ST ;'and' 2 numbers
 LDA NUMB
 AND DATA+1
 TAX
 LDA NUMB+1
 AND DATA+2
 JMP CP_END

CP_OR JSR CP_ST ;'or' 2 numbers
 LDA NUMB
 ORA DATA+1
 TAX
 LDA NUMB+1
 ORA DATA+2
 JMP CP_END

CP_EOR JSR CP_ST ;'eor' 2 numbers
 LDA NUMB
 EOR DATA+1
 TAX
 LDA NUMB+1
 EOR DATA+2
 JMP CP_END

CP_ST LDA NUMB ;compare start
 PHA
 LDA NUMB+1 ;just save stuff
 PHA
 JSR INPMATH
 PLA
 STA DATA+2
 PLA
 STA DATA+1
 RTS

CP_LTGT LDA DATA+2
 EOR #hibit ;invert sign bits of numbers
 STA DATA+2
 LDA NUMB+1
 EOR #hibit
 STA NUMB+1
 RTS

CP_END STX DATA+1
 STA DATA+2 ;save result
 LDY #1
 STY DATA
 RTS

*-------------------------------
* ----- logic operations -------
*-------------------------------

CMPEQ LDX #0
 LDA NUMB
 CMP DATA+1
 BNE :CMPEQ0

 LDA NUMB+1
 CMP DATA+2
 BNE :CMPEQ0

 INX

:CMPEQ0 LDA #0
 RTS

CMPLT LDX #0
 LDA NUMB+1
 CMP DATA+2
 BLT :CMPLT0
 BNE :CMPLT1

 LDA NUMB
 CMP DATA+1
 BEQ :CMPLT0
 BLT :CMPLT0

:CMPLT1 INX

:CMPLT0 LDA #0
 RTS

CMPGT LDX #0
 LDA DATA+2
 CMP NUMB+1
 BLT :CMPGT0
 BNE :CMPGT1

 LDA DATA+1
 CMP NUMB
 BEQ :CMPGT0
 BLT :CMPGT0

:CMPGT1 INX

:CMPGT0 LDA #0
 RTS

INVERT PHA  ;change bit 0
 TXA
 EOR #1
 TAX
 PLA
 RTS


