MainMenu:
; Check save file
	call InitOptions
	xor a
	ld [wOptionsInitialized], a
	inc a
	ld [wSaveFileStatus], a
	call CheckForPlayerNameInSRAM
	jr nc, .mainMenuLoop

	predef TryLoadSaveFile

.mainMenuLoop
	ld c, 20
	call DelayFrames
	xor a ; LINK_STATE_NONE
	ld [wLinkState], a
	ld hl, wPartyAndBillsPCSavedMenuItem
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [wDefaultMap], a
	ld hl, wStatusFlags4
	res BIT_LINK_CONNECTED, [hl]
	call ClearScreen
	call RunDefaultPaletteCommand
	call LoadTextBoxTilePatterns
	call LoadFontTilePatterns
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
	ld a, [wSaveFileStatus]
	cp 1
	jr z, .noSaveFile
; there's a save file
	hlcoord 0, 0
	ld b, 6
	ld c, 13
	call TextBoxBorder
	hlcoord 1, 2
	ld de, ShinyPatchMarkerText
	call PlaceString
	hlcoord 2, 2
	ld de, ContinueText
	call PlaceString
	jr .next2
.noSaveFile
	hlcoord 0, 0
	ld b, 4
	ld c, 13
	call TextBoxBorder
	hlcoord 1, 2
	ld de, ShinyPatchMarkerText
	call PlaceString
	hlcoord 2, 2
	ld de, NewGameText
	call PlaceString
.next2
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	call UpdateSprites
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuJoypadPollCount], a
	inc a
	ld [wTopMenuItemX], a
	inc a
	ld [wTopMenuItemY], a
	ld a, PAD_A | PAD_B | PAD_START
	ld [wMenuWatchedKeys], a
	ld a, [wSaveFileStatus]
	ld [wMaxMenuItem], a
	call HandleMenuInput
	bit B_PAD_B, a
	jp nz, DisplayTitleScreen ; if so, go back to the title screen
	ld c, 20
	call DelayFrames
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wSaveFileStatus]
	cp 2
	jp z, .skipInc
; If there's no save file, increment the current menu item so that the numbers
; are the same whether or not there's a save file.
	inc b
.skipInc
	ld a, b
	and a
	jr z, .choseContinue
	cp 1
	jp z, StartNewGame
	call DisplayOptionMenu
	ld a, TRUE
	ld [wOptionsInitialized], a
	jp .mainMenuLoop
.choseContinue
	call DisplayContinueGameInfo
	ld hl, wCurrentMapScriptFlags
	set BIT_CUR_MAP_LOADED_1, [hl]
.inputLoop
	xor a
	ldh [hJoyPressed], a
	ldh [hJoyReleased], a
	ldh [hJoyHeld], a
	call Joypad
	ldh a, [hJoyHeld]
	bit B_PAD_A, a
	jr nz, .pressedA
	bit B_PAD_B, a
	jp nz, .mainMenuLoop
	jr .inputLoop
.pressedA
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	ld a, PLAYER_DIR_DOWN
	ld [wPlayerDirection], a
	ld c, 10
	call DelayFrames
	ld a, [wNumHoFTeams]
	and a
	jp z, SpecialEnterMap
	ld a, [wCurMap]
	cp HALL_OF_FAME
	jp nz, SpecialEnterMap
	xor a
	ld [wDestinationMap], a
	ld hl, wStatusFlags6
	set BIT_FLY_OR_DUNGEON_WARP, [hl]
	call PrepareForSpecialWarp
	jp SpecialEnterMap

InitOptions:
	ld a, 1 << BIT_FAST_TEXT_DELAY
	ld [wLetterPrintingDelayFlags], a
	ld a, TEXT_DELAY_MEDIUM
	ld [wOptions], a
	ret

