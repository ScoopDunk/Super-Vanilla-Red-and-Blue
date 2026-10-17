Random_::
; Generate a random 16-bit value in hRandomAdd/hRandomSub.
;
; The original generator only mixed rDIV into two bytes, which made consecutive
; calls strongly correlated. Among other things that meant a wild Pokemon could
; never roll the DVs that make it shiny once traded to Gen 2. This is a 32-bit
; xorshift generator instead, so every DV combination is possible
; (shiny odds: 1/8192, same as Gen 2).
	push hl
	push bc
	push de
	call .gatherEntropy
	ld hl, wRandomState
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld d, a
	ld e, [hl]
	ld a, e
	add a
	xor b
	ld b, a
	ld a, d
	rla
	ld l, c
	rl l
	ld h, b
	rl h
	sbc a
	and 1
	xor c
	ld c, a
	ld a, h
	xor d
	ld d, a
	ld a, l
	xor e
	ld e, a
	ld h, b
	ld l, c
	push hl
	ld h, d
	ld a, e
	sla e
	rl d
	rl c
	rl b
	sla e
	rl d
	rl c
	rl b
	xor e
	ld e, a
	ld a, h
	xor d
	ld d, a
	pop hl
	ld a, l
	xor c
	ld c, a
	ld a, h
	xor b
	ld hl, wRandomState
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, d
	ld [hli], a
	ld [hl], e
	ldh a, [rDIV]
	add [hl]
	ldh [hRandomAdd], a
	ld a, [hli]
	inc hl
	inc hl
	ASSERT wRandomState + 6 == wRandomEntropy + 2
	sub [hl]
	ldh [hRandomSub], a
	pop de
	pop bc
	pop hl
	ret

.gatherEntropy
	ldh a, [rDIV]
	ld hl, wRandomEntropy + 2
	sbc [hl]
	ld [hld], a
	ldh a, [rDIV]
	adc [hl]
	ld [hld], a
	ret nc
	inc [hl]
	ret

Random_MixEntropy::
; Called once per frame from VBlank.
; XOR the gathered entropy into one half of the xorshift state (picked by rDIV),
; taking care never to zero that half.
	ld hl, wRandomState
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
	ASSERT wRandomState + 4 == wRandomEntropy
	ld a, [hli]
	ld l, [hl]
	ld h, a
	ldh a, [rDIV]
	rra
	jr nc, .tryHighWord
	ld a, h
	cp d
	ld a, l
	jr nz, .mixLowWord
	cp e
	jr nz, .mixLowWord
.mixHighWord
	xor c
	ld c, a
	ld a, h
	xor b
	jr .store
.tryHighWord
	ld a, h
	cp b
	ld a, l
	jr nz, .mixHighWord
	cp c
	jr nz, .mixHighWord
.mixLowWord
	xor e
	ld e, a
	ld a, h
	xor d
	ld d, a
	ld a, b
.store
	ld hl, wRandomState
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, d
	ld [hli], a
	ld [hl], e
	ret
