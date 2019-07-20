; *******************
; GBBS "Pro" V:2.2n
; Copyright 1980-2017
;  Kevin M. Smallwood
; *******************
; main segment - 2/19/2017

 public fromsys
 public return
 public term1
 public termin2

 on nocar goto term1
 if flag(0) goto main
 if fv then a$="b:v1":gosub force
 ready "g:mail"
 if not msg(un) goto main
 print "You have mail waiting!"
 input @2 \"Read it now ([Y]/N) ?" i$
 if i$<>"N" then a$="rd.mail":gosub link.msg

fromsys
 on nocar goto term1

main
 x=(clock(2)-clock(1))/60:y=clock(2):x$=right$("0"+str$(x),2)
 if clock(1)>clock(2) x$="!!"
 if x=0 x$="--"
 if not y x$="**"
 if info(5) x$="::"
 print \"["x$"][Main Level] ";
 input "Option (?=Help):" i$:push main

main.cmd
 if i$="B" bb=1:a$="bulletins":goto link.msg
 if left$(i$,1)="B" a$="bulletins":goto bulletins
 if left$(i$,1)="J" a$="bulletins":goto bulletins
 if i$="R" then a$="rd.mail":goto link.msg
 if (i$="?" or i$="/") goto menu
 if i$="C" goto chat
 if i$="D" goto display
 if i$="F" goto feedback
 if i$="T" goto terminate
 if i$="E" goto show.stat
 if i$="$" f$="b:sys.news":goto show.file
 if i$="H" f$="b:hlp.main":goto show.file
 if i$="I" f$="b:sys.info":goto show.file
 if (i$="P") and (flag(0)) goto getpass
 if (i$="%") and (info(5)) pop:link "a:system.seg"
 if not(flag(1) or info(5)) goto main2

 if i$="S" a$="sd.mail":goto link.msg
 if i$="P" goto setpass
 if i$="U" goto userlist
 if i$="V" a$="b:v1":goto voting
 if i$="G" a$="c:g1":goto general
 if i$="Q" bb=1:a$="bulletins":goto link.msg
 if i$="O" f$="b:bbs":goto show.file
 if i$="L" f$="b:log.daily":goto show.file
 if i$="X" a$="d:d1":goto download

main2
 a1=a1+1:print \'Sorry, "'i$'" is not a command.':if a1<3 return

; *** sub - routines ***
; On the fly menus
menu
 a1=0:f$="b:mnu.new"
 if not (flag(1)) goto menu.1
 if (edit(3)<79) f$="b:mnu.val.40":else f$="b:mnu.val.80"
menu.1
 open #1,f$:input #1,x$:setint(" "):for l=1 to len(x$)
 addint(mid$(x$,l,1)):next:print \sc$\
 copy #1:if key(3) goto menu.key
 a=key(0):close:setint(""):pop:goto main

menu.key
 close:setint(""):a=key(0)
 if (a>96) and (a<123) a=a-32
 if a=32 pop:goto main
 print:i$=chr$(a):print i$:goto main.cmd

; terminate from system and recycle
terminate
 print \"Terminate Connection"
 input @2 \"Are you sure (Y/[N]) ?" i$
 if left$(i$,1)<>"Y" return
termin2
 on nocar goto term5
 if (not ma) or (not flag(34)) goto term1
 if ma and flag(34) input @2 \"Delete Mail ([Y]/N) ?" i$:if i$="" i$="Y"
 i$=left$(i$,1):ma=(i$="Y")
term1
 on nocar clear
 print \"Goodbye "a3$","\"you were caller #"cn$
 print \"Thank you for calling "sn$:a=clock(1)
 if a print \"Connected "a/60" mins, "a mod 60" secs"
 print \md$\"           GBBS Pro V:2.2n" \"   (C)1986-2017 Kevin Smallwood" \md$
 close:log "b:":modem(1):if a1$="" goto term4
 if not un goto term3
term2
 open #1,"b:users":nibble(6)=nibble(6)+1:tc=tc+1
 byte(1)=tc mod 256:nibble(1)=tc/256
 byte(2)=bp mod 256:nibble(2)=bp/256
 byte(3)=dl mod 256:nibble(3)=dl/256
 byte(4)=ul mod 256:nibble(4)=ul/256
 byte(5)=lr mod 256:byte(6)=lr/256
 byte(0)=info(3):when$="x"

; to enable the time per day mod remove the ';' from the line below
; byte(7)=(byte(7)+(clock(1)/60))

 position #1,128,un
 print #1,a1$,a2$\a3$\a4$,a5$
 position #1,128,un,70
 write #1,ram,58:close
