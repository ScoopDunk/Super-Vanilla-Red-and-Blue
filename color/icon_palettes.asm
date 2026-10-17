; Colours for the unique party icons (engine/gfx/party_mon_icons.asm): every icon gets
; the palette its Pokémon has in battle.
;
; A reminder for everything in this file: while WRAM bank 2 is loaded, the stack is
; bank 2's memory too. A push and its pop, and a call and its ret, must happen with
; the same bank loaded.

SECTION "Mon Palette Lookup", ROMX, BANK[$1C]

GetMonPaletteID_d::
; d = species index. Returns the Pokémon's palette (a PAL_*MON constant) in d.
; Keeps e. For far calls, which cannot pass a.
	push de
	ld a, d
	call DeterminePaletteID
	pop de
	ld d, a
	ret


SECTION "Icon Palettes", ROMX, BANK[$2C]

LoadSpritePaletteAndUpdate::
; d = palette (PAL_* constant), e = sprite palette number. Loads it and has it shown.
	call LoadSGBPalette_Sprite
	; fallthrough
ForceSpritePaletteUpdate:
	ldh a, [rWBK]
	ld b, a
	ld a, 2
	ldh [rWBK], a
	ld a, 1
	ld [W2_ForceOBPUpdate], a
	ld a, b
	ldh [rWBK], a
	ret

PartyMenuIconPalettes:
; Called by SetPal_PartyMenu where it used to call ClearSpritePaletteMap, with WRAM
; bank 2 loaded. The icons carry their palette number in OAM (slot n uses sprite
; palette n) and the sprite palette map says "leave it"; what is left to do is to load
; each party member's palette.
	call ClearSpritePaletteMap
	xor a
	ldh [rWBK], a ; the party is in WRAM bank 1
	ld hl, wPartySpecies
	ld e, 0
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	ld d, a
	push hl
	push de
	farcall GetMonPaletteID_d
	call LoadSGBPalette_Sprite
	pop de
	pop hl
	inc e
	ld a, e
	cp PARTY_LENGTH
	jr c, .loop
.done
	ld a, 2
	ldh [rWBK], a
; On the map, sprite palettes 4-7 follow OBP1, which is not set up for the icons of
; party slots 5 and 6. The palette command that runs when the menu closes sets this
; again.
	xor a
	ld [W2_UseOBP1], a
	inc a
	ld [W2_ForceOBPUpdate], a
	ret


BoxGrid_WaitForPalettes::
; Wait until the colours BoxGrid_ApplyPalettes set are the LCD's: for the VBlank, and
; for the next one if they were set too late in the frame for this one (they are worked
; out at scanline 110 and written in the VBlank after it).
.frame
	call DelayFrame
	ldh a, [rWBK]
	ld b, a
	ld a, 2
	ldh [rWBK], a
	ld a, [W2_ForceBGPUpdate]
	ld hl, W2_ForceOBPUpdate
	or [hl]
	ld hl, W2_BgPaletteDataModified
	or [hl]
	ld hl, W2_SprPaletteDataModified
	or [hl]
	ld c, a
	ld a, b
	ldh [rWBK], a
	ld a, c
	and a
	jr nz, .frame
	ret

BoxGrid_ApplyPalettes::
; The colours of the box grid, from what engine/pokemon/box_grid.asm worked out (all of
; it in WRAM0, so it can be read with WRAM bank 2 loaded):
;   wBoxGridBoxPalettes     the background palette of each of the twenty places
;   wBoxGridClassSlots      which background palette each colour class has
;   wBoxGridSpritePalettes  the palette of each sprite icon set
; and the cursor's colour from wBoxGridQuick.
; (wBoxGridQuick is not in WRAM0 and has to be read before the bank changes)
	ld a, [wBoxGridQuick]
	ld [wBoxGridMenuPlaces], a ; scratch, in WRAM0
	ldh a, [rWBK]
	ld b, a
	ld a, 2
	ldh [rWBK], a
	push bc

; the palette of every tile on the screen: the text's, except under the icons
	ld hl, W2_TilesetPaletteMap
	ld bc, SCREEN_AREA
	ld a, BOXGRID_TEXT_PALETTE
	call FillMemory
	ld de, wBoxGridBoxPalettes
	ld hl, W2_TilesetPaletteMap + BOXGRID_BOX_Y * SCREEN_WIDTH + 1
	ld b, 4 ; rows
.row
	ld c, 5 ; columns
.cell
	ld a, [de]
	inc de
	push hl
	ld [hli], a
	ld [hl], a
	push bc
	ld bc, SCREEN_WIDTH - 1
	add hl, bc
	pop bc
	ld [hli], a
	ld [hl], a
	pop hl
	inc hl
	inc hl
	inc hl
	dec c
	jr nz, .cell
	push bc
	ld bc, 3 * SCREEN_WIDTH - 3 * 5
	add hl, bc
	pop bc
	dec b
	jr nz, .row

; the background palettes that belong to a colour class. Gray's is number 7, the text's.
	ld hl, wBoxGridClassSlots
	ld d, PAL_MEWMON
.class
	ld a, [hli]
	cp 8 ; $ff: none. Bit 7: it borrows the palette of another class
	jr nc, .nextClass
	ld e, a
	push hl
	push de
	call LoadSGBPalette
	pop de
	pop hl
.nextClass
	inc d
	ld a, d
	cp PAL_MEWMON + NUM_ICON_COLOR_CLASSES
	jr c, .class

; the sprite palettes: set n of sprite tiles uses sprite palette n
	ld hl, wBoxGridSpritePalettes
	ld e, 0
.sprite
	ld a, [hli]
	ld d, a
	push hl
	push de
	call LoadSGBPalette_Sprite
	pop de
	pop hl
	inc e
	ld a, e
	cp PARTY_LENGTH + 1
	jr c, .sprite
	ASSERT PARTY_LENGTH + 1 == BOXGRID_CURSOR_PALETTE
; the cursor: red, or blue while A picks up at once
	ld hl, .CursorPalette
	ld a, [wBoxGridMenuPlaces]
	and a
	jr z, .gotCursorPalette
	ld hl, .QuickCursorPalette
.gotCursorPalette
	ld de, W2_SprPaletteData + BOXGRID_CURSOR_PALETTE * 8
	ld bc, 8
	call CopyData

; the sprites keep the palette that is in their OAM entry
	call ClearSpritePaletteMap
	xor a
	ld [W2_TileBasedPalettes], a
	ld [W2_UseOBP1], a
	ld a, 3
	ld [W2_StaticPaletteMapChanged], a
	ld a, 1
	ld [W2_ForceBGPUpdate], a
	ld [W2_ForceOBPUpdate], a

	pop af
	ldh [rWBK], a
	ret

.CursorPalette
	RGB 31, 31, 31
	RGB 31, 12, 12
	RGB 31, 12, 12
	RGB 26, 3, 3
.QuickCursorPalette
	RGB 31, 31, 31
	RGB 10, 16, 31
	RGB 10, 16, 31
	RGB 3, 7, 26
