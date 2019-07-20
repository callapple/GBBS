; *******************
;  GBBS "Pro" V:2.2
;   New Msg Fix
; Copyright 1980-2017
;  Kevin M. Smallwood
; *******************
 byte=ram

start
 text:home
 print "New Msg Fix V2.2"
 print \"Reset users to see all or none of"
 print "the new bulletins?"
 input @0 \"(All/None):" i$
 if i$="A" lr=1
 if i$="N" lr=2
 if not lr goto start
 open #1,"b:data"
 input #1,c1,c2,ct,ct$,da$
 input #1,nu,mn,wm,tm\lu$
 close:mn=1:tm=0
 bb=1:gosub bl.ldinf
 for x=1 to ab
 bb=x:gosub bl.ldinf
 print \"Fixing: "bn$
 ready bf$
 if not msg(0) goto loop
 for y=1 to msg(0)
 msg(y)=mn:mn=mn+1
 tm=tm+1:next

loop
 next:update
 if lr=2 then lr=mn

 print \"Fixing Users..."\
 open #1,"b:users"
 for x=1 to nu
 print "Fixing user #"x" of "nu;:poke 36,0
 position #1,128,x
 input #1,a$
 if a$="" goto loop2

 byte(0)=lr mod 256:byte(1)=lr/256
 position #1,128,x,112
 write #1,ram,2

loop2
 next:close

 open #1,"b:data"
 print #1,c1,c2,ct,ct$,da$
 print #1,nu,mn,wn,tm\lu$
 close

 print \\"New Msg Fix Complete"
 end

bl.ldinf
 if bb=0 then bf$="":bl=0:return
 me=0:if bl=bb ready bf$:return
 bl=bb:open #1,"b:data2"
 mark(1)=1120:input #1,ab
 if bb>ab close:bf$="":bl=0:return
 position #1,128,bb+8
 input #1,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb
 b1=1:if b3 then b1=flag(b3)
 b2=1:if b4 then b2=flag(b4)
 close:if bf$="" then bl=0:return
 if (b1) ready bf$:nn=nb
 return