LinkMenu:
	xor a
	ld [wLetterPrintingDelayFlags], a
	ld hl, wStatusFlags4
	set BIT_LINK_CONNECTED, [hl]
	ld hl, LinkMenuEmptyText
	call PrintText
	call SaveScreenTilesToBuffer1
	ld hl, WhereWouldYouLikeText
	call PrintText
	hlcoord 5, 5
	ld b, $6
	ld c, $d
	call TextBoxBorder
	call UpdateSprites
	hlcoord 7, 7
	ld de, CableClubOptionsText
	call PlaceString
	xor a
	ld [wUnusedLinkMenuByte], a
	ld [wCableClubDestinationMap], a
	ld hl, wTopMenuItemY
	ld a, 7
	ld [hli], a
	ASSERT wTopMenuItemY + 1 == wTopMenuItemX
	ld a, 6
	ld [hli], a
	ASSERT wTopMenuItemX + 1 == wCurrentMenuItem
	xor a
	ld [hli], a
	inc hl
	ASSERT wCurrentMenuItem + 2 == wMaxMenuItem
	ld a, 2
	ld [hli], a
	ASSERT wMaxMenuItem + 1 == wMenuWatchedKeys
	ASSERT 2 + 1 == PAD_A | PAD_B
	inc a
	ld [hli], a
	ASSERT wMenuWatchedKeys + 1 == wLastMenuItem
	xor a
	ld [hl], a
.waitForInputLoop
	call HandleMenuInput
	and PAD_A | PAD_B
	add a
	add a
	ld b, a
	ld a, [wCurrentMenuItem]
	add b
	add $d0
	ld [wLinkMenuSelectionSendBuffer], a
	ld [wLinkMenuSelectionSendBuffer + 1], a
.exchangeMenuSelectionLoop
	call LinkMenu_ExchangeSelection ; engine/link/link_menu_exchange.asm
	ld a, [wLinkMenuSelectionReceiveBuffer]
	ld b, a
	and $f0
	cp $d0
	jr z, .checkEnemyMenuSelection
	ld a, [wLinkMenuSelectionReceiveBuffer + 1]
	ld b, a
	and $f0
	cp $d0
	jr nz, .exchangeMenuSelectionLoop
.checkEnemyMenuSelection
	ld a, b
	and $c ; did the enemy press A or B?
	jr nz, .enemyPressedAOrB
; the enemy didn't press A or B
	ld a, [wLinkMenuSelectionSendBuffer]
	and $c ; did the player press A or B?
	jr z, .waitForInputLoop ; if neither the player nor the enemy pressed A or B, try again
	jr .doneChoosingMenuSelection ; if the player pressed A or B but the enemy didn't, use the player's selection
.enemyPressedAOrB
	ld a, [wLinkMenuSelectionSendBuffer]
	and $c ; did the player press A or B?
	jr z, .useEnemyMenuSelection ; if the enemy pressed A or B but the player didn't, use the enemy's selection
; the enemy and the player both pressed A or B
; The gameboy that is clocking the connection wins.
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr z, .doneChoosingMenuSelection
.useEnemyMenuSelection
	ld a, b
	ld [wLinkMenuSelectionSendBuffer], a
	and $3
	ld [wCurrentMenuItem], a
.doneChoosingMenuSelection
	ldh a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr nz, .skipStartingTransfer
	call DelayFrame
	call DelayFrame
	ld a, SC_START | SC_INTERNAL
	ldh [rSC], a
.skipStartingTransfer
	ld b, ' '
	ld c, ' '
	ld d, '▷'
	ld a, [wLinkMenuSelectionSendBuffer]
	and PAD_B << 2 ; was B button pressed?
	jr nz, .updateCursorPosition
; A button was pressed
	ld a, [wCurrentMenuItem]
	cp $2
	jr z, .updateCursorPosition
	ld c, d
	ld d, b
	dec a
	jr z, .updateCursorPosition
	ld b, c
	ld c, d
.updateCursorPosition
	ld a, b
	ldcoord_a 6, 7
	ld a, c
	ldcoord_a 6, 9
	ld a, d
	ldcoord_a 6, 11
	ld c, 40
	call DelayFrames
	call LoadScreenTilesFromBuffer1
	ld a, [wLinkMenuSelectionSendBuffer]
	and PAD_B << 2 ; was B button pressed?
	jr nz, .choseCancel ; cancel if B pressed
	ld a, [wCurrentMenuItem]
	cp $2
	jr z, .choseCancel
	xor a
	ld [wWalkBikeSurfState], a ; start walking
	ld a, [wCurrentMenuItem]
	and a
	ld a, COLOSSEUM
	jr nz, .next
	ld a, TRADE_CENTER
