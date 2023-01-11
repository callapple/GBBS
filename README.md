# GBBS
Official Archive for GBBS Pro for Apple II Series Computers

Official Call-A.P.P.L.E. site:  https://gbbs.applearchives.com

Several items have been changed and or fixed in the official 2.2 release and include the following items:
GBBS 2.2 Fixes from 2.2b1 to current (v2.2)

LOGON.SEG.S
	Fixed syntax for ACOS.TIME (line still commented out however; we don't include this external)
	Fixed an unclosed quote
	Fixed spelling of "tomarrow"
	Fixed bug in this line
			a=z:if not z then nu=nu+1:a=nu:close
		Changed it to
			a=z:if not z then nu=nu+1:a=nu
			close
	Fixed get.time routine to account for 12 or 24 hour clocks

Patched version of PRODOS 1.9 with current date table
SYS.NEW.INFO renamed to SYS.NEWINFO so it works

Removed README.214 from /GBBS.CONFIG as it does not apply
Added ENCODE to /GBBS.CONFIG

Removed ACOS.OBJ and ACOS.SYSTEM from /GBBS.SYSTEM
Updated XDOS with newer version on /GBBS.SYSTEM

CONFIG.SYSTEM
	Now shows all CAPS if on a ][+ instead of garbage
	directories created for UPLOAD and DOWNLOAD, downloads now in the DOWNLOAD directory
	X.UP and X.DN now properly copied during installation
