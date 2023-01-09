*-------------------------------
* Clock Driver Header Block
*-------------------------------
* Revised Date: 11/08/89
*-------------------------------
*
* driver load info
*
* $0800 = header block                  ;offset
* $0a00 = Thunder/Timemaster            ;2
* $0b00 = A.E. Serial Pro               ;3
* $0c00 = SMT No Slot clock             ;4
* $0d00 = Apple //gs Clock              ;5
* $0e00 = A.E. Ultra Clock              ;6
* $0f00 = prodos compatible             ;7
* $1000 = Mountain Clock                ;8
* $1100 = Versacard                     ;9
* $1200 = no clock in system            ;a
* $1300 = //c System Clock              ;b

 rel
 dsk rel/header

 org $0800

clocks hex 0201
 asc 'Thunderclock Compatable       '
 hex 0201
 asc 'A.E. Timemaster II H.O.       '
 hex 0301
 asc 'A.E. Serial Pro               '
 hex 8401
 asc 'SMT No Slot Clock             '
 hex 8501
 asc 'Apple //GS built-in clock     '
 hex 8601
 asc 'A.E. Ultra Clock              '
 hex 8701
 asc 'ProDOS Compatible Clock       '
 hex 0801
 asc 'Mountain Hardware Clock       '
 hex 0901
 asc 'Prometheus Versacard          '
 hex 8a01
 asc 'No Clock in System            '
 hex 0b01
 asc 'A.E. //c System Clock         '

 hex 0000
 ds \


