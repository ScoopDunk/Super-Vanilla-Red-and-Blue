; MOVE <PKMN> in Bill's PC: the open box as a grid of icons with the party beside it,
; in the manner of the storage system of the third generation.
;
;   +>-BOX 1---18/20-++--+     the box: 5 x 4 icons, background tiles, with a free
;   | o  o* o  o  o  ||o |     row above them for the cursor's arrow and the mark of
;   | o  o  o  o  o  ||o |     a shiny Pokémon (*); the party: 6 icons, sprites
;   | o  o  o  o  o  ||o |     below: the Pokémon under the cursor
;   | o  o  o        ||o |     A        on a Pokémon: MOVE (pick up), STATS, RELEASE
;   +----------------++--+              with one picked up: put it down
;   |NAME      F  :L24  *|              on the title: the list of boxes, SORT
;   |/SPECIES    No.025  |     B        put it back / leave
;   +--------------------+     SELECT   the list of boxes
;                              START    the quick way on or off: A picks up at once
;                              left and right on the title: the box before, the next
;
; The storage format is the cartridge's and is not changed: a box is a count and a
; packed list, so there are no gaps and "moving" a Pokémon means changing the order.
; Putting a Pokémon on another one exchanges the two; putting it on a free place moves
; it to the end of that list. Deposits and withdrawals go through the game's own
; MoveMon and RemovePokemon; an exchange between box and party is done in place and
; then gets what MoveMon does for the two directions (ExchangeBoxAndPartyMon).
;
; While a Pokémon is picked up, nothing has happened to the data yet. It is only drawn
; at the cursor instead of at its place, so there is no state in which a Pokémon is in
; neither list. That is also what lets it be carried to another box: the box changes
; under it are the game's own, each with its save, and the Pokémon is still in its
; own box until it is put down ("other boxes" below).
;
; Why the box is drawn with background tiles: twenty icons as sprites would be 80, and
; the hardware shows 40, ten on a line. The party column, the Pokémon that is carried
; and the cursor are sprites.
;
; The icon tiles in VRAM are tied to the Pokémon, not to the place: wBoxGridBoxIcons and
; wBoxGridPartyIcons say which set of tiles a place shows, and reordering only changes
; those tables and the tile map. One set of each kind is always off screen, and a
; Pokémon that changes sides is loaded there before the tables are changed.

DEF BOXGRID_COLUMNS      EQU 5
DEF BOXGRID_ROWS         EQU 4
	ASSERT BOXGRID_COLUMNS * BOXGRID_ROWS == MONS_PER_BOX

; where the cursor is (wBoxGridCursorSide), and where a Pokémon was picked up
DEF BOXGRID_BOX          EQU 0
DEF BOXGRID_PARTY        EQU 1
DEF BOXGRID_TITLE        EQU 2 ; the cursor only: on the box's title, where left and right change the box

DEF BOXGRID_SPARE_BOX_ICON    EQU MONS_PER_BOX ; index in wBoxGridBoxIcons
DEF BOXGRID_SPARE_PARTY_ICON  EQU PARTY_LENGTH ; index in wBoxGridPartyIcons

; where the party column is, in pixels
DEF BOXGRID_PARTY_X      EQU 17 * 8
DEF BOXGRID_PARTY_Y      EQU 1 * 8
; with the cursor on the title: where the carried Pokémon's place is taken to be (it is
; drawn 4 pixels left of that and 6 above), and where the cursor's arrow is
DEF BOXGRID_TITLE_CARRY_X  EQU 14 * 8 + 4
DEF BOXGRID_TITLE_CARRY_Y  EQU 6
DEF BOXGRID_TITLE_ARROW_X  EQU 1 * 8

DEF BOXGRID_ANIM_FRAMES  EQU 10 ; frames between the two pictures of an icon, as in the party menu

; A menu in the box at the bottom has four places: 0 and 1 in the upper row, 2 and 3 in
; the lower one. The last is always CANCEL.
; the menu that A opens on a Pokémon
	const_def
	const BOXGRID_MOVE    ; 0
	const BOXGRID_STATS   ; 1
	const BOXGRID_RELEASE ; 2
	const BOXGRID_CANCEL  ; 3
; the menu that A opens on the box's title
	const_def
	const BOXGRID_LIST    ; 0
	const BOXGRID_SORT    ; 1
; the orders SORT offers
	const_def
	const BOXGRID_SORT_NUMBER ; 0
	const BOXGRID_SORT_LEVEL  ; 1
	const BOXGRID_SORT_NAME   ; 2

BoxGrid::
	ldh a, [hTileAnimations]
	push af
	ldh a, [hJoy7]
	push af
	ldh a, [hJoy6]
	push af
	xor a
	ldh [hTileAnimations], a ; the water and flower animations write to tiles that hold icons here
	ldh [hJoy6], a
	inc a
	ldh [hJoy7], a ; a held direction repeats
	ld hl, wBoxGridCursorSide
	ld bc, wBoxGridSaveAsked + 1 - wBoxGridCursorSide
	xor a
	call FillMemory ; the cursor at the first place, nothing picked up, the menu way, not asked yet
.enter
	call BoxGrid_LoadScreen
.loop
	call BoxGrid_Frame
	call JoypadLowSensitivity
	ldh a, [hJoyPressed]
	ld b, a
	ldh a, [hJoy5]
	or b
	call nz, BoxGrid_ShowFirstPicture ; before anything is done about a button
	ldh a, [hJoyPressed]
	bit B_PAD_A, a
	jr nz, .pressedA
	bit B_PAD_B, a
	jr nz, .pressedB
	bit B_PAD_SELECT, a
	jr nz, .pressedSelect
	bit B_PAD_START, a
	jr nz, .pressedStart
	ldh a, [hJoy5]
	and PAD_CTRL_PAD
	call nz, BoxGrid_MoveCursor
	jr .loop

.pressedA
	call BoxGrid_PressSound
	ld a, [wBoxGridCarrying]
	and a
	jr nz, .putDown
	ld a, [wBoxGridCursorSide]
	cp BOXGRID_TITLE
	jr z, .titleMenu
	call BoxGrid_GetHovered
	jr nc, .loop ; nothing there
	ld a, [wBoxGridQuick]
	and a
	jr nz, .pickUp ; the quick way: no menu
	call BoxGrid_ActionMenu
	cp BOXGRID_MOVE
	jr z, .pickUp
	cp BOXGRID_STATS
	jr z, .stats
	cp BOXGRID_RELEASE
	jr z, .release
	call BoxGrid_DrawInfo
	jr .loop
.pickUp
	call BoxGrid_PickUp
	jr .loop
.putDown
	call BoxGrid_PutDown
	jr .loop
.titleMenu
	call BoxGrid_TitleMenu
	jr .loop
.stats
	call ClearSprites
	call BoxGrid_GetHovered
	predef StatusScreen
	predef StatusScreen2
	jr .enter
.release
	call BoxGrid_Release
	jr .loop

.pressedB
	call BoxGrid_PressSound
	ld a, [wBoxGridCarrying]
	and a
	jr z, .leave
; put it back: nothing has happened to it, wherever it was carried
	xor a
	ld [wBoxGridCarrying], a
	call BoxGrid_HoverChanged
	call BoxGrid_ShowBoxNow ; its place shows it again at once
	jp .loop

.pressedSelect
; the list of boxes, also with a Pokémon picked up
	call BoxGrid_PressSound
	call BoxGrid_ChooseBox
	jp .loop

.pressedStart
; the quick way on and off: A picks up at once, without the menu
	call BoxGrid_PressSound
	ld hl, wBoxGridQuick
	ld a, [hl]
	xor 1
	ld [hl], a
	farcall BoxGrid_ApplyPalettes ; the cursor's colour says which way is on
	call BoxGrid_DrawInfo
	jp .loop

.leave
	call BoxGrid_LeaveScreen
	pop af
	ldh [hJoy6], a
	pop af
	ldh [hJoy7], a
	pop af
	ldh [hTileAnimations], a
	ret

BoxGrid_PressSound:
	ld a, SFX_PRESS_AB
	jp PlaySound

BoxGrid_Frame:
; One frame: the icon under the cursor changes between its two pictures, the sprites
; are written, and the frame ends.
	ld hl, wBoxGridAnimTimer
	inc [hl]
	ld a, [hl]
	cp BOXGRID_ANIM_FRAMES
	jr c, .sameFrame
	ld [hl], 0
	ld hl, wBoxGridAnimFrame
	ld a, [hl]
	xor 1
	ld [hl], a
	call BoxGrid_DrawHoveredCell
	call BoxGrid_ShowHoveredCellNow
.sameFrame
	call BoxGrid_UpdateOAM
	jp DelayFrame

BoxGrid_ShowFirstPicture:
; The icon under the cursor goes back to its first picture, on the screen at once.
; Its second picture is in four tiles of its own, and whatever happens next may load
; them with another icon's while the screen still shows them here (the screen is brought
; up to date a third per frame).
	ld a, [wBoxGridAnimFrame]
	and a
	ret z
	xor a
	ld [wBoxGridAnimFrame], a
	ld [wBoxGridAnimTimer], a
	call BoxGrid_DrawHoveredCell
	; fallthrough
BoxGrid_ShowHoveredCellNow:
; the box place under the cursor, as BoxGrid_ShowCellNow, when the picture is not at it
	ld a, [wBoxGridCursorSide]
	and a
	ret nz
	ld a, [wBoxGridCursorY]
	ld b, a
	ld c, 4
	call BoxGrid_WaitForRow
	call BoxGrid_BoxCursorPosition
	; fallthrough
