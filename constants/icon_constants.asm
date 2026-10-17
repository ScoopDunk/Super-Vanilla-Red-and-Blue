; party menu icons
; used in MonPartySpritePointers (see data/icon_pointers.asm)
	const_def
	const ICON_MON         ; $0
	const ICON_BALL        ; $1
	const ICON_HELIX       ; $2
	const ICON_FAIRY       ; $3
	const ICON_BIRD        ; $4
	const ICON_WATER       ; $5
	const ICON_BUG         ; $6
	const ICON_GRASS       ; $7
	const ICON_SNAKE       ; $8
	const ICON_QUADRUPED   ; $9
	const_skip 4
	const ICON_TRADEBUBBLE ; $e

DEF ICONOFFSET EQU $40 ; difference between alternating icon frames' tile IDs


; the unique party icons (engine/gfx/party_mon_icons.asm), one per Pokémon
DEF PARTY_MON_ICON_TILES  EQU 8 ; both 16x16 frames
DEF PARTY_MON_ICON_FRAME  EQU 4 ; tiles from the first frame to the second

; the box grid of Bill's PC (engine/pokemon/box_grid.asm)
; background tiles: 21 sets of 4 (twenty places and a spare), then the second frame of
; the icon under the cursor
DEF BOXGRID_BOX_ICON_TILES  EQU 4
DEF BOXGRID_HOVER_TILE      EQU (MONS_PER_BOX + 1) * BOXGRID_BOX_ICON_TILES
; the row of the first row of box icons on the screen; a row of icons every three
DEF BOXGRID_BOX_Y           EQU 2
; background palette 7 is the text's (and the gray Pokémon's), sprite palette 7 the cursor's
DEF BOXGRID_TEXT_PALETTE    EQU 7
DEF BOXGRID_CURSOR_PALETTE  EQU 7
; the colours a Pokémon can have: PAL_MEWMON to PAL_GRAYMON
DEF NUM_ICON_COLOR_CLASSES  EQU 10
