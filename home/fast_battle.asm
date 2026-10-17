; FAST BATTLES: BATTLE ANIMATION has a third choice, FAST. It is the OFF setting with
; every wait that only paces a battle taken out as well: the pause that stands in for a
; move's animation, the blink or shake when a hit lands, the slides and the growing and
; shrinking of the pics, the pauses before and after messages, and waiting for sounds
; and cries to end. Messages that wait for a button still do.

; nz if the battle in progress is one of those. hBattleFast is worked out once, when the
; battle begins (SetFastBattleIntro): never in a link battle, where both games keep the
; original pace, nor in the old man's demonstration. It is cleared when the battle is
; over, or earlier if a Pokemon evolves after it: an evolution is shown as it always was.
IsBattleFast::
	ldh a, [hBattleFast]
	and a
	ret

; DelayFrames, for a wait that is not taken in a FAST battle
BattleDelayFrames::
	call IsBattleFast
	jp z, DelayFrames
	xor a ; what DelayFrames returns
	ld c, a
	ret

; The last step of MoveAnimation (so its bank is loaded): the blink or shake that shows
; a hit. In a FAST battle only its sound is left, and it is not waited for.
BattleApplyingAttackAnimation::
	call IsBattleFast
	jp z, PlayApplyingAttackAnimation
	ld a, [wAnimationType]
	and a
	ret z
	cp ANIMATIONTYPE_SHAKE_SCREEN_HORIZONTALLY_SLOW
	ret z
	cp ANIMATIONTYPE_SHAKE_SCREEN_HORIZONTALLY_SLOW_2
	ret z ; these two never had a sound
	jp PlayApplyingAttackSound
