; The link menu's exchange of button press and menu item (TRADE CENTER / COLOSSEUM /
; CANCEL), for the game that is being clocked.
;
; Serial_ExchangeLinkMenuSelection (home/serial.asm) swaps three bytes and keeps the last
; two, and the game that is being clocked waits for each of them for as long as it takes.
; The clocking game, though, stops as soon as it has what it needs: a Gen 2 game at the
; Time Capsule sends its choice until one byte of ours has come back and then walks into
; the room, and a Gen 1 game sends one more byte after it has decided. If our three bytes
; are not through by then (we see only every other byte when they arrive right after our
; VBlank), nothing clocks the rest, and the original game sits at "Where would you like
; to go?" for good with the other player already in the room.
;
; This is the same exchange with one addition. Every menu byte the other game sends is
; remembered in wUnusedLinkMenuByte (LinkMenu clears it on the way in). When no byte has
; come for about half a second, a wait the other game's menu never causes while it is
; still undecided:
; - if the other game sent a choice (A or B), that choice is used, as it would have been;
; - if it was in its menu without a choice of its own and we have chosen, it has taken
;   ours and gone on, and so do we;
; - if nothing has come from its menu yet, we keep waiting, as the original does.
; The clocking game still uses the original routine.

LinkMenu_ExchangeSelection::
	ldh a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	jp nz, Serial_ExchangeLinkMenuSelection
	ld hl, wLinkMenuSelectionSendBuffer
	ld de, wLinkMenuSelectionReceiveBuffer
	ld c, 2 ; number of bytes to save
	ld a, 1
	ldh [hSerialIgnoringInitialData], a
.loop
	call DelayFrame
	ld a, [hl]
	ldh [hSerialSendData], a
.waitForByte
	xor a
	ldh [hSerialReceivedNewData], a
	push bc
	ld bc, LINK_MENU_QUIET_PASSES
.wait
	ldh a, [hSerialReceivedNewData]
	and a
	jr nz, .gotByte
	dec bc
	ld a, b
	or c
	jr nz, .wait
	pop bc
; nothing for a while: has the other game moved on?
	ld a, [wUnusedLinkMenuByte]
	and a
	jr z, .waitForByte ; it has not been in its menu yet
	ld b, a
	and (PAD_A | PAD_B) << 2
	jr nz, .useRememberedByte ; it chose
	ld a, [wLinkMenuSelectionSendBuffer]
	and (PAD_A | PAD_B) << 2
	jr z, .waitForByte ; nobody has chosen
; b = its last menu byte, without a choice: LinkMenu goes on with ours
.useRememberedByte
	ld a, b
	ld [wLinkMenuSelectionReceiveBuffer], a
	ld [wLinkMenuSelectionReceiveBuffer + 1], a
	ret
.gotByte
	pop bc
	xor a
	ldh [hSerialReceivedNewData], a
	ldh a, [hSerialReceiveData]
	cp SERIAL_NO_DATA_BYTE
	jr nz, .haveByte
; the other game had nothing ready: offer the same byte again next frame,
; as Serial_ExchangeByte does
	ld a, [hl]
	ldh [hSerialSendData], a
	call DelayFrame
	jr .waitForByte
.haveByte
	ld b, a
	and $f0
	cp $d0
	jr nz, .notAMenuByte
; remember it; a byte with a choice in it is not replaced by one without
	ld a, [wUnusedLinkMenuByte]
	and (PAD_A | PAD_B) << 2
	jr nz, .notAMenuByte
	ld a, b
	ld [wUnusedLinkMenuByte], a
.notAMenuByte
	inc hl
	ldh a, [hSerialIgnoringInitialData]
	and a
	ld a, 0
	ldh [hSerialIgnoringInitialData], a
	jr nz, .loop
	ld a, b
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	ret
