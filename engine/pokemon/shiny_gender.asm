; Shiny and gender indicators.
;
; Gen 1 has no notion of shininess or gender, but Gen 2 derives both from a
; mon's DVs, so they can be previewed here before trading through the
; Time Capsule:
;   - shiny:  Def, Spd and Spc DVs are all 10 and the Atk DV is 2, 3, 6, 7, 10, 11, 14 or 15
;   - gender: female if the Atk DV is below the species' gender ratio threshold

IsShinyDVs:
; hl = pointer to a mon's DVs. Returns nz if the mon is shiny in Gen 2.
	ld a, [hl]
	bit 5, a ; Atk DV bit 1
	jr z, .notShiny
	and $f ; Def DV
	cp 10
	jr nz, .notShiny
	inc hl
	ld a, [hl] ; Spd and Spc DVs
	cp (10 << 4) | 10
	jr nz, .notShiny
	ld a, 1
	and a
	ret
.notShiny
	xor a
	ret

; The battle HUDs don't look at the DVs directly. The result is latched in
; wBattleShinyFlags when a mon enters the field, so a Transformed mon (which
; copies its target's DVs) doesn't pick up or lose the indicator.

LatchPlayerMonShinyFlag::
	ld hl, wBattleShinyFlags
	res BIT_PLAYER_MON_SHINY, [hl]
	ld hl, wBattleMonDVs
	call IsShinyDVs
	ret z
	ld hl, wBattleShinyFlags
	set BIT_PLAYER_MON_SHINY, [hl]
	ret

LatchEnemyMonShinyFlag::
	ld hl, wBattleShinyFlags
	res BIT_ENEMY_MON_SHINY, [hl]
	ld hl, wEnemyMonDVs
	call IsShinyDVs
	ret z
	ld hl, wBattleShinyFlags
	set BIT_ENEMY_MON_SHINY, [hl]
	ret

ClearPlayerMonShinyFlag::
	ld hl, wBattleShinyFlags
	res BIT_PLAYER_MON_SHINY, [hl]
	ret

ClearEnemyMonShinyFlag::
	ld hl, wBattleShinyFlags
	res BIT_ENEMY_MON_SHINY, [hl]
	ret

DrawPlayerHUDShinyAndGender::
; sparkle left of the name, gender left of the level
	ld a, [wBattleShinyFlags]
	bit BIT_PLAYER_MON_SHINY, a
	jr z, .notShiny
	hlcoord 9, 7
	ld [hl], '<SHINY>'
.notShiny
	ld a, [wBattleMonDVs]
	swap a
	and $f
	ld e, a
	ld a, [wBattleMonSpecies]
	ld d, a
	call GetMonGenderSymbol
	ld a, d
	and a
	ret z
	hlcoord 13, 8
	ld [hl], a
	ret

DrawEnemyHUDShinyAndGender::
; sparkle left of the name, gender left of the level
	ld a, [wBattleShinyFlags]
	bit BIT_ENEMY_MON_SHINY, a
	jr z, .notShiny
	hlcoord 0, 0
	ld [hl], '<SHINY>'
.notShiny
	ld a, [wEnemyMonDVs]
	swap a
	and $f
	ld e, a
	ld a, [wEnemyMonSpecies]
	ld d, a
	call GetMonGenderSymbol
	ld a, d
	and a
	ret z
IF GEN_2_GRAPHICS
	hlcoord 5, 1 ; the level is at 6, 1 and the caught icon at 1, 1
ELSE
	hlcoord 3, 1
ENDC
	ld [hl], a
	ret

DrawStatusScreenShinyAndGender::
; sparkle left of the name, gender left of the level
	ld hl, wLoadedMonDVs
	call IsShinyDVs
	jr z, .notShiny
	hlcoord 8, 1
	ld [hl], '<SHINY>'
.notShiny
	ld a, [wLoadedMonDVs]
	swap a
	and $f
	ld e, a
	ld a, [wLoadedMonSpecies]
	ld d, a
	call GetMonGenderSymbol
	ld a, d
	and a
	ret z
	hlcoord 13, 2
	ld [hl], a
	ret

GetMonGenderSymbol:
; d = species, e = Atk DV
; Returns "♂" or "♀" in d, or 0 if the species has no gender to show.
	ld hl, GenderRatios
.nextGroup
	ld a, [hli]
	cp -1
	jr z, .noGender
	ld b, a ; threshold
.nextSpecies
	ld a, [hli]
	and a
	jr z, .nextGroup
	cp d
	jr nz, .nextSpecies
	ld a, e
	cp b
	ld d, '♂'
	ret nc
	ld d, '♀'
	ret
.noGender
	ld d, 0
	ret

GenderRatios:
; Each group is a threshold followed by a 0-terminated species list:
; a mon is female if its Atk DV is below the threshold.
; NIDORAN_M and NIDORAN_F are left out since their names already say it.
; Genderless species are not listed at all.

	db 0 ; always male
	db NIDORINO, NIDOKING, HITMONCHAN, HITMONLEE, TAUROS
	db 0

	db 2 ; 12.5% female
	db AERODACTYL, BLASTOISE, BULBASAUR, CHARIZARD, CHARMANDER, CHARMELEON
	db EEVEE, FLAREON, IVYSAUR, JOLTEON, KABUTO, KABUTOPS, OMANYTE, OMASTAR
	db SNORLAX, SQUIRTLE, VAPOREON, VENUSAUR, WARTORTLE
	db 0

	db 4 ; 25% female
	db ABRA, ALAKAZAM, ARCANINE, ELECTABUZZ, GROWLITHE, KADABRA, MACHAMP
	db MACHOKE, MACHOP, MAGMAR
	db 0

	db 8 ; 50% female
	db ARBOK, BEEDRILL, BELLSPROUT, BUTTERFREE, CATERPIE, CLOYSTER, CUBONE
	db DEWGONG, DIGLETT, DODRIO, DODUO, DRAGONAIR, DRAGONITE, DRATINI
	db DROWZEE, DUGTRIO, EKANS, EXEGGCUTE, EXEGGUTOR, FARFETCHD, FEAROW
	db GASTLY, GENGAR, GEODUDE, GLOOM, GOLBAT, GOLDEEN, GOLDUCK, GOLEM
	db GRAVELER, GRIMER, GYARADOS, HAUNTER, HORSEA, HYPNO, KAKUNA, KINGLER
	db KOFFING, KRABBY, LAPRAS, LICKITUNG, MAGIKARP, MANKEY, MAROWAK, MEOWTH
	db METAPOD, MR_MIME, MUK, ODDISH, ONIX, PARAS, PARASECT, PERSIAN, PIDGEOT
	db PIDGEOTTO, PIDGEY, PIKACHU, PINSIR, POLIWAG, POLIWHIRL, POLIWRATH
	db PONYTA, PRIMEAPE, PSYDUCK, RAICHU, RAPIDASH, RATICATE, RATTATA, RHYDON
	db RHYHORN, SANDSHREW, SANDSLASH, SCYTHER, SEADRA, SEAKING, SEEL
	db SHELLDER, SLOWBRO, SLOWPOKE, SPEAROW, TANGELA, TENTACOOL, TENTACRUEL
	db VENOMOTH, VENONAT, VICTREEBEL, VILEPLUME, WEEDLE, WEEPINBELL, WEEZING
	db ZUBAT
	db 0

	db 12 ; 75% female
	db CLEFABLE, CLEFAIRY, JIGGLYPUFF, NINETALES, VULPIX, WIGGLYTUFF
	db 0

	db 16 ; always female
	db NIDORINA, NIDOQUEEN, JYNX, CHANSEY, KANGASKHAN
	db 0

	db -1 ; end
