; One party icon per Pokémon instead of the ten shared shapes.
;
; After the pret wiki tutorial "Add All Unique Party Menu Sprite Icons" (dannye). The
; icons were drawn by Blue Emerald, Chamber_, Soloo993, et al.
;
; The original game loads every shape when the party menu opens and picks tiles per
; Pokémon. Here the tiles of the Pokémon that are present are loaded, and the sprites
; of party slot n always use tiles n * 8 to n * 8 + 7 and sprite palette n.
;
; gfx/icons/party_mon_icons.png has two 16x16 frames per Pokémon, in Pokédex order, the
; second below the first, so the 8 tiles of an icon are
;     frame 1: top left, top right, bottom left, bottom right
;     frame 2: the same four
; (the tutorial's sheet has the frames side by side; this is the same art rearranged so
; that a frame is four tiles in a row). 151 icons are $4B80 bytes: 128 icons fill one
; bank exactly, the rest are in the next.
;
; Used by the party menu, the nickname screen and the box grid. The trade animation
; still uses the old shapes (engine/gfx/mon_icons.asm), so the link code is untouched.

DEF PARTY_MON_ICON_SIZE EQU PARTY_MON_ICON_TILES tiles

SECTION "Party Mon Icons 1", ROMX[$4000], BANK[$2D]

PartyMonIcons:
	INCBIN "gfx/icons/party_mon_icons.2bpp", 0, $4000

SECTION "Party Mon Icons 2", ROMX[$4000], BANK[$2E]

	INCBIN "gfx/icons/party_mon_icons.2bpp", $4000


SECTION "Party Mon Icon Routines", ROMX, BANK[$2E]

GetPartyMonIconPointer::
; a = species index. Returns the bank in a and the address in hl of the Pokémon's
; 8 icon tiles. Keeps bc and de.
	ld [wPokedexNum], a
	push de
	predef IndexToPokedex ; a predef returns with its own de and hl
	pop de
	ld a, [wPokedexNum]
	dec a
	cp NUM_POKEMON
	jr c, .valid
	xor a ; MissingNo. and anything else without a Pokédex number
.valid
	ld l, a
	ld h, 0
REPT 7
	add hl, hl ; PARTY_MON_ICON_SIZE
ENDR
	ASSERT PARTY_MON_ICON_SIZE == 1 << 7
; hl is $0000-$4B00. Below $4000 it is an offset into the first bank, from $4000 on it
; is already the address in the second.
	bit 6, h
	set 6, h
	ld a, BANK(PartyMonIcons)
	ret z
	inc a
	ret

CopyPartyMonIcon:
; Copy the 8 icon tiles of species a to de. For use while the LCD is off.
; Returns de behind the copy.
	call GetPartyMonIconPointer
	ld bc, PARTY_MON_ICON_SIZE
	jp FarCopyData

LoadPartyMonIcons::
; The party menu when it opens: load the icon of every Pokémon in the party, slot n to
; sprite tiles n * 8. The screen has just been cleared, so the LCD is off unseen, as it
; was for the shared shapes in the original.
	call DisableLCD
	ld de, vSprites
	ld hl, wPartySpecies
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	push hl
	call CopyPartyMonIcon
	pop hl
	jr .loop
.done
	jp EnableLCD

LoadSwitchedPartyMonIcons::
; The party menu after SWITCH: the Pokémon in slots [wSwappedMenuItem] and
; [wCurrentMenuItem] changed places. Their icons are loaded during VBlank, a frame each,
; with the menu on screen (turning the LCD off here would make the menu blink), and
; their colours with them. SwitchPartyMon has hidden the sprites of the two slots, so
; no icon is seen with the other one's tiles or colours.
	ld a, [wSwappedMenuItem]
	call .load
	ld a, [wCurrentMenuItem]
.load
	ld e, a
	ld d, 0
	ld hl, wPartySpecies
	add hl, de
	ld d, [hl]
	push de
	farcall GetMonPaletteID_d
	farcall LoadSpritePaletteAndUpdate
	pop de
	jp LoadSpriteIcon

PlacePartyMonIcon::
; Write the four sprites of party slot [hPartyMonIndex] and make the copy that
; AnimatePartyMon flips back to.
	push hl
	push de
	push bc
	ldh a, [hPartyMonIndex]
	swap a ; * 16
	ld c, a
	ld b, 0
	ld hl, wShadowOAM
	add hl, bc
	ld d, h
	ld e, l
	ld hl, PartyMonIconOAM
	add hl, bc
	ld bc, OBJ_SIZE * 4
	call CopyData
	ld hl, wShadowOAM
	ld de, wMonPartySpritesSavedOAM
	ld bc, OBJ_SIZE * 4 * PARTY_LENGTH
	call CopyData
	pop bc
	pop de
	pop hl
	ret

