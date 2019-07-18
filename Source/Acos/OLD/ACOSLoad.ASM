	MCOPY MERLIN.MACROS
	MCOPY MY.MACROS
TRANSLATION  START
	LCLA	&LUP
********************************
*		                *
*   ACOS Loader Version 2.0    *
*		                *
********************************

*-------------------------------
* Date: 12/21/86
*-------------------------------
*   typ $ff
	KEEP	acos.system

	ORG	$2000

cr	EQU	$d
lf	EQU	$a

mli	EQU	$bf00
home	EQU	$fc58
cout	EQU	$fdf0
vtab	EQU	$fc22
inpln	EQU	$fd6f
rdkey	EQU	$fd35

lnbuf	EQU	$200
flname	EQU	$300
acosobj	EQU	$800
drivea	EQU	$815

dirinfo	EQU	$5c00
dirbuf	EQU	$5e00
prefix	EQU	$6000
flbuf	EQU	$6100
flbuf1	EQU	$6500

runadr	EQU	$6900

temp	EQU	0
temp2	EQU	2
numfls	EQU	4
blkcnt	EQU	6
prn	EQU	8

; relocate code up to $800

	LDA	temp	save startup bytes
	PHA
	LDA	temp+1
	PHA

	LDA	#<objcode	to obj code
	STA	temp
	LDA	#>objcode
	STA	temp+1

	LDA	#<runadr	point to dest address
	STA	temp2
	LDA	#>runadr
	STA	temp2+1

	LDX	#$10	move $10 pages
	LDY	#0
domove	LDA	(temp),y	move a byte
	STA	(temp2),y
	INY
	BNE	domove

	INC	temp+1	go to the next page
	INC	temp2+1
	DEX
	BNE	domove

	PLA
	STA	startup+1	save startup bytes
	PLA
	STA	startup
	JMP	runadr	execute code

	MDS	\	fill space

objcode	OBJ	runadr

; set to normal 40 col text mode
init	LDA	$c30b
	CMP	#1
	BNE	init_2

	LDA	$c30c
	CMP	#$82
	BNE	init_1

	LDA	$c058
	CLC
	BCC	init_2

init_1	CMP	#$87
	BNE	init_2

	LDA	#0
	STA	$c0b2

init_2	LDA	#0	reset screen
	STA	$20
	STA	$22
	LDA	#40
	STA	$21
	LDA	#24
	STA	$23

	JSR	home	clear screen
	JSR	pr	show main screen
	DC	C'########################################'  1
	DC	C'# ACOS LOADER  V2.1 #    ACOS FILES    #'  2
	DC	C'# COPYRIGHT 1986-90 ####################'  3
	DC	C'#  L&L PRODUCTIONS  #                  #'  4
	DC	C'#####################                  #'  5
	DC	C'#    FILENAMES      #                  #'  6
	DC	C'#####################                  #'  7
	DC	C'#                   #                  #'  8
	DC	C'#                   ####################'  9
	DC	C'#                   #  DELETED FILES   #'  10
	DC	C'#                   ####################'  11
	DC	C'#                   #                  #'  12
	DC	C'#                   #                  #'  13
	DC	C'#                   #                  #'  14
	DC	C'#                   #                  #'  15
	DC	C'#                   ####################'  16
	DC	C'#                   # STARTUP SEGMENT  #'  17
	DC	C'#                   ####################'  18
	DC	C'#                   #                  #'  19
	DC	C'########################################'  20
	DC	C'# STATUS:                              #'  21
	DC	C'#   LOADING ACOS.OBJ                   #'  22
	DC	C'########################################',H'00'	23

	JSR	mli
	DC	I1'$c7'	get prefix
	DC	I'p_pfx'

	LDA	prefix
	BNE	gotdef	we have a default

	LDA	$bf30	save currently used disk
	STA	p_onln+1

	JSR	mli
	DC	I1'$c5'	get the online volume
	DC	I'p_onln'

	LDA	prefix+1	get rid of drive specifier
	AND	#$f
	TAX
	INX		add 1 for '/'
	STX	prefix

	LDA	#'/'	put in leading slash
	STA	prefix+1

	JSR	mli
	DC	I1'$c6'	set the prefix
	DC	I'p_pfx'

