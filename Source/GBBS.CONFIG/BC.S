; ********************
; GBBS Pro v2.2
; Copyright 1980-2017
; ********************

; Bulletin Copy Utility
; By GS @ 04/30/85
; Modified by Lance @ 4/20/87
; Updated for 2.1 - 04/11/90
; Updated for 2.2 - 02/19/17

 public start

 input "press [ret] to continue..." i$

 flag=ram
 s1$="<"+chr$(8):s2$=">"+chr$(8)
 s3$="{"+chr$(8):s4$="}"+chr$(8)

start
 home
 print "Bulletin Copy Utility v2.2"
 print \"Written by Greg Schaefer"
 print "Modified for v2.2 by BillM"
 input \"Source Bulletin File (ex: F:B1):" f1$
 open #1,f1$:a=mark(1):close
 if a print \"Cant find "f1$" press [RET] ";:get i$:goto start
 ready f1$:print chr$(8);:sz=(peek(36)=79)
 fill ram,64,0:if msg(0) goto status
 print \"That message file is empty."
 gosub getret:goto start

status
 home:z=1:b=(msg(0)/20)*5+1
 for x=1 to b step 5
 a=20:if x=b a=msg(0) mod 20
 for y=5 to a+4:a$=left$("*",flag(z))
 print @x,y;z;a$;:z=z+1:next:next

cmd
 print @1,1 "R=Restart, Q=Quit, V=View, C=Copy"
 print "K=Kill, T=Tag, U=Untag, W=Write"
 print "Enter Cmd: ";chr$(32,28);chr$(8,28);
 get i$:if i$>"a" i$=chr$(asc(i$)-32)
 print chr$(8);i$;:z=1
 if i$="Q" goto quit
 if i$="V" goto view
 if i$="C" goto copy
 if i$="K" goto kill
 if i$="T" goto tag
 if i$="U" goto untag
 if i$="R" goto restart
 if i$="W" goto write
 goto cmd

quit
 input @0 "uit Y/N ?" i$:if i$<>"Y" goto cmd
 home:goto doquit

restart
 input @0 "estart Y/N ?" i$:if i$<>"Y" goto cmd
 home:goto start

tag
 input @2 "ag (#[,#] or ALL):" i$
 if i$="" goto cmd
 if left$(i$,1)="A" fill ram,64,255:goto status
tag2
 a=val(i$):if not ((a=0) or (a>msg(0))) flag(a)=1
 a=instr(",",i$):if a i$=mid$(i$,a+1):goto tag2
 goto status

untag
 input @2 "ntag (#[,#] or ALL):" i$
 if i$="" goto cmd
 if left$(i$,1)="A" fill ram,64,0:goto status
untag2
 a=val(i$):if not ((a=0) or (a>msg(0))) flag(a)=0
 a=instr(",",i$):if a i$=mid$(i$,a+1):goto untag2
 goto status

view
 input @2 "iew (ALL,TAG,#[,#]):" i$
 gosub inprng:if i$="" goto cmd
 home:print "Viewing Bulletin(s):"
view2
 d=0:gosub show:if a goto view2
 gosub getret:goto status

write
 input @2 "rite (ALL,TAG,#[,#]):" i$
 gosub inprng:if i$="" goto cmd
write2
 home:print "Write these bulletins:"\
 gosub list:input @2 \"Filename (to write):" f$
 if f$="" goto cmd
 create f$:open #1,f$:append #1
 print \"Wait...Writing bulletin(s)"
write3
 d=1:gosub show:if a goto write3
 close:goto status

kill
 input @2 "ill (ALL,TAG,#[,#]):" i$
 gosub inprng:if i$="" goto cmd
 home:print "Kill these bulletins:"\:gosub list
 input @0 \"Kill: Are you sure Y/N ?" i$
 if i$<>"Y" goto status
 print "Wait...Killing bulletin(s)"
 b=msg(msg(0)):for x=1 to msg(0)
 if flag(x+512) kill #msg(x)
 next:crunch:a=msg(0):if a msg(a)=b
 update:if a goto status
 home:print \"All bulletins killed."
 gosub getret:goto start

copy
 input @2 "opy (ALL,TAG,#[,#]):" i$
 gosub inprng:if i$="" goto cmd
 home:print "Copy these bulletins:"\:gosub list
 input @0 \"Copy: Are you sure Y/N ?" i$
 if i$<>"Y" goto status
copy2
 print \"Enter destination bulletin file"
 input @2 \"Destin Bulletin File (ex: D:B2):" f$
 if f$="" goto cmd
 open #1,f$:a=mark(1):close:b=msg(0)
 if a print "Can't find "f$" press [RET]";:get i$:goto copy2
 print \"Wait...Copying bulletin(s): ";
 open #1,"b:data":input #1,c1,c2,ct,ct$,da$
 input #1,nu,mn,wm\lu$:close:ready f$

 for x=1 to b:if not flag(x+512) goto copy3
 print s1$;:kill "dummy":create "dummy":open #1,"dummy"
 print s2$;:ready f1$:copy #msg(x),#1:close:ready f$
 print s3$;:b=msg(0)+1:copy "dummy",#msg(b):msg(b)=mn
 update:mn=mn+1:print s4$;
copy3
 next:open #1,"b:data":print #1,c1,c2,ct,ct$,da$
 print #1,nu,mn,wm\lu$:close:ready f1$:goto status

inprng
 if left$(i$,1)="T" move ram,64 to ram2:return
 if left$(i$,1)="A" fill ram2,64,255:return
 fill ram2,64,0
inprng2
 a=val(i$):if (a=0) or (a>msg(0)) i$="":return
 flag(a+512)=1:a=instr(",",i$):if not a return
 i$=mid$(i$,a+1):goto inprng2

list
 a$="":for x=1 to msg(0)
 if flag(x+512) print a$x;:a$=","
 next:if peek(36)>0 print
 return

show
 if z>msg(0) a=0:return
 if flag(z+512)=0 z=z+1:goto show
 input #msg(z),sb$\b,b$\c,c$
 print #d,\"Numb ->"z" of "msg(0)\" Sub ->"sb$
 print #d, "  To ->"b$\"From ->"c$
 copy #6,#d:a=1:z=z+1:return

getret
 input @2 \"Press [RETURN] to continue... "i$
 return

doquit
 end
