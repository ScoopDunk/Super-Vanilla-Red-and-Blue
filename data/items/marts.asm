; Mart inventories. They are text scripts: each one is read while the bank of its mart's
; map is loaded and copied to RAM at once, so it does not have to be in the home bank
; (where the original games keep them) as long as it is in the same bank as that map.
;
; They are NOT put in the map script files themselves: save files hold pointers into the
; map sections, so those must keep their cartridge layout (see layout.link). Each list
; goes in a small section of its own, which the linker places in free space of the bank.

SECTION "Mart Inventories 06", ROMX, BANK[$06]

IndigoPlateauLobbyClerkText::
	script_mart ULTRA_BALL, GREAT_BALL, FULL_RESTORE, MAX_POTION, FULL_HEAL, REVIVE, MAX_REPEL
	ASSERT BANK(IndigoPlateauLobbyClerkText) == BANK(IndigoPlateauLobby_TextPointers)


SECTION "Mart Inventories 07", ROMX, BANK[$07]

ViridianMartClerkText::
	script_mart POKE_BALL, ANTIDOTE, PARLYZ_HEAL, BURN_HEAL
	ASSERT BANK(ViridianMartClerkText) == BANK(ViridianMart_TextPointers)

FuchsiaMartClerkText::
	script_mart ULTRA_BALL, GREAT_BALL, SUPER_POTION, REVIVE, FULL_HEAL, SUPER_REPEL
	ASSERT BANK(FuchsiaMartClerkText) == BANK(FuchsiaMart_TextPointers)


SECTION "Mart Inventories 12", ROMX, BANK[$12]

CeladonMart4FClerkText::
	script_mart POKE_DOLL, FIRE_STONE, THUNDER_STONE, WATER_STONE, LEAF_STONE
	ASSERT BANK(CeladonMart4FClerkText) == BANK(CeladonMart4F_TextPointers)

CeladonMart5FClerk1Text::
	script_mart X_ACCURACY, GUARD_SPEC, DIRE_HIT, X_ATTACK, X_DEFEND, X_SPEED, X_SPECIAL
	ASSERT BANK(CeladonMart5FClerk1Text) == BANK(CeladonMart5F_TextPointers)

CeladonMart5FClerk2Text::
	script_mart HP_UP, PROTEIN, IRON, CARBOS, CALCIUM
	ASSERT BANK(CeladonMart5FClerk2Text) == BANK(CeladonMart5F_TextPointers)


SECTION "Mart Inventories 15", ROMX, BANK[$15]

CeladonMart2FClerk1Text::
	script_mart GREAT_BALL, SUPER_POTION, REVIVE, SUPER_REPEL, ANTIDOTE, BURN_HEAL, ICE_HEAL, AWAKENING, PARLYZ_HEAL
	ASSERT BANK(CeladonMart2FClerk1Text) == BANK(CeladonMart2F_TextPointers)

CeladonMart2FClerk2Text::
	script_mart TM_DOUBLE_TEAM, TM_REFLECT, TM_RAZOR_WIND, TM_HORN_DRILL, TM_EGG_BOMB, TM_MEGA_PUNCH, TM_MEGA_KICK, TM_TAKE_DOWN, TM_SUBMISSION
	ASSERT BANK(CeladonMart2FClerk2Text) == BANK(CeladonMart2F_TextPointers)


SECTION "Mart Inventories 17", ROMX, BANK[$17]

CeruleanMartClerkText::
	script_mart POKE_BALL, POTION, REPEL, ANTIDOTE, BURN_HEAL, AWAKENING, PARLYZ_HEAL
	ASSERT BANK(CeruleanMartClerkText) == BANK(CeruleanMart_TextPointers)

VermilionMartClerkText::
	script_mart POKE_BALL, SUPER_POTION, ICE_HEAL, AWAKENING, PARLYZ_HEAL, REPEL
	ASSERT BANK(VermilionMartClerkText) == BANK(VermilionMart_TextPointers)

LavenderMartClerkText::
	script_mart GREAT_BALL, SUPER_POTION, REVIVE, ESCAPE_ROPE, SUPER_REPEL, ANTIDOTE, BURN_HEAL, ICE_HEAL, PARLYZ_HEAL
	ASSERT BANK(LavenderMartClerkText) == BANK(LavenderMart_TextPointers)

SaffronMartClerkText::
	script_mart GREAT_BALL, HYPER_POTION, MAX_REPEL, ESCAPE_ROPE, FULL_HEAL, REVIVE
	ASSERT BANK(SaffronMartClerkText) == BANK(SaffronMart_TextPointers)


SECTION "Mart Inventories 1D", ROMX, BANK[$1D]

PewterMartClerkText::
	script_mart POKE_BALL, POTION, ESCAPE_ROPE, ANTIDOTE, BURN_HEAL, AWAKENING, PARLYZ_HEAL
	ASSERT BANK(PewterMartClerkText) == BANK(PewterMart_TextPointers)

CinnabarMartClerkText::
	script_mart ULTRA_BALL, GREAT_BALL, HYPER_POTION, MAX_REPEL, ESCAPE_ROPE, FULL_HEAL, REVIVE
	ASSERT BANK(CinnabarMartClerkText) == BANK(CinnabarMart_TextPointers)
