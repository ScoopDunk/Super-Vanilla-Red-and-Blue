; ANOTHER REPEL?
; When a repel wears off and there is another one in the bag, the game offers to use it.
; (The pret wiki has a tutorial for this, "Repel QoL Improvements"; this version keeps
; the code out of the home bank and uses the item through the normal item code.)

; Called by DisplayRepelWoreOffText (home/text_script.asm).
; Returns carry if the text box can be closed without waiting for another button.
RepelWoreOff::
	ld hl, .RepelWoreOffText
	call PrintText
	call ChooseRepelToOffer
	ret nc ; none in the bag: just the usual message
; the item to use, the way the bag menu would have set it up
	ld [wCurItem], a
	ld [wNamedObjectIndex], a
	ld a, b
	ld [wWhichPokemon], a ; its position in the bag
	call GetItemName
	call CopyToStringBuffer
; wait for a button with the message on screen, then ask
	ld hl, .WaitForButtonText
	call PrintText_NoCreatingTextBox
	ld hl, wLastRepelUsed
	ld a, [wCurItem]
	cp [hl]
	ld hl, .UseAnotherText
	jr z, .ask
	ld hl, .UseOtherKindText ; not the kind that wore off, so name it
.ask
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
; YES: use it like any item. That sets the steps, says "<PLAYER> used X!", waits for a
; button and takes it out of the bag.
	xor a
	ld [wPseudoItemID], a
	call UseItem
.done
	scf
	ret

.RepelWoreOffText:
	text_far _RepelWoreOffText
	text_end

.WaitForButtonText:
	text_promptbutton
	text_end

.UseAnotherText:
	text_far _RepelUseAnotherText
	text_end

.UseOtherKindText:
	text_far _RepelUseOtherKindText
	text_end

; Picks the repel to offer: the kind that was used last if there is one left, otherwise
; the strongest kind in the bag.
; Returns carry if there is one, with a = the item and b = its position in the bag.
ChooseRepelToOffer:
	ld a, [wLastRepelUsed]
	cp REPEL
	jr z, .lastKind
	cp SUPER_REPEL
	jr z, .lastKind
	cp MAX_REPEL
	jr nz, .strongest
.lastKind
	call .find
	ret c
.strongest
	ld a, MAX_REPEL
	call .find
	ret c
	ld a, SUPER_REPEL
	call .find
	ret c
	ld a, REPEL
.find
	ld c, a
	ld hl, wBagItems
	ld b, 0
.loop
	ld a, [hli]
	cp -1
	ret z ; the end of the bag (carry is clear)
	cp c
	jr z, .found
	inc hl
	inc b
	jr .loop
.found
	scf
	ret
