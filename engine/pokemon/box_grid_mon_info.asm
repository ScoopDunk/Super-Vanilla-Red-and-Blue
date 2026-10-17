; For the box grid (engine/pokemon/box_grid.asm), which is in another bank than the
; shiny and gender routines and cannot pass them hl through a far call.

GetLoadedMonShinyGender::
	ASSERT BANK(GetMonGenderSymbol) == BANK(@), "the box grid's helper has to be in the bank of the shiny and gender code"
; For the Pokémon in wLoadedMon: d = "♂", "♀" or 0, e = 1 if it is shiny, else 0.
	ld hl, wLoadedMonDVs
	call IsShinyDVs
	push af
	ld a, [wLoadedMonDVs]
	swap a
	and $f
	ld e, a
	ld a, [wLoadedMonSpecies]
	ld d, a
	call GetMonGenderSymbol
	pop af
	ld e, 0
	ret z
	inc e
	ret
