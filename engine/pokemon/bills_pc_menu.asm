; The menu of Bill's PC with its sixth entry, MOVE <PKMN> (the box grid). In a section
; of its own in the PC's bank: BillsPCMenu jumps here where it has to do something
; else than before, so that nothing in the section "Bill's PC" changes its size.

BillsPCDrawMenuBoxes:
	ASSERT BANK(BillsPCMenu) == BANK(@), "the PC menu's new parts have to be in the PC's bank"
; Called where BillsPCMenu drew the box with the box number. That one first, then the
; menu again, two rows taller and with its sixth entry: the text box under it has been
; drawn in the meantime and covers the rows that were added.
	hlcoord 9, 14
	lb bc, 2, 9
	call TextBoxBorder
	hlcoord 0, 0
	lb bc, 12, 12
	call TextBoxBorder
	hlcoord 2, 2
	ld de, .MenuText
	jp PlaceString

.MenuText
	db   "WITHDRAW <PKMN>"
	next "DEPOSIT <PKMN>"
	next "MOVE <PKMN>"
	next "RELEASE <PKMN>"
	next "CHANGE BOX"
	next "SEE YA!"
	db "@"

BillsPCMenuDispatch:
; a = the entry that was chosen
	and a
	jp z, BillsPCWithdraw
	dec a
	jp z, BillsPCDeposit
	dec a
	jr z, .move
	dec a
	jp z, BillsPCRelease
	dec a
	jp z, BillsPCChangeBox
	jp ExitBillsPC
.move
	farcall BoxGrid
	jp BillsPCMenu