gotdef	LDX	$280	get length of path
gotdef2	DEX
	BEQ	loadg	we have the path set

	LDA	$280,x
	CMP	#'/'	find path?
	BNE	gotdef2	nope

	STX	$280	set new length

	JSR	mli
	DC	I1'$c6'	set prefix
	DC	I'p_pfx2'

loadg	LDA	#0
	STA	$bf94
	JSR	mli	close ALL open files
	DC	I1'$cc'
	DC	I'r_close'

	JSR	mli
	DC	I1'$c8'	open a file
	DC	I'r_open'

	LDA	r_open+5	move refnum
	STA	r_read+1

	JSR	mli
	DC	I1'$ca'	read in acos.obj
	DC	I'r_read'

	JSR	mli
	DC	I1'$cc'	close file
	DC	I'r_close'

; check for turnkey run
	LDA	startup	is first i/d byte ok?
	CMP	#1
	BNE	sname	nope

	LDA	startup+1
	STA	startup	make sure they dont match again
	CMP	#2
	BEQ	sname4

; get name of starting segment
sname	LDA	acosobj+2	point to filename
	STA	temp
	LDA	acosobj+3
	STA	temp+1

	JSR	prstat
	DC	C'SOURCE MODULE [',H'00'
	LDY	#0
	LDA	(temp),y

	TAX
sname2	INY
	LDA	(temp),y	print filename
	ORA	#$80
	JSR	cout
	DEX
	BNE	sname2

	JSR	pr	finish off string
	DC	C']: ',H'00'

	JSR	inpln
	CPX	#0	cr?
	BEQ	sname4	yep
	CPX	#14	14 or over?
	BCS	sname	yep

	TXA
	TAY
sname3	LDA	lnbuf-1,y	copy filename
	STA	(temp),y
	DEY
	BNE	sname3

	TXA		save length
	STA	(temp),y
	JMP	sname	go back

sname4	LDX	acosobj+2
	LDA	acosobj+3	display in window 3
	LDY	#3
	JSR	prwind

	LDA	#<drivea	point to pathname
	STA	p_ginfo+1
	LDA	#>drivea
	STA	p_ginfo+2

chkprg	JSR	mli
	DC	I1'$c4'	get file info
	DC	I'p_ginfo'
	BEQ	docheck

	JSR	prstat
	DC	C'INSERT SYSTEM DISK INTO OTHER DRIVE',H'0d00'
	JSR	getcr
	JMP	chkprg

; get a directory and look for ".s" files.
; if any exist, check to see if they have 
; been changed. If so, kill the ".c" file.

docheck	JSR	prstat
	DC	C'STATUS:',H'0d'
	DC	C'  CHECKING FILES...',H'00'
 
logprg	JSR	mli
	DC	I1'$c7'	get the current prefix
	DC	I'p_pfx'

	LDY	drivea
logprg1	LDA	drivea,y	are these 2 paths the same?
	EOR	prefix,y
	AND	#%11011111
	BNE	logprg2	nope

	DEY
	BNE	logprg1	keep checking

logprg2	JSR	mli	open the current prefix
	DC	I1'$c8'
	DC	I'p_open'

	LDA	p_open+5	get refnum
	STA	p_rdinf+1
	STA	p_rddir+1
	STA	p_pos+1

	JSR	mli	read dir info
	DC	I1'$ca'
	DC	I'p_rdinf'

	JSR	mli	set to byte 0
	DC	I1'$ce'
	DC	I'p_pos'

	LDX	#0
	STX	numfls	0 files processed
	STX	numfls+1
	DEX
	STX	blkcnt	start at file 1 in block

rdloop	LDA	#<dirbuf+4	point to buf
	STA	temp
	LDA	#>dirbuf+4
	STA	temp+1

	JSR	mli	read block
	DC	I1'$ca'
	DC	I'p_rddir'
	BNE	rdloop1	opps, error

	LDA	blkcnt	first pass?
	BPL	rdloop2	nope

	INC	blkcnt	set to 0
	JMP	rdloop5	go to next entry

rdloop2	LDA	numfls	we done?
	CMP	dirinfo+$25
	BNE	rdloop3	nope

	LDA	numfls+1	check high
	CMP	dirinfo+$26
	BNE	rdloop3	were done

rdloop1	JMP	finish