.next
	ld [wCableClubDestinationMap], a
	ld hl, PleaseWaitText
	call PrintText
	ld c, 50
	call DelayFrames
	ld hl, wStatusFlags6
	res BIT_DEBUG_MODE, [hl]
	ld a, [wDefaultMap]
	ld [wDestinationMap], a
	call PrepareForSpecialWarp
	ld c, 20
	call DelayFrames
	xor a
	ld [wMenuJoypadPollCount], a
	ld [wSerialExchangeNybbleSendData], a
	inc a ; LINK_STATE_IN_CABLE_CLUB
	ld [wLinkState], a
	ld [wEnteringCableClub], a
	jr SpecialEnterMap
.choseCancel
	xor a
	ld [wMenuJoypadPollCount], a
	vc_hook Wireless_net_stop
	call Delay3
	call CloseLinkConnection
	ld hl, LinkCanceledText
	vc_hook Wireless_net_end
	call PrintText
	ld hl, wStatusFlags4
	res BIT_LINK_CONNECTED, [hl]
	ret

WhereWouldYouLikeText:
	text_far _WhereWouldYouLikeText
	text_end

PleaseWaitText:
	text_far _PleaseWaitText
	text_end

LinkCanceledText:
	text_far _LinkCanceledText
	text_end

StartNewGame:
	ld hl, wStatusFlags6
	; Ensure debug mode is not used when starting a regular new game.
	; Debug mode persists in saved games for both debug and non-debug builds, and is
	; only reset here by the main menu.
	res BIT_DEBUG_MODE, [hl]
	; fallthrough
StartNewGameDebug:
	call OakSpeech
	ld c, 20
	call DelayFrames

; enter map after using a special warp or loading the game from the main menu
SpecialEnterMap::
	xor a
	ldh [hJoyPressed], a
	ldh [hJoyHeld], a
	ldh [hJoy5], a
	ld [wCableClubDestinationMap], a
	ld hl, wStatusFlags6
	set BIT_GAME_TIMER_COUNTING, [hl]
	call ResetPlayerSpriteData
	ld c, 20
	call DelayFrames
	ld a, [wEnteringCableClub]
	and a
	ret nz
	jp EnterMap

; Sits under the menu cursor; shows up next to the first entry
; once the cursor moves off it.
ShinyPatchMarkerText:
	db "<SHINY>@"

ContinueText:
	db "CONTINUE"
	next ""
	; fallthrough

NewGameText:
	db   "NEW GAME"
	next "OPTION@"

CableClubOptionsText:
	db   "TRADE CENTER"
	next "COLOSSEUM"
	next "CANCEL@"

DisplayContinueGameInfo:
	xor a
	ldh [hAutoBGTransferEnabled], a
	hlcoord 4, 7
	ld b, 8
	ld c, 14
	call TextBoxBorder
	hlcoord 5, 9
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 12, 9
	ld de, wPlayerName
	call PlaceString
	hlcoord 17, 11
	call PrintNumBadges
	hlcoord 16, 13
	call PrintNumOwnedMons
	hlcoord 13, 15
	call PrintPlayTime
	ld a, 1
	ldh [hAutoBGTransferEnabled], a
	ld c, 30
	jp DelayFrames

PrintSaveScreenText:
	xor a
	ldh [hAutoBGTransferEnabled], a
	hlcoord 4, 0
	ld b, $8
	ld c, $e
	call TextBoxBorder
	call LoadTextBoxTilePatterns
	call UpdateSprites
	hlcoord 5, 2
	ld de, SaveScreenInfoText
	call PlaceString
	hlcoord 12, 2
	ld de, wPlayerName
	call PlaceString
	hlcoord 17, 4
	call PrintNumBadges
	hlcoord 16, 6
	call PrintNumOwnedMons
	hlcoord 13, 8
	call PrintPlayTime
	ld a, $1
	ldh [hAutoBGTransferEnabled], a
	ld c, 5 ; was 30 (pret wiki, "Remove Artificial Save Delay")
	jp DelayFrames

PrintNumBadges:
	push hl
	ld hl, wObtainedBadges
	ld b, $1
	call CountSetBits
	pop hl
	ld de, wNumSetBits
	lb bc, 1, 2
	jp PrintNumber

PrintNumOwnedMons:
	push hl
	ld hl, wPokedexOwned
	ld b, wPokedexOwnedEnd - wPokedexOwned
	call CountSetBits
	pop hl
	ld de, wNumSetBits
	lb bc, 1, 3
	jp PrintNumber

