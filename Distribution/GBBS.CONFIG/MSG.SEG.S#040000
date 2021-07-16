; *******************
; GBBS "Pro" V:2.2n
; Copyright 1980-2017
;  Kevin M. Smallwood
; *******************
; msg segment - 2/19/2017

 public bulletins
 public rd.mail
 public sd.mail
 public wr.letter

bulletins
 zz=0:fl=peek(2053)*256:pf=peek(fl):gosub start
 flag(37)=1:gosub pfilter:goto link.main
rd.mail
 gosub rd.mail0:goto link.main
sd.mail
 gosub snd.mail:goto link.main
wr.letter
 s=8:gosub wr.ltr
link.main
 link "a:main.seg","return"
link.term
 link "a:main.seg","termin2"

; *** bulletins / e-mail ***

start
 on nocar goto link.term
 gosub idinf
 if bf$="" print \"That board is down right now.":gosub cmd2c:return
 if not b1 print \"You do not have access to that board.":gosub cmd2c:return
 if i$="Q" gosub qscan
cmd1
 if msg(0) goto cmd2
 print \"The "bn$\" has no bulletins...";
 input @2 "Post a bulletin ([Y]/N) ?" i$
 if left$(i$,1)="N" return
 sb$="":ti$="All":d=0:gosub post:if not b2 return
 goto cmd1

cmd2
 x=(clock(2)-clock(1))/60:y=clock(2):x$=right$("0"+str$(x),2)
 if clock(1)>clock(2) x$="!!"
 if x=0 x$="--"
 if not y x$="**"
 if info(5) x$="::"
 free:print \bn$\"["x$"][Board #"bb"  1-"msg(0)"] ";
 input "Option (?=Help):" i$
cmd2a
 zz=0:a=val(i$):push cmd2
 if left$(i$,1)="J" then i$=mid$(i$,2):goto jmp3
 if left$(i$,1)="F" goto fwd
 if left$(i$,1)="R" goto rvs
 if left$(i$,1)="K" goto kill
 if left$(i$,1)="S" goto scan
 if i$="A" or i$="Q" pop:return
 if i$="M" goto mark
 if i$="N" goto new
 if i$="B" goto browse
 if i$="G" goto qscan
 if i$="H" f$="b:hlp.msg":goto show.file
 if i$="J" y=0:goto jump
 if i$="P" then ti$="All":sb$="":d=0:goto post
 if i$="L" y=1:goto list
 if i$="T" goto terminate
 if i$=">" and (bb<ab) bb=bb+1:zz=1:pop:goto start
 if i$="<" and (bb>1) bb=bb-1:zz=2:pop:goto start
 if (a>0) and (a<=msg(0)) i$="F"+i$:goto fwd
 if i$="?" or i$="/" goto cmd.menu
 a1=a1+1:print \'Sorry, "'i$'" is not a command. (?=Help)':if a1<3 return

cmd.menu
 a1=0:print \bn$\'
 Read #, OR: [N]ew   [F#]orward [S#]can [B]rowse [M]arked [L]ist
             [R#]vse [G]lobal   [J#]ump [P]ost   [K#]ill  [H]elp
             [Q]uit  [>] Next board     [<] Previous board

 Command letters followed with "#" have a numeric argument option.
 "F45" reads F)orward beginning at bulletin 45
 "K32" would K)ill bulletin #32"
':return

cmd2c
 if not zz return
 if zz=1 bb=bb+1
 if zz=2 bb=bb-1
 zz=0:pop:goto start

; terminate connection

terminate
 print \"Terminate Connection"
 input @2 \"Are you sure (Y/[N]) ?" i$
 if left$(i$,1)<>"Y" return
 link "a:main.seg","termin2"

; post a bulletin

post
 if not b2 print \"You do not have access to that board.":return
 edit(0):if kl goto post2
 if msg(0)=mb print \"Sorry, no room on this board.":return
 if msg(0)=info(1) print \"Board directory full.":return
 if info(6)<29 print \"Board bit-map full.":return
