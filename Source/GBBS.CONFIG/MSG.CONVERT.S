; *******************
; GBBS "Pro" V:2.2
; Copyright 1980-2017
;  Kevin M. Smallwood
; *******************
; Message File 1.0-1.2 to 2.2 Converter
; This module will convert the stock GBBS Pro V:1.2
; message formats to the standard V:2.2 format.
; *NOTE*: If you have modified your message segments
; to alter the way it writes the header info you will
; need to adjust this program accordingly.

; Written by Lance on 02/03/87
; Updated to 2.1 on 04/11/90 - LPT
; Updated to 2.2 on 02/19/17 - WPM

msg.conv
 print '
Once this program runs your message
files will be in V:2.1 format and will
not run under 1.0-1.2.  Once you do this
there is no turnning back.'
 print \"Do you wish to continue (YES/[NO]) ? NO";
 print chr$(8,2);:input i$
 if i$<>"YES" end

 open #1,"b:data2"
 mark(1)=1120:input #1,ab
 close
 print \"System has "ab" sub-boards"\
 for bb=1 to ab
 gosub read.msg
 print "Converting Board #"bb" - The "bn$
 print "Message #";
 for a=1 to msg(0)
 print a;
 edit(0):gosub convert
 print chr$(8,(len(str$(a))));
 next:print:print:next
 print '
Conversion compleate!

Your systems Message files are now
converted to run under GBBS Pro V:2.2

Please make sure you have made the
changes to your message segments
before running the board with the
messages in this format.':end

read.msg
 open #1,"b:data2":position #1,128,bb+8
 input #1,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb
 close:ready bf$
 return

convert
 input #msg(a),un,sb$\fr$
 copy #6,#8
 ti=0:ti$="All Users"
 x=msg(a):kill #msg(a)
 print #msg(a),sb$\ti,ti$\un,mid$(fr$,8)
 copy #8,#6:msg(a)=x:update
 return