term3
 if not info(5) then ct=ct+1:c2=c2+1
 if c2>9999 then c2=0:c1=c1+1
 open #1,"data":print #1,c1,c2,ct,ct$,date$
 print #1,nu,mn,wm,tm\a1$" "a2$:close
 if ma ready "g:mail":kill #msg(un):update
 if (lg=0) or (info(5)) goto term4
 create "b:log.system":open #1,"b:log.system":append #1
 print #1,"Call #"cn$" / Connected at "cm$" / "a3$" of "a4$", "a5$
 print #1,"Last date on "lc$" / "ph$" / "un"-"pa$;
 print #1," / Speed = "info(2)*300" baud"
 for x=1 to 8:print #1,flag(x);:next:a=clock(1)
 print #1," / Connected "a/60" mins, "a mod 60" secs"\:close
 open #1,"b:log.daily":append #1
 print #1,left$(a3$+"...................",20);
 z$="  0000":z$=left$(z$,6-(len(str$(info(2)*300))))+str$(info(2)*3 00)
 print #1,z$"  "time$:close
term4
 link "a:logon.seg"
term5
 ma=0:goto term1

; chat with sysop
chat
 if ch>6 print \"You were warned.  Goodbye!":goto term1
 if ch>5 print \"Once more and you`ll be logged off":ch=ch+1
 if ch>3 print \"Sysop is not available":ch=ch+1:return
 print \"Paging Sysop: ";:tone(100,100,100)
 if flag(2) tone (125,100,100):tone(150,100,100)
 print "Continue...":info(4)=1:ch=ch+1:return

; show user's status
show.stat
 print \"   Your Status"\
 print "Name -> "a3$
 print "From -> "a4$", "a5$
 print "Phone # "ph$
 print "User  # "un
 print "Last On : "lc$
 print "Level # : ";
 for x=1 to 8:print flag(x);:next
 print \\"Last Caller: "lu$
 print \"You are caller : "cn$
 print "Todays  calls : "ct\
 print "Logon time : "cm$
 print "Actual time: "date$" "time$:a=clock(1)
 print "Connected  : "a/60" mins, "a mod 60" secs"
 b=clock(2):if b print "Time left  : "(b-a)/60" mins"
 print \"[ Options Available ]"\
 open #1,"b:data2":z=0:for x=0 to 34:a$=""
 if flag(x) position #1,32,x:input #1,a$
 if a$<>"" setint(1):print a$:z=1:if key(1) then x=34
 next:close:if not z print "Limited system access"
 setint(""):return

; show list of system users
userlist
 print \"List of System Users"\
 input @2 "Match letters (<CR>=All,?):" i$
 if i$="?" f$="b:hlp.user":gosub show.file:goto userlist
 m$="":if info(5) input @0 \"Show passwords ?" m$
 print \s$:open #1,"b:users":x=1
 if left$(i$,1)="#" x=val(mid$(i$,2)):i$=""
 if (x=0) or (x>nu) then x=1
usrlst2
 position #1,128,x:input #1,a$,b$
 if a$="" goto usrlst3
 a$=a$+" "+b$:setint(1)
 if not instr(i$,a$) goto usrlst3
 input #1,c$\d$,e$:position #1,128,x,70
 move ram,58 to ram2:on nocar goto usrlst4:read #1,ram,58
 setint(1):print \"#"x" "c$" ][ On: "when$\"From: "d$", "e$;
 if (m$<>"") or (mid$(ph$,4,1)=" ") print " ][ "ph$:else print
 if m$="Y" print "Pass: "pa$" ][ Time: "nibble(5)*10
 move ram2,58 to ram:on nocar goto term1
usrlst3
 if (not key(1)) and (x<nu) then x=x+1:goto usrlst2
 setint(""):close:return
usrlst4
 move ram2,58 to ram:goto term1

; file transfer section
download
 open #1,a$:input #1,x,d3$:close
 if d3$<>"" d3$=chr$(13)+d3$+chr$(13)
 b$=left$(a$,instr(":",a$))
down2
 print d3$\"Download Files 1-"x" [L]ist Files"
 input "[U]pload a File [H]elp [Q]uit ?" i$
 a=val(i$):if i$="Q" return
 if i$="U" goto upload
 if i$="L" goto down3
 if i$="H" then f$="b:help.xfer":gosub show.file:goto down2
 if (a=0) or (a>x) goto down2
 print \"A)scii, D)os Xmodem, P)roDOS Xmodem"
 input @0 "S)tandard Xmodem (ibm,trs), Q)uit ?" i$
 z=9:if i$="S" then z=0
 if i$="P" then z=1
 if i$="D" then z=2
 if i$="A" then z=3
 if z=9 goto down2
 open #1,a$:input #1,x:y=0
