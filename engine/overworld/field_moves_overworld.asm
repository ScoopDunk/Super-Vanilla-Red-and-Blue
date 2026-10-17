; USING CUT, SURF AND STRENGTH FROM THE OVERWORLD
; After the pret wiki tutorial "Use Cut, Surf, and Strength From the Overworld":
; press A facing a small tree, water or a boulder and, if a party mon knows the move
; and you have the badge for it, the game offers to use it.
;
; Everything lives in this bank, next to the routines the party menu uses for the same
; moves (UsedCut, ItemUseSurfboard, PrintStrengthText, IsSurfingAllowed), and those
; routines still do the work, so both ways of using a move behave the same.

; Called first thing by PrintBookshelfText, i.e. when A was pressed and no hidden event
; is in front of the player.
; If the player faces a tree that can be cut, or water that can be surfed on from where
; he stands, shows the text for it and returns with carry set.
TryFieldMoveOnFacingTile:
	lda_coord 8, 9
	ld [wTilePlayerStandingOn], a ; ItemUseSurfboard checks tile pairs with this
	call _GetTileAndCoordsInFrontOfPlayer ; c = [wTileInFrontOfPlayer]
; the same trees UsedCut accepts
	ld a, [wCurMapTileset]
	and a ; OVERWORLD
	ld b, $3d ; cut tree
	jr z, .checkTree
	cp GYM
	jr nz, .checkWater
	ld b, $50 ; gym cut tree
.checkTree
	ld a, c
	cp b
	ld b, (CutTreeText_id - TextPredefs) / 2 + 1
	jr z, .found
.checkWater
	ld a, [wWalkBikeSurfState]
	cp 2
	jr z, .none ; already surfing
; the same checks ItemUseSurfboard makes
	call IsNextTileShoreOrWater
	jr c, .none
	ld hl, TilePairCollisionsWater
	call CheckForTilePairCollisions
	jr c, .none
	ld b, (CalmWaterText_id - TextPredefs) / 2 + 1
.found
; someone standing there (a swimmer, say) or a sign comes first
	push bc
	call IsSpriteOrSignInFrontOfPlayer
	pop bc
	ldh a, [hTextID]
	and a
	jr nz, .none
	push bc
	call EnableAutoTextBoxDrawing
	pop af
	call PrintPredefTextID
	scf
	ret
.none
	and a
	ret

; Looks for a party mon that knows move d.
; Found: carry clear, and as if that mon had been picked in the party menu:
; [wWhichPokemon] = its party index, [wCurPartySpecies] = its species (for the cry),
; wNameBuffer = its nickname (for the text).
; Not found: carry set.
FindPartyMonWithMove:
	ld a, [wPartyCount]
	and a
	jr z, .notFound
	ld e, a
	ld c, 0
	ld hl, wPartyMon1Moves
.monLoop
	push hl
	ld b, NUM_MOVES
.moveLoop
	ld a, [hli]
	cp d
	jr z, .found
	dec b
	jr nz, .moveLoop
	pop hl
	ld a, PARTYMON_STRUCT_LENGTH
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	inc c
	dec e
	jr nz, .monLoop
.notFound
	scf
	ret
.found
	pop hl
	ld a, c
	ld [wWhichPokemon], a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	ld [wCurPartySpecies], a
	ld a, c
	ld hl, wPartyMonNicks
	call GetPartyMonName
	and a
	ret

; Waits for a button with the text that is on screen, then asks the question at hl.
; z if the answer is YES.
AskToUseFieldMove:
	push hl
	ld hl, .WaitForButtonText
	call PrintText_NoCreatingTextBox
	pop hl
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	ret

.WaitForButtonText:
	text_promptbutton
	text_end

; the text has done its own waiting: close the box without asking for another button
CloseFieldMoveTextBox:
	ld a, 1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ret

CutTreeText::
	text_asm
	ld hl, .TreeCanBeCutText
	call PrintText
	ld a, [wObtainedBadges]
	bit BIT_CASCADEBADGE, a
	jr z, .done
	ld d, CUT
	call FindPartyMonWithMove
	jr c, .done
	ld hl, .LikeToUseCutText
	call AskToUseFieldMove
	call z, UsedCutFromOverworld
	call CloseFieldMoveTextBox
.done
	jp TextScriptEnd

.TreeCanBeCutText:
	text_far _TreeCanBeCutText
	text_end

.LikeToUseCutText:
	text_far _LikeToUseCutText
	text_end

; UsedCut without the trip back from the party menu.
; TryFieldMoveOnFacingTile has made sure the tile in front is a tree.
UsedCutFromOverworld:
	ld a, [wTileInFrontOfPlayer]
	ld [wCutTile], a
	ld a, 1
	ld [wActionResultOrTookBattleTurn], a ; used cut
	ld hl, UsedCutText
	call PrintText
	call LoadCurrentMapView ; the map without the text box, as UsedCut has it here
	jp UsedCut_Animate

CalmWaterText::
	text_asm
	ld a, [wObtainedBadges]
	bit BIT_SOULBADGE, a
	jr z, .cannotSurf
	ld d, SURF
	call FindPartyMonWithMove
	jr c, .cannotSurf
	call IsSurfingAllowed ; says why not on the Cycling Road and in the Seafoam current
	ld hl, wStatusFlags1
	bit BIT_SURF_ALLOWED, [hl]
	res BIT_SURF_ALLOWED, [hl]
	jr z, .close
	ld hl, .WaterIsCalmText
	call PrintText
	ld hl, .LikeToUseSurfText
	call AskToUseFieldMove
	jr nz, .close
; what choosing SURF in the party menu does
	ld a, SURFBOARD
	ld [wCurItem], a
	ld [wPseudoItemID], a
	call UseItem
.close
	call CloseFieldMoveTextBox
	jr .done
.cannotSurf
	ld hl, .WaterIsCalmText
	call PrintText
.done
	jp TextScriptEnd

.WaterIsCalmText:
	text_far _WaterIsCalmText
	text_end

.LikeToUseSurfText:
	text_far _LikeToUseSurfText
	text_end

; the script of BoulderText (home/overworld_text.asm), which every boulder has
BoulderTextScript::
	ld a, [wStatusFlags1]
	bit BIT_STRENGTH_ACTIVE, a
	ld hl, .BouldersCanBeMovedText
	jp nz, PrintText
	ld hl, .RequiresStrengthText
	call PrintText
	ld a, [wObtainedBadges]
	bit BIT_RAINBOWBADGE, a
	ret z
	ld d, STRENGTH
	call FindPartyMonWithMove
	ret c
	ld hl, .LikeToUseStrengthText
	call AskToUseFieldMove
	call z, PrintStrengthText
	jp CloseFieldMoveTextBox

.RequiresStrengthText:
	text_far _BoulderText
	text_end

.BouldersCanBeMovedText:
	text_far _BouldersCanBeMovedText
	text_end

.LikeToUseStrengthText:
	text_far _LikeToUseStrengthText
	text_end
