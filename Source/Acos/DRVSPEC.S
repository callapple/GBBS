 PAG
*-------------------------------
* Default Drivspecs
*-------------------------------
* to be created by the config program
*-------------------------------

START RTS

TOVAL DB 159 ;value for timeout (159 = 5 mins)
 DA BBS_PRG ;location of startup setment name
 DB #>CODEND ;location of start of segment space
 DB #>FILTER-START ;location of filter

 DA START1 ;init acos w/ modem interupt
 DA START2 ;init acos w/out modem interupt
 DA FATAL6
 DA TOPBUF

STPCHR ASC ' ' ;stop message char
NXTCHR ASC 'N' ;next message char

WIDTH DB 4 ;index for default
 DB 32,40,64,80

DEVNAM STR '/H1/GBBS.PRO/PROGRAM' A
 STR '/H1/GBBS.PRO/SYSTEM' B
 STR '/H1/GBBS.PRO/GFILES' C
 DB 0 D
 STR '/H1/GBBS.PRO/SYSTEM' E
 STR '/H1/GBBS.PRO/BULLETINS' F
 STR '/H1/GBBS.PRO/MAIL' G
 DB 0 H
 DB 0 I
 DB 0 J
 DB 0 K
 DB 0 L
 DS \