post2
 print \"Post Bulletin"\
 if d open #1,"b:users":position #1,128,d:input #1,d1$,d2$\d3$:close
 if d ti$=d3$+" (#"+str$(d)+")":if d=1 ti$="Sysop"
 if ti$<>"" print "  To ->"ti$" ([Y]/N):";: get i$
 if i$=chr$(13) n=9:gosub backup:print:goto post2a
 if i$="N" n=len(ti$)+10:gosub backup:input @4 ti$:if ti$="" return
 if (ti$<>"") and left$(i$,1)<>"N" n=10:gosub backup:print
 if ti$="" input @4 "  To ->"ti$:if ti$="" return
post2a
 i$="":if sb$<>"" print " Sub ->"sb$" ([Y]/N):";:get i$
 if i$=chr$(13) n=9:gosub backup:print:goto post2b
 if i$="N" n=len(sb$)+10:gosub backup:input @4 a$:if a$="" return
 if (sb$<>"" or a$<>"") and left$(i$,1)<>"N" n=10:gosub backup:print
 if sb$="" input @4 " Sub ->"a$:if a$="" return
 if a$<>"" sb$=a$
post2b
 a$=a3$:if (un=bs) and  (bs$<>"") a$=bs$
 a$=a$+" (#"+str$(un)+")"
 if not info(5) goto post2c
 i$="":print "From ->"a$" ([Y]/N):";:get i$
 if i$=chr$(13) n=9:gosub backup:print:goto post2c
 if i$="N" n=len(a$)+10:gosub backup:input @3 a$:if a$="" return
 if (a$<>"") and left$(i$,1)<>"N" n=10:gosub backup:print
post2c
 i$="":if flag(36) print \"Anonymous Posting (Y/[N]):";:get i$:print
 if (flag(36)) and (i$="Y") flag(38)=1:else flag(38)=0
 input @2 \"Post: [Y]es, N)o, X)modem " i$
 if i$="N" return
 if i$="X" gosub up.xmdm:else gosub editor
 if not edit(2) return
 print \edit(2)" bytes entered"
 print "Saving Message...wait..";:bp=bp+1
 if (kl>0) and (kl<=msg(0)) kill #msg(kb):crunch:b=b-1
 a=msg(0)+1
 if flag(38) print #msg(a),"*"sb$:else print #msg(a),sb$
 print #6,tn,ti$
 if flag(38) print #6,0,a$:else print #6,un,a$
 if flag(38) print #6,"Date ->"date$\:else print #6,"Date ->"date$"  "time$\
 copy #8,#6:msg(a)=mn:mn=mn+1:update:tm=tm+1
 print ".saved":ti$="":a$="":return

; show new bulletins
new
 print \"New Bulletins"
 if nn>msg(msg(0)) print \"No new bulletins":return
 x=msg(0):if not lr a=1:goto fwd2
new1
 if nn=<msg(x) a=x:x=x-1:if x goto new1
 goto fwd2

; bulletin retrieval - Forward
fwd
 if len(i$)>1 a=val(mid$(i$,2)):goto fwd1
 print \"Sequential Retrieval - Forward"
 input @2 \"Start where (#, F)irst, <CR>):" i$
 a=val(i$):if i$="F" a=1
fwd1
 if a<1 return
 if a>msg(0) a=msg(0)
fwd2
 print \s$\n$
fwd3
 gosub show:if x return
 if a<msg(0) then a=a+1:goto fwd3
 return

; bulletin retrieval - Reverse
rvs
 if len(i$)>1 a=val(mid$(i$,2)):goto rvs1
 print \"Sequential Retrieval - Reverse"
 input @2 \"Start where (#, L)ast, <CR>):" i$
 a=val(i$):if i$="L" a=msg(0)
rvs1
 if a<1 return
 if a>msg(0) a=msg(0)
rvs2
 print \s$\n$
rvs3
 gosub show:if x return
 if a>1 then a=a-1:goto rvs3
 return

; kill bulletins
kill
 if len(i$)>1 a=val(mid$(i$,2)):goto kill.1
 print \"Kill a Bulletin"
 input @2 \"Kill Bulletin (#,<CR>):" a
