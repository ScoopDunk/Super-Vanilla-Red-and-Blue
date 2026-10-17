; SWITCH in the party menu. SwitchPartyMon ends here instead of in RedrawPartyMenu_: the
; two Pokémon that changed places need their icons loaded again before the menu is
; drawn, because a party slot always uses the same sprite tiles. In a section of its own
; at the end of the menu's bank, so that nothing in that bank moves.

RedrawPartyMenu_SwitchedIcons:
	ASSERT BANK(RedrawPartyMenu_) == BANK(@), "has to be in the party menu's bank"
	farcall LoadSwitchedPartyMonIcons
	jp RedrawPartyMenu_
