; Changing boxes and moving a Pokémon between two boxes, for the box grid
; (engine/pokemon/box_grid.asm). In the bank of the game's save code, whose routines
; this is built from, and reached by far calls.
;
; How the game keeps boxes. Only the open box is in work RAM. The other eleven are in
; cartridge RAM, six to a bank ("slots"), and the open box is saved with the rest of
; the game. CHANGE BOX copies the open box to its slot, copies the other one in and
; saves the game; its copy routine empties what it copied from, so the slot of the open
; box is empty while that box is open.
;
; The rule everything here is ordered by: a Pokémon is never without a place in what
; has been saved. Where two saved places have to change, the one that receives is
; written first, so that turning the console off in between leaves the Pokémon in both
; places rather than in none. The game's own box change does not manage that (between
; emptying the new box's slot and the end of the save, that box is nowhere), which is
; why a box is read here without emptying its slot, and the slot is emptied afterwards.

DEF BOXSTORE_ENTRY_SIZE EQU 1 + BOXMON_STRUCT_LENGTH + NAME_LENGTH * 2
	ASSERT BOXSTORE_ENTRY_SIZE == wBoxStoreBufferB - wBoxStoreBufferA

BoxStore_SwitchTo::
; d = the number of a box (0-11). The open box goes to its slot, box d becomes the open
; one, and the game is saved: the game's box change without its texts and its jingle.
	ASSERT BANK(ChangeBox) == BANK(@), "the box routines have to be in the bank of the save code"
	push de
	ld hl, wCurrentBoxNum
	bit BIT_HAS_CHANGED_BOXES, [hl] ; the first box change ever?
	call z, EmptyAllSRAMBoxes ; then the slots hold nothing yet (as ChangeBox does)
	call BoxStore_WriteOpenBox
	pop de
	ld a, d
	call BoxStore_ReadBox
	call BoxStore_Save
	jp BoxStore_ClearOpenBoxSlot

BoxStore_MoveFromBox::
; The Pokémon at [wBoxStoreIndex] of box [wBoxStoreBox] becomes entry [wBoxStorePos] of
; the open box. The open box must have room.
;   saved before          its own box has it
;   after the save        both boxes have it
;   in the end            the open box has it
	call BoxStore_ReadEntry
	call BoxStore_InsertBufferA
	call BoxStore_Save
; out of its own box: the open box out of the way, that box in, the Pokémon out, that
; box back to its slot, the open box in again
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	push af
	call BoxStore_WriteOpenBox
	ld a, [wBoxStoreBox]
	call BoxStore_ReadBox
	call BoxStore_RemoveEntry
	call BoxStore_WriteOpenBox
	pop af
	call BoxStore_ReadBox
	jp BoxStore_ClearOpenBoxSlot

BoxStore_MoveToBox::
; The Pokémon at [wBoxStoreIndex] of the open box becomes entry [wBoxStorePos] of box
; [wBoxStoreBox]. That box must have room.
;   saved before          the open box has it
;   after the slot write  both boxes have it
;   after the save        the other box has it
	ld a, [wBoxStoreIndex]
	ld de, wBoxStoreBufferA
	call BoxStore_OpenBoxToBuffer
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	push af
	call BoxStore_WriteOpenBox
	ld a, [wBoxStoreBox]
	call BoxStore_ReadBox
	call BoxStore_InsertBufferA
	call BoxStore_WriteOpenBox
	pop af
	call BoxStore_ReadBox
	call BoxStore_RemoveEntry
	call BoxStore_Save
	jp BoxStore_ClearOpenBoxSlot