rdloop3	LDY	#0
	LDA	(temp),y	get length and type
	AND	#$f
	STA	(temp),y	get rid of extra stuff
	STA	temp2
	BNE	rdlp3a

	JMP	rdloop5

rdlp3a	INC	numfls	inc file count
	BNE	rdloop4
	INC	numfls+1

rdloop4	LDX	temp
	LDA	temp+1	display filename in window 0
	LDY	#0
	JSR	prwind

	LDY	drivea	get length of path
	TYA
	TAX		save length
mvpath	LDA	drivea,y
	STA	flname,y	move pathname
	DEY
	BPL	mvpath

	LDA	#'/'	add in slash
	INX
	STA	flname,x

	LDY	#0
mvpath2	INX
	INY
	LDA	(temp),y	get name of file
	STA	flname,x
	CPY	temp2
	BNE	mvpath2

	LDA	#'C'	make into '.c'
	STA	flname,x
	STX	flname	update length

	LDA	temp2	get length
	CMP	#3	is it a possible '.s' file?
	BCC	rdloop5	nope

	TAY
	LDA	(temp),y	check for 's' in '.s'
	CMP	#'S'
	BNE	rdloop5

	DEY
	LDA	(temp),y	check for '.' in '.s'
	CMP	#'.'
	BNE	rdloop5

rdloop4c LDX	temp
	LDA	temp+1
	LDY	#1	display .s source file
	JSR	prwind

	LDA	temp	point at filename
	STA	p_ginfo+1
	STA	p_open2+1
	LDA	temp+1
	STA	p_ginfo+2
	STA	p_open2+2

	LDA	#10	setup for get.info
	STA	p_ginfo

	JSR	mli	get file info
	DC	I1'$c4'
	DC	I'p_ginfo'
	BNE	rdloop5	hmmm, error

	LDA	p_ginfo+5	check backup bit
	BNE	rdlop4a	all is well

	LDA	#1
	STA	p_ginfo+5	set bit in mod.time

	LDA	#7	setup for set.file.info
	STA	p_ginfo

	JSR	mli	set info
	DC	I1'$c3'
	DC	I'p_ginfo'

	LDY	#0
	LDA	(temp),y	change file into .C
	TAY
	LDA	#'C'
	STA	(temp),y

	LDX	temp
	LDA	temp+1
	LDY	#2	display in window 2
	JSR	prwind

	LDY	#0
	LDA	(temp),y
	TAY		change file back to .S
	LDA	#'S'
	STA	(temp),y

	JSR	mli	delete '.c' file
	DC	I1'$c1'
	DC	I'p_del'

rdlop4a	JSR	flcopy	copy over the file

rdloop5	CLC
	LDA	temp	go to next entry
	ADC	dirinfo+$23
	STA	temp
	LDA	temp+1
	ADC	#0
	STA	temp+1

	INC	blkcnt	inc place within block
	LDA	blkcnt
	CMP	dirinfo+$24
	BEQ	rdloop6	go to next block

	JMP	rdloop2	do next entry within this block

rdloop6	LDA	#0	reset count
	STA	blkcnt
	JMP	rdloop	do another block

finish	LDA	#0
	STA	p_close+1

	JSR	mli	close file
	DC	I1'$cc'
	DC	I'p_close'

	LDA	$c000	did they want to pause?
	CMP	#' '+128
	BEQ	wait2c	yep, wait to see

	JMP	exeacos

wait2c	LDA	#1
	STA	$20
	STA	$22
	LDA	#38
	STA	$21
	LDA	#22
	STA	$23
	JSR	home	clear screen
	JSR	pr
	DC	I1'cr'
	DC	C' MAKE SURE THESE DISKS ARE IN PLACE:',H'0d00'


	LDY	#0	move A:
	LDX	#<lnbuf
	LDA	#>lnbuf
	JSR	movpath	move pathname

	LDY	#1	move B:
	LDX	#<lnbuf+128
	LDA	#>lnbuf+128
	JSR	movpath	move pathname

	LDY	lnbuf	get pathname length
	INY
show2	DEY		count down
	BMI	show3	they match

	LDA	lnbuf,y
	CMP	lnbuf+128,y	are they the same?
	BEQ	show2	yep

	JSR	pr
	DC	I1'cr'
	DC	C' BOOT DISK     -- ',H'00'
	LDY	lnbuf
	LDX	#<lnbuf+1
	LDA	#>lnbuf+1
	JSR	prstr	show pathname

