; Far calls to another bank

; There is no difference between `farcall` and `callfar`, except the arbitrary
; order in which they set `b` and `hl` before calling `FarCall`.
; We use the more natural name "farcall" for the more common order.
; The same goes for `farjp` and `jpfar`.

; In the home bank, where space is short, the call is `rst _Bankswitch`, a one-byte
; call to `jp Bankswitch` (home/header.asm). Everywhere else it stays a plain call:
; the other banks hold the maps and their scripts, whose addresses end up in save
; files, so that code must keep the size it has on the cartridge.
; (IN_HOME_BANK is defined at the top of home.asm.)

MACRO farcall
	ld b, BANK(\1)
	ld hl, \1
IF DEF(IN_HOME_BANK)
	rst _Bankswitch
ELSE
	call Bankswitch
ENDC
ENDM

MACRO callfar
	ld hl, \1
	ld b, BANK(\1)
IF DEF(IN_HOME_BANK)
	rst _Bankswitch
ELSE
	call Bankswitch
ENDC
ENDM

MACRO farjp
	ld b, BANK(\1)
	ld hl, \1
	jp Bankswitch
ENDM

MACRO jpfar
	ld hl, \1
	ld b, BANK(\1)
	jp Bankswitch
ENDM

; `rst SetRomBank` is a one-byte call that loads the ROM bank in a (home/header.asm).

MACRO homecall
	ldh a, [hLoadedROMBank]
	push af
	ld a, BANK(\1)
	rst SetRomBank
	call \1
	pop af
	rst SetRomBank
ENDM

MACRO homecall_sf ; homecall but save flags by popping into bc instead of af
	ldh a, [hLoadedROMBank]
	push af
	ld a, BANK(\1)
	rst SetRomBank
	call \1
	pop bc
	ld a, b
	rst SetRomBank
ENDM
