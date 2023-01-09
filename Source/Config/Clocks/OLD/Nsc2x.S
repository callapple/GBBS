 TTL "ACOS 2.x-NSC driver"

 rel
 dsk rel/noslot

* ACOS 2.x-NSC Clock driver (modified 90/02/10-JAB)
 DUMMY $42
NSC_work
NSC_Ptr DS 2 ;Pointer to NSC Init string
NSCoutpt
Year DS 1
Month DS 1
Date DS 1
 DS 1 ;<Day of week>
Hour DS 1
 DS 1 ;<Minutes>
 DS 2 ;<Seconds/ .01 Seconds>
 DEND
 DUMMY $2F0
NSC_save DS 10 ;Zero-Page save area durning NSC access
 DEND

CLRCXROM = $C006
SETCXROM = $C007
RDCXROM = $C015

NSC_data = $C800
NSC_init = $C804

 TR ADR
noslot ent
 ORG $0D00
 HEX 10 ;Clock slot # <Not used by NSC driver>
HrFormat HEX 80 ;If -; 12 Hr format / If +; 24 Hour format
 JMP :GetDate ;GETDATE
 JMP :GetTime ;GETTIME
 RTS  ;SETDATE

:GetDate JSR :ReadClk ;Read the clock
 LDA Month ;Convert Date/Month/Year into ProDOS
 ASL  ;Strings
 ASL
 ASL
 ASL
 ASL
 ROL Year
 ORA Date
 TAX
 LDA Year
 PHA
 JSR :RestZPg ;Restore Zero-Page
 PLA
 RTS

:GetTime JSR :ReadClk ;Read the clock
 LDY Hour
 BIT HrFormat ;24 hour time format ?
 BPL :CnvTime ;Yes
 LDA #'M' ;No : Setup time sting for 12 hour format
 STA :TimeStr+10
 LDX #'A' ;<Assume AM>
 SED
 SEC
 TYA  ;Is it Afternoon/Evening ?
 SBC #$12
 CLD
 BCC :SetAMPM ;No
 TAY  ;Yes: Save "result" hour
 BNE :MakePM
 LDY #$12 ;....It's the Noon hour....
:MakePM LDX #'P'
:SetAMPM STX :TimeStr+9
 TYA  ;Is it the 12 AM hour ?
 BNE :CnvTime
 LDY #$12 ;Yes
:CnvTime TYA  ;Setup time string
 LDY #0
 LDX #0
:NxtByte PHA  ;Split byte into nibbles
 AND #$F0
 LSR
 LSR
 LSR
 LSR
 CLC
 ADC #'0' ;Setup 'Tens' digit
 STA :TimeStr,Y
 INY  ;Setup 'Ones' digit
 PLA
 AND #$0F
 ADC #'0'
 STA :TimeStr,Y
 INY
 INY
 INX  ;Are we finished (thru Seconds) ?
 LDA Hour,X
 CPX #4-1
 BNE :NxtByte ;No
 JSR :RestZPg ;Yes: Restore Zero-Page
 LDX #<:TimeStr ;and return with pointer to time string
 LDA #>:TimeStr
 RTS

:RestZPg LDY #10 ;Restore Zero page
:RestZP1 LDA NSC_save,Y
 STA NSC_work-1,Y
 DEY
 BNE :RestZP1
 RTS

* ReadClk - Read the values from the NSC's memory
:ReadClk LDY #10 ;Save off Zero page that we are using
:SaveZPg LDA NSC_work-1,Y
 STA NSC_save,Y
 DEY
 BNE :SaveZPg
 SEI  ;Don't allow Interrupts durning NSC access
 LDA RDCXROM ;Save CX-ROM state
 PHA
 STA SETCXROM
 LDA NSC_init ;Enable NSC  for  init string
 LDA #<:InitStr ;Setup pointer to init string
 STA NSC_Ptr
 LDA #>:InitStr
 STA NSC_Ptr+1
 LDY #7 ;Send init string
:IntNByt LDA (NSC_Ptr),Y ;Get next NSC inti byte
 SEC
 ROR
:IntNBit PHA  ;Send the bits...
 LDA #0
 ROL
 TAX
 LDA NSC_data,X
 PLA
 LSR
 BNE :IntNBit
 DEY
 BPL :IntNByt
 LDX #7 ;Read in the time from the NSC chip
:NxtOByt LDY #7
:NxtOBit LDA NSC_init
 ROR
 ROR NSCoutpt,X
 DEY  ;More bits to receive ?
 BPL :NxtOBit ;Yes
 CPX #3 ;Are we down to "Day of Week" ?
 BPL :MoreO? ;Yes: Ignore DOW, Date, Month, and Year
 LDA NSCoutpt,X ;No : Convert BCD to Hex
 PHA
 AND #$0F
 STA NSCoutpt,X
 PLA
 AND #$F0
 LSR
 LSR
 LSR
 LSR
 TAY
 BEQ :MoreO?
 LDA #0
:Cnv2Hex ADC #10
 DEY
 BNE :Cnv2Hex
 ADC NSCoutpt,X
 STA NSCoutpt,X
:MoreO? DEX  ;More bytes to read from NSC ?
 BPL :NxtOByt ;Yes
 PLA  ;No : Restore CX-ROM setting <if necessary>
 ROL
 BCS :ReadDon
 STA CLRCXROM
:ReadDon RTS

:InitStr HEX 5C,A3,3A,C5,5C,A3,3A,C5
:TimeStr ASC '00:00:00   '
 HEX 00,00