PrintPlayTime:
	ld de, wPlayTimeHours
	lb bc, 1, 3
	call PrintNumber
	ld [hl], $6d
	inc hl
	ld de, wPlayTimeMinutes
	lb bc, LEADING_ZEROES | 1, 2
	jp PrintNumber

SaveScreenInfoText:
	db   "PLAYER"
	next "BADGES    "
	next "#DEX    "
	next "TIME@"

; Cursor Y coordinates of the option menu rows, top to bottom.
; Each row's cursor X is kept at wOptionsTextSpeedCursorX + row.
DEF OPTIONS_TEXT_SPEED_Y   EQU 2
DEF OPTIONS_BATTLE_ANIM_Y  EQU 5
DEF OPTIONS_BATTLE_STYLE_Y EQU 8
DEF OPTIONS_INSTANT_TEXT_Y EQU 11
DEF OPTIONS_BAR_SPEED_Y    EQU 14
DEF OPTIONS_CANCEL_Y       EQU 16
DEF NUM_OPTION_MENU_OPTIONS EQU 5

DisplayOptionMenu:
; One frame around all the options, each three rows high (a line, the title, the
; choices), drawn as boxes that share their top and bottom lines.
	hlcoord 0, 0
	ld a, NUM_OPTION_MENU_OPTIONS
.drawBoxLoop
	push af
	push hl
	lb bc, 2, 18
	call TextBoxBorder
	pop hl
	ld bc, SCREEN_WIDTH * 3
	add hl, bc
	pop af
	dec a
	jr nz, .drawBoxLoop
; where two boxes meet, the frame carries straight on
	hlcoord 0, 3
	ld de, SCREEN_WIDTH - 1
	ld b, NUM_OPTION_MENU_OPTIONS - 1
.joinBoxesLoop
	ld a, '│'
	ld [hl], a
	add hl, de
	ld [hli], a
	add hl, de
	add hl, de
	inc hl
	inc hl
	dec b
	jr nz, .joinBoxesLoop
