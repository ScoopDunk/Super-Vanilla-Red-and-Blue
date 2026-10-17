SECTION "Fast Video Copy", ROM0

; INSTANT BATTLE START
; While a battle's intro is being skipped the screen is black, and the pics, the font and
; the HUD tiles still have to be loaded. CopyVideoData does that 8 tiles per frame during
; VBlank, which for a battle adds up to about 40 frames. These routines do the same copy
; in the gaps between scanlines, 8 bytes at a time, and need about 8 frames altogether.
; The LCD stays on: turning it off would be faster still, but a GBC shows a white screen
; while it is off.

; Waits until VRAM can be written. Returns with interrupts disabled. The caller has time
; for 8 writes and must then enable interrupts again.
;
; The wait is for the start of an HBlank. HBlank is at least 87 dots long and is followed
; by 80 dots of OAM scan, during which VRAM is still writable, so there are at least 167
; dots (83 machine cycles in double speed mode, which this game always runs in) before
; the next line starts drawing. The polling loop notices HBlank at most 11 cycles late and
; the callers' 8 writes are done 55 cycles after that at the latest.
; During VBlank nothing is written, and interrupts are let through.
WaitForVRAMAccess::
	ldh a, [rLCDC]
	add a
	jr nc, .lcdOff ; VRAM is always writable
.restart
	di
.leaveHBlank ; if already in HBlank, there is no telling how much of it is left
	ldh a, [rSTAT]
	and STAT_MODE
	jr z, .leaveHBlank
.waitForHBlank
	ldh a, [rSTAT]
	and STAT_MODE
	ret z ; HBlank has just begun
	dec a ; STAT_VBLANK?
	jr nz, .waitForHBlank
	ei ; let the VBlank handler run on time
	jr .restart
.lcdOff
	di
	ret

MACRO fast_copy_video_data
	inc c
	dec c
	ret z
	push hl
	push de
	push bc
	ldh a, [hLoadedROMBank]
	push af
	ld a, b
	ldh [hLoadedROMBank], a
	ld [rROMB], a
.tileLoop
	ld b, 2 ; two bursts of eight writes fill one tile
.burstLoop
	call WaitForVRAMAccess
IF \1 == 2
REPT 8
	ld a, [de]
	ld [hli], a
	inc de
ENDR
ELSE
REPT 4
	ld a, [de]
	ld [hli], a
	ld [hli], a
	inc de
ENDR
ENDC
	ei
	dec b
	jr nz, .burstLoop
	dec c
	jr nz, .tileLoop
	pop af
	ldh [hLoadedROMBank], a
	ld [rROMB], a
	pop bc
	pop de
	pop hl
	ret
ENDM

; copy c 2bpp tiles from b:de to hl, like CopyVideoData
FastCopyVideoData::
	fast_copy_video_data 2

; copy c 1bpp tiles from b:de to hl, like CopyVideoDataDouble
FastCopyVideoDataDouble::
	fast_copy_video_data 1
