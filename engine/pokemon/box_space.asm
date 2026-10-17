; Called after a #MON was caught or received and went to the current box: tells how
; many more fit in it, or that it is full now. (From pureRGB, rewritten.)

; After a catch: waits for a button, as the "transferred to PC" text before it does.
PrintBoxSpaceLeftPrompt::
	call PrintBoxSpaceLeft
	ld hl, .promptButtonText
	jp PrintText_NoCreatingTextBox

.promptButtonText
	text_promptbutton
	text_end

; After a gift: leaves the text up for the caller to end, as "sent to BOX" did.
PrintBoxSpaceLeft::
	ld hl, wBoxNumString
	ld a, [wBoxCount]
	ld b, a
	ld a, MONS_PER_BOX
	sub b
	ld [hli], a ; slots left
	ld b, a
	ld a, [wCurrentBoxNum]
	and BOX_NUM_MASK
	inc a
	ld [hl], a ; box number, from 1
	ld hl, BoxNowFullText
	ld a, b
	and a
	jr z, .gotText
	ld hl, BoxOneSlotLeftText
	dec a
	jr z, .gotText
	ld hl, BoxSlotsLeftText
.gotText
	jp PrintText

BoxSlotsLeftText:
	text_decimal wBoxNumString, 1, 2
	text " slots left in"
	line "BOX @"
	text_decimal wBoxNumString + 1, 1, 2
	text "."
	done

BoxOneSlotLeftText:
	text "1 slot left in"
	line "BOX @"
	text_decimal wBoxNumString + 1, 1, 2
	text "."
	done

BoxNowFullText:
	text "BOX @"
	text_decimal wBoxNumString + 1, 1, 2
	text " is now"
	line "full."

	para "Time to change"
	line "boxes!"
	done
