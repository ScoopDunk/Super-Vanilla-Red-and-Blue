; The order SortItemList puts items in (from the pret wiki tutorial "Add Item Sorting In
; Bag"). Items that are not listed end up after these.
ItemSortList:
	; Used Key Items
	db BICYCLE
	db ITEMFINDER
	db EXP_ALL
	db TOWN_MAP
	; Rods
	db OLD_ROD
	db GOOD_ROD
	db SUPER_ROD
	; Balls
	db POKE_BALL
	db GREAT_BALL
	db ULTRA_BALL
	db SAFARI_BALL
	db MASTER_BALL
	; Common Items
	db REPEL
	db SUPER_REPEL
	db MAX_REPEL
	db ESCAPE_ROPE
	db POKE_DOLL
	; Health
	db POTION
	db SUPER_POTION
	db HYPER_POTION
	db MAX_POTION
	db FULL_RESTORE
	db FRESH_WATER
	db SODA_POP
	db LEMONADE
	; Revival
	db REVIVE
	db MAX_REVIVE
	; Status
	db ANTIDOTE
	db BURN_HEAL
	db ICE_HEAL
	db AWAKENING
	db PARLYZ_HEAL
	db FULL_HEAL
	db POKE_FLUTE
	; PP
	db ETHER
	db MAX_ETHER
	db ELIXER
	db MAX_ELIXER
	; Battle Raises
	db X_ACCURACY
	db X_ATTACK
	db X_DEFEND
	db X_SPEED
	db X_SPECIAL
	db GUARD_SPEC
	db DIRE_HIT
	; Permanent Raises
	db RARE_CANDY
	db HP_UP
	db PROTEIN
	db IRON
	db CARBOS
	db CALCIUM
	db PP_UP
	; Stones
	db LEAF_STONE
	db FIRE_STONE
	db THUNDER_STONE
	db WATER_STONE
	db MOON_STONE
	; Money
	db COIN_CASE
	db COIN
	db NUGGET
	; Fossils
	db DOME_FOSSIL
	db HELIX_FOSSIL
	db OLD_AMBER
	; Maps and Items with No Use
	db SAFARI_BAIT
	db SAFARI_ROCK
	db S_S_TICKET
	; Key Items With No Use
	db SECRET_KEY
	db BIKE_VOUCHER
	db CARD_KEY
	db GOLD_TEETH
	db OAKS_PARCEL
	db LIFT_KEY
	db SILPH_SCOPE
	; TMs
FOR n, NUM_TMS
	db TM01 + n
ENDR
	; HMs
FOR n, NUM_HMS
	db HM01 + n
ENDR
	db -1 ; end
