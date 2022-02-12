;; a2-monitor.inc
;;   entry points, soft switches, and ZP var locations
;;   from the Apple ][ monitor/AppleSoft

Mon_WNDLFT	= $20
Mon_WNDWDTH	= $21
Mon_WNDTOP	= $22
Mon_WNDBTM	= $23
Mon_CH		= $24
Mon_CV		= $25
Mon_BASL	= $28
Mon_BASH	= $29
Mon_BAS2L	= $2a
Mon_BAS2H	= $2b
Mon_INVFLG	= $32
Mon_CSWL	= $36
Mon_KSWL	= $38
Mon_RNDL	= $4E
Mon_RNDH	= $4F
Mon_TEXTTAB	= $67
Mon_VARTAB	= $69
Mon_PRGEND	= $AF
Mon_CHRGET	= $B1
Mon_CHRGOT	= $B7

Mon_BASCALC	= $FBC1
Mon_BELL1	= $FBD9
Mon_VTAB	= $FC22
Mon_VTABZ	= $FC24
Mon_KEYIN	= $FD1B
Mon_COUT1	= $FDF0
Mon_MONZ	= $FF69

SS_KBD		= $C000
SS_KBDSTRB	= $C010