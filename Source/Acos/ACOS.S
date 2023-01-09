 TR
 TR ADR
********************************
*                              *
*    GBBS Pro Version 2.20     *
*                              *
********************************

* Copyright 1986-2019 by Kevin Smallwood

 LST OFF
N = 0
n = 0
Y = 1
y = 1

L_SOURCE KBD "List this assembly? (Y/N)"

 DSK ACOS.OBJ

 DO L_SOURCE
 LST
 FIN

 PUT EQUATES

 ORG $800

 PUT DRVSPEC
 PUT DRIVERS
 PUT START
 PUT ROUTINE
 PUT VAR
 PUT MATH
 PUT DISK
 PUT DRIVE
 PUT DISKIO
 PUT LOAD
 PUT CMD
 PUT CMD2
 PUT EDIT

 DS \ fill

 PUT FILTER
CODEND = *

 PUT INIT

 DSK ENCODE

 PUT ENCODE