BoxStore_SaveParty::
; The party (and the Pokédex) into the save, and nothing else: for a Pokémon that has
; just come out of a box into the party, before the save that takes it out of the box.
; (The game's own save writes the box first and the party last.)
	jp SavePartyAndDexData

BoxStore_AskSave::
; The game's own question before a box change ("When you change a #MON BOX, data will
; be saved. OK?"). Carry if the answer is no.
	ld hl, WhenYouChangeBoxText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	ret z
	scf
	ret

BoxStore_ChooseBox::
; The game's own list of boxes, as ChangeBox shows it. Carry if it was left with B;
; otherwise d = the box that was chosen.
	ld hl, wCurrentBoxNum
	bit BIT_HAS_CHANGED_BOXES, [hl]
	call z, EmptyAllSRAMBoxes ; before the first box change the slots hold anything; the list counts what is in them (ChangeBox empties them here too)
	call DisplayChangeBoxMenu
	call UpdateSprites
	ld hl, hUILayoutFlags
	set BIT_DOUBLE_SPACED_MENU, [hl]
	call HandleMenuInput
	ld hl, hUILayoutFlags
	res BIT_DOUBLE_SPACED_MENU, [hl]
	bit B_PAD_B, a
	scf
	ret nz
	ld a, [wCurrentMenuItem]
	ld d, a
	and a
	ret


BoxStore_WriteOpenBox:
; The open box to its slot, with the game's own routine: afterwards the box in work RAM
; is empty and the slots' checksums are right.
	call GetBoxSRAMLocation
	ld e, l
	ld d, h
	ld hl, wBoxDataStart
	jp CopyBoxToOrFromSRAM

BoxStore_ReadBox:
; a = the number of a box. It becomes the open box, read from its slot, and the slot
; stays as it is: until the game has been saved, the slot is the only saved place of
; what is in it.
	set BIT_HAS_CHANGED_BOXES, a
	ld [wCurrentBoxNum], a
	call GetBoxSRAMLocation
	call BoxStore_OpenSRAM
	ld de, wBoxDataStart
	ld bc, wBoxDataEnd - wBoxDataStart
	call CopyData
	jr BoxStore_CloseSRAM

BoxStore_ClearOpenBoxSlot:
; The slot of the open box becomes empty, as the game leaves it after a box change.
; Done with the game's copy routine, by copying the slot onto itself: it empties what
; it copied from and works out the checksums.
	call GetBoxSRAMLocation
	ld d, h
	ld e, l
	jp CopyBoxToOrFromSRAM

BoxStore_Save:
; the save of a box change, as ChangeBox does it: the map's own text pointer goes into
; the save, not the PC's
	ld hl, wCurMapTextPtr
	ld de, wChangeBoxSavedMapTextPointer
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	call RestoreMapTextPointer
	call SaveGameData
	ld hl, wChangeBoxSavedMapTextPointer
	jp SetMapTextPointer

BoxStore_OpenSRAM:
; b = the bank of cartridge RAM
	ld a, RAMG_SRAM_ENABLE
	ld [rRAMG], a
	ld a, BMODE_ADVANCED
	ld [rBMODE], a
	ld a, b
	ld [rRAMB], a
	ret

BoxStore_CloseSRAM:
	xor a
	ld [rBMODE], a
	ld [rRAMG], a
	ret

BoxStore_RemoveEntry:
; entry [wBoxStoreIndex] out of the open box, with the game's own routine
	ld a, [wBoxStoreIndex]
	ld [wWhichPokemon], a
	ld a, 1
	ld [wRemoveMonFromBox], a
	jp RemovePokemon

BoxStore_ReadEntry:
; Entry [wBoxStoreIndex] of box [wBoxStoreBox] to wBoxStoreBufferA, read from the box's
; slot, which is not changed.
	ld a, [wCurrentBoxNum]
	push af
	ld a, [wBoxStoreBox]
	ld [wCurrentBoxNum], a ; where GetBoxSRAMLocation takes the number from
	call GetBoxSRAMLocation
	pop af
	ld [wCurrentBoxNum], a
	push hl
	call BoxStore_OpenSRAM
	pop hl
	ld a, [wBoxStoreIndex]
	ld de, wBoxStoreBufferA
	and a ; to the buffer
	call BoxStore_CopyEntry
	jr BoxStore_CloseSRAM

BoxStore_InsertBufferA:
; The Pokémon in wBoxStoreBufferA becomes entry [wBoxStorePos] of the open box, and the
; ones from there on move one place on. (Both buffers are used up.)
; First behind the last one...
	ld a, [wBoxCount]
	ld de, wBoxStoreBufferA
	call BoxStore_BufferToOpenBox
	ld hl, wBoxCount
	inc [hl]
	ld c, [hl]
	ld b, 0
	ld hl, wBoxSpecies
	add hl, bc
	ld [hl], $ff ; the end of the list
; ...then forward to its place, changing places with the one in front of it
	ld a, [wBoxCount]
	dec a
.loop
	ld hl, wBoxStorePos
	cp [hl]
	ret z
	ret c
	push af
	ld de, wBoxStoreBufferA
	call BoxStore_OpenBoxToBuffer
	pop af
	push af
	dec a
	ld de, wBoxStoreBufferB
	call BoxStore_OpenBoxToBuffer
	pop af
	push af
	ld de, wBoxStoreBufferB
	call BoxStore_BufferToOpenBox
	pop af
	dec a
	push af
	ld de, wBoxStoreBufferA
	call BoxStore_BufferToOpenBox
	pop af
	jr .loop

BoxStore_OpenBoxToBuffer:
; entry a of the open box to the buffer at de
	ld hl, wBoxDataStart
	and a
	jr BoxStore_CopyEntry

BoxStore_BufferToOpenBox:
; the buffer at de to entry a of the open box
	ld hl, wBoxDataStart
	scf
	; fallthrough
BoxStore_CopyEntry:
; One entry of a box: its species, its data, its original trainer and its nickname.
; hl = the box (in work RAM, or its slot with cartridge RAM open), a = the entry,
; de = a buffer of BOXSTORE_ENTRY_SIZE bytes. Carry: buffer to box; no carry: box to
; buffer.
	ld [wBoxStoreEntry], a
	ld a, 0
	rla
	ld [wBoxStoreToBox], a
	ld a, l
	ld [wBoxStoreBase], a
	ld a, h
	ld [wBoxStoreBase + 1], a
	ld hl, .Parts
	ld a, 4
.part
	push af
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a ; where the table is in the box
	ld a, [hli] ; how long one entry of it is
	push hl
	push af
	ld hl, wBoxStoreBase
	ld a, [hli]
	ld h, [hl]
	ld l, a
	add hl, bc
	pop af
	ld c, a
	ld b, 0
	ld a, [wBoxStoreEntry]
	call AddNTimes
	ld a, [wBoxStoreToBox]
	and a
	jr z, .copy
; CopyData copies from hl to de: turn the two round, and afterwards de is the buffer
; again, behind what was copied
	ld a, h
	ld h, d
	ld d, a
	ld a, l
	ld l, e
	ld e, a
	call CopyData
	ld d, h
	ld e, l
	jr .next
.copy
	call CopyData
.next
	pop hl
	pop af
	dec a
	jr nz, .part
	ret

.Parts
; where each table is in a box, and the size of one entry
	dw wBoxSpecies - wBoxDataStart
	db 1
	dw wBoxMons - wBoxDataStart
	db BOXMON_STRUCT_LENGTH
	dw wBoxMonOT - wBoxDataStart
	db NAME_LENGTH
	dw wBoxMonNicks - wBoxDataStart
	db NAME_LENGTH


BoxStore_DisplayBoxList:
; The list of boxes of CHANGE BOX, with how many Pokémon each box holds where the
; original marked the boxes that are not empty with a ball. DisplayChangeBoxMenu jumps
; here. The list is wider for it (12 columns instead of 7), and the open box's number
; is in a narrower box at the left.
	xor a
	ldh [hAutoBGTransferEnabled], a
	ld a, PAD_A | PAD_B
	ld [wMenuWatchedKeys], a
	ld a, NUM_BOXES - 1
	ld [wMaxMenuItem], a
	ld a, 1
	ld [wTopMenuItemY], a
	ld a, 7
	ld [wTopMenuItemX], a
	xor a
	ld [wMenuWatchMovingOutOfBounds], a
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	hlcoord 0, 0
	lb bc, 2, 4
	call TextBoxBorder
	ld hl, ChooseABoxText
	call PrintText
	hlcoord 1, 1
	ld de, .BoxText
	call PlaceString
	ld a, '№'
	ldcoord_a 1, 2
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	inc a
	ld [wBoxStoreEntry], a ; scratch
	hlcoord 3, 2
	ld de, wBoxStoreEntry
	lb bc, 1, 2
	call PrintNumber
	hlcoord 6, 0
	lb bc, 12, 12
	call TextBoxBorder
	ld hl, hUILayoutFlags
	set BIT_SINGLE_SPACED_LINES, [hl]
	ld de, BoxNames
	hlcoord 8, 1
	call PlaceString
	ld hl, hUILayoutFlags
	res BIT_SINGLE_SPACED_LINES, [hl]
	call GetMonCountsForAllBoxes
	hlcoord 14, 1
	ld de, wBoxMonCounts
	ld a, NUM_BOXES
.loop
	push af
	push hl
	push de
	lb bc, 1, 2
	call PrintNumber
	ld de, .OfTwentyText
	call PlaceString
	pop de
	pop hl
	ld bc, SCREEN_WIDTH
	add hl, bc
	inc de
	pop af
	dec a
	jr nz, .loop
	ld a, 1
	ldh [hAutoBGTransferEnabled], a
	ret

.BoxText
	db "BOX@"
.OfTwentyText
	db "/{d:MONS_PER_BOX}@"