LoadSinglePartyMonIcon::
; The nickname screen: load the icon of species [wMonPartySpriteSpecies] as the icon
; of party slot 0, in the Pokémon's own colours.
	ld a, [wMonPartySpriteSpecies]
	call GetPartyMonIconPointer
	ld b, a
	ld d, h
	ld e, l
	ld hl, vSprites
	ld c, PARTY_MON_ICON_TILES
	call CopyVideoData
	ld a, [wMonPartySpriteSpecies]
	ld d, a
	farcall GetMonPaletteID_d
	ld e, 0
	farcall LoadSpritePaletteAndUpdate
	ldh a, [hPartyMonIndex]
	push af
	xor a
	ldh [hPartyMonIndex], a
	call PlacePartyMonIcon
	pop af
	ldh [hPartyMonIndex], a
	ret

PartyMonIconOAM:
; y, x, tile, attributes (the sprite palette)
FOR n, PARTY_LENGTH
	db $10 + n * 16, $10, n * PARTY_MON_ICON_TILES + 0, n
	db $10 + n * 16, $18, n * PARTY_MON_ICON_TILES + 1, n
	db $18 + n * 16, $10, n * PARTY_MON_ICON_TILES + 2, n
	db $18 + n * 16, $18, n * PARTY_MON_ICON_TILES + 3, n
ENDR


; The box grid (engine/pokemon/box_grid.asm). A box icon is the first frame only, as
; four background tiles; a sprite icon is both frames, as in the party menu.
; All of these take the species in d, as far calls cannot pass a.

LoadBoxIcon::
; d = species, e = box icon set. Copied during VBlank; takes a frame.
	call BoxIconAddress
	ld c, BOXGRID_BOX_ICON_TILES
	jr CopyIconDuringVBlank

LoadSpriteIcon::
; d = species, e = sprite icon set. Copied during VBlank; takes a frame.
	call SpriteIconAddress
	ld c, PARTY_MON_ICON_TILES
	; fallthrough
CopyIconDuringVBlank:
; d = species, hl = destination, c = how many tiles
	push hl
	push bc
	ld a, d
	call GetPartyMonIconPointer
	pop bc
	ld b, a
	ld d, h
	ld e, l
	pop hl
	jp CopyVideoData

LoadHoverFrame::
; d = species. Its second frame goes to the four tiles the grid shows in turn with the
; icon under the cursor.
	ld a, d
	call GetPartyMonIconPointer
	ld b, a
	ld de, PARTY_MON_ICON_FRAME tiles
	add hl, de
	ld d, h
	ld e, l
	ld hl, vChars2 tile BOXGRID_HOVER_TILE
	ld c, PARTY_MON_ICON_FRAME
	jp CopyVideoData

LoadBoxIconFast::
; d = species, e = box icon set. Copied between scanlines with the screen on, at once
; (home/fast_video_copy.asm): for a whole box of icons when the box changes.
	call BoxIconAddress
	push hl
	ld a, d
	call GetPartyMonIconPointer
	ld b, a
	ld d, h
	ld e, l
	pop hl
	ld c, BOXGRID_BOX_ICON_TILES
	jp FastCopyVideoData

LoadBoxIconNow::
; d = species, e = box icon set. For use while the LCD is off.
	call BoxIconAddress
	ld bc, BOXGRID_BOX_ICON_TILES tiles
	jr CopyIconNow

LoadSpriteIconNow::
; d = species, e = sprite icon set. For use while the LCD is off.
	call SpriteIconAddress
	ld bc, PARTY_MON_ICON_SIZE
	; fallthrough
CopyIconNow:
; d = species, hl = destination, bc = how many bytes
	push hl
	push bc
	ld a, d
	call GetPartyMonIconPointer
	pop bc
	pop de
	jp FarCopyData

BoxIconAddress:
; hl = where box icon set e is in VRAM. Keeps de.
	ld l, e
	ld h, 0
REPT 6
	add hl, hl ; BOXGRID_BOX_ICON_TILES tiles
ENDR
	ASSERT BOXGRID_BOX_ICON_TILES tiles == 1 << 6
	ld a, h
	add HIGH(vChars2)
	ld h, a
	ret

SpriteIconAddress:
; hl = where sprite icon set e is in VRAM. Keeps de.
	ld l, e
	ld h, 0
REPT 7
	add hl, hl ; PARTY_MON_ICON_SIZE
ENDR
	ld a, h
	add HIGH(vSprites)
	ld h, a
	ret