show3	JSR	pr
	DC	I1'cr'
	DC	C' SYSTEM DISK   -- ',H'00'
	LDY	lnbuf+128
	LDX	#<lnbuf+129
	LDA	#>lnbuf+129
	JSR	prstr	show pathname

	LDY	#5
	LDX	#<lnbuf	move pathname
	LDA	#>lnbuf
	JSR	movpath

	JSR	pr
	DC	I1'cr'
	DC	C' BULLETIN DISK -- ',H'00'
	LDY	lnbuf
	LDX	#<lnbuf+1
	LDA	#>lnbuf+1
	JSR	prstr	show pathname

	LDY	#6
	LDX	#<lnbuf+128
	LDA	#>lnbuf+128	move pathname
	JSR	movpath

	LDY	lnbuf	get length of path
	INY
show4	DEY
	BMI	show5	the path's match

	LDA	lnbuf,y	are they the same?
	CMP	lnbuf+128,y
	BEQ	show4	yep

	JSR	pr
	DC	I1'cr'
	DC	C' MAIL DISK     -- ',H'00'
	LDY	lnbuf+128
	LDX	#<lnbuf+129
	LDA	#>lnbuf+129
	JSR	prstr

show5	JSR	pr
	DC	I1'cr,cr'
	DC	C' ONCE THESE DISKS ARE IN PLACE',H'0d0d'
	DC	C' ',H'00'
	JSR	getcr

exeacos	LDA	#0
	STA	$bf94	set level to 0

	JSR	mli
	DC	I1'$cc'	close all open files
	DC	I'r_close'	specifically EXEC files

	LDA	acosobj+6
	STA	temp
	LDA	acosobj+7
	STA	temp+1
	JMP	(temp)	start acos running


; sub-routines
; print a line of status
prstat	LDA	#2
	STA	$20
	LDA	#36
	STA	$21
	LDA	#20	set window
	STA	$22
	LDA	#22
	STA	$23
	JSR	home	clear window

pr	PLA		point to string
	STA	prn
	PLA
	STA	prn+1

pr2	INC	prn	get next byte
	BNE	pr3
	INC	prn+1

pr3	LDY	#0	get byte
	LDA	(prn),y
	ORA	#$80
	CMP	#'#'+128	inverse block?
	BNE	pr3a	nope
	LDA	#$20

pr3a	JSR	cout	print
	ASL	a
	BNE	pr2	keep going

	INC	prn	make into correct address
	BNE	pr4
	INC	prn+1

pr4	JMP	(prn)	return


; get a return
getcr	JSR	pr
	DC	C'PRESS [RETURN] TO CONTINUE...',H'00'
getcr2	JSR	$fd35
	CMP	#$8d
	BNE	getcr2
	RTS


; print a filename within a window
prwind	STX	prn	point to filename
	STA	prn+1
	LDA	wndlft,y	define text window
	STA	$20
	STA	$24
	LDA	wndrgt,y
	STA	$21
	LDA	wndtop,y
	STA	$22
	LDA	wndbtm,y
	STA	$23
	SEC		make into vtab
	SBC	#1
	STA	$25
	JSR	$fc22	vtab down
	LDA	#$8d
	JSR	$fdf0	scroll down

	LDY	#0
	LDA	(prn),y	get filename length
	TAX
prwind2	INY
	LDA	(prn),y	print name
	ORA	#$80
	JSR	$fdf0
	DEX
	BNE	prwind2
	RTS

wndlft	DC	I1'02,22,22,22'
wndrgt	DC	I1'16,16,16,16'
wndtop	DC	I1'07,03,11,18'
wndbtm	DC	I1'19,08,15,19'


; print a string pointed to by X & A, length Y
prstr	STX	prn
	STA	prn+1	point at string
	TYA
	TAX		save length
	LDY	#0
prstr2	LDA	(prn),y	get data
	ORA	#$80
	JSR	$fdf0
	INY
	DEX
	BNE	prstr2	do entire string
	RTS


; move a pathname into a buffer
movpath	STX	temp	point to buffer
	STA	temp+1

	LDX	#0