; the choices go on the line right below each title
	ldh a, [hUILayoutFlags]
	set BIT_SINGLE_SPACED_LINES, a
	ldh [hUILayoutFlags], a
	hlcoord 1, OPTIONS_TEXT_SPEED_Y - 1
	ld de, TextSpeedOptionText
	call PlaceString
	hlcoord 1, OPTIONS_BATTLE_ANIM_Y - 1
	ld de, BattleAnimationOptionText
	call PlaceString
	hlcoord 1, OPTIONS_BATTLE_STYLE_Y - 1
	ld de, BattleStyleOptionText
	call PlaceString
	hlcoord 1, OPTIONS_INSTANT_TEXT_Y - 1
	ld de, InstantTextOptionText
	call PlaceString
	hlcoord 1, OPTIONS_BAR_SPEED_Y - 1
	ld de, BarSpeedOptionText
	call PlaceString
	ldh a, [hUILayoutFlags]
	res BIT_SINGLE_SPACED_LINES, a
	ldh [hUILayoutFlags], a
	hlcoord 2, 16
	ld de, OptionMenuCancelText
	call PlaceString
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ASSERT BIT_FAST_TEXT_DELAY == 0
	inc a ; 1 << BIT_FAST_TEXT_DELAY
	ld [wLetterPrintingDelayFlags], a
	ld [wOptionsCancelCursorX], a
	ld a, OPTIONS_TEXT_SPEED_Y
	ld [wTopMenuItemY], a
	call SetCursorPositionsFromOptions
	ld a, [wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	ld [wTopMenuItemX], a
	ld a, $01
	ldh [hAutoBGTransferEnabled], a ; enable auto background transfer
	call Delay3
.loop
	call PlaceMenuCursor
	call SetOptionsFromCursorPositions
.getJoypadStateLoop
	call JoypadLowSensitivity
	ldh a, [hJoy5]
	ld b, a
	and ~PAD_SELECT ; any key besides select pressed?
	jr z, .getJoypadStateLoop
	bit B_PAD_B, b
	jr nz, .exitMenu
	bit B_PAD_START, b
	jr nz, .exitMenu
	bit B_PAD_A, b
	jr z, .checkDirectionKeys
; A was pressed
	ld a, [wTopMenuItemY]
	cp OPTIONS_CANCEL_Y ; is the cursor on Cancel?
	jr nz, .loop
.exitMenu
	ld a, SFX_PRESS_AB
	call PlaySound
	ret
.eraseOldMenuCursor
	ld [wTopMenuItemX], a
	call EraseMenuCursor
	jp .loop
.checkDirectionKeys
	ld a, [wTopMenuItemY]
	bit B_PAD_DOWN, b
	jr nz, .downPressed
	bit B_PAD_UP, b
	jr nz, .upPressed
	cp OPTIONS_BATTLE_ANIM_Y
	jr z, .cursorInBattleAnimation
	cp OPTIONS_BATTLE_STYLE_Y
	jr z, .cursorInBattleStyle
	cp OPTIONS_INSTANT_TEXT_Y
	jr z, .cursorInInstantText
	cp OPTIONS_BAR_SPEED_Y
	jr z, .cursorInBarSpeed
	cp OPTIONS_CANCEL_Y
	jp z, .loop
; cursor in Text Speed
	bit B_PAD_LEFT, b
	jp nz, .pressedLeftInTextSpeed
	jp .pressedRightInTextSpeed
.downPressed
	ld c, 1
	jr .moveVertically
.upPressed
	ld c, -1
.moveVertically
; a = current cursor Y, c = direction. Wraps around at both ends.
	ld hl, OptionMenuCursorYs
	ld b, 0
.findRowLoop
	cp [hl]
	jr z, .foundRow
	inc hl
	inc b
	jr .findRowLoop
.foundRow
	ld a, b
	add c
	cp -1
	jr nz, .notPastTop
	ld a, NUM_OPTION_MENU_ROWS - 1
.notPastTop
	cp NUM_OPTION_MENU_ROWS
	jr c, .gotRow
	xor a
.gotRow
	ld c, a
	ld b, 0
	ld hl, OptionMenuCursorYs
	add hl, bc
	ld a, [hl]
	ld [wTopMenuItemY], a
	ld hl, wOptionsTextSpeedCursorX
	add hl, bc
	ld a, [hl]
	ld [wTopMenuItemX], a
	call PlaceUnfilledArrowMenuCursor
	jp .loop
.cursorInBattleAnimation
	ld de, wOptionsBattleAnimCursorX ; battle animation cursor X coordinate
	ld hl, BattleAnimCursorXs
	jr .threeChoices
.cursorInBattleStyle
	ld a, [wOptionsBattleStyleCursorX] ; battle style cursor X coordinate
	xor 1 ^ 10 ; toggle between 1 and 10
	ld [wOptionsBattleStyleCursorX], a
	jp .eraseOldMenuCursor
.cursorInInstantText
	ld a, [wOptionsInstantTextCursorX] ; instant text cursor X coordinate
	xor 1 ^ 10 ; toggle between 1 and 10
	ld [wOptionsInstantTextCursorX], a
	jp .eraseOldMenuCursor
.cursorInBarSpeed
	ld de, wOptionsBarSpeedCursorX ; bar speed cursor X coordinate
	ld hl, BarSpeedCursorXs
.threeChoices
; three choices: step through the cursor X coordinates at hl, stopping at either end.
; de = where this row's cursor X is kept
	ld a, [de]
	ld c, 0
.findChoiceLoop
	cp [hl]
	jr z, .foundChoice
	inc hl
	inc c
	jr .findChoiceLoop
.foundChoice
	bit B_PAD_LEFT, b
	jr nz, .pressedLeftInThreeChoices
	ld a, c
	cp 3 - 1
	jp z, .loop
	inc hl
	jr .updateThreeChoicesXCoord
.pressedLeftInThreeChoices
	ld a, c
	and a
	jp z, .loop
	dec hl
.updateThreeChoicesXCoord
	ld a, [hl]
	ld [de], a
	jp .eraseOldMenuCursor
.pressedLeftInTextSpeed
	ld a, [wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	cp 1
	jr z, .updateTextSpeedXCoord
	cp 7
	jr nz, .fromSlowToMedium
	sub 6
	jr .updateTextSpeedXCoord
.fromSlowToMedium
	sub 7
	jr .updateTextSpeedXCoord
.pressedRightInTextSpeed
	ld a, [wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	cp 14
	jr z, .updateTextSpeedXCoord
	cp 7
	jr nz, .fromFastToMedium
	add 7
	jr .updateTextSpeedXCoord
.fromFastToMedium
	add 6
.updateTextSpeedXCoord
	ld [wOptionsTextSpeedCursorX], a ; text speed cursor X coordinate
	push af
	call .turnInstantTextOff
	pop af
	jp .eraseOldMenuCursor
.turnInstantTextOff
; Picking a text speed takes over from INSTANT TEXT.
	ld a, [wOptionsInstantTextCursorX]
	cp 10
	ret z
	ld a, 10
	ld [wOptionsInstantTextCursorX], a
	hlcoord 1, OPTIONS_INSTANT_TEXT_Y
	ld [hl], ' '
	hlcoord 10, OPTIONS_INSTANT_TEXT_Y
	ld [hl], '▷'
	ret

OptionMenuCursorYs:
	db OPTIONS_TEXT_SPEED_Y
	db OPTIONS_BATTLE_ANIM_Y
	db OPTIONS_BATTLE_STYLE_Y
	db OPTIONS_INSTANT_TEXT_Y
	db OPTIONS_BAR_SPEED_Y
	db OPTIONS_CANCEL_Y
DEF NUM_OPTION_MENU_ROWS EQU @ - OptionMenuCursorYs
	ASSERT NUM_OPTION_MENU_ROWS == NUM_OPTION_MENU_OPTIONS + 1
	ASSERT wOptionsCancelCursorX == wOptionsTextSpeedCursorX + NUM_OPTION_MENU_ROWS - 1

TextSpeedOptionText:
	db   "TEXT SPEED"
	next " FAST  MEDIUM SLOW@"

BattleAnimationOptionText:
	db   "BATTLE ANIMATION"
	next " ON    OFF   FAST@"

; cursor X coordinates of the battle animation choices: ON, OFF and FAST (FAST BATTLES)
BattleAnimCursorXs:
	db 1, 7, 13
DEF BATTLE_ANIM_OFF_CURSOR_X  EQU 7
DEF BATTLE_ANIM_FAST_CURSOR_X EQU 13

BattleStyleOptionText:
	db   "BATTLE STYLE"
	next " SHIFT    SET@"

InstantTextOptionText:
	db   "INSTANT TEXT"
	next " ON       OFF@"

BarSpeedOptionText:
	db   "HP/EXP BAR SPEED"
	next " NORMAL 2× INSTANT@"

; cursor X coordinates of the bar speed choices, in the order of the BAR_SPEED_* constants
BarSpeedCursorXs:
	db 1, 8, 11
	ASSERT @ - BarSpeedCursorXs == NUM_BAR_SPEEDS
	ASSERT NUM_BAR_SPEEDS == 3 ; .threeChoices

OptionMenuCancelText:
	db "CANCEL@"

; sets the options variable according to the current placement of the menu cursors in the options menu
SetOptionsFromCursorPositions:
	ld d, TEXT_DELAY_NONE
	ld a, [wOptionsInstantTextCursorX] ; instant text cursor X coordinate
	dec a
	jr z, .gotTextDelay ; INSTANT TEXT is on: no delay, whatever the text speed row says
	ld hl, TextSpeedOptionData
	ld a, [wOptionsTextSpeedCursorX] ; text speed cursor X coordinate
	ld c, a
.loop
	ld a, [hli]
	cp c
	jr z, .textSpeedMatchFound
	inc hl
	jr .loop
.textSpeedMatchFound
	ld a, [hl]
	ld d, a
.gotTextDelay
	ld a, [wOptionsBattleAnimCursorX] ; battle animation cursor X coordinate
	dec a
	jr z, .battleAnimationOn
; battle animation Off
	set BIT_BATTLE_ANIMATION, d
	jr .checkBattleStyle
.battleAnimationOn
	res BIT_BATTLE_ANIMATION, d
.checkBattleStyle
	ld a, [wOptionsBattleStyleCursorX] ; battle style cursor X coordinate
	dec a
	jr z, .battleStyleShift
; battle style Set
	set BIT_BATTLE_SHIFT, d
	jr .storeOptions
.battleStyleShift
	res BIT_BATTLE_SHIFT, d
.storeOptions
	ld a, d
	ld [wOptions], a
; bar speed: the position of its cursor X in BarSpeedCursorXs
	ld a, [wOptionsBarSpeedCursorX] ; bar speed cursor X coordinate
	ld hl, BarSpeedCursorXs
	ld c, -1
.barSpeedLoop
	inc c
	cp [hl]
	inc hl
	jr nz, .barSpeedLoop
	ld a, c
	ld [wBarSpeed], a
; FAST BATTLES: FAST is OFF in wOptions (set above) plus a byte of its own
	ld a, [wOptionsBattleAnimCursorX] ; battle animation cursor X coordinate
	cp BATTLE_ANIM_FAST_CURSOR_X
	ld a, FAST_BATTLES_ON
	jr z, .gotFastBattles
	xor a
.gotFastBattles
	ld [wFastBattles], a
	ret

; reads the options variable and places menu cursors in the correct positions within the options menu
SetCursorPositionsFromOptions:
	ld a, [wOptions]
	ld c, a
	and $3f
	ld b, 10 ; INSTANT TEXT off
	jr nz, .findTextSpeed
; A text delay of 0 is INSTANT TEXT. The text speed row then shows FAST,
; which is what turning INSTANT TEXT off falls back to.
	ld b, 1 ; on
	ld a, TEXT_DELAY_FAST
.findTextSpeed
	push bc
	ld hl, TextSpeedOptionData + 1
	ld de, 2
	call IsInArray
	pop bc
	dec hl
	ld a, [hl]
	ld [wOptionsTextSpeedCursorX], a ; text speed cursor X coordinate
	hlcoord 0, OPTIONS_TEXT_SPEED_Y
	call .placeUnfilledRightArrow
	ld a, b
	ld [wOptionsInstantTextCursorX], a ; instant text cursor X coordinate
	hlcoord 0, OPTIONS_INSTANT_TEXT_Y
	call .placeUnfilledRightArrow
	sla c
	ld a, 1 ; On
	jr nc, .storeBattleAnimationCursorX
	ld a, [wFastBattles]
	dec a ; FAST_BATTLES_ON
	ld a, BATTLE_ANIM_OFF_CURSOR_X
	jr nz, .storeBattleAnimationCursorX
	ld a, BATTLE_ANIM_FAST_CURSOR_X
.storeBattleAnimationCursorX
	ld [wOptionsBattleAnimCursorX], a ; battle animation cursor X coordinate
	hlcoord 0, OPTIONS_BATTLE_ANIM_Y
	call .placeUnfilledRightArrow
	sla c
	ld a, 1
	jr nc, .storeBattleStyleCursorX
	ld a, 10
.storeBattleStyleCursorX
	ld [wOptionsBattleStyleCursorX], a ; battle style cursor X coordinate
	hlcoord 0, OPTIONS_BATTLE_STYLE_Y
	call .placeUnfilledRightArrow
; bar speed. The byte is one the original games never write, but treat anything that
; is not one of the three choices as NORMAL all the same.
	ld a, [wBarSpeed]
	cp NUM_BAR_SPEEDS
	jr c, .gotBarSpeed
	xor a ; BAR_SPEED_NORMAL
.gotBarSpeed
	ld e, a
	ld d, 0
	ld hl, BarSpeedCursorXs
	add hl, de
	ld a, [hl]
	ld [wOptionsBarSpeedCursorX], a ; bar speed cursor X coordinate
	hlcoord 0, OPTIONS_BAR_SPEED_Y
	call .placeUnfilledRightArrow
; cursor in front of Cancel
	hlcoord 0, OPTIONS_CANCEL_Y
	ld a, 1
.placeUnfilledRightArrow
	ld e, a
	ld d, 0
	add hl, de
	ld [hl], '▷'
	ret

; table that indicates how the 3 text speed options affect frame delays
TextSpeedOptionData:
	db 14, TEXT_DELAY_SLOW
	db  7, TEXT_DELAY_MEDIUM
	db  1, TEXT_DELAY_FAST
	db  7, -1 ; end (default X coordinate)

CheckForPlayerNameInSRAM:
; Check if the player name data in SRAM has a string terminator character
; (indicating that a name may have been saved there) and return whether it does
; in carry.
	ld a, RAMG_SRAM_ENABLE
	ld [rRAMG], a
	ld a, BMODE_ADVANCED
	ld [rBMODE], a
	ASSERT BANK(sPlayerName) == BMODE_ADVANCED
	ld [rRAMB], a
	ld b, NAME_LENGTH
	ld hl, sPlayerName
.loop
	ld a, [hli]
	cp '@'
	jr z, .found
	dec b
	jr nz, .loop
; not found
	xor a
	ld [rRAMG], a
	ld [rBMODE], a
	and a
	ret
.found
	xor a
	ld [rRAMG], a
	ld [rBMODE], a
	scf
	ret
