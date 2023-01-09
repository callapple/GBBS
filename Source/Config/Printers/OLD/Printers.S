********************************
*                              *
*     Printer Header Block     *
*                              *
********************************

*-------------------------------
* Date: 01/06/87
*-------------------------------
*
* load info:
*
* $800 = header           ;offset
* $a00 = parallel printer ;2
* $b00 = grappler         ;3
* $c00 = cout based       ;4
* $d00 = no printer       ;5

 org $0800

* Equates
* ~~~~~~~

cr equ $0d
lf equ $0a

 db $04,$01
 asc 'Apple //c Printer Port        '
 db $02,$01
 asc 'Apple Parallel Interface      '
 db $04,$01
 asc 'Apple Super Serial Card       '
 db $02,$01
 asc 'Epson APL Printer Card        '
 db $02,$01
 asc 'Tyvec Printer Interface       '
 db $02,$01
 asc 'Appricorn Parallel Card       '
 db $03,$01
 asc 'Star Micronics Grafstar       '
 db $03,$01
 asc 'Orange Micro Grapler Card     '
 db $04,$01
 asc 'Generic Printer Driver        '
 db $85,$01
 asc 'No Printer in System          '
 db 00,00
 ds \

 org $0a00
 org $0c00
 put /merlin/gbbs/printer/parallel
 ds \
 org $0b00
 org $0c00
 put /merlin/gbbs/printer/grappler
 ds \
 org $0c00
 org $0c00
 put /merlin/gbbs/printer/serial
 ds \
 org $0d00
 org $0c00
 put /merlin/gbbs/printer/null

 sav /gbbs.pro/printers