down2a
 if eof(1) close:goto down2
 input #1,i$:if left$(i$,1)<>")" goto down2a
 y=y+1:if a<>y goto down2a:else y=instr("^",i$)
 if y f$=b$+mid$(i$,y+1):else f$=b$+mid$(i$,3)
 close:open #1,f$:if mark(1) close:goto down2
 i$=mid$(i$,3):if y i$=left$(i$,y-4)
 print \"Sending "i$", "size(1)*2+1" blocks":close
 input @3 \"Press <CR> to begin" i$
 byte(2)=byte(2)+1:use "b:x.dn",z,f$:goto down2
down3
 print:open #1,a$:input #1,x:a=1
 if not x close:print \"No downloads today":goto down2
down4
 input #1,i$:z=instr("^",i$):if z=0 z=len(i$)+1
 if left$(i$,1)=")" print a;:a=a+1:i$=left$(i$,z-1)
 setint(1):print i$:if not(eof(1) or key(1)) goto down4
 close:setint(""):goto down2

upload
 if not flag(2) print \"Security too low":goto down2
 print \"Upload a file"\\"A)scii, D)os Xmodem, P)roDOS Xmodem"
 input @0 "S)tandard Xmodem (ibm,trs), Q)uit ?" i$
 z=9:if i$="S" then z=0
 if i$="P" then z=1
 if i$="D" then z=2
 if i$="A" then z=3
 if z=9 goto down2
 y=1:f$=""
upload2
 input @2 \"Filename:" f$:if f$="" goto upload
 if not info(5) then f$="e:u"+str$(un)+"."+f$
 if not instr(":",f$) then f$="e:"+f$
 if len(f$)>17 print \"Illegal filename":goto upload2
 open #1,f$:a=mark(1):close:if a goto upload3
 if info(5)=0 print \"Filename in use":goto upload2
 input @0 \"Filename in use: Overwrite ?" i$
 if i$<>"Y" goto upload2
upload3
 create f$:open #1,f$:a=mark(1):close
 if a print \"Illegal filename":goto upload2
 if z<>3 input @3 \"Press <CR> to begin" i$
 nibble(3)=nibble(3)+1
 use "b:x.up",z,f$:goto down2

; feedback to sysop
feedback
 print \"Feedback to Sysop"
 input @3 \"Subject:" sb$:if sb$="" sb$="None"
 gosub editor:if not edit(2) return
 h$="     --> Feedback from a User <--"
 d=1:print \"Wait...";:a$="wr.letter"
 gosub link.msg:print ".Feedback saved":return

; general files
general
 open #1,a$:input #1,x
 if not x close:print \"No Active Files":return
 print \s$\:setint(1):gosub showfl2
general2
 print \"Which 1-"x" (?=Menu,<CR>):";
 input @3 i$:if i$="" return
 if i$="?" goto general
 a=val(i$):if (not a) or (a>x) goto general2
 f$=a$+"."+str$(a):gosub show.file:goto general2

; set display characteristics
display
 print \"Display Characteristics"\
 print "Video width now = "edit(3)+1
 print "Back-space mode = ";
 a=nibble(0)/4:if a=1 print "non-";
 if a=0 print "Unknown":else print "destruct"
 print "Nulls sent @ LF = "info(3)
 print "Page pause mode = ";
 if flag(35) print "ON":else print "OFF"
 print "Show phone numb = ";
 if mid$(ph$,4,1)=" " print "YES":else print "NO"
display2
 input @0 \"Set: [V, B, N, P, S, or Q=Quit] ?" i$
 if i$="Q" return
 if i$="B" goto backspace
 if i$="S" goto phone
 if i$="N" goto nulls
 if i$="P" goto paging
 if i$<>"V" goto display2

video
 print \"Set Video Width"
 print \"New width (";
 print width(1),width(2),width(3),width(4);
 input @2 ") ?" i$:if i$="" goto display2
 a=val(i$):for x=1 to 4
 if a=width(x) nibble(0)=nibble(0)/4*4+(x-1):edit(3)=a-1
 next:print \"Video width = "edit(3)+1:goto display