kill.1
 if (a<1) or (un=0) return
 if a>msg(0) print \"That Bulletin Does Not Exist!":return
 input #msg(a),a$\x,b$\x,c$
 if (info(5)) or (un=bs) goto kill.2
 if x<>un print \"Thats not your bulletin!":return
kill.2
 if (flag(38)) and (left$(a$,1)="*") a$=mid$(a$,2)
 print \"Numb ->"a" of "msg(0)\" Sub ->"a$
 input @2 \"Kill this bulletin (Y/[N]) ?" i$
 if left$(i$,1)<>"Y" return
kill.3
 tm=tm-1:y=msg(msg(0)):kill #msg(a):crunch
 b=msg(0):if b then msg(b)=y:update
 print \"Bulletin #"a" killed..."
 return

; browse bulletins titles
browse
 m$="":a=0:print \"Scan Bulletin Titles"
 print \"Scan for what text [<CR>=Everything]?"
 input @3 ":" m$:a=1:if m$="" a=0:return
 goto scan.2

; scan bulletins
scan
 print \"Scan bulletins"
 if len(i$)>1 a=val(mid$(i$,2):goto scan.1
 input @3 \"Start at (#,<CR>):"a
scan.1
 m$="":if a<1 return
 if a>msg(0) print \"That Bulletin Does Not Exist!":return
scan.2
 input @2 \"Allow marking (Y/[N]) ?" i$
 ms=0:if left$(i$,1)="Y" ms=a
 d=0:x=15:print:z=flag:flag=ram2
scan.3
 a$=" ":if msg(a)>nn then a$="*"
 flag(a-ms)=0:input #msg(a),t$\b,b$
 if m$ if not instr(m$,t$) goto scan.4
 if left$(t$,1)="*" t$=mid$(t$,2)
 x=x-1:d=d+1:print a$a". "t$\"  Addressed to:"b$\
 if i$<>"Y" goto scan.4
 print "Mark (Y/[N]/Q) ?";:get a$:print
 if a$="Q" goto scan.5
 flag(a-ms)=(a$="Y")
scan.4
 if a=msg(0) goto scan.5
 a=a+1:if x goto scan.3
 input @2 \"More ([Y]/N/C) ?" a$
 if left$(a$,1)="C" x=msg(0)-a-1:goto scan.3
 if left$(a$,1)<>"N" print:x=15:goto scan.3
scan.5
 me=a:flag=z:if not (d) print "Sorry, no match":ms=0:return
 if left$(i$,1)<>"Y" return

; marked bulletins retrieval
mark
 print \"Retrieve marked bulletins":a=ms
 if not ms print \"No marked bulletins":return
mark.2
 z=flag:flag=ram2:b=flag(a-ms):flag=z
 x=0:if b gosub show
 if x=0 a=a+1:if a<me goto mark.2
 return

; jump to another board.
jump
 print \"Jump to Another Board"
jmp2
 print \"Jump to (1-"ab",?,<CR>):";
 input @2 i$:if i$="" return
jmp3
 a=val(i$)
 if (a>0) and (a<=ab) pop:bb=a:goto start
 if i$<>"?" goto jmp2

; list of available boards.
list
 print sc$\s$\:open #1,"b:data2"
 for x=1 to ab:position #1,128,x+8
 input #1,a$\b$\a:setint(1)
 if instr(left$(a$,1),"#$%") a$=mid$(a$,2)
 b=1:if a then b=flag(a)
 if b and (b$<>"") print x". "a$
 if key(1) setint(""):x=ab
 next:close:if y return:else goto jmp2

; global quickscan
qscan
 ob=bb:bb=1
 print \"Global Quickscan...Spacebar Exits"
qs1
 setint (1):print \"Checking board: [";
qs2
 i$="":a$=right$("0"+str$(bb),2)
 print a$"]";:gosub idinf:setint(1):if key(1) goto qs4
 if (not b1) or (bf$="") or (msg(0)=0) goto qs3
 if nn>msg(msg(0)) goto qs3
 print \\"The "bn$\"contains new message(s)"
 input @2 \"[R]ead S)kip Q)uit ?" i$
 if left$(i$,1)="Q" return
 if left$(i$,1)="S" goto qs3
 gosub new:input @2 \"Post a message (Y/[N]) ? " i$
 if i$="Y" sb$="":ti$="":gosub post
 i$="Y"
qs3
 bb=bb+1:if bb>ab goto qs4
 if i$<>"" goto qs1
 print chr$(8,3);:goto qs2
qs4
 if i$="" or i$=" " print
 setint(""):bb=ob:goto idinf

; bulletin show routine
show
 if nn<=msg(a) then nn=msg(a)+1
 x=0:if lr<=msg(a) then lr=msg(a)+1
show1
 if flag(36) goto anony
 input #msg(a),sb$\tn,ti$\d,fr$:setint(2)
 print #x,\" Brd ->"bn$\"Numb ->"a" of "msg(0)\" Sub ->"sb$
 print #x,"  To ->"ti$
 print #x,"From ->"fr$
show1a
 copy #6,#x:x=0:setint("")
 if key(1) x=1:return
 if key(2) return
show2
 if i$="+" return
 print \"[B"bb" #"a" of "msg(0)"] ? or Cmd [N]#";
 get i$:print
 if i$="?" print \"M)ail [N]ext R)eread X)modem Q)uit D)ump ";
 if i$="?" and (d=un or info(5)) print "E)dit K)ill ";
 if i$="?" and info(5) print "S)wap P)rint"
 if i$="?" print
 if i$="D" i$="+":return
 if i$="N" or i$=chr$(13) or i$="+" return
 if i$="Q" x=1:return
 if i$="R" goto show
 if i$="P" and info(5) x=5:goto show1
 if (i$="A" or i$="M") and flag(1) a$="":goto show5
 if i$="A" or i$="M" print \"Security too low":goto show2
 if i$="X" goto dn.xmdm
 if not flag(1) goto show2
 if not((d=un) or (info(5))) goto show2
 if i$="E" and (flag(2) or info(5)) goto show4
 if i$="W" and info(5) goto wrt.msg
 if i$="S" and info(5) goto mov.msg
 if i$<>"K" goto show2
 input @2 \"Kill: Are you Sure (Y/[N]) ?" i$
 if left$(i$,1)<>"Y" goto show2
 gosub kill.3:a=a-1:return
show4
 input @2 \"Edit: Are you Sure (Y/[N]) ?" i$
 if left$(i$,1)<>"Y" goto show2
 edit(0):input #msg(a),a$\b,b$\c,c$\d$\e$
 copy #6,#8:edit(1):if not edit(2) goto show2
 x=msg(a):kill #msg(a):print #msg(a),a$\b,b$\c,c$\d$\e$
 copy #8,#6:msg(a)=x:update:goto show2
show5
 input @2 \"Is this a private letter (Y/[N]) ?" i$
 if left$(i$,1)="Y" goto show6
 if (d=0 and flag(36)) ti$="Anoymous User":goto show5a
 open #1,"b:users":position #1,128,d
 input #1,d1$,d2$\d3$:close:ti$=d3$
show5a
 if left$(sb$,3)<>"Re:" then sb$="Re: "+sb$
 b=a:gosub post:a=b:goto show2
show6
 if d=0 print \"Sorry, anonymous sender":goto show2
 gosub editor:if not edit(2) goto show2
 print \edit(2)" bytes entered"
 print "Wait..";:s=8:gosub wr.ltr
 ready bf$:print ".reply sent":goto show2

wrt.msg
 input @2 \"Filename (to write):" i$
 if i$="" goto show2
 create i$:open #1,i$:append #1
 copy #msg(a),#1:close:goto show2

mov.msg
; Bulletin Mover From Al Anderson
 print \\"Bulletin Mover Utility"\\"Boards 1-"ab
 input @2 \"Move this post to board #" i$:zx=val(i$)
 if (zx>ab) or (zx<1) goto show2
 edit(0):input #msg(a),a$\b,b$\c,c$:copy #6,#8
 x=msg(a):b5=bb:bb=zx:gosub idinf
 if (kl>0)and(kl<=msg(0)) kill #msg(kb):crunch
 zx=msg(0)+1:print #msg(zx),a$\b,b$\c,c$:copy #8,#6:msg(a)=zx:update
 bb=b5:gosub idinf:msg(a)=x:print "On this board...";:gosub kill.3:a=a-1
 print "Bulletin is now on other board.":goto show2

;show a bulletin on anonymous boards.
anony
 input #msg(a),sb$\tn,ti$\d,fr$:setint(2)
 if left$(sb$,1)="*" sb$=mid$(sb$,2):goto anony1
 print #x,\" Brd ->"bn$\"Numb ->"a" of "msg(0)\" Sub ->"sb$
 print #x,"  To ->"ti$
 print #x,"From ->"fr$
 goto show1a
anony1
 print #x,\" Brd ->"bn$\"Numb ->"a" of "msg(0)\" Sub ->"sb$
 print #x,"  To ->"ti$
 if info(5) print #x,"From ->"fr$:goto show1a
 print #x,"From ->Anonymous Poster":goto show1a

;xmodem d/l of bulletin by Keith Christian

dn.xmdm
 print \"Download bulletin #"a;
 input @2 " via Xmodem (Y/[N]) ?" i$
 if left$(i$,1)<>"Y" return
 print \"Select Xmodem type:"
 input @2 \"P)roDOS  D)OS3.3  S)tandard " i$
 if i$="" return
 z=instr(i$,"PDS"):z=z*(z<>3):f$="b:d"
 create f$:ready bf$:open #1,f$
 input #msg(a),sb$\b,ti$\c,fr$:setint(2)
 y=0:if left$(sb$,1)="*" sb$=mid$(sb$,2):y=1
 print #1,\" Brd ->"bn$\Numb ->"a" of "msg(0)\" Sub ->"sb$
 print #1,"  To ->"ti$
 if y print #1,"From ->Anonymous Poster":else print #1,"From ->"fr$
 copy #6,#1:close:print \"Ready to Send..."
 use "b:x.dn",z,f$:kill f$:goto show2

;xmodem u/l of bulletin by Keith Christian

up.xmdm
 print \"Select Xmodem type:"
 input @2 \"P)roDOS  D)OS3.3  S)tandard ?" i$
 z=instr(i$,"PDS"):if not z pop:return
 z=z*(z<>3):print \"Ready to Receive..."
 f$="b:u":use "b:x.up",z,f$
 close:edit(0):copy f$,#8
 print \edit(2)" bytes received"
 kill f$:edit(1):return

idinf
 flag(36)=0:flag(37)=1:flag(38)=0
 if bb=0 then bf$="":bl=0:return
 me=0:bl=bb:open #1,"b:data2"
 mark(1)=1120:input #1,ab
 if bb>ab close:bf$="":bl=0:return
 position #1,128,bb+8
 input #1,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb
 if left$(bn$,1)="%" flag(36)=1:flag(37)=1:bn$=mid$(bn$,2)
 if left$(bn$,1)="$" flag(36)=1:flag(37)=0:bn$=mid$(bn$,2)
 if left$(bn$,1)="#" flag(36)=0:flag(37)=0:bn$=mid$(bn$,2)
 b1=1:if b3 then b1=flag(b3)
 b2=1:if b4 then b2=flag(b4)
 close:if bf$="" then bl=0:return
 if (b1) ready bf$:nn=nb
pfilter
 if not flag(37) poke fl,0:else poke fl,pf
 return

; read e-mail
rd.mail0
 on nocar goto link.term
 print \"Read Mail"
 if flag(0) print \"Guests can not receive mail":return
 ready "g:mail"
 if not msg(un) print \"No mail for you":return
 ready #msg(un)
rd.mail2
 x=0:input #7,i$:d=val(i$)
 if i$="" then ma=1:return
rd.mail3
 print #x,\md$:setint (2):copy #7,#x
 setint (""):print #x,md$
 if key(2) goto rd.mail2
rd.mail4
 input @2 \"(A)uto reply, [C]ontinue, (R)e-read :" i$
 if i$="" or i$="C" or i$="N" goto rd.mail2
 if i$="Q" return
 if i$="R" rewind:x=0:goto rd.mail3
 if i$="P" and info(5) rewind:x=5:goto rd.mail3
 if i$="W" and info(5) goto wr.mail
 if i$="F" goto forward
 if i$<>"A" goto rd.mail4
 if d=0 print \"Sorry, anonymous sender":goto rd.mail4
 input @2 \"Subject:" sb$:if sb$="" goto rd.mail4
 gosub editor:if not edit(2) goto rd.mail4
 print \edit(2)" bytes entered"
 print "Wait..";:h$="":s=8:gosub wr.ltr
 print ".reply sent":goto rd.mail2

wr.mail
 input @2 \"Filename (to write):" i$:if i$="" goto rd.mail4
 create i$:rewind:open #1,i$:input #7,i$
 append #1:copy #7,#1:close:goto rd.mail4

forward
 print \"Forward letter"
 a=d:gosub mail.who
 if d=0 then d=a:goto rd.mail4
 rewind:s=7
 input @2 "Subject:" sb$:if sb$="" sb$="For your information"
 h$="   --> A Forwarded Letter <--"
 r$=".letter forwarded":gosub snd.bulk
 d=a:goto rd.mail4

; send e-mail
snd.mail
 on nocar goto link.term
 print \"Send Mail"
 gosub mail.who:if d=0 return
 input @3 "Subject:" sb$:if sb$="" sb$="None"
 gosub editor:if not edit(2) return
 h$="":r$=".letter sent"
 s=8:goto snd.bulk

mail.who
 input @2 \"To who: Name, #, B)ulk mailing, <CR>):" i$
 clear #10:if i$="" then d=0:return
 if i$<>"B" gosub mail.wh2:print #10,d\0:return
 print \"Bulk Mailing":x=1
 y=5:if flag(2) then y=25

bulk1
 input @2 \"Send copy to (#,<CR>):" i$
 if i$="" then d=0:if x=1 return
 if i$<>"" gosub mail.wh2:if d=0 goto bulk1
 print #10,d:x=x+1:if d if x<y goto bulk1
 d=1:return

mail.wh2
 if left$(i$,1)="#" then i$=mid$(i$,2):goto snd.num
 if val(left$(i$,1)) goto snd.num
 d$=i$:if (d$="SYSOP") or (d$=sys$) then d=1:return
 if not instr(" ",i$) goto snd.usr2
 open #1,"b:users":d=1

snd.user
 position #1,128,d
 input #1,a$,b$\c$
 if (a$+" "+b$=d$) or (a$+b$=d$) close:return
 if d<nu then d=d+1:goto snd.user
 close:d=0
 print \d$" is not a user":return
snd.usr2
 print \"That user does not exist"
 d=0:return

snd.num
 d=val(i$)
 if (d<1) or (d>nu) goto snd.usr2
 move ram,58 to ram2:open #1,"b:users"
 position #1,128,d:input #1,a$,b$\c$
 position #1,128,d,70:read #1,ram,58
 close:i$=when$:move ram2,58 to ram
 if a$="" goto snd.usr2
 print \"Send to "c$\"Last on "i$;
 input @2 " ([Y]\N) ?" i$
 if left$(i$,1)="N" then d=0
 return

; write a bunch of letters to disk
snd.bulk
 print \edit(2)" bytes entered"
 print "Wait..";:mark(10)=0
snd.blk2
 input #10,d:if d=0 print r$:return
 gosub wr.ltr:print ".";:if s=7 rewind
 goto snd.blk2

; write the letter to disk
wr.ltr
 ready "g:mail"
 if info(6)<29 print \"Mail bit-map full":return
 print #msg(d),un:if h$<>"" print #6,h$\
 print #6,"Subj ->"sb$
 print #6,"From ->"a3$" (#"un")"
 print #6,"Date ->"date$" "time$\
 copy #s,#6:print #msg(d),chr$(4);chr$(0);
 msg(d)=1:update:return

; *** sub - routines ***

; backspace over text
backup
 print chr$(8,n);chr$(32,n);chr$(8,n);
 return

; enter a message
editor
 print \"Enter message now, "edit(3)" cols, [4k] max"
 print "[DONE] when finished, [.H] for help'
 cl=clock(2):clock(2)=0:edit(0):edit(1):clock(2)=cl:return

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