BoxGrid_ShowCellNow:
; Box position a as the tile map has it (its four tiles and the mark above them) and in
; its palette, written to video memory between two scanlines: the whole place changes
; from one line of the picture to the next.
; The game's own way, which everything else on this screen uses, brings a third of the
; screen up to date per frame. The second and the fourth row of the box lie across two
; thirds, so an icon there would be the upper half of one picture and the lower half of
; another for a frame or two whenever it changes, and that is every ten frames for the
; icon under the cursor.
	ld e, a
	push de
	call BoxGrid_CellCoord ; (keeps de)
	ld d, 0
	push hl
	ld hl, wBoxGridBoxPalettes
	add hl, de
	ld b, [hl] ; its palette
	pop hl
	ld c, [hl] ; its first tile
	inc hl
	ld a, [hl]
	sub c
	ld d, a ; 1 from one tile of an icon to the next, 0 on a place that shows nothing
	push bc
	ld bc, -SCREEN_WIDTH
	add hl, bc
	pop bc
	ld e, [hl] ; the mark
	pop hl ; l = the position
	ld a, l
	push bc
	push de
	call BoxGrid_MarkAddress
	pop de
	pop bc
	call WaitForVRAMAccess ; interrupts off, and time for some fifty cycles (home/fast_video_copy.asm)
	ld a, e
	ld [hl], a
	ld a, l
	add TILEMAP_WIDTH - 1
	ld l, a
	adc h
	sub l
	ld h, a ; the upper two tiles
	ld a, c
	ld [hli], a
	add d
	ld [hld], a
	ld a, 1
	ldh [rVBK], a ; their palette (with interrupts off: the handlers expect the tiles' half of video memory)
	ld a, b
	ld [hli], a
	ld [hld], a
	ld a, l
	add TILEMAP_WIDTH
	ld l, a
	adc h
	sub l
	ld h, a ; the lower two
	ld a, b
	ld [hli], a
	ld [hld], a
	xor a
	ldh [rVBK], a
	ld a, c
	add d
	add d
	ld [hli], a
	add d
	ld [hl], a
	ei
	ret

BoxGrid_ShowBoxNow:
; Every place of the box, as BoxGrid_ShowCellNow, a row at a time and no row while the
; picture is at it or about to be: a row that is waited for shows in the next frame, and
; so do the ones below it, so the whole box changes in one frame, this one or the next.
	ld b, 0
.row
	ld c, 12 ; a place takes a scanline or two
	call BoxGrid_WaitForRow
	push bc
	ld a, b
	add a
	add a
	add b ; the first place of the row
	ld c, BOXGRID_COLUMNS
.place
	push af
	push bc
	call BoxGrid_ShowCellNow
	pop bc
	pop af
	inc a
	dec c
	jr nz, .place
	pop bc
	inc b
	ld a, b
	cp BOXGRID_ROWS
	jr c, .row
	ret

BoxGrid_WaitForRow:
; b = a row of the box, c = a number of scanlines. Returns when the picture is neither
; in that row nor within c lines before it. Keeps bc.
	ld a, b
	add a
	add b
	add a
	add a
	add a
	add BOXGRID_BOX_Y * 8
	ld d, a ; the row's first line
	add 2 * 8
	ld e, a ; the first line below it
.wait
	ldh a, [rLY]
	cp e
	ret nc ; past it (or in VBlank)
	add c
	cp d
	ret c ; not near it yet
	jr .wait

BoxGrid_MarkAddress:
; a = box position. Returns in hl where its mark is (above its second tile) in the tile
; map of video memory that the screen is copied to.
	ld hl, (BOXGRID_BOX_Y - 1) * TILEMAP_WIDTH + 2
	ld bc, 3 * TILEMAP_WIDTH
.row
	cp BOXGRID_COLUMNS
	jr c, .gotRow
	sub BOXGRID_COLUMNS
	add hl, bc
	jr .row
.gotRow
	ld c, a
	add a
	add c
	ld c, a
	ld b, 0
	add hl, bc
	ldh a, [hAutoBGTransferDest]
	ld c, a
	ldh a, [hAutoBGTransferDest + 1]
	ld b, a
	add hl, bc
	ret


; ---- entering and leaving ---------------------------------------------------------

BoxGrid_LoadScreen:
; Everything from nothing: the icons, the frame, the colours. Also the way back from
; the status screen and from CHANGE BOX. The cursor is left where it is.
	xor a
	ld [wUpdateSpritesEnabled], a ; the map's sprites are hidden at the next frame and then left alone
	call GBPalWhiteOutWithDelay3
	xor a
	ldh [hAutoBGTransferEnabled], a
	ld [wBoxGridAnimTimer], a
	ld [wBoxGridAnimFrame], a
	call ClearSprites
	call BoxGrid_InitTables
	call DisableLCD
	call BoxGrid_LoadAllIcons
	call BoxGrid_LoadCarriedIcon
	call EnableLCD
	call LoadHpBarAndStatusTilePatterns ; the level sign, also after the status screen
	hlcoord 0, 0
	ld bc, SCREEN_AREA
	ld a, ' '
	call FillMemory
	call BoxGrid_DrawFrame
	call BoxGrid_AssignPalettes
	call BoxGrid_DrawBoxCells
	call BoxGrid_DrawHeaderNumbers
	farcall BoxGrid_ApplyPalettes
	call BoxGrid_HoverChanged
	call BoxGrid_UpdateOAM
	ld a, 1
	ldh [hAutoBGTransferEnabled], a
	call Delay3
	jp GBPalNormal

BoxGrid_LeaveScreen:
; Back to what the PC's menu expects: the map's tiles and sprites, its colours, and
; the status tiles BillsPC_ loaded.
	call GBPalWhiteOutWithDelay3
	call ReloadTilesetTilePatterns
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadHpBarAndStatusTilePatterns
	jp LoadGBPal

BoxGrid_InitTables:
	call BoxGrid_InitBoxTables
	ld hl, wBoxGridPartyIcons
	xor a
.partyIcons
	ld [hli], a
	inc a
	cp PARTY_LENGTH + 1
	jr c, .partyIcons
	ld hl, wBoxGridSpritePalettes
	ld bc, PARTY_LENGTH + 1
	ld a, PAL_MEWMON
	call FillMemory
; the palette of each party member
	ld c, 0
.partyPalettes
	ld a, [wPartyCount]
	cp c
	ret z
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld d, [hl]
	push bc
	farcall GetMonPaletteID_d
	pop bc
	ld hl, wBoxGridSpritePalettes
	add hl, bc
	ld [hl], d
	inc c
	jr .partyPalettes

BoxGrid_InitBoxTables:
; The tables of the box's side, for a box whose icons are about to be loaded: position n
; shows icon set n, no icon has its second picture loaded, no colour class has a palette.
	ld hl, wBoxGridBoxIcons
	xor a
.boxIcons
	ld [hli], a
	inc a
	cp MONS_PER_BOX + 1
	jr c, .boxIcons
	ld a, $ff
	ld [wBoxGridHoverIcon], a
	ld hl, wBoxGridClassSlots
	ld bc, NUM_ICON_COLOR_CLASSES - 1
	call FillMemory
	ld [hl], BOXGRID_TEXT_PALETTE ; gray shares the palette of the text
	ret

BoxGrid_LoadCarriedIcon:
; With the LCD off, after the tables were set up: a Pokémon that was picked up in a box
; is drawn from the spare set of sprite tiles, which has to be loaded again.
	ld a, [wBoxGridCarrying]
	and a
	ret z
	ld a, [wBoxGridCarrySide]
	and a ; BOXGRID_BOX
	ret nz
	ld a, [wBoxGridCarrySpecies]
	ld d, a
	ld e, BOXGRID_SPARE_PARTY_ICON
	push de
	farcall LoadSpriteIconNow
	pop de
	farcall GetMonPaletteID_d
	ld a, d
	ld [wBoxGridSpritePalettes + BOXGRID_SPARE_PARTY_ICON], a
	ret

BoxGrid_LoadAllIcons:
; With the LCD off: box position n into box icon set n, party slot n into sprite set n.
	ld c, 0
.box
	ld a, [wBoxCount]
	cp c
	jr z, .boxDone
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld d, [hl]
	ld e, c
	push bc
	farcall LoadBoxIconNow
	pop bc
	inc c
	jr .box
.boxDone
	ld c, 0
.party
	ld a, [wPartyCount]
	cp c
	ret z
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld d, [hl]
	ld e, c
	push bc
	farcall LoadSpriteIconNow
	pop bc
	inc c
	jr .party


; ---- drawing ------------------------------------------------------------------------

BoxGrid_DrawFrame:
	hlcoord 0, 0
	lb bc, 12, 14
	call TextBoxBorder
	hlcoord 16, 0
	lb bc, 12, 2
	call TextBoxBorder
	hlcoord 0, 14
	lb bc, 2, 18
	call TextBoxBorder
	hlcoord 1, 0
	ld de, .BoxTitle
	call PlaceString
	hlcoord 17, 0
	ld de, .PartyTitle
	jp PlaceString

.BoxTitle
	db " BOX      /{d:MONS_PER_BOX} @"
.PartyTitle
	db "<PK><MN>@"

BoxGrid_DrawHeaderNumbers:
; the number of the box and how many Pokémon are in it
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	inc a
	ld [wBoxGridNumber], a
	hlcoord 6, 0
	ld a, ' '
	ld [hli], a
	ld [hld], a
	ld de, wBoxGridNumber
	lb bc, LEFT_ALIGN | 1, 2
	call PrintNumber
	hlcoord 9, 0
	ld a, ' ' ; PrintNumber does not write in front of a short number
	ld [hli], a
	ld [hld], a
	ld de, wBoxCount
	lb bc, 1, 2
	jp PrintNumber

BoxGrid_DrawBoxCells:
	xor a
.loop
	push af
	call BoxGrid_DrawBoxCell
	pop af
	inc a
	cp MONS_PER_BOX
	jr c, .loop
	ret

BoxGrid_DrawHoveredCell:
; the cell under the cursor, if the cursor is in the box
	ld a, [wBoxGridCursorSide]
	and a
	ret nz
	call BoxGrid_BoxCursorPosition
	; fallthrough
BoxGrid_DrawBoxCell:
; Draw box position a: its four icon tiles, or nothing if the place is free or its
; Pokémon is picked up, and above its right half the mark of a shiny Pokémon.
	ld e, a
	call BoxGrid_CellCoord
	ld a, [wBoxCount]
	ld d, a
	ld a, e
	cp d
	jr nc, .blank
	call BoxGrid_CarriedFromOpenBox
	jr nz, .notCarried
	ld a, [wBoxGridCarryIndex]
	cp e
	jr z, .blank
.notCarried
	push hl
	ld hl, wBoxGridBoxIcons
	ld d, 0
	add hl, de
	ld d, [hl] ; its icon set
	pop hl
	ld a, d
	add a
	add a
	ld c, a ; first tile of the set
	ld a, [wBoxGridAnimFrame]
	and a
	jr z, .gotTile
	ld a, [wBoxGridHoverIcon]
	cp d
	jr nz, .gotTile
	ld c, BOXGRID_HOVER_TILE ; the second picture of the icon under the cursor
.gotTile
	ld a, c
	ld [hli], a
	inc a
	ld [hl], a
	ld bc, SCREEN_WIDTH - 1
	add hl, bc
	inc a
	ld [hli], a
	inc a
	ld [hl], a
; the mark: one row above the icon, over its right half
	ld bc, -2 * SCREEN_WIDTH
	add hl, bc
	push hl
	ld hl, wBoxMons + MON_DVS
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, e
	call AddNTimes
	call BoxGrid_IsShiny
	pop hl
	ld a, ' '
	jr z, .mark
	ld a, '<SHINY>'
.mark
	ld [hl], a
	ret
.blank
	ld a, ' '
	ld [hli], a
	ld [hl], a
	ld bc, SCREEN_WIDTH - 1
	add hl, bc
	ld [hli], a
	ld [hl], a
	ld bc, -2 * SCREEN_WIDTH
	add hl, bc
	ld [hl], a
	ret

BoxGrid_IsShiny:
; hl = a Pokémon's DVs. nz if it is shiny in the second generation: Atk DV 2, 3, 6, 7,
; 10, 11, 14 or 15 and the other three 10. The rule of IsShinyDVs
; (engine/pokemon/shiny_gender.asm), which is in another bank.
	ld a, [hli]
	and %00101111 ; bit 1 of the Atk DV, and the Def DV
	cp %00101010
	jr nz, .no
	ld a, [hl] ; Spd and Spc DVs
	cp (10 << 4) | 10
	jr nz, .no
	or 1
	ret
.no
	xor a
	ret

BoxGrid_CarriedFromOpenBox:
; z if a Pokémon is picked up and it is in the box that is open: then it is at
; [wBoxGridCarryIndex] there. nz if nothing is picked up, or one from the party, or one
; from a box that was open earlier. Keeps c, de and hl.
	ld a, [wBoxGridCarrying]
	and a
	jr z, .no
	ld a, [wBoxGridCarrySide]
	and a ; BOXGRID_BOX
	ret nz
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	ld b, a
	ld a, [wBoxGridCarryBox]
	cp b
	ret
.no
	inc a
	ret

BoxGrid_CellCoord:
; a = box position. Returns in hl where its top left tile is in the tile map.
; Keeps de.
	hlcoord 1, BOXGRID_BOX_Y
	ld bc, 3 * SCREEN_WIDTH
.row
	cp BOXGRID_COLUMNS
	jr c, .gotRow
	sub BOXGRID_COLUMNS
	add hl, bc
	jr .row
.gotRow
	ld c, a
	add a
	add c
	ld c, a
	ld b, 0
	add hl, bc
	ret

BoxGrid_BoxCursorPosition:
; the box position under the cursor (the cursor has to be in the box)
	ld a, [wBoxGridCursorY]
	ld b, a
	add a
	add a
	add b
	ld b, a
	ld a, [wBoxGridCursorX]
	add b
	ret

BoxGrid_GetHovered:
; The list position under the cursor in a, and carry if there is a Pokémon. Sets
; wWhichPokemon and wMonDataLocation for it.
	ld a, [wBoxGridCursorSide]
	and a
	jr z, .box
	dec a
	jr z, .party
	xor a ; on the title: nothing
	ret
.box
	call BoxGrid_BoxCursorPosition
	ld b, a
	ld a, BOX_DATA
	ld [wMonDataLocation], a
	ld a, [wBoxCount]
	jr .compare
.party
	ld a, [wBoxGridCursorY]
	ld b, a
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	ld a, [wPartyCount]
.compare
	ld c, a
	ld a, b
	ld [wWhichPokemon], a
	cp c
	ret

BoxGrid_CursorPixel:
; d = x and e = y of the top left pixel of the place under the cursor
	ld a, [wBoxGridCursorSide]
	and a
	jr z, .box
	dec a
	jr z, .party
; on the title: the place a Pokémon that is carried is drawn at, on the corner of the
; box's frame
	lb de, BOXGRID_TITLE_CARRY_X, BOXGRID_TITLE_CARRY_Y
	ret
.box
	ld a, [wBoxGridCursorX]
	call .timesThreePlusOneTimesEight
	ld d, a
	ld a, [wBoxGridCursorY]
	call .timesThreePlusOneTimesEight
	add (BOXGRID_BOX_Y - 1) * 8
	ld e, a
	ret
.party
	ld d, BOXGRID_PARTY_X
	ld a, [wBoxGridCursorY]
	swap a ; * 16
	add BOXGRID_PARTY_Y
	ld e, a
	ret
.timesThreePlusOneTimesEight
	ld b, a
	add a
	add b
	inc a
	add a
	add a
	add a
	ret

BoxGrid_UpdateOAM:
; Write every sprite of the screen: the marks of shiny party members (first, so that
; they are in front of the icons), the party, the Pokémon that is carried, the cursor.
	ld hl, wShadowOAM
	ld c, 0
.mark
	push hl
	call .partyMemberShown
	jr nc, .noMark
	ld hl, wPartyMon1DVs
	push bc
	ld a, c
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	pop bc
	call BoxGrid_IsShiny
	jr z, .noMark
	ld hl, wBoxGridPartyIcons
	ld b, 0
	add hl, bc
	ld b, [hl] ; its icon set, which is also its palette
	pop hl
	ld a, c
	swap a
	add BOXGRID_PARTY_Y + 16 - 2
	ld [hli], a
	ld a, BOXGRID_PARTY_X + 8 + 11
	ld [hli], a
	ld a, '<SHINY>'
	ld [hli], a
	ld a, b
	ld [hli], a
	jr .nextMark
.noMark
	pop hl
	xor a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
.nextMark
	inc c
	ld a, c
	cp PARTY_LENGTH
	jr c, .mark

	ld c, 0
.party
	call .partyMemberShown
	jr nc, .noIcon
	ld d, BOXGRID_PARTY_X
	ld a, c
	swap a
	add BOXGRID_PARTY_Y
	ld e, a
	push hl
	ld hl, wBoxGridPartyIcons
	ld b, 0
	add hl, bc
	ld b, [hl]
	pop hl
; the second picture, if the cursor is on it
	ld a, [wBoxGridCursorSide]
	cp BOXGRID_PARTY
	jr nz, .firstPicture
	ld a, [wBoxGridCursorY]
	cp c
	jr nz, .firstPicture
	ld a, [wBoxGridAnimFrame]
	and a
	jr z, .firstPicture
	ld a, PARTY_MON_ICON_FRAME
	jr .write
.firstPicture
	xor a
.write
	call BoxGrid_WriteIconOAM
	jr .nextParty
.noIcon
	call BoxGrid_HideIconOAM
.nextParty
	inc c
	ld a, c
	cp PARTY_LENGTH
	jr c, .party
; the Pokémon that is carried, a little up and to the left of the place under the cursor
	ld a, [wBoxGridCarrying]
	and a
	jr z, .notCarrying
	push hl
	call BoxGrid_CursorPixel
	ld a, d
	sub 4
	ld d, a
	ld a, e
	sub 6
	ld e, a
	ld a, [wBoxGridCarrySide]
	and a
	ld a, BOXGRID_SPARE_PARTY_ICON ; from a box: it was loaded into the spare set
	jr z, .gotCarriedIcon
	ld a, [wBoxGridCarryIndex]
.gotCarriedIcon
	ld c, a
	ld b, 0
	ld hl, wBoxGridPartyIcons
	add hl, bc
	ld b, [hl]
	pop hl
	ld a, [wBoxGridAnimFrame]
	add a
	add a
	ASSERT PARTY_MON_ICON_FRAME == 4
	call BoxGrid_WriteIconOAM
; no cursor while carrying
	xor a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ret
.notCarrying
	call BoxGrid_HideIconOAM
	ld a, [wBoxGridAnimFrame]
	ld b, a
	ld a, [wBoxGridCursorSide]
	cp BOXGRID_TITLE
	jr nz, .notOnTitle
; on the title: an arrow in front of it, pointing right
	ld a, 16
	ld [hli], a
	ld a, BOXGRID_TITLE_ARROW_X + 8
	add b
	ld [hli], a
	ld a, '▶'
	jr .cursorTile
.notOnTitle
	push hl
	push bc
	call BoxGrid_CursorPixel
	pop bc
	pop hl
	ld a, [wBoxGridCursorSide]
	and a
	jr nz, .partyCursor
; in the box: an arrow above the icon, pointing down
	ld a, e
	add 16 - 8
	add b
	ld [hli], a
	ld a, d
	add 8 + 4
	ld [hli], a
	ld a, '▼'
	jr .cursorTile
.partyCursor
; in the party: an arrow at its left, pointing right
	ld a, e
	add 16 + 4
	ld [hli], a
	ld a, d
	add b
	ld [hli], a
	ld a, '▶'
.cursorTile
	ld [hli], a
	ld [hl], BOXGRID_CURSOR_PALETTE
	ret

.partyMemberShown
; carry if party slot c holds a Pokémon that is drawn in the column (one that is picked
; up is drawn at the cursor instead). Keeps c and hl.
	ld a, [wPartyCount]
	ld b, a
	ld a, c
	cp b
	ret nc
	ld a, [wBoxGridCarrying]
	and a
	jr z, .shown
	ld a, [wBoxGridCarrySide]
	and a
	jr z, .shown
	ld a, [wBoxGridCarryIndex]
	cp c
	jr nz, .shown
	and a
	ret
.shown
	scf
	ret

BoxGrid_WriteIconOAM:
; hl = where in wShadowOAM, d = x and e = y on the screen, b = sprite icon set,
; a = 0 or PARTY_MON_ICON_FRAME. Writes the four sprites; hl ends behind them.
; Keeps c.
	push bc
	ld c, a
	ld a, b
	add a
	add a
	add a
	ASSERT PARTY_MON_ICON_TILES == 8
	add c
	ld c, a ; first tile
	ld a, e
	add 16
	ld [hli], a
	ld a, d
	add 8
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, b
	ld [hli], a

	ld a, e
	add 16
	ld [hli], a
	ld a, d
	add 16
	ld [hli], a
	ld a, c
	inc a
	ld [hli], a
	ld a, b
	ld [hli], a

	ld a, e
	add 24
	ld [hli], a
	ld a, d
	add 8
	ld [hli], a
	ld a, c
	add 2
	ld [hli], a
	ld a, b
	ld [hli], a

	ld a, e
	add 24
	ld [hli], a
	ld a, d
	add 16
	ld [hli], a
	ld a, c
	add 3
	ld [hli], a
	ld a, b
	ld [hli], a
	pop bc
	ret

BoxGrid_HideIconOAM:
; four sprites that are not shown. Keeps c and de.
	xor a
	ld b, OBJ_SIZE * 4
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret


; ---- the box at the bottom ------------------------------------------------------------

BoxGrid_ClearInfo:
	hlcoord 1, 15
	call .line
	hlcoord 1, 16
.line
	ld a, ' '
	ld b, SCREEN_WIDTH - 2
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret

BoxGrid_HoverChanged:
; The cursor is somewhere else, or what is under it changed: start the icon's animation
; over, load the second picture of the box icon under it, and describe the Pokémon.
	call BoxGrid_DrawCurrent
	call BoxGrid_UpdateOAM
	; fallthrough
BoxGrid_LoadHoverPicture:
; the second picture of the box icon under the cursor into its four tiles (a frame)
	ld a, [wBoxGridCursorSide]
	and a
	ret nz
	call BoxGrid_GetHovered
	ret nc
	ld c, a
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld d, [hl]
	push bc
	farcall LoadHoverFrame
	pop bc
	ld hl, wBoxGridBoxIcons
	add hl, bc
	ld a, [hl]
	ld [wBoxGridHoverIcon], a
	ret

BoxGrid_DrawCurrent:
; the box's places and the box at the bottom as they are now, every icon in its first
; picture (in the tile map; the sprites are BoxGrid_UpdateOAM's)
	xor a
	ld [wBoxGridAnimTimer], a
	ld [wBoxGridAnimFrame], a
	ld a, $ff
	ld [wBoxGridHoverIcon], a
	call BoxGrid_DrawBoxCells
	jp BoxGrid_DrawInfo

BoxGrid_DrawInfo:
; nickname, gender, level and the shiny mark; below that the species and its number
	call BoxGrid_ClearInfo
	call BoxGrid_GetHovered
	jp nc, .nothingThere
	call LoadMonData
	ld a, [wBoxGridCursorSide]
	and a
	ld hl, wBoxMonNicks
	jr z, .gotNicks
	ld hl, wPartyMonNicks
.gotNicks
	ld a, [wWhichPokemon]
	call GetPartyMonName
	hlcoord 1, 15
	call PlaceString
; a box holds the level in another place than the party
	ld a, [wBoxGridCursorSide]
	and a
	ld a, [wLoadedMonBoxLevel]
	jr z, .gotLevel
	ld a, [wLoadedMonLevel]
.gotLevel
	ld [wBoxGridNumber], a
	hlcoord 14, 15
	ld a, '<LV>'
	ld [hli], a
	ld de, wBoxGridNumber
	lb bc, LEFT_ALIGN | 1, 3
	call PrintNumber
	farcall GetLoadedMonShinyGender
	ld a, d
	and a
	jr z, .noGender
	ldcoord_a 12, 15
.noGender
	ld a, e
	and a
	jr z, .notShiny
	ld a, '<SHINY>'
	ldcoord_a 18, 15
.notShiny
	ld a, [wLoadedMonSpecies]
	ld [wNamedObjectIndex], a
	call GetMonName
	hlcoord 1, 16
	ld a, '/'
	ld [hli], a
	call PlaceString
	ld a, [wLoadedMonSpecies]
	ld [wPokedexNum], a
	predef IndexToPokedex
	hlcoord 13, 16
	ld a, '№'
	ld [hli], a
	ld a, '<DOT>'
	ld [hli], a
	ld de, wPokedexNum
	lb bc, LEADING_ZEROES | 1, 3
	jp PrintNumber
.nothingThere
	ld a, [wBoxGridCursorSide]
	cp BOXGRID_TITLE
	jr z, .onTitle
	ld a, [wBoxGridCarrying]
	and a
	ret nz
; a free place: what SELECT and START do
	hlcoord 1, 15
	ld de, .SelectText
	call PlaceString
	hlcoord 1, 16
	ld de, .QuickText
	call PlaceString
	ld a, [wBoxGridQuick]
	and a
	ld de, .OffText
	jr z, .gotQuick
	ld de, .OnText
.gotQuick
	hlcoord 14, 16
	jp PlaceString
.onTitle
	hlcoord 1, 15
	ld de, .LeftRightText
	call PlaceString
	ld a, [wBoxGridCarrying]
	and a
	ret nz
	hlcoord 1, 16
	ld de, .TitleMenuText
	jp PlaceString

.SelectText
	db "SELECT: BOX LIST@"
.QuickText
	db "START: QUICK@"
.OnText
	db "ON@"
.OffText
	db "OFF@"
.LeftRightText
	db "LEFT/RIGHT: BOX@"
.TitleMenuText
	db "A: LIST OR SORT@"

BoxGrid_ActionMenu:
; What to do with the Pokémon under the cursor. Returns a BOXGRID_* action.
; RELEASE is for the box only, as in the PC's menu.
	ld a, [wBoxGridCursorSide]
	and a
	ld a, %1111
	jr z, .gotPlaces
	ld a, %1011 ; no RELEASE in the party
.gotPlaces
	ld hl, .Texts
	jr BoxGrid_Menu

.Texts
	dw .MoveText, .StatsText, .ReleaseText, BoxGrid_CancelText
.MoveText
	db "MOVE@"
.StatsText
	db "STATS@"
.ReleaseText
	db "RELEASE@"

BoxGrid_CancelText:
	db "CANCEL@"

BoxGrid_Menu:
; A menu of up to four places in the box at the bottom. hl = four pointers to the texts,
; a = which of the places exist (bits 0-3; place 3 always does, it is CANCEL).
; Returns the place that was chosen in a; B gives place 3.
	ld [wBoxGridMenuPlaces], a
	push hl
	call BoxGrid_ClearInfo
	pop hl
	ld c, 0
.draw
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl
	call .placeExists
	jr z, .next
	hlcoord 2, 15
	bit 0, c
	jr z, .gotColumn
	hlcoord 11, 15
.gotColumn
	bit 1, c
	jr z, .gotRow
	push bc
	ld bc, SCREEN_WIDTH
	add hl, bc
	pop bc
.gotRow
	push bc
	call PlaceString
	pop bc
.next
	pop hl
	inc c
	ld a, c
	cp 4
	jr c, .draw
; the cursor starts on the first place there is
	ld c, -1
.first
	inc c
	call .placeExists
	jr z, .first
	ld a, c
	ld [wBoxGridMenuItem], a
.loop
	call BoxGrid_DrawTwoByTwoCursor
	call BoxGrid_Frame
	call JoypadLowSensitivity
	ldh a, [hJoyPressed]
	bit B_PAD_A, a
	jr nz, .chosen
	bit B_PAD_B, a
	jr nz, .cancelled
	ldh a, [hJoy5]
	ld b, a
	ld a, [wBoxGridMenuItem]
	ld c, a
	bit B_PAD_LEFT, b
	jr nz, .sideways
	bit B_PAD_RIGHT, b
	jr nz, .sideways
	bit B_PAD_UP, b
	jr nz, .upOrDown
	bit B_PAD_DOWN, b
	jr z, .loop
.upOrDown
	ld a, c
	xor 2
	jr .moved
.sideways
	ld a, c
	xor 1
.moved
	ld c, a
	call .placeExists
	jr z, .loop
	ld a, c
	ld [wBoxGridMenuItem], a
	jr .loop
.chosen
	call BoxGrid_PressSound
	ld a, [wBoxGridMenuItem]
	ret
.cancelled
	call BoxGrid_PressSound
	ld a, BOXGRID_CANCEL
	ret

.placeExists
; nz if the menu has place c. Keeps bc, de and hl.
	push bc
	ld a, [wBoxGridMenuPlaces]
	inc c
.shift
	rrca
	dec c
	jr nz, .shift
	pop bc
	bit 7, a
	ret

BoxGrid_TitleMenu:
; A on the box's title: the list of boxes, or SORT.
	ld hl, .Texts
	ld a, %1011
	call BoxGrid_Menu
	and a ; BOXGRID_LIST
	jp z, BoxGrid_ChooseBox
	dec a ; BOXGRID_SORT
	jp nz, BoxGrid_DrawInfo
	ld hl, .SortTexts
	ld a, %1111
	call BoxGrid_Menu
	cp BOXGRID_CANCEL
	jp z, BoxGrid_DrawInfo
	jp BoxGrid_SortBox

.Texts
	dw .ListText, .SortText, BoxGrid_CancelText, BoxGrid_CancelText
.SortTexts
	dw .NumberText, .LevelText, .NameText, BoxGrid_CancelText
.ListText
	db "LIST@"
.SortText
	db "SORT@"
.NumberText
	db "BY №<DOT>@"
.LevelText
	db "BY LEVEL@"
.NameText
	db "BY NAME@"

BoxGrid_DrawTwoByTwoCursor:
; the cursor of a menu with four places in the box at the bottom: item [wBoxGridMenuItem],
; bit 0 = right column, bit 1 = lower row
	ld a, ' '
	ldcoord_a 1, 15
	ldcoord_a 10, 15
	ldcoord_a 1, 16
	ldcoord_a 10, 16
	hlcoord 1, 15
	ld a, [wBoxGridMenuItem]
	bit 0, a
	jr z, .gotColumn
	hlcoord 10, 15
.gotColumn
	bit 1, a
	jr z, .gotRow
	ld bc, SCREEN_WIDTH
	add hl, bc
.gotRow
	ld [hl], '▶'
	ret

BoxGrid_ConfirmRelease:
; "Really release?" NO / YES. Returns carry for YES.
	call BoxGrid_ClearInfo
	hlcoord 1, 15
	ld de, .ReallyText
	call PlaceString
	hlcoord 2, 16
	ld de, .NoText
	call PlaceString
	hlcoord 11, 16
	ld de, .YesText
	call PlaceString
	ld a, 2 ; NO
	ld [wBoxGridMenuItem], a
.loop
	call BoxGrid_DrawTwoByTwoCursor
; the upper row holds the question, not choices, and the cursor routine cleared two
; tiles of it
	hlcoord 1, 15
	ld de, .ReallyText
	call PlaceString
	call BoxGrid_Frame
	call JoypadLowSensitivity
	ldh a, [hJoyPressed]
	bit B_PAD_B, a
	jr nz, .no
	bit B_PAD_A, a
	jr nz, .chosen
	ldh a, [hJoy5]
	and PAD_LEFT | PAD_RIGHT
	jr z, .loop
	ld a, [wBoxGridMenuItem]
	xor 1
	ld [wBoxGridMenuItem], a
	jr .loop
.chosen
	call BoxGrid_PressSound
	ld a, [wBoxGridMenuItem]
	cp 3
	jr nz, .no
	scf
	ret
.no
	and a
	ret

.ReallyText
	db "Really release?@"
.NoText
	db "NO@"
.YesText
	db "YES@"

BoxGrid_LastMonMessage:
; one thing that is refused: the last Pokémon of the party cannot go into the box
	ld hl, BoxGrid_LastMonText1
	ld de, BoxGrid_LastMonText2
	; fallthrough
BoxGrid_Message:
; hl and de = two lines for the box at the bottom, shown with the sound of something
; that is not possible until A or B is pressed.
	push de
	push hl
	ld a, SFX_DENIED
	call PlaySound
	call BoxGrid_ClearInfo
	pop de
	hlcoord 1, 15
	call PlaceString
	pop de
	hlcoord 1, 16
	call PlaceString
.wait
	call BoxGrid_Frame
	call JoypadLowSensitivity
	ldh a, [hJoyPressed]
	and PAD_A | PAD_B
	jr z, .wait
	jp BoxGrid_DrawInfo

BoxGrid_LastMonText1:
	db "That's your last@"
BoxGrid_LastMonText2:
	db "#MON!@"


; ---- moving around --------------------------------------------------------------------

BoxGrid_MoveCursor:
; a = the directions pressed. The six columns (five of the box, then the party) wrap
; around, and so do the party's slots. In the box's columns the title is one more row,
; between the last row and the first; on it, left and right change the box.
	ld b, a
	ld a, [wBoxGridCursorSide]
	and a
	jr z, .inBox
	dec a
	jp z, .inParty
; on the title
	bit B_PAD_LEFT, b
	ld a, -1
	jp nz, BoxGrid_FlipBox
	bit B_PAD_RIGHT, b
	ld a, 1
	jp nz, BoxGrid_FlipBox
	bit B_PAD_UP, b
	ld a, BOXGRID_ROWS - 1
	jr nz, .titleToBox
	xor a
.titleToBox
	ld [wBoxGridCursorY], a
	xor a ; BOXGRID_BOX
	ld [wBoxGridCursorSide], a
	jp .moved
.inBox
	bit B_PAD_UP, b
	jr z, .boxNotUp
	ld a, [wBoxGridCursorY]
	and a
	jr z, .toTitle
	dec a
	ld [wBoxGridCursorY], a
	jp .moved
.toTitle
	ld a, BOXGRID_TITLE
	ld [wBoxGridCursorSide], a
	jp .moved
.boxNotUp
	bit B_PAD_DOWN, b
	jr z, .boxNotDown
	ld a, [wBoxGridCursorY]
	inc a
	cp BOXGRID_ROWS
	jr z, .toTitle
	ld [wBoxGridCursorY], a
	jp .moved
.boxNotDown
	bit B_PAD_LEFT, b
	jr z, .boxRight
	ld a, [wBoxGridCursorX]
	and a
	jr z, .toParty
	dec a
	ld [wBoxGridCursorX], a
	jr .moved
.boxRight
	ld a, [wBoxGridCursorX]
	inc a
	cp BOXGRID_COLUMNS
	jr z, .toParty
	ld [wBoxGridCursorX], a
	jr .moved
.toParty
; to the party slot at about the same height
	ld a, [wBoxGridCursorY]
	ld c, a
	ld b, 0
	ld hl, .BoxRowToPartySlot
	add hl, bc
	ld a, [hl]
	ld [wBoxGridCursorY], a
	ld a, BOXGRID_PARTY
	ld [wBoxGridCursorSide], a
	jr .moved

.inParty
	bit B_PAD_UP, b
	jr z, .partyNotUp
	ld a, [wBoxGridCursorY]
	and a
	jr nz, .partyUp
	ld a, PARTY_LENGTH
.partyUp
	dec a
	ld [wBoxGridCursorY], a
	jr .moved
.partyNotUp
	bit B_PAD_DOWN, b
	jr z, .partyNotDown
	ld a, [wBoxGridCursorY]
	inc a
	cp PARTY_LENGTH
	jr c, .partyDown
	xor a
.partyDown
	ld [wBoxGridCursorY], a
	jr .moved
.partyNotDown
; left goes to the last column of the box, right to the first
	ld a, BOXGRID_COLUMNS - 1
	bit B_PAD_LEFT, b
	jr nz, .toBox
	xor a
.toBox
	ld [wBoxGridCursorX], a
	ld a, [wBoxGridCursorY]
	ld c, a
	ld b, 0
	ld hl, .PartySlotToBoxRow
	add hl, bc
	ld a, [hl]
	ld [wBoxGridCursorY], a
	xor a ; BOXGRID_BOX
	ld [wBoxGridCursorSide], a
.moved
	jp BoxGrid_HoverChanged

.BoxRowToPartySlot
	db 0, 1, 3, 4
.PartySlotToBoxRow
	db 0, 0, 1, 2, 2, 3


; ---- picking up and putting down ---------------------------------------------------------

BoxGrid_PickUp:
; The Pokémon under the cursor (BoxGrid_GetHovered said there is one) is carried from
; now on. One from the box needs sprite tiles first: into the spare set.
	call BoxGrid_GetHovered
	ld [wBoxGridCarryIndex], a
	ld a, [wBoxGridCursorSide]
	ld [wBoxGridCarrySide], a
	and a
	jr nz, .carry
; from the box: which box, and what it is, for when another box is open
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	ld [wBoxGridCarryBox], a
	ld a, [wBoxGridCarryIndex]
	ld c, a
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld d, [hl]
	ld a, d
	ld [wBoxGridCarrySpecies], a
	call BoxGrid_LoadSpareSpriteIcon
	farcall BoxGrid_ApplyPalettes
.carry
	ld a, 1
	ld [wBoxGridCarrying], a
	call BoxGrid_HoverChanged
	jp BoxGrid_ShowHoveredCellNow ; the place it left is empty at once, not half of it first

BoxGrid_LoadSpareSpriteIcon:
; d = species. Load its icon into the sprite set that is not on screen and note its
; palette.
	ld a, [wBoxGridPartyIcons + BOXGRID_SPARE_PARTY_ICON]
	ld e, a
	push de
	farcall LoadSpriteIcon
	pop de
	push de
	farcall GetMonPaletteID_d
	ld a, d
	pop de
	ld d, 0
	ld hl, wBoxGridSpritePalettes
	add hl, de
	ld [hl], a
	ret

BoxGrid_LoadSpareBoxIcon:
; d = species. Load its icon into the box set that is not on screen.
	ld a, [wBoxGridBoxIcons + BOXGRID_SPARE_BOX_ICON]
	ld e, a
	farcall LoadBoxIcon
	ret

BoxGrid_PutDown:
; A with a Pokémon picked up. From (wBoxGridCarrySide, wBoxGridCarryIndex) to the place
; under the cursor:
;   same list, on a Pokémon        the two change places
;   same list, on a free place     it goes to the end of the list
;   other list, on a Pokémon       the two are exchanged between box and party
;   other list, on a free place    it is deposited or withdrawn
	ld a, [wBoxGridCursorSide]
	cp BOXGRID_TITLE
	ret z ; not on the title
	ld a, [wBoxGridCarrySide]
	and a ; BOXGRID_BOX
	jr nz, .listsAreHere
	call BoxGrid_CarriedFromOpenBox
	jp nz, BoxGrid_PutDownFromOtherBox
.listsAreHere
	call BoxGrid_GetHovered
	ld [wBoxGridPosB], a ; where it goes
	push af ; carry: a Pokémon is there
	ld a, [wBoxGridCarryIndex]
	ld [wBoxGridPosA], a
	ld a, [wBoxGridCarrySide]
	ld b, a
	ld a, [wBoxGridCursorSide]
	cp b
	jr nz, .otherList

; within the box or within the party
	pop af
	jr nc, .toEnd
	ld a, [wBoxGridPosA]
	ld b, a
	ld a, [wBoxGridPosB]
	cp b
	jp z, .done ; put back where it was
	ld a, [wBoxGridCarrySide]
	call BoxGrid_ExchangeInList
	jp .done
.toEnd
	ld a, [wBoxGridCarrySide]
	call BoxGrid_MoveToEndOfList
	jp .landedAtEnd

.otherList
	ld a, [wBoxGridCarrySide]
	and a
	jr nz, .fromParty

; from the box to the party
	pop af
	jr nc, .withdraw
; exchange: the party member at PosB goes to box position PosA
	ld a, [wBoxGridPosB]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld d, [hl]
	call BoxGrid_LoadSpareBoxIcon ; the one that leaves the party
	ld a, [wBoxGridPosA]
	ld b, a
	ld a, [wBoxGridPosB]
	ld c, a
	call BoxGrid_ExchangeBoxAndPartyMon
; the sprite icon of the Pokémon that was carried is in the spare set already
	ld a, [wBoxGridPosB]
	call BoxGrid_TakeSparePartyIcon
	ld a, [wBoxGridPosA]
	call BoxGrid_TakeSpareBoxIcon
	jp .done
.withdraw
	ld a, [wBoxCount]
	ld [wBoxGridNumber], a
	ld a, [wPartyCount]
	push af
	ld a, [wBoxGridPosA]
	call BoxGrid_Withdraw
	pop af ; where it is in the party now
	push af
	call BoxGrid_TakeSparePartyIcon
	ld a, [wBoxGridNumber]
	ld c, a
	ld a, [wBoxGridPosA]
	ld hl, wBoxGridBoxIcons
	call BoxGrid_RemoveIcon
	pop af
	ld [wBoxGridCursorY], a
	jp .done

.fromParty
; from the party to the box
	pop af
	jr nc, .deposit
; exchange: the box Pokémon at PosB goes to party slot PosA
	ld a, [wBoxGridPosB]
	ld c, a
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld d, [hl]
	call BoxGrid_LoadSpareSpriteIcon ; the one that comes out of the box
	ld a, [wBoxGridPosA]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld d, [hl]
	call BoxGrid_LoadSpareBoxIcon ; the one that goes in
	ld a, [wBoxGridPosB]
	ld b, a
	ld a, [wBoxGridPosA]
	ld c, a
	call BoxGrid_ExchangeBoxAndPartyMon
	ld a, [wBoxGridPosA]
	call BoxGrid_TakeSparePartyIcon
	ld a, [wBoxGridPosB]
	call BoxGrid_TakeSpareBoxIcon
	jr .done
.deposit
	ld a, [wPartyCount]
	dec a
	jp z, BoxGrid_LastMonMessage ; and it stays picked up
	ld a, [wBoxGridPosA]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld d, [hl]
	call BoxGrid_LoadSpareBoxIcon
	ld a, [wPartyCount]
	ld [wBoxGridNumber], a
	ld a, [wBoxCount]
	push af
	ld a, [wBoxGridPosA]
	call BoxGrid_Deposit
	pop af ; where it is in the box now
	push af
	call BoxGrid_TakeSpareBoxIcon
	ld a, [wBoxGridNumber]
	ld c, a
	ld a, [wBoxGridPosA]
	ld hl, wBoxGridPartyIcons
	call BoxGrid_RemoveIcon
	pop af
	call BoxGrid_CursorToBoxPosition
	jr .done

.landedAtEnd
; show where it went: the cursor follows it to the end of its list
	ld a, [wBoxGridCarrySide]
	and a
	jr nz, .endOfParty
	ld a, [wBoxCount]
	dec a
	call BoxGrid_CursorToBoxPosition
	jr .done
.endOfParty
	ld a, [wPartyCount]
	dec a
	ld [wBoxGridCursorY], a
.done
	; fallthrough
BoxGrid_PutDownDone:
	xor a
	ld [wBoxGridCarrying], a
	; fallthrough
BoxGrid_Refresh:
; After the lists changed: colours, places, count, the box at the bottom.
; The box's places are not left to the copy that brings a third of the screen up to
; date per frame. That copy takes the colours of its third as they were at scanline 110
; and the tiles as they are at the end of the frame, so a redraw that is under way then
; (after a box change or a sort, which end anywhere in a frame) leaves a third of the
; box with the new icons in the old colours until its turn comes round again, three
; frames later. Here the copy is held back while everything is worked out; then the
; colours go to the LCD's palettes in a VBlank, and right after that VBlank every place
; is written with its tiles and its palette together, before the picture gets to it.
; The sprites follow a frame later: a party icon that has just been loaded into the
; spare set must not be shown before that set's colours are the LCD's.
	xor a
	ldh [hAutoBGTransferEnabled], a
	call BoxGrid_AssignPalettes
	call BoxGrid_DrawHeaderNumbers
	call BoxGrid_DrawCurrent
	farcall BoxGrid_ApplyPalettes
	farcall BoxGrid_WaitForPalettes
	call BoxGrid_ShowBoxNow
	call BoxGrid_UpdateOAM
	ld a, 1
	ldh [hAutoBGTransferEnabled], a ; the rest of the screen, and the box again as it is
	jp BoxGrid_LoadHoverPicture

BoxGrid_CursorToBoxPosition:
; put the cursor on box position a
	ld b, 0
.row
	cp BOXGRID_COLUMNS
	jr c, .gotRow
	sub BOXGRID_COLUMNS
	inc b
	jr .row
.gotRow
	ld [wBoxGridCursorX], a
	ld a, b
	ld [wBoxGridCursorY], a
	xor a ; BOXGRID_BOX
	ld [wBoxGridCursorSide], a
	ret

BoxGrid_TakeSpareBoxIcon:
; Box position a shows the spare set of box tiles from now on, and the set it showed
; is the spare one.
	ld hl, wBoxGridBoxIcons
	ld de, wBoxGridBoxIcons + BOXGRID_SPARE_BOX_ICON
	jr BoxGrid_ExchangeIconWithSpare

BoxGrid_TakeSparePartyIcon:
; the same for party slot a and the sprite tiles
	ld hl, wBoxGridPartyIcons
	ld de, wBoxGridPartyIcons + BOXGRID_SPARE_PARTY_ICON
	; fallthrough
BoxGrid_ExchangeIconWithSpare:
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	ld b, [hl]
	ld [hl], a
	ld a, b
	ld [de], a
	ret

BoxGrid_RemoveIcon:
; hl = wBoxGridBoxIcons or wBoxGridPartyIcons, a = the position that was taken out of
; the list, c = how many Pokémon the list had before. The sets of the positions behind
; it move up, and the set that is free now goes behind them.
	ld b, a
	ld e, a
	ld d, 0
	add hl, de ; entry of the removed position
	ld a, c
	dec a
	sub b ; entries to move up
	ret z
	ld c, a
	ld b, [hl] ; the set that is free now
.loop
	inc hl
	ld a, [hld]
	ld [hli], a
	dec c
	jr nz, .loop
	ld [hl], b
	ret


; ---- other boxes ---------------------------------------------------------------------------

; Changing the box is the game's own box change: the open box goes to its slot in
; cartridge RAM, the other one comes in, and the game is saved
; (engine/pokemon/box_storage.asm). The game asks before it does that; here it asks
; the first time, and not again until the grid has been left.
;
; A Pokémon that is picked up can be taken along. Nothing has happened to it: it is
; still in its list, and if that list is a box that is no longer open, it is in that
; box's slot. The work is done when it is put down (BoxGrid_PutDownFromOtherBox).

BoxGrid_FlipBox:
; a = 1 or -1: the next or the previous box, round the twelve.
	ld b, a
	call BoxGrid_PressSound ; (keeps bc)
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	add b
	cp -1
	jr nz, .notBelow
	ld a, NUM_BOXES - 1
.notBelow
	cp NUM_BOXES
	jr c, .gotBox
	xor a
.gotBox
	ld d, a
	ld a, [wBoxGridSaveAsked]
	and a
	jr nz, .inPlace
; the first change: the game's question, over the PC's screen
	push de
	call BoxGrid_LeaveScreen
	call BoxGrid_AskSaveOnce
	pop de
	jp c, BoxGrid_LoadScreen ; no
	farcall BoxStore_SwitchTo
	jp BoxGrid_LoadScreen
.inPlace
; The places are emptied at once and stay empty while the boxes are copied and the game
; is saved (a third of a second); then the other box's icons are there.
	push de
	call BoxGrid_BlankBox
	pop de
	farcall BoxStore_SwitchTo
	; fallthrough
BoxGrid_ShowOpenBox:
; The open box is another one than the one on the screen: its icons, its colours, its
; count. The party's side stays as it is.
	call BoxGrid_InitBoxTables
	ld c, 0
.icon
	ld a, [wBoxCount]
	cp c
	jr z, .loaded
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld d, [hl]
	ld e, c
	push bc
	farcall LoadBoxIconFast
	pop bc
	inc c
	jr .icon
.loaded
	jp BoxGrid_Refresh

BoxGrid_BlankBox:
; every place of the box empty on the screen, and no count
	ld a, $ff
	ld [wBoxGridHoverIcon], a
	xor a
.place
	push af
	ld e, a
	call BoxGrid_CellCoord
	call BoxGrid_DrawBoxCell.blank
	pop af
	inc a
	cp MONS_PER_BOX
	jr c, .place
	ld a, ' '
	hlcoord 6, 0
	ld [hli], a
	ld [hl], a
	hlcoord 9, 0
	ld [hli], a
	ld [hl], a
	call BoxGrid_ClearInfo
	jp BoxGrid_ShowBoxNow

BoxGrid_AskSaveOnce:
; The game's question before a box change, unless it has been answered with yes since
; the grid was opened. The PC's screen has to be up (BoxGrid_LeaveScreen). Carry: no.
	ld a, [wBoxGridSaveAsked]
	and a
	ret nz
	farcall BoxStore_AskSave
	ret c
	ld a, 1
	ld [wBoxGridSaveAsked], a
	and a
	ret

BoxGrid_ChooseBox:
; SELECT, or BOX LIST in the title's menu: the game's list of boxes, over the PC's
; screen, and the box that is chosen there.
	call BoxGrid_LeaveScreen
	call BoxGrid_AskSaveOnce
	jr c, .back
	farcall BoxStore_ChooseBox
	jr c, .back
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	cp d
	jr z, .back
	farcall BoxStore_SwitchTo
.back
	jp BoxGrid_LoadScreen

BoxGrid_PutDownFromOtherBox:
; A with a Pokémon picked up that is in another box than the open one: it was carried
; through a box change and is still in its own box's slot.
;   on a free place of the open box    it moves there, to the end
;   on a Pokémon of the open box       the two change boxes and take each other's place
;   on a free place of the party       it is withdrawn from its box
;   on a party member                  the two are exchanged, as within one box
; Every one of these saves the game, as every box change does.
	ld a, [wBoxGridCarryBox]
	ld [wBoxStoreBox], a
	ld a, [wBoxGridCarryIndex]
	ld [wBoxStoreIndex], a
	call BoxGrid_GetHovered
	ld [wBoxGridPosB], a
	push af ; carry: a Pokémon is there
	ld a, [wBoxGridCursorSide]
	and a ; BOXGRID_BOX
	jp nz, .toParty

; into the open box
	pop af
	jr c, .exchangeBoxes
	ld a, [wBoxCount]
	ld [wBoxGridPosB], a ; where it will be: behind the last one
	ld [wBoxStorePos], a
	farcall BoxStore_MoveFromBox
	jr .inOpenBox

.exchangeBoxes
; Each of the two is written to its new box before it leaves its old one, so one of the
; boxes holds both for a moment and needs a free place for that.
	ld a, [wBoxCount]
	cp MONS_PER_BOX
	jr z, .openBoxIsFull
; the carried one comes in, in front of the one that is here...
	ld a, [wBoxGridPosB]
	ld [wBoxStorePos], a
	farcall BoxStore_MoveFromBox
; ...which is one place further on now, and goes to where the other one was
	ld a, [wBoxGridPosB]
	inc a
	ld [wBoxStoreIndex], a
	ld a, [wBoxGridCarryIndex]
	ld [wBoxStorePos], a
	farcall BoxStore_MoveToBox
	jr .inOpenBox
.openBoxIsFull
	farcall GetMonCountsForAllBoxes
	ld a, [wBoxGridCarryBox]
	ld c, a
	ld b, 0
	ld hl, wBoxMonCounts
	add hl, bc
	ld a, [hl]
	cp MONS_PER_BOX
	jp z, BoxGrid_BothBoxesFullMessage ; and it stays picked up
; the one that is here goes over first, in front of the carried one...
	ld a, [wBoxGridPosB]
	ld [wBoxStoreIndex], a
	ld a, [wBoxGridCarryIndex]
	ld [wBoxStorePos], a
	farcall BoxStore_MoveToBox
; ...which is one place further on in its box now, and comes here
	ld a, [wBoxGridCarryIndex]
	inc a
	ld [wBoxStoreIndex], a
	ld a, [wBoxGridPosB]
	ld [wBoxStorePos], a
	farcall BoxStore_MoveFromBox
.inOpenBox
; its icon: into the spare set of box tiles, which its place shows from now on
	ld a, [wBoxGridCarrySpecies]
	ld d, a
	call BoxGrid_LoadSpareBoxIcon
	ld a, [wBoxGridPosB]
	call BoxGrid_TakeSpareBoxIcon
	ld a, [wBoxGridPosB]
	call BoxGrid_CursorToBoxPosition
	jp BoxGrid_PutDownDone

.toParty
; Its own box has to be the open one for that: the box change there, what the grid does
; between a box and the party, and the box change back.
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	ld [wBoxStorePos], a ; the box to come back to
	ld a, [wBoxGridCarryBox]
	ld d, a
	farcall BoxStore_SwitchTo
	pop af
	jr nc, .withdraw
	ld a, [wBoxGridCarryIndex]
	ld b, a
	ld a, [wBoxGridPosB]
	ld c, a
	call BoxGrid_ExchangeBoxAndPartyMon
	jr .backToBox
.withdraw
	ld a, [wPartyCount]
	ld [wBoxGridPosB], a ; where it will be
	ld a, [wBoxGridCarryIndex]
	call BoxGrid_Withdraw
; the party is saved before the box it came out of, so that what is saved has it in
; both places for a moment and not in neither
	farcall BoxStore_SaveParty
.backToBox
	ld a, [wBoxStorePos]
	ld d, a
	farcall BoxStore_SwitchTo
; its sprite icon is in the spare set already
	ld a, [wBoxGridPosB]
	call BoxGrid_TakeSparePartyIcon
	ld a, [wBoxGridPosB]
	ld [wBoxGridCursorY], a
	jp BoxGrid_PutDownDone

BoxGrid_BothBoxesFullMessage:
; the other thing that is refused: an exchange between two boxes that are both full
	ld hl, .Text1
	ld de, .Text2
	jp BoxGrid_Message

.Text1
	db "Both boxes are@"
.Text2
	db "full!@"

BoxGrid_SortBox:
; a = BOXGRID_SORT_*: the open box in that order (by Pokédex number, by level with the
; highest first, or by nickname). Neighbours change places until every Pokémon is
; behind the ones that belong in front of it, so those that are equal keep their order.
	ld [wBoxGridSortMode], a
	ld a, 1
.next
; a = the Pokémon to place; the ones in front of it are in order
	ld hl, wBoxCount
	cp [hl]
	jr nc, .sorted
	push af
.forward
	and a
	jr z, .placed
	ld [wBoxGridPosB], a
	dec a
	ld [wBoxGridPosA], a
	call .wrongOrder
	jr nc, .placed
	xor a ; BOXGRID_BOX
	call BoxGrid_ExchangeInList
	ld a, [wBoxGridPosA]
	jr .forward
.placed
	pop af
	inc a
	jr .next
.sorted
	jp BoxGrid_Refresh

.wrongOrder
; carry if the Pokémon at [wBoxGridPosA] belongs behind the one at [wBoxGridPosB]
	ld a, [wBoxGridSortMode]
	and a ; BOXGRID_SORT_NUMBER
	jr z, .byNumber
	dec a ; BOXGRID_SORT_LEVEL
	jr z, .byLevel
; by nickname: the first letter that differs decides
	ld hl, wBoxMonNicks
	ld a, [wBoxGridPosA]
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wBoxMonNicks
	ld a, [wBoxGridPosB]
	call SkipFixedLengthTextEntries
	ld c, NAME_LENGTH
.letter
	ld a, [de]
	cp [hl]
	jr nz, .differ
	cp '@'
	ret z ; the same name (no carry)
	inc de
	inc hl
	dec c
	jr nz, .letter
	and a
	ret
.differ
	ccf ; carry if the first one's letter is the greater
	ret
.byNumber
	ld a, [wBoxGridPosA]
	call .number
	push af
	ld a, [wBoxGridPosB]
	call .number
	pop bc
	cp b ; carry if the second one's number is the smaller
	ret
.number
	ld c, a
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld a, [hl]
	ld [wPokedexNum], a
	predef IndexToPokedex
	ld a, [wPokedexNum]
	ret
.byLevel
	ld a, [wBoxGridPosA]
	call .level
	push af
	ld a, [wBoxGridPosB]
	call .level
	pop bc
	ld c, a
	ld a, b
	cp c ; carry if the first one's level is the lower
	ret
.level
	ld hl, wBoxMons + MON_BOX_LEVEL
	ld bc, BOXMON_STRUCT_LENGTH
	call AddNTimes
	ld a, [hl]
	ret


; ---- the data ----------------------------------------------------------------------------

BoxGrid_Withdraw:
; box position a to the end of the party, the way the PC's menu does it
	ld [wWhichPokemon], a
	ld c, a
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld a, [hl]
	ld [wCurPartySpecies], a
	xor a ; BOX_TO_PARTY
	ld [wMoveMonType], a
	call MoveMon
	ld a, 1
	ld [wRemoveMonFromBox], a
	jp RemovePokemon

BoxGrid_Deposit:
; party slot a to the end of the box, the way the PC's menu does it
	ld [wWhichPokemon], a
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	ld [wCurPartySpecies], a
	ld a, PARTY_TO_BOX
	ld [wMoveMonType], a
	call MoveMon
	xor a
	ld [wRemoveMonFromBox], a
	jp RemovePokemon

BoxGrid_Release:
; RELEASE for the box Pokémon under the cursor, after asking
	call BoxGrid_ConfirmRelease
	jp nc, BoxGrid_DrawInfo
	call BoxGrid_GetHovered
	ld [wBoxGridPosA], a
	ld c, a
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld a, [hl]
	push af
	ld a, [wBoxCount]
	ld [wBoxGridNumber], a
	ld a, 1
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	ld a, [wBoxGridNumber]
	ld c, a
	ld a, [wBoxGridPosA]
	ld hl, wBoxGridBoxIcons
	call BoxGrid_RemoveIcon
	call BoxGrid_Refresh
	pop af
	jp PlayCry

BoxGrid_MoveToEndOfList:
; a = BOXGRID_BOX or BOXGRID_PARTY. The Pokémon at [wBoxGridPosA] goes to the end of
; that list; the ones behind it move up.
	ld d, a
.loop
	and a
	ld a, [wBoxCount]
	jr z, .gotCount
	ld a, [wPartyCount]
.gotCount
	dec a
	ld b, a
	ld a, [wBoxGridPosA]
	cp b
	ret nc ; it is the last
	inc a
	ld [wBoxGridPosB], a
	push de
	ld a, d
	call BoxGrid_ExchangeInList
	pop de
	ld hl, wBoxGridPosA
	inc [hl]
	ld a, d
	jr .loop

BoxGrid_ExchangeInList:
; a = BOXGRID_BOX or BOXGRID_PARTY. The Pokémon at [wBoxGridPosA] and [wBoxGridPosB] of
; that list change places: species, data, original trainer, nickname, and the icon
; sets that go with them.
	and a
	jr nz, .party
	ld hl, wBoxSpecies
	ld bc, 1
	call BoxGrid_ExchangeEntries
	ld hl, wBoxMons
	ld bc, BOXMON_STRUCT_LENGTH
	call BoxGrid_ExchangeEntries
	ld hl, wBoxMonOT
	ld bc, NAME_LENGTH
	call BoxGrid_ExchangeEntries
	ld hl, wBoxMonNicks
	ld bc, NAME_LENGTH
	call BoxGrid_ExchangeEntries
	ld hl, wBoxGridBoxIcons
	jr .icons
.party
	ld hl, wPartySpecies
	ld bc, 1
	call BoxGrid_ExchangeEntries
	ld hl, wPartyMons
	ld bc, PARTYMON_STRUCT_LENGTH
	call BoxGrid_ExchangeEntries
	ld hl, wPartyMonOT
	ld bc, NAME_LENGTH
	call BoxGrid_ExchangeEntries
	ld hl, wPartyMonNicks
	ld bc, NAME_LENGTH
	call BoxGrid_ExchangeEntries
	ld hl, wBoxGridPartyIcons
.icons
	ld bc, 1
	; fallthrough
BoxGrid_ExchangeEntries:
; exchange entries [wBoxGridPosA] and [wBoxGridPosB] of the table at hl, whose entries
; are bc bytes (fewer than 256)
	push hl
	ld a, [wBoxGridPosA]
	call AddNTimes
	ld d, h
	ld e, l
	pop hl
	ld a, [wBoxGridPosB]
	call AddNTimes
	; fallthrough
BoxGrid_ExchangeBytes:
; exchange the c bytes at de and at hl
.loop
	ld a, [de]
	ld b, [hl]
	ld [hl], a
	ld a, b
	ld [de], a
	inc hl
	inc de
	dec c
	jr nz, .loop
	ret

BoxGrid_ExchangeBoxAndPartyMon:
; The Pokémon at box position b and the one in party slot c change places.
;
; The game can only do this as a deposit and a withdrawal, each to the end of the other
; list, and that needs a free place in one of the two. Here the two are exchanged where
; they are: the 33 bytes that a box entry and a party entry have in common, the
; original trainer and the nickname. Then each gets what MoveMon does for its
; direction: the box entry gets the level in its level byte, and the party entry gets
; its level worked out from the experience and its stats calculated. The result is
; what a deposit and a withdrawal give.
	ld a, b
	ld [wBoxGridBoxPos], a
	ld a, c
	ld [wBoxGridPartyPos], a

; species
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld d, h
	ld e, l
	ld a, [wBoxGridBoxPos]
	ld c, a
	ld hl, wBoxSpecies
	add hl, bc
	ld c, 1
	call BoxGrid_ExchangeBytes

; the data both kinds of entry have
	call .partyMon
	ld d, h
	ld e, l
	call .boxMon
	ld c, BOXMON_STRUCT_LENGTH
	call BoxGrid_ExchangeBytes

; original trainer
	ld hl, wPartyMonOT
	ld a, [wBoxGridPartyPos]
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wBoxMonOT
	ld a, [wBoxGridBoxPos]
	call SkipFixedLengthTextEntries
	ld c, NAME_LENGTH
	call BoxGrid_ExchangeBytes

; nickname
	ld hl, wPartyMonNicks
	ld a, [wBoxGridPartyPos]
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wBoxMonNicks
	ld a, [wBoxGridBoxPos]
	call SkipFixedLengthTextEntries
	ld c, NAME_LENGTH
	call BoxGrid_ExchangeBytes

; into the box: the level the Pokémon had in the party, which is still in the party
; entry behind the bytes that were exchanged
	call .partyMon
	ld bc, MON_LEVEL
	add hl, bc
	ld a, [hl]
	push af
	call .boxMon
	ld bc, MON_BOX_LEVEL
	add hl, bc
	pop af
	ld [hl], a

; into the party: level from the experience, then the stats (as _MoveMon)
	ld a, [wBoxGridPartyPos]
	ld [wWhichPokemon], a
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	call LoadMonData
	farcall CalcLevelFromExperience
	ld a, d
	ld [wCurEnemyLevel], a
	push af
	call .partyMon
	pop af
	ld bc, MON_LEVEL
	add hl, bc
	ld [hli], a
	ld d, h
	ld e, l
	ld bc, (MON_HP_EXP - 1) - MON_STATS
	add hl, bc
	ld b, 1
	jp CalcStats

.partyMon
	ld hl, wPartyMons
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, [wBoxGridPartyPos]
	jp AddNTimes
.boxMon
	ld hl, wBoxMons
	ld bc, BOXMON_STRUCT_LENGTH
	ld a, [wBoxGridBoxPos]
	jp AddNTimes


; ---- colours ----------------------------------------------------------------------------

; There are eight background palettes. The text has one, and the gray Pokémon share it
; (text only uses its white and its black). That leaves seven for the nine other colour
; classes a Pokémon can have. A box rarely holds more than seven of them at once; when
; it does, cyan is shown with blue's palette, or Mew's class with pink's.
;
; A class keeps its palette for as long as it is in the box, so that the colours of the
; screen do not shuffle when a Pokémon comes or goes.

BoxGrid_AssignPalettes:
; From the species in the box: wBoxGridClassSlots (the palette of each class) and
; wBoxGridBoxPalettes (the palette of each position).
	ld hl, wBoxGridClassPresent
	ld bc, NUM_ICON_COLOR_CLASSES
	xor a
	call FillMemory
	ld hl, wBoxGridBoxPalettes
	ld bc, MONS_PER_BOX
	ld a, BOXGRID_TEXT_PALETTE ; for the places that are free
	call FillMemory
; the class of each position
	ld c, 0
.classOfPosition
	ld a, [wBoxCount]
	cp c
	jr z, .gotClasses
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld d, [hl]
	push bc
	farcall GetMonPaletteID_d
	pop bc
	ld a, d
	sub PAL_MEWMON
	cp NUM_ICON_COLOR_CLASSES
	jr c, .validClass
	xor a
.validClass
	ld hl, wBoxGridBoxPalettes
	add hl, bc
	ld [hl], a ; the class, for now
	ld e, a
	ld d, 0
	ld hl, wBoxGridClassPresent
	add hl, de
	ld [hl], 1
	inc c
	jr .classOfPosition
.gotClasses

; a class that is gone gives its palette back, and one that borrowed tries again
	ld hl, wBoxGridClassSlots
	ld de, wBoxGridClassPresent
	ld b, NUM_ICON_COLOR_CLASSES - 1 ; not gray
.giveBack
	ld a, [de]
	and a
	jr z, .free
	bit 7, [hl]
	jr z, .keep
.free
	ld [hl], $ff
.keep
	inc hl
	inc de
	dec b
	jr nz, .giveBack

; a free palette for every class that has none
	ld c, 0
.assign
	call .needsPalette
	jr nc, .assignNext
	call .findFreePalette
	jr c, .assignNext
	call .setPalette
.assignNext
	inc c
	ld a, c
	cp NUM_ICON_COLOR_CLASSES - 1
	jr c, .assign

; more than seven classes: the ones left over share
	ld c, 0
.share
	call .needsPalette
	call c, .borrow
	inc c
	ld a, c
	cp NUM_ICON_COLOR_CLASSES - 1
	jr c, .share

; the palette of each position
	ld c, 0
.paletteOfPosition
	ld a, [wBoxCount]
	cp c
	ret z
	ld b, 0
	ld hl, wBoxGridBoxPalettes
	add hl, bc
	ld e, [hl]
	ld d, 0
	push hl
	ld hl, wBoxGridClassSlots
	add hl, de
	ld a, [hl]
	and 7
	pop hl
	ld [hl], a
	inc c
	jr .paletteOfPosition

.needsPalette
; carry if class c is in the box and has no palette
	ld b, 0
	ld hl, wBoxGridClassPresent
	add hl, bc
	ld a, [hl]
	and a
	ret z
	ld hl, wBoxGridClassSlots
	add hl, bc
	ld a, [hl]
	cp $ff
	scf
	ret z
	ccf
	ret

.getPalette
; a = the palette class e has: $ff none, bit 7 borrowed. Keeps bc and de.
	push de
	ld d, 0
	ld hl, wBoxGridClassSlots
	add hl, de
	ld a, [hl]
	pop de
	ret

.setPalette
; class c gets palette a
	ld b, 0
	ld hl, wBoxGridClassSlots
	add hl, bc
	ld [hl], a
	ret

.findFreePalette
; a = a palette no class has, or carry if all seven are taken. Keeps c.
	ld d, 0
.tryPalette
	ld hl, wBoxGridClassSlots
	ld b, NUM_ICON_COLOR_CLASSES - 1
.checkClass
	ld a, [hli]
	cp d
	jr z, .taken
	dec b
	jr nz, .checkClass
	ld a, d
	and a ; clears carry
	ret
.taken
	inc d
	ld a, d
	cp BOXGRID_TEXT_PALETTE
	jr c, .tryPalette
	scf
	ret

.borrow
; Class c got no palette, so more than seven classes are in the box. Then at least one
; of the pairs cyan/blue and Mew/pink is in the box whole.
; If the class c is paired with has a palette of its own, c uses that one.
	ld b, 0
	ld hl, .SimilarClass
	add hl, bc
	ld a, [hl]
	cp $ff
	jr z, .mergeAPair
	ld e, a
	call .getPalette
	cp BOXGRID_TEXT_PALETTE
	jr nc, .mergeAPair
; Of a pair, blue and pink are the classes with more Pokémon. They get the palette, and
; the other one of the pair borrows it.
	ld d, a
	ld a, c
	cp PAL_BLUEMON - PAL_MEWMON
	jr z, .takeOver
	cp PAL_PINKMON - PAL_MEWMON
	jr z, .takeOver
	ld a, d
	or $80
	jp .setPalette
.takeOver
	ld a, d
	call .setPalette
	push bc
	ld a, d
	or $80
	ld c, e
	call .setPalette
	pop bc
	ret
.mergeAPair
; Otherwise a pair that holds two palettes gives one up: cyan takes blue's, or Mew's
; class takes pink's, and c gets the palette that became free.
	lb de, PAL_BLUEMON - PAL_MEWMON, PAL_CYANMON - PAL_MEWMON
	call .mergePair
	ret nc
	lb de, PAL_PINKMON - PAL_MEWMON, PAL_MEWMON - PAL_MEWMON
	call .mergePair
	ret nc
; cannot be reached: with all seven palettes taken by other classes, one of the two pairs
; holds two of them. Gray, rather than something undefined.
	ld a, BOXGRID_TEXT_PALETTE | $80
	jp .setPalette

.mergePair
; If classes d and e both have a palette of their own: e borrows d's, and class c gets
; the one e had. Carry if not.
	push de
	ld e, d
	call .getPalette
	pop de
	cp BOXGRID_TEXT_PALETTE
	ccf
	ret c
	ld b, a ; d's palette
	call .getPalette ; e's
	cp BOXGRID_TEXT_PALETTE
	ccf
	ret c
	push af
	ld a, b
	or $80
	push bc
	ld c, e
	call .setPalette
	pop bc
	pop af
	call .setPalette
	and a
	ret

.SimilarClass
; indexed by colour class (palette - PAL_MEWMON)
	db PAL_PINKMON - PAL_MEWMON ; PAL_MEWMON
	db PAL_CYANMON - PAL_MEWMON ; PAL_BLUEMON
	db $ff                      ; PAL_REDMON
	db PAL_BLUEMON - PAL_MEWMON ; PAL_CYANMON
	db $ff                      ; PAL_PURPLEMON
	db $ff                      ; PAL_BROWNMON
	db $ff                      ; PAL_GREENMON
	db PAL_MEWMON - PAL_MEWMON  ; PAL_PINKMON
	db $ff                      ; PAL_YELLOWMON
	ASSERT PAL_GRAYMON - PAL_MEWMON == NUM_ICON_COLOR_CLASSES - 1