backspace
 print \"Set Cursor Characteristics"
 print \"123456" chr$(8,3):a=0
 print \"How many numbers do you see"\
 print "3 shows a destructable backspace"
 print "6 shows a non-destructable backspace"
 input @2 \"How many (3 or 6) ?" i$
 if i$="" goto display2
 if i$="6" then a=1
 if i$="3" then a=2
 nibble(0)=(nibble(0) mod 4)+(a*4)
 edit(4)=a:goto display

nulls
 print \"Set new null value"
 input @2 \"Set to (0-127):" i$
 if i$<>"" then info(3)=val(i$)
 goto display

phone
 ph$=left$(ph$,3)+"-"+mid$(ph$,5)
 input @2 \"Show phone number to other users ?" i$
 i$=left$(i$,1):if i$<>"Y" goto display
 ph$=left$(ph$,3)+" "+mid$(ph$,5):goto display

paging
 print \"Pause after page"
 input @2 \"Set paging (ON,OFF):" i$
 if i$="ON" flag(35)=1
 if i$="OFF" flag(35)=0
 goto display

; get a password for guests
getpass
 print \"Do you wish to receive a password to"
 input @0 "log in with the next time you call ?" i$
 if i$<>"Y" return
 d1$=a1$:d2$=a2$:d3$=a3$
 link "a:logon.seg","get.pass"

; get a new password
setpass
 print \"Change your Password"
 input @2 \"Enter your current password: "; i$
 if i$="" return
 i$=left$(i$+"    ",8):if i$<>pa$ print \"Incorrect!":return
 print \"Your password may be 4-8 chars long"
 echo="X":input @2 \"Enter your new password: "; i$
 if i$="" then echo="":return
 input @2 "Please type it in again: " a$
 echo="":a=len(i$)
 if a$<>i$ print \"Passwords do not match":return
 if (a<4) or (a>8) print \"Password must be 4-8 chars":return
 pa$=left$(i$+"    ",8):print \"New Password Accepted":return

; do voting section
force
 if not flag(1) then return
 open #1,a$:mark(1)=(un/512)*64:fill ram2,64,0
 read #1,ram2,64:z=flag:flag=ram2:a=flag(un)
 flag=z:close:if a return

voting
 setint(""):create a$:open #1,a$
 mark(1)=(un/512)*64:x=mark(1):fill ram2,64,0
 read #1,ram2,64:z=flag:flag=ram2:a=flag(un)
 flag(un)=1:flag=z:mark(1)=x:write #1,ram2,64
 x=1:z=byte:byte=ram2
vote2
 open #2,a$+"."+str$(x):if mark(2) goto vote5
 input #2,y:if a then setint(1)
 print \s$\:copy #2:position #1,32,x+7
 fill ram2,32,0:read #1,ram2,32
 b=byte(0)+byte(1)*256:if a goto vote4
vote3
 print \"Vote (1-"y",S=Skip):";
 input i$:if i$="S" goto vote4
 d=val(i$):if (d<1) or (d>y) goto vote3
 b=b+1:byte(0)=b mod 256:byte(1)=b/256
 c=byte(d*2)+byte(d*2+1)*256:c=c+1
 byte(d*2)=c mod 256:byte(d*2+1)=c/256
 position #1,32,x+7:write #1,ram2,32
vote4
 if key(1) then close:return
 print \"Results from "b" users:"\:b=b+(b=0)
 for c=1 to y:y=byte(c*2)+byte(c*2+1)*256
 print "Answer "c" - "(y*100)/b"%"
 next:close #2:x=x+1:goto vote2
vote5
 close:byte=z:return

; bulletins / e-mail
bulletins
 if len(i$)<2 goto link.msg
 a=val(mid$(i$,2)):if a then bb=a
link.msg
 link "a:msg.seg",a$
return
 on nocar goto term1
 return

; *** sub - routines ***

; enter a message
editor
 on nocar goto editor1
 print \"Enter message now, "edit(3)" cols, [4k] max"
 print '[DONE] when finished, [.H] for help'
 cl=clock(2):clock(2)=0:edit(0):edit(1):clock(2)=cl
 on nocar goto term1:return
editor1
 pop:clock(2)=cl:goto term1

; show a disk file
show.file
 setint(1):print \s$\:open #1,f$:if mark(1) close #1:return
showfl2
 copy (20) #1
 if (eof(1) or key(1)) setint(""):close #1:return
 if not flag(35) goto showfl2
 print "Press [RETURN] ";:get i$:if i$=chr$(13) print " ";
 print chr$(8,16);chr$(32,16);chr$(8,16);
 if i$=" " setint(""):close #1:return
 setint(1):goto showfl2