move2	DEY		count down
	BMI	move3	all finished

	TXA
	SEC
	ADC	drivea,x	add in next offset
	TAX
	JMP	move2

move3	LDA	drivea,x	get path length
	STA	temp2	save as counter

	LDY	#0
move4	LDA	drivea,x
	STA	(temp),y	save in buffer
	INX
	INY
	DEC	temp2	count down length
	BPL	move4
	RTS


; copy over a source file
flcopy	JSR	mli
	DC	I1'$c8'	does '.c' file exist?
	DC	I'p_open1'
	BNE	flcopy1	nope, copy source

	LDA	p_open1+5
	STA	p_close+1
	JSR	mli	close compiled file
	DC	I1'$cc'
	DC	I'p_close'
flcopy2	RTS		all is well

flcopy1	LDX	flname	change '.c' back to '.s'
	LDA	#'S'
	STA	flname,x

	JSR	mli
	DC	I1'$c0'	create new file
	DC	I'p_creat'
	BNE	flcopy2	file must already exist

	JSR	mli
	DC	I1'$c8'	open old file
	DC	I'p_open2'

	LDA	p_open2+5	save refnum
	STA	p_read+1
	STA	p_close+1

	JSR	mli
	DC	I1'$ca'	read in file
	DC	I'p_read'

	JSR	mli
	DC	I1'$cc'	close source file
	DC	I'p_close'

	JSR	mli
	DC	I1'$c8'	open new file
	DC	I'p_open1'

	LDA	p_open1+5	setup write routine
	STA	p_write+1
	STA	p_close+1
	LDA	p_read+6	setup write length
	STA	p_write+4
	LDA	p_read+7
	STA	p_write+5

	JSR	mli
	DC	I1'$cb'	write out segment
	DC	I'p_write'

	JSR	mli	close file 2
	DC	I1'$cc'
	DC	I'p_close'
	RTS		we are done


; prodos parmlist
startup	DC	I'0'

p_creat	DC	I1'7'
	DC	I'flname'
	DC	I1'$c3'
	DC	I1'4'
	DC	I'0'
	DC	I1'1'
	DC	I'0'
	DC	I'0'

p_open	DC	I1'3'
	DC	I'prefix'
	DC	I'flbuf'
	DC	I1'0'

p_open1	DC	I1'3'
	DC	I'flname'
	DC	I'flbuf1'
	DC	I1'0'

p_open2	DC	I1'3'
	DC	I'0'
	DC	I'flbuf1'
	DC	I1'0'

p_rdinf	DC	I1'4'
	DC	I1'0'
	DC	I'dirinfo'
	DC	I'$100'
	DC	I'0'

p_rddir	DC	I1'4'
	DC	I1'0'
	DC	I'dirbuf'
	DC	I'$200'
	DC	I'0'

p_read	DC	I1'4'
	DC	I1'0'
	DC	I'copybuf'
	DC	I'copylen'
	DC	I'0'

p_write	DC	I1'4'
	DC	I1'0'
	DC	I'copybuf'
	DC	I'copylen'
	DC	I'0'

p_close	DC	I1'1'
	DC	I1'0'

p_ginfo	DC	I1'$a'
	DC	I'0'
	DC	I1'0'
	DC	I1'0'
	DC	I'0'
	DC	I1'0'
	DC	I'0'
	DC	I'0'
	DC	I'0'
	DC	I'0'
	DC	I'0'

p_del	DC	I1'1'
	DC	I'flname'

p_pos	DC	I1'2'
	DC	I1'0'
	DC	I1'0,0,0'

p_pfx	DC	I1'1'
	DC	I'prefix'

p_pfx2	DC	I1'1'
	DC	I'$280'

p_onln	DC	I1'2'
	DC	I1'0'
	DC	I'prefix+1'

; data for relocated code
r_open	DC	I1'3'
	DC	I'r_file'
	DC	I'flbuf1'	use last possible buffer
	DC	I1'0'

r_read	DC	I1'4'
	DC	I1'0'
	DC	I'acosobj'
	DC	I'$6000'
	DC	I'0'

r_close	DC	I1'1'
	DC	I1'0'

r_file	DC	I1'8'
	DC	C'acos.obj'

copybuf	EQU	*
copylen	EQU	mli-copybuf
	END
