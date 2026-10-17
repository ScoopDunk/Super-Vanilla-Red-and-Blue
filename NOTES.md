# Super Vanilla Red and Blue: technical notes

How each feature works and where it is in the source. For the list of features and how
to patch or build the game, see [README.md](README.md).

This tree is [pokered-gbc](https://github.com/dannye/pokered-gbc) (the source of the
"Full Color" patches, at commit c1a3b6c5) with the "Shiny + Gender Indicators + RNG
Patch v1.1" ported onto it, and everything described below added. The shiny patch ships
without source, so its changes were recovered by diffing its IPS against the pokered
disassembly and rewritten here.

## Why the two IPS files could not be stacked

Both patches are rebuilds of the whole game, not small in-place edits. Each one inserts
code into the home bank and the battle engine, which moves everything after it, so
nearly every pointer in the ROM changes. The two patches disagree on about 7,700 bytes
in bank 0 alone, 12,500 in the battle bank and so on. The shiny patch also inserts 7
bytes into WRAM, shifting every later RAM address by 7. Applying one on top of the other
overwrites half of the first with pointers meant for a different layout.

## What is in the build

From the color hack: full GBC color, the Gen 2 style HP bar, EXP bar in battle and on
the status screen, caught Poké Ball icon on wild enemies, original Red/Blue sprites.

From the shiny patch: a sparkle next to the name of any Pokémon that will be shiny in
Gen 2, a ♂/♀ symbol next to its level (the gender Gen 2 will assign), shown in both
battle HUDs and on the status screen, and the replacement random number generator that
lets wild Pokémon roll shiny DVs (1 in 8192).

From the Fast Red patch (rewritten in source, so it is in Blue as well): hold B to move
faster. On foot that is bike speed (2x). On the bike it is 4x. Surfing moves at bike
speed as well: 2x, and 4x with B.

Modeled on Shin Pokémon: an INSTANT TEXT option in the options menu that prints text
with no per-letter delay.

The bag holds 50 stacks instead of 20 (pret wiki, "Increase Bag Space"), with save
compatibility kept.

Battles start instantly: no transition, no trainers sliding in, no opening messages, no
send-out animations. The screen cuts to black and comes back on the battle menu with
both Pokémon out.

Saving no longer waits: the two-second "Now saving..." message and the pauses around it
are gone (pret wiki, "Remove Artificial Save Delay").

Cut, Surf and Strength can be used by pressing A in front of a small tree, water or a
boulder (pret wiki, "Use Cut, Surf, and Strength From the Overworld").

START in the bag, or in the PC's item lists, sorts the items (pret wiki, "Add Item
Sorting In Bag").

When a Repel wears off and there is another in the bag, the game asks whether to use it.

A fifth option, HP/EXP BAR SPEED, makes the HP and EXP bars move at NORMAL speed, twice
as fast, or jump straight to the new amount.

BATTLE ANIMATION has a third choice, FAST: animations off, and every wait that only paces
a battle taken out as well ("Fast battles"). A turn in which both sides land a plain hit
takes half a second instead of four and a half.

Three conveniences from pureRGB, rewritten for this tree: Bill's PC shows how many
Pokémon are in the current box; when a caught or received Pokémon goes to the box, the
game says how many slots the box has left, or that it is full now; and the low health
alarm rings three times and stops ("Box count and box space", "Low health alarm").

Two places where a link session could freeze before any trade or battle began are closed
on this game's side: the "Where would you like to go?" menu when the other game clocks
the cable and walks into the room first, and the start of the party data when the other
game is not listening yet ("Link cable timing"). What goes over the cable is unchanged.

Every Pokémon has its own party icon instead of one of ten shared shapes (pret wiki,
"Add All Unique Party Menu Sprite Icons"; the icons were drawn by Blue Emerald, Chamber_,
Soloo993 and others). They are in the party menu, on the nickname screen and in the box,
each in the colours its Pokémon has in battle ("Party icons").

Bill's PC has a new entry, MOVE PKMN: the open box as a grid of icons with the party
beside it, in the manner of the storage system of the third generation. A Pokémon is
picked up and put down somewhere else: in the box, in the party, or on another Pokémon,
and then the two change places. WITHDRAW, DEPOSIT and RELEASE are still there and work
as before ("Moving Pokémon in the box").

Save files move both ways between this build, the cartridge games, the color patch and
the shiny patch, and the build fails if a change would break that ("Save files and
where things are in the ROM").

## Build

Needs rgbds 1.0.x (1.0.1 and 1.0.4 build identical ROMs).

    make            # pokered.gbc and pokeblue.gbc
    make compare    # checks both against roms.sha1, the released games

Two switches at the top of `includes.asm`:

    GEN_2_GRAPHICS  1 = Gen 2 HUD, EXP bar, caught icon, font, text boxes
    GEN_2_SPRITES   0 = original Red/Blue pics, 1 = Gold/Silver pics and palettes

Upstream only has `GEN_2_GRAPHICS`, which turns both on together. It was split so the
"vanilla sprites + EXP bar" flavor can be built. Setting both to 1 gives the Gen 2
graphics flavor with the indicators.

## Where the ported pieces live

    engine/pokemon/shiny_gender.asm   shiny test, gender table, HUD/status drawing
    engine/math/random.asm            xorshift RNG (byte-identical logic to the patch)
    home/init.asm                     RNG seeding
    home/vblank.asm                   per-frame RNG stirring
    engine/battle/core.asm            HUD hooks, shiny flag latching
    engine/battle/trainer_ai.asm      clears the enemy flag when a trainer switches
    engine/pokemon/status_screen.asm  status screen hook
    engine/menus/main_menu.asm        sparkle marker on the main menu
    gfx/gs/font.png, gfx/font/font.png  four new tiles at $DC-$DF ($DF is the sparkle)
    ram/wram.asm                      wRandomState, wRandomEntropy, wBattleShinyFlags

    engine/battle/core.asm            instant battle start (search INSTANT BATTLE START)
    engine/battle/common_text.asm     opening messages skipped
    home/fast_video_copy.asm          tile loading between scanlines while the screen is black
    home/copy2.asm, color/color.asm   hooks for the above
    ram/hram.asm                      hFastBattleIntro

    engine/overworld/field_moves_overworld.asm   Cut, Surf, Strength from the overworld
    engine/events/hidden_events/bookshelves.asm  where A on a tree or water is noticed
    home/overworld_text.asm           BoulderText hands over to the above
    engine/menus/swap_items.asm       SortItems, SortItemList
    data/items/sort_order.asm         the order items are sorted into
    home/list_menu.asm                START in a list menu
    engine/items/repel_prompt.asm     "Use another?" when a Repel wears off
    home/text_script.asm              DisplayRepelWoreOffText hands over to the above
    engine/items/item_effects.asm     ItemUseRepelCommon records the kind used

    engine/pokemon/calc_stats.asm     CalcStats and CalcStat, moved out of the home bank
    data/items/marts.asm              mart item lists, moved out of the home bank
    macros/farcall.asm, home/header.asm   one-byte rst calls for far calls and bank switches (home bank only)

    layout.link                       every map section pinned at its cartridge address
    data/maps/cartridge_addresses.asm, gfx/tileset_cartridge_addresses.asm,
    data/tilesets/collision_cartridge_addresses.asm   link-time checks on those addresses
    tools/make_cartridge_addresses.py writes the three files above
    home/overworld.asm                LoadMapHeader reads the header from the ROM on CONTINUE too
    engine/overworld/tilesets.asm     ReloadTilesetHeader, for the same

    home/fast_battle.asm              IsBattleFast, BattleDelayFrames, the hit effect without its blink (search FAST BATTLES)
    engine/battle/core.asm            hBattleFast set and cleared; fainting, sending out and switching without the slides
    engine/battle/animations.asm, effects.asm, move_effects/*.asm, engine/items/item_effects.asm
                                      the waits a FAST battle skips (every BattleDelayFrames)
    home/delay.asm, home/text.asm     sounds and text pauses are not waited for in a FAST battle
    audio/engine_2.asm                a note lasts at least one tick (the menu click that hung on its channel)
    engine/menus/main_menu.asm        BATTLE ANIMATION: ON / OFF / FAST
    ram/wram.asm, ram/hram.asm        wFastBattles, hBattleFast

    engine/pokemon/bills_pc.asm       BillsPCMenu: the count line in the corner box
    engine/pokemon/box_space.asm      PrintBoxSpaceLeft and its texts (bank $0C)
    engine/items/item_effects.asm     ItemUseBall calls it after "transferred to PC"
    engine/events/give_pokemon.asm    _GivePokemon calls it after "sent to BOX"
    audio/low_health_alarm.asm        the alarm counts its rings and switches itself off
    engine/battle/core.asm            DrawPlayerHUDAndHPBar starts it once per spell of low HP; SendOutMon re-arms it
    ram/wram.asm                      wLowHealthAlarmRings

    engine/link/link_menu_exchange.asm  the link menu's byte exchange for the clocked game, which no longer waits forever (bank 1)
    engine/menus/main_menu.asm        LinkMenu calls it
    engine/link/cable_club.asm        the clocking game waits for the other game's preamble byte before the party data
    constants/serial_constants.asm    LINK_DATA_START_TRIES, LINK_MENU_QUIET_PASSES

    gfx/icons/party_mon_icons.png     151 icons, two 16x16 pictures each (banks $2D and $2E)
    engine/gfx/party_mon_icons.asm    finding an icon, loading it, the party menu's and the nickname screen's sprites
    color/icon_palettes.asm           each icon in its Pokémon's colours; the colours of the box grid
    engine/menus/party_menu.asm, start_sub_menus.asm, naming_screen.asm, engine/gfx/mon_icons.asm
                                      the places that loaded and placed the shared shapes (same-size edits)
    engine/menus/party_menu_switch.asm  where SWITCH goes to have its two icons loaded (the last 11 bytes of bank 4)
    engine/pokemon/box_grid.asm       MOVE PKMN: the box grid (bank $2F)
    engine/pokemon/box_grid_mon_info.asm  gender and shiny mark for the grid, next to the code that knows them (bank $15)
    engine/pokemon/bills_pc_menu.asm  the PC's menu with six entries, and where each one goes
    engine/pokemon/bills_pc.asm       BillsPCMenu hands over to the above (same-size edits)
    constants/icon_constants.asm, ram/wram.asm   the grid's constants and its variables (in the screen buffer's union)

    engine/gfx/hp_bar.asm             HP bar at double speed or instant (search BAR SPEED)
    color/exp_bar.asm                 EXP bar at double speed or instant
    engine/menus/main_menu.asm        the HP/EXP BAR SPEED row of the options menu
    ram/wram.asm                      wBarSpeed

    home/overworld.asm                DoBikeSpeedup: hold-B running and fast bike
    home/print_text.asm               zero text delay
    engine/menus/main_menu.asm        options menu with the INSTANT TEXT row

## Running (hold B)

`DoBikeSpeedup` is now called for every step and decides how many extra advances the
player gets that frame. A step is 8 advances, so the total per frame is always 1, 2 or
4 and a step can never overshoot.

    on foot          1      with B  2
    bike             2      with B  4
    bike, Cycling Road against the slope   1   with B  2
    surfing          2      with B  4

Nothing speeds up during scripted NPC movement (Oak walking you to the lab and the
like) or while jumping a ledge, same as the bike in the original game.

In the original game surfing is walking speed and ignores B. Here it takes the bike's
path through `DoBikeSpeedup`. The strong current in the Seafoam Islands, which moves you by simulated
button presses, carries you along the same tiles as before at 2x; B makes no difference
there because the simulated buttons replace the real ones.

Differences from the Fast Red IPS: it dropped the Cycling Road slope rule (the bike was
always fast there) and, on foot, the check that turns the boost off during scripted NPC
movement. Both original rules are kept here. It also used a spare RAM byte ($D711) as a
flag, which is not needed. It left surfing at walking speed.

## Instant text

Stored the way Shin Pokémon stores it: a text delay of 0 in the low bits of `wOptions`.
No new save data. A save with INSTANT TEXT on loads in an unpatched game with the
delay still 0; since that is not a value its menu knows, opening its options screen
switches it to MEDIUM.

The options screen has a row of its own for this (and one for the bar speed, see "HP
and EXP bar speed"). Picking ON sets the delay to 0. Picking a TEXT SPEED turns INSTANT TEXT off again; turning it off
by hand falls back to FAST.

Link play is not affected: while linked, the game ignores the text speed setting and
prints one letter per frame, and that path is untouched.

## Saving

From the pret wiki tutorial "Remove Artificial Save Delay". The game is fully written to
the save by the time "Now saving..." appeared; that message and its 120 frame wait are
removed, the wait after the jingle is 10 frames instead of 30, and the pause after the
PLAYER/BADGES/POKéDEX/TIME box is drawn is 5 frames instead of 30
(`engine/menus/save.asm`, `PrintSaveScreenText` in `engine/menus/main_menu.asm`). With
INSTANT TEXT on, choosing SAVE to walking again takes about 1.2 seconds instead of 3.9.
What is left is mostly the save jingle.

The tutorial's optional step of dropping the "Would you like to SAVE the game?" question
was not taken, so SAVE still asks before overwriting.

## Cut, Surf and Strength from the overworld

Press A facing a small tree, surfable water or a boulder:

    tree      "This tree can be CUT."              then "Would you like to use CUT?"
    water     "The water is calm."                 then "Would you like to use SURF?"
    boulder   "This requires STRENGTH to move!"    then "Would you like to use STRENGTH?"

The question only comes up if a Pokémon in the party knows the move and you have the
badge it needs (Cascade, Soul, Rainbow), the same conditions as in the party menu.
Without them you just get the first line. A boulder that can already be pushed says
"Boulders can now be moved." The party menu still works as before.

This follows the wiki tutorial in behaviour, but it is arranged differently:

- The tutorial puts its three text scripts in the home bank, which is short of space
  here (see "Home bank space"). Here everything is in bank 3
  (`engine/overworld/field_moves_overworld.asm`), next to the routines the party menu
  uses, and only `BoulderText` grew, by 7 bytes.
- A tree or water is found by asking the game's own routines (`UsedCut`'s tile check,
  `IsNextTileShoreOrWater`, the water tile pair collisions) instead of a second list of
  tile IDs, so the prompt appears exactly where the move would work. That also replaces
  the tutorial's special case for elevated ground.
- Saying YES runs the party menu's own code: `UsedCut` (entered at `UsedCut_Animate`,
  after the part that returns from the menu), `ItemUseSurfboard` through `UseItem`,
  `PrintStrengthText`. No new RAM is used; the tutorial's `wSearchedMove` is not needed.
- If someone is standing on the water in front of you, or there is a sign, A talks to
  them as before. In the tutorial the water text would win.
- While surfing, A on water does nothing, as in the tutorial, but hidden items and the
  like are still checked (the tutorial skips them while surfing).

## Sorting items

START in an item list opens a small SORT / CANCEL box. It works wherever the bag is
shown (start menu, battle, selling in a mart, depositing in the PC) and in the PC's own
item lists (withdraw, toss). SORT puts the list in the order of
`data/items/sort_order.asm` (the wiki tutorial's order: used key items, rods, balls,
repels, healing, status, PP, battle items, vitamins, stones, valuables, fossils, other
key items, TMs, HMs) and shows it from the top.

Differences from the tutorial:

- It asks with SORT / CANCEL inside the list box instead of a question in the text box
  at the bottom. The tutorial needs flags borrowed from the overworld engine to work out
  which of four screens it is on and what to put back afterwards; this way nothing
  outside the list box is touched and no "Sort complete" message has to be dismissed.
- Stacks of the same item that end up next to each other are joined (up to 99), the way
  swapping one onto the other with SELECT joins them. That also tidies up the two
  stacks the 50-slot bag can end up with after a round trip through an original game.
- Several stacks of one item are all moved (the tutorial moves the first one only).

START does nothing in lists that are not item lists (the mart's BUY list, Pokémon lists).

## Another Repel?

When the last step of a REPEL, SUPER REPEL or MAX REPEL is used up, "REPEL's effect wore
off." is followed by a YES / NO question if the bag holds any of the three. YES uses one
through the normal item code ("<PLAYER> used SUPER REPEL!", the sound, one taken from the
bag), NO or B closes the box. With none in the bag the message is the original one.

Which one is offered: the kind used last if there is still one of it, asked as "Use
another?". Otherwise the strongest kind in the bag, asked by name ("Use a MAX REPEL?")
so a different kind is never used unseen. The kind used last is kept in `wLastRepelUsed`
($D496), one of the saved bytes after the bag that the original games leave unused, so
it survives saving and an original game carries it through untouched.

The pret wiki's "Repel QoL Improvements" does the same job from the home bank, with a
copy of the repel effect for each kind and always the strongest kind. The home bank has
no room for that here, so this version lives in bank 3 next to the item code and calls
`UseItem` instead of copying it; `DisplayRepelWoreOffText` in the home bank is the same
size as before. The first half of that tutorial (refusing a Repel while one is active)
is not included.

How long a Repel lasts is unchanged, including the original quirk that turning on the
spot counts as a step.

## HP and EXP bar speed

HP/EXP BAR SPEED on the options screen: NORMAL, 2× or INSTANT. It applies to every HP
bar that animates (both sides in battle, and the party menu when an item heals) and to
the EXP bar after a knockout.

- NORMAL is the original timing, frame for frame.
- 2×: the HP bar moves 2 HP per step instead of 1 and waits one frame per pixel instead
  of two; the EXP bar grows two pixels a frame and its pause at the end is 16 frames
  instead of 32. Both take half as long.
- INSTANT: the bar and the HP number are drawn once at the new amount. The EXP sound
  still plays.

Frames measured on the same battle state (NORMAL / 2× / INSTANT):

    your bar, 300 -> 1 HP            400 / 203 / 6
    your bar, 45 -> 20 HP             86 /  46 / 6
    healed 10 -> 290 of 300          377 / 191 / 6
    foe's bar, 300 -> 150 HP          78 /  29 / 5
    EXP bar, empty to nearly full     95 /  48 / 4
    Super Potion in the party menu    98 /  52 / 7

The original spends a frame on every single HP of your own bar (to print the number)
plus two frames per pixel, which is why a big hit on a high-HP Pokémon takes six
seconds. The foe's bar has no number, so it was already quicker; at 2× it gains more
than double because the arithmetic done for every HP is halved as well.

Whatever the setting, the game ends up in the same state: the final picture (bar colors
included), the tile map and the HP variables are identical. In INSTANT mode that needed
one detail: `DrawHPBar` decides from register c whether an empty bar still shows a
one-pixel sliver, and the loop being skipped is what normally leaves the right value
there.

The setting is `wBarSpeed` ($D497), the saved-but-unused byte after `wLastRepelUsed`,
not a bit in `wOptions`: bits 4-5 of `wOptions` are free in Red/Blue, but an original
game shows and stores MEDIUM text speed as soon as its options screen is opened with
them set. A byte of its own is ignored and carried along by an original game. It is
kept through NEW GAME the way `wOptions` is (`PrepareOakSpeech`), so a choice made on
the title screen sticks; any value other than the three settings counts as NORMAL.

The original options screen has no room for a fifth box, so here it is one frame with a
dividing line between options (boxes that share their top and bottom lines), three rows
per option instead of four, CANCEL below.

Link battles: the bars are drawn by each game for itself and the two sides only meet at
the next move choice, so each player can use a different setting. A link battle with
INSTANT on this side against an original Red stayed in step at every turn.

Shin Pokémon speeds the HP bar up too, by halving the wait per pixel for everyone; no
hack with a three-way setting was found, so this one is new.

## Fast battles

BATTLE ANIMATION on the options screen reads ON, OFF, FAST.

OFF is the original setting, and it is slower than it sounds. With the animations off
the game still waits half a second where a move's animation would have been, still
blinks the target six times or shakes the screen, and still waits for every sound and
cry to finish. Around that are pauses before and after messages, the fainted Pokémon
sliding down, the trainer's pic sliding out and back, and the next Pokémon growing out
of its ball.

FAST is OFF with all of that taken out:

- a move: no pause in place of the animation, no blink or shake. The sound of the hit
  still plays (it is how a super effective hit differs from a weak one), nothing waits
  for it;
- no half-second pauses before "But, it failed!", a miss, a stat change, a status
  taking hold, the hurt from poison, burn or Leech Seed;
- a Pokémon that faints is gone at once; the next one, yours or the trainer's, is
  simply there, with its cry started and not waited for; switching the same way;
- the trainer's pic is there at once when the battle is won;
- sounds, cries and jingles (level up, the catch fanfare) never hold the battle up;
- a thrown ball flies and wobbles as before, since the wobbles are the news, but the
  two-thirds of a second before each wobble is gone. A catch takes 2.8 seconds from the
  throw instead of 5.1;
- the substitute doll is swapped out and in at once around each move.

What FAST leaves alone: every message that waits for a button still does. The HP and
EXP bars follow their own option. Menus, the instant battle start and what follows a
battle (an evolution plays as it always did) are untouched. Link battles and the old
man's catching lesson run at the pace of OFF.

The messages that do not wait for a button ("X used Y!", "Go! X!", "X sent out Y!")
are on screen for about a sixth of a second with the bars at INSTANT, longer when the
bars animate. That is the price of the speed; the prompts that follow a move (critical
hit, effectiveness, stat changes, misses, fainting) all still stop.

Frames the game spends not waiting for a button, same battle and same rolls, INSTANT
TEXT on and bars at INSTANT unless noted (60 frames = 1 second):

                                                        OFF   FAST   (frames)
    a turn, both sides land a plain hit (TACKLE)            265     32
    a turn, both use a stat move (GROWL)                    212     20
    a turn, both hit with a side effect (THUNDERSHOCK)      222     34
    the same plain hits with the bars at NORMAL             314     81
    the same plain hits with the bars at 2×                 287     53
    a trainer's Pokémon is knocked out: move to "fainted!"  308     31
    the trainer's next Pokémon, after the EXP message       143     43
    switching your Pokémon (the foe attacks once)           291     57
    your Pokémon faints: its last turn to "fainted!"        226     17
    the last foe is down: "defeated" to the prize money      93     29
    POKé BALL thrown to "All right! X was caught!"          305    165
    RUN chosen to walking again                              94     44
    whole battle, Youngster (2 Pokémon, 2 turns)            889    240
    whole battle, Erika (weak team, 14 turns)              4289    880
    whole battle, Koga (weak team, 18 turns)               5365   1185

One run of 69 scripted battles (trainers, gym leaders and Elite Four members with their
items and switches, wild battles, catching, items, status moves, fainting, blacking out,
the Safari Zone) spent about 138,000 frames waiting with OFF and about 36,000 with FAST.

How it works. `hBattleFast` is worked out once when a battle begins
(`SetFastBattleIntro` in `engine/battle/core.asm`): set if the animations are off in
`wOptions` and `wFastBattles` is 1, never in a link battle or the old man's. It is
cleared when the battle is over, or sooner if a Pokémon is about to evolve. Three
small routines in the home bank (`home/fast_battle.asm`) do the rest:

- `IsBattleFast` returns the flag.
- `BattleDelayFrames` is `DelayFrames` that returns at once in a FAST battle (with the
  registers `DelayFrames` leaves). Every wait that only paces a battle calls it instead
  of `DelayFrames`: 33 places in the battle engine, the move effects, the item code, the
  animation code and the text pause command, each the same size as before.
- `WaitForSoundToFinish` returns at once in a FAST battle. The original already does
  exactly that whenever the low health alarm is sounding, so every caller is known to
  cope. `PlayCry` and the sound commands in texts go through it.

The rest is a handful of spots that do something instead of waiting: the hit effect
(`BattleApplyingAttackAnimation`), the fainting slide, the growing and shrinking pics
(`IsFastBattle`, the same test the instant battle start uses), the faint sound of
a trainer's Pokémon (one thud instead of fall, wait, thud), and the Poké Flute's tune
in battle.

Nothing a FAST battle computes is different. That was the test: with the random
numbers made independent of timing, the same battle was played with OFF and with FAST
and compared at every point where the game waits for a button (tile map, both
Pokémon, both parties, statuses, stat stages, bag, money, Pokédex): every move used by
either side, and 175 whole battles of 42 kinds. The picture on screen at those points
is the same too, pixel for pixel.

The setting. FAST is animations off in `wOptions` plus `wFastBattles` ($D498, save
offset $2744), the next saved byte the original games leave unused. An original game
sees animations OFF and carries the byte along. If it is used to turn the animations
back on, this build shows ON, not FAST: the byte only counts together with the bit.
Like the other options it survives NEW GAME when set on the title screen. The options
screen did not grow: the BATTLE ANIMATION row has three choices, like the bar speed
row, and the two rows share the code that steps through them.

Shin Pokémon was looked at for this (its source is what the instant text and the HP
bar speed-up were modelled on). Its animations-off path has the same half-second pause
and the same blink as the original, so there was nothing to take over.

### The click that hung

A fault the instant battle start exposes with any animation setting, found while timing
FAST battles. The battle sound engine gives every
sound effect the tempo of whatever is on the noise channel, if that is a cry or a
battle sound (`Audio2_IsBattleSFX`; the overworld engine has no such rule). A cry can
have a tempo below 1, and at such a tempo a one-tick note, which is what the menu
click is made of, can come out as zero ticks. The note counter takes zero for 256: the
click sits on its channel for over four seconds, the music loses that channel
meanwhile, and anything that waits for sounds to end waits with it. The original game
never plays a click over a cry, because it waits for cries. The instant battle start
does not, so pressing A in the wrong fraction of a second after the menu opened froze
the first move, or RUN, for four and a half seconds.

Measured without the fix: 150 species as the wild foe, FIGHT pressed at each of 20
moments in the first second after the menu opens and the first move chosen right away,
3000 battle starts in all. The click hung in 190 of them (6.3%), with 28 of the species,
and the turn then took up to 473 frames. With the fix, with OFF and with FAST: 0 of 3000.

`Audio2_note_length` makes a note last at least one tick. Nothing else about the
sound engine changed, and no sound in the game has a zero-length note by design. FAST
battles needed this too: they play clicks over hit sounds all the time.

## Box count and box space

Two lines from pureRGB's feature list: "When viewing Bills PC, it'll always tell you
how many pokemon are in the current box" and "The game will tell you how many slots
are left in your box after catching a pokemon, and when the box is full". pureRGB
builds them on its own PC menu (box names kept in SRAM, new tiles, new RAM), so they
were written again here on the original menu.

The PC. The small box in the corner of the storage menu had two lines and used one:
"BOX No. 3" on the lower line. The number is on the upper line now, and the lower one
reads "PKMN  7/20" (the PKMN is the game's two-tile symbol). `BillsPCMenu` draws it,
and every deposit, withdrawal, release and box change comes back through there, so the
count is always the current one. It stays on screen under the list while a Pokémon is
being picked.

After a catch or a gift. When the party is full and the new Pokémon goes to the box,
one more message follows "transferred to BILL's PC!" or "sent to BOX 3 on PC!":

    14 slots left in        1 slot left in        BOX 3 is now          Time to change
    BOX 3.                  BOX 3.                full.                 boxes!

The last pair is the one that matters. With a full box and a full party the original
games refuse to throw a ball at all, and nothing in them says the box has just filled
up.

`PrintBoxSpaceLeft` (`engine/pokemon/box_space.asm`, in a section of its own in bank
$0C together with its three texts) is called from `ItemUseBall` and from
`_GivePokemon`, which is every gift and prize: Eevee, Lapras, the fossils, the dojo
prize, the Magikarp, the Game Corner counter. After a catch it waits for a button, as
the message before it does. After a gift it leaves the text up for the calling script
to end, as "sent to BOX" used to; that text now ends with a button wait instead (one
byte for another, so the text bank did not move). The two numbers are written to
`wBoxNumString`, scratch bytes the deposit message already uses, and printed with the
text engine's number command.

## Low health alarm

The alarm rang for as long as the HP bar was red. It now rings three times (a second
and a half) and stops. pureRGB took this from Shin Pokémon; the version here is
shorter and behaves a little differently, see below.

How the original works: every time the player's HUD is drawn with a red bar,
`DrawPlayerHUDAndHPBar` sets bit 7 of `wLowHealthAlarm`, and with that bit set
`Music_DoLowHealthAlarm` (run every frame while battle music plays) writes the high
tone, twenty frames later the low tone, and starts over. Only a HUD drawn with a bar
that is not red, a healing item, a faint or the end of the battle clears the bit.

Now there is a counter, `wLowHealthAlarmRings` ($CCF8, one of thirteen unused and
unsaved bytes behind `wPlayerMonMinimized`). The HUD code starts the alarm only when
the counter is 0, and sets it to 4. The alarm takes one off before each high tone and,
at what would be the fourth, switches itself off the way the game always switched it
off (bit cleared, channel released, silence written). The counter stays at 1, so
further HUD redraws with a red bar start nothing. A HUD drawn with a bar that is not
red sets it back to 0, and so does `SendOutMon`.

So it rings three times

- when HP drops into the red,
- again when HP has been out of the red (healed, or drained back up) and drops in again,
- when a Pokémon is sent out with HP in the red, at the start of a battle or on a
  switch, including one that was out before,

and not again while HP stays red: not on later hits, not when the foe sends out its
next Pokémon, not after a Potion that leaves the bar red (the original starts ringing
again there). A faint, a win or a heal in the middle of the three rings cuts them
short as before. Shin Pokémon and pureRGB re-arm only while the alarm is off and the
bar is not red, so there, going by the code, a second Pokémon sent out in the red right
after another one rang stays silent.

One fault of the original only matters now that the rings can be counted. The alarm
marks the sound channel as taken on every tick except the one that plays the high tone,
so on its very first tick the music could still write a note of its own over that tone.
With an alarm that never stops that is one ring in dozens. With three it was the first
of the three, in 7 of 171 test cases: the first beep came out as a note of the music.
The channel is marked on that tick too now.

What follows from the alarm really being off afterwards, rather than muted: the music
gets its first channel back (in the original it loses it for as long as HP is red),
sound effects on that channel play again, the POKé FLUTE plays its tune, and the game
waits for sound effects to end the way it does at normal HP. With the alarm on,
`WaitForSoundToFinish` returns at once, so the original runs slightly faster while HP
is red; over 42 test battles with animations OFF the short alarm costs 0.4% more
frames than the endless one, all of it in battles where HP got that low. FAST battles
do not wait for sounds in the first place and take the same number of frames either
way.

## Link cable timing

Trading and battling over the cable use the original code, and a Pokémon traded from
this build is byte for byte what a cartridge would have sent. Two things about when this
game sends and how long it waits are changed. Both were found with two emulated
consoles whose frames were shifted against each other in small steps. The first freeze
happens with unmodified Red and Blue cartridge ROMs as well, more often than with this
build; the second comes from the frame wait of the original game on the other side.

The link menu. After both players have saved at the Cable Club, the two games agree on
TRADE CENTER or COLOSSEUM by swapping a menu byte three times and keeping the last two.
The game that clocks the cable stops clocking as soon as it is satisfied: a Gen 2 game
at the Time Capsule sends its choice until one byte has come back and then walks into
the room. The clocked game waits for each of its three bytes for as long as it takes.
When the clocking game's bytes arrive right after the clocked game's VBlank, the clocked
game catches only every other one, and if it got to "Please wait." first, the other
game's first byte is used up by a leftover zero. The clocking game is then done one byte
before the clocked game is, and the clocked game sits at "Where would you like to go?"
for good with the other player already in the room. With a Gen 2 game clocking and the
Red/Blue player waiting first, that was 4 of 48 frame alignments for this game without
the change, 5 of 48 for the plain color hack and 10 of 48 for a clean Red.

`LinkMenu_ExchangeSelection` (engine/link/link_menu_exchange.asm, a section of its own
in bank 1) is the same exchange for the clocked game with one addition: it remembers
every menu byte the other game sends, and when no byte has come for about half a second
it goes on with the other game's choice, or with its own if the other game was in its
menu without one. A game still in its menu clocks a byte every few frames, so the wait
only ends this way when the other game has moved on. If nothing has come from the other
game's menu yet, it waits as the original does. The clocking game still uses
`Serial_ExchangeLinkMenuSelection`. With this, none of 48 alignments freezes, with Gold
or Crystal clocking and with either player waiting first.

The party data. Before the two games swap their parties (at the table, and again after
every trade), each counts off the same handshake, and the clocking game then sends two
zero bytes and starts the data. The data is sent back to back with every interrupt but
the serial one off, and the clocked game has to be in that state already: if its VBlank
interrupt is still running, it misses bits, the two games never line up again and both
stay on PLEASE WAIT!. The clocked game can be late: a byte that arrives just before its
VBlank can make its frame wait sleep through a frame. Seen at one frame alignment, a
few microseconds wide, in about 600 tries with this game clocking without the change
(the other game was a clean Red, and it lost six frames).

The clocking game sends its zero bytes one a frame until the other game answers with
the preamble byte of its data, which it only does once it is waiting with the other
interrupts off (`.sendZeroByteLoop` in `CableClub_DoBattleOrTradeAgain`). A game that is
ready on time answers the second zero byte, so this costs one frame; after 30 tries the
data starts regardless. Nothing changes when the other game clocks.

Not changed: the first contact at the Cable Club. A game standing in a Pokémon Center
re-arms its serial port every other frame, and if the other game's first byte is on the
cable at that moment, the link does not come up; both games say so after a few seconds
and the players talk to the attendants again. That is the original behaviour of both
generations (about 3 in 100 tries) and affects this build and a cartridge alike.

This build always runs the CPU at double speed, as the color hack does, so when it
clocks the cable it sends the party data at one byte per 0.70 ms instead of 1.28 ms. The
other game needs about 0.4 ms per byte; it had its next byte ready 0.24 ms or more before
it was needed in every one of over 100,000 bytes measured (0.85 ms with a cartridge
clocking).

## Party icons

The original games have ten icon shapes (a ball, a bird, a bug, a fish and so on) and
give each Pokémon one of them. This build has an icon for every Pokémon, after the pret
wiki tutorial "Add All Unique Party Menu Sprite Icons" by dannye; the icons were drawn
by Blue Emerald, Chamber_, Soloo993 and others. `gfx/icons/party_mon_icons.png` is the
tutorial's sheet rearranged (the sheet itself is kept beside it as
`party_mon_sprites_wiki.png`): two 16x16 pictures per Pokémon in Pokédex order, the
second below the first, so that a picture is four tiles in a row. 151 icons are 19,328
bytes: 128 of them fill bank $2D exactly and the rest are in bank $2E, so an icon's
address is its number times 128 with one bit choosing the bank
(`GetPartyMonIconPointer`).

The original loads all ten shapes when the party menu opens and picks tiles by shape.
Here the icons of the Pokémon that are present are loaded: party slot n always uses
sprite tiles n * 8 to n * 8 + 7 and sprite palette n, and each palette is the one the
Pokémon has in battle (`PartyMenuIconPalettes`, called where the color hack clears its
sprite palette map; in the color hack every icon has the colours of the player's
sprite). The
second picture is four tiles behind the first, so the animation is one add; the two
shapes that only shook up and down are gone with their special case. The icons move at
the pace the tutorial recommends, that of the second generation (a picture every 10
frames with a green bar, 24 with a yellow one, 32 with a red one; the original has 5,
16 and 32). When the menu opens, the icons are loaded with the LCD off, as the shapes
were; the screen has just been cleared. After SWITCH the two Pokémon that changed places
get their tiles and colours loaded during VBlank while their sprites are hidden
(`LoadSwitchedPartyMonIcons`), so the menu does not blink.

The nickname screen loads the one icon of the Pokémon being named, in its colours.

The trade animation still shows the ten shared shapes. Its code is the link code's, and
none of it is touched: an in-game trade gives the same 2,391 pictures with and without
the unique icons.

How the icons and the box grid were fitted in: nothing that existed before moved. Every
edit to old code has the size of what it replaces (a call to another routine, or the old
instructions blanked out), and everything new is in sections of its own. The symbol
files with and without them agree on every one of the 20,725 labels they share.

## Moving Pokémon in the box

MOVE PKMN is the third entry of Bill's PC. It shows the open box as five by four icons,
the party as a column at the right, and at the bottom the Pokémon under the cursor:
nickname, gender, level, the shiny mark, species and Pokédex number. A shiny Pokémon
also has the mark at the upper right corner of its icon, in the box and in the party.

    A        on a Pokémon: MOVE, STATS, RELEASE (box only), CANCEL
             with a Pokémon picked up: put it down here
             on the box's title: LIST (the list of boxes), SORT, CANCEL
    B        put it back; with nothing picked up, leave
    SELECT   the list of boxes
    START    the quick way on or off: A picks up at once, without the menu
             (the cursor is blue while it is on)
    left and right with the cursor on the title: the box before, the next box

The cursor gets onto the title by going up from the first row of the box (or down from
the last). A Pokémon that is picked up stays picked up through box changes, so it can be
carried to any box.

Where a Pokémon that is picked up can go:

    on another Pokémon of the same list       the two change places
    on a free place of the same list          it goes to the end of the list
    on a Pokémon of the other list            the two are exchanged between box and party
    on a free place of the other list         it is deposited or withdrawn
    carried from another box:
      on a free place of the open box         it moves to the end of the open box
      on a Pokémon of the open box            the two change boxes and places
      on a free place of the party            it is withdrawn from its box
      on a party member                       the two are exchanged

Two things are refused: putting the last Pokémon of the party on a free place of a box
(it can still be exchanged for one from the box), and an exchange between two boxes
that are both full (one of the two has to hold both Pokémon for a moment, see below).

SORT puts the open box in order of Pokédex number, of level (highest first) or of
nickname. Pokémon that are equal in that keep the order they had.

The storage format is the cartridge's and is not changed: a box is a count and a packed
list, so there are no gaps to leave, and "moving" means changing the order. That is why
a Pokémon put on a free place lands at the end of the list and the cursor follows it
there. Nothing happens to the data while a Pokémon is carried; it is only drawn at the
cursor instead of at its place.

Deposits, withdrawals and releases are the game's own `MoveMon` and `RemovePokemon`,
called the way the PC's lists call them. An exchange between box and party is something
the original cannot do without a free place in one of the two, so it is done in place
(`BoxGrid_ExchangeBoxAndPartyMon`): the 33 bytes a box entry and a party entry have in
common, the trainer name and the nickname change places, then the box entry gets the
level in its level byte and the party entry gets its level from its experience and its
stats calculated, which is what `MoveMon` does in the two directions. The result is
byte for byte what a deposit and a withdrawal give.

### Other boxes

How the game keeps boxes: only the open box is in work RAM. The other eleven are in
cartridge RAM, six to a bank ("slots"), and the open box is saved with the rest of the
game. CHANGE BOX copies the open box to its slot, copies the other one in and saves the
game; its copy routine empties what it copied from, so the slot of the open box is empty
while that box is open. The save is not optional: without it, a reset would come back
with the old box open and the new one's slot empty.

The grid's box change (`BoxStore_SwitchTo`, engine/pokemon/box_storage.asm) is that
change without its texts and its jingle, about a third of a second. The game's question
("When you change a POKéMON BOX, data will be saved. OK?") is asked at the first change
after the grid is opened and not again until the grid is left. The list of boxes is the
game's own menu; it shows how many Pokémon each box holds ("BOX 3  12/20") where the
original marked the boxes that are not empty with a ball, also when it is opened with
CHANGE BOX from the PC's menu (`BoxStore_DisplayBoxList`, which `DisplayChangeBoxMenu`
jumps to).

A Pokémon carried from another box is still in that box's slot when it is put down. The
work is done then, with the routines of box_storage.asm:

    BoxStore_MoveFromBox   an entry of another box becomes an entry of the open box
    BoxStore_MoveToBox     an entry of the open box becomes an entry of another box

Onto a Pokémon of the open box, both are used, one after the other. To the party, the
Pokémon's own box is made the open one, the grid does what it does between a box and
the party, and the box that was open is opened again. Every one of these saves the game,
as every box change does; they take from under half a second (a move to a free place)
to under a second (an exchange across boxes).

What a power cut leaves behind. The cartridge's save is not safe against one: while the
main save is being written, its checksum is wrong, and a console switched off then says
the file is destroyed. That is so for every SAVE of the original game and for these too,
for two to three frames per save. Beyond that the original's box change has a second
gap: from the moment the other box's slot is emptied to the end of the save, that box is
in no saved place (five frames on this build, eleven on a cartridge, which runs at half
the speed). The routines here are ordered so that this does not happen: a box is read
from its slot without emptying it and the slot is emptied after the save, and where a
Pokémon changes from one saved place to another, the place that receives it is written
first. A console switched off in between comes back with the Pokémon in both places,
not in neither. Two things remain:

- A slot that is rewritten with one entry more or less (the other box, when a Pokémon is
  carried between two boxes) is not whole for the third of a frame the copy takes.
- The game's save writes the box before the party. A withdrawal that has not been saved
  yet is therefore in neither for two frames of the next save, whichever save that is.
  When a Pokémon is carried from another box to a free place of the party, the party is
  saved first for that reason (`BoxStore_SaveParty`); when it is exchanged with a party
  member, one of the two is exposed whichever is written first, and the order is the
  game's.

All of this was measured by stepping an emulated console a few instructions at a time
and reading cartridge RAM the way the game's loader would.

### How it is drawn

Twenty icons as sprites would be 80 sprites, and the hardware shows 40, ten on a line.
So the box is background tiles: 21 sets of four tiles (twenty places and one spare),
with four more for the second picture of the icon under the cursor. The party, the
Pokémon that is carried and the cursor are sprites: seven sets of eight tiles. A set of
tiles belongs to a Pokémon, not to a place; two small tables say which set each place
shows, so reordering changes the tables and the tile map and loads nothing. A Pokémon
that changes sides is loaded into the spare set of the other kind first. The mark of a
shiny Pokémon is a tile in the free row above a box icon and a sprite at the corner of
a party icon.

Colours. Every icon has the palette its Pokémon has in battle. Sprites have eight
palettes, enough for the party, the carried Pokémon and the cursor. The background has
eight too: one is the text's, which gray Pokémon share, and seven are left for the nine
other colour classes. A class keeps its palette while it is in the box, so the colours
do not shuffle when a Pokémon comes or goes. With more than seven classes in one box,
cyan Pokémon are shown with blue's palette or Mew's class with pink's.

Getting it onto the screen. The game brings a third of the screen up to date per frame
(six rows of tiles), and the color engine sends the colours of that third with it. Left
to that, a place in the second or the fourth row of the box, which lie across two
thirds, shows the upper half of one picture and the lower half of another for a frame
or two whenever it changes, which for the icon under the cursor is every ten frames;
and a redraw that is still being worked out when a third goes over leaves that third
with new icons in old colours for three frames. So the places of the box are written to
video memory by the grid itself (`BoxGrid_ShowCellNow`): the four tiles of a place, its
palette and its mark between two scanlines, with the wait for that from the fast
battle start (home/fast_video_copy.asm), and a row only while the picture is not at it.
After a change the colours go to the LCD's palettes first, in a VBlank, and the places
follow at the top of the same frame; the sprites follow a frame later. Before anything
is done about a button, the icon under the cursor goes back to its first picture, since
the four tiles of the second one are about to be loaded with another icon's.
When the box changes without the screen being built again, its icons are loaded between
scanlines too (`LoadBoxIconFast`), into tiles no place shows at that moment.

### Variables

What the screen needs only while it is up lives in the buffer the game saves the screen
in (`wTileMapBackup`, through a union). The game's question and its list of boxes use
that buffer too, so what has to last through them (the cursor, what is picked up and
from where, the quick way, whether the question has been answered) is in ten bytes of
unsaved work RAM behind the EXP bar's variables. No saved RAM was added. The water and
flower animations are off while the screen is up (they write to tiles that hold icons
here).

The PC's menu has six entries instead of five (`engine/pokemon/bills_pc_menu.asm`). Its
box is two rows taller and reaches over the top edge of the text box; "What?" and the
box with the box number and the count are where they were.

## Home bank space

The home bank (ROM0, the 16 KB that is always mapped) has little room, which is why
several features are in other banks. Without the changes below it would have 107 free
bytes; with them it has 675, 572 of them in one block at the end. Nothing here changes
what the game does. From the pret wiki's
"Free MORE some space in the Home BANK" and the pokeyellow wiki tutorial it points to:

- Mart item lists (148 bytes). They are text scripts, read while the map's bank is
  loaded and copied to RAM at once, so they do not need to be in the home bank.
  `data/items/marts.asm` now puts each list in a small section of its own in the bank of
  the mart's map ("Mart Inventories 06" and so on), which the linker drops into free
  space. The two lists no clerk uses (a bike shop list and a spare mart list) are gone.
- `CalcStats` and `CalcStat` (261 bytes). The code moved unchanged to
  `engine/pokemon/calc_stats.asm`, in a section of its own ("Calc Stats");
  `home/move_mon.asm` keeps two 12-byte stubs with the old names, so no caller changed.
- `homecall` (88 bytes). The macro switched banks with two instructions written out,
  twice per use. It now uses `rst SetRomBank`, a one-byte call. The tutorial adds a
  routine and calls it (3 bytes); the color hack already had that routine sitting next to
  the rst vectors, so it was moved onto the $20 vector and costs one byte per switch.
- `farcall` / `callfar` in the home bank (84 bytes). `call Bankswitch` became
  `rst _Bankswitch`; the color hack already had `jp Bankswitch` on the $18 vector for its
  own macro. Outside the home bank the macro is the original three-byte call: the rst
  everywhere would make code in the map banks two bytes shorter per call, move the maps
  and break save files (next section).

What is left in the same vein, if the home bank fills up again: about 60 places in the
home bank still write out the two-instruction bank switch and could use the same rst
(4 bytes each).

## Save files and where things are in the ROM

A Gen 1 save file holds ROM addresses. For the map the game was saved on it stores the
pointers to the map's block data, its text pointer table and its script, the block data
of the maps connected to it, and the tileset's bank, block set, graphics and collision
list. On CONTINUE the original game does not look any of these up again
(`LoadMapHeader` returns early when a save was just loaded); it trusts what the file
says until the player walks into another map.

So a save only loads on another ROM if all of that data sits at the same addresses
there. If it does not, the map looks right but its script is garbage: in Viridian
Forest, for example, a trainer's encounter music starts and the game then sits there
with the overworld on screen, ignoring the buttons. The color hack was written with this
in mind and keeps every map bank laid out as on the cartridge, and so does this game:

- Everything is at its cartridge address, in Red and in Blue: the map sections are
  pinned in `layout.link` (three that differ between the versions are pinned in the
  source), code that grew or was added is in sections of its own in the nearly empty
  bank $0C and elsewhere, and `rst` far calls are used in the home bank only.
- The build checks it. `tools/make_cartridge_addresses.py` reads the symbol files of an
  unmodified color hack build and writes one link-time assertion for each of the 966
  labels a save can point at (map block data, objects, scripts, text pointer tables;
  tileset graphics, block sets and collision lists). Changing the size of anything in
  front of one of them is a build error that names the label, instead of a broken save
  some weeks later.
- CONTINUE reads the map header, the connections and the tileset pointers from the ROM
  instead of trusting the file (`LoadMapHeader` in `home/overworld.asm`). For a save
  made on a ROM with the cartridge layout this writes the values that are already
  there. For a save from a ROM that moved the maps, it repairs them. The map's objects
  (people, signs, warps) still come from the save file, as in the original.

So saves from the cartridges, the color patch and the shiny patch are interchangeable
with this game's in both directions.

## SGB border data ("Trim the SGB tilemap")

Not applied, because there is nothing left to trim. The tutorial shortens the Super Game
Boy border tilemap that Red and Blue carry in bank $1C. The color hack is GBC only and
already dropped the border: `data/sgb/sgb_border.asm` is commented out in
`engine/gfx/palettes.asm` and `LoadSGB` no longer sends it, so the tilemap is not in the
ROM at all and bank $1C has about 3.8 KB free. The space that was short was the home
bank, which that tutorial does not touch; see "Home bank space" above.

## 50-slot bag

`BAG_ITEM_CAPACITY` is 50. As in the pret tutorial, the bag moved into the 128 saved
bytes after `wDestinationWarpID` that the original games never use ($D430), so nothing
else in RAM or in the save file moved.

The tutorial stops there, which leaves the old bag location dead: an original game or a
save editor opening the save finds no items, and a save from an original game loads
here with an empty or glitched bag. This build keeps the old location alive as a mirror
(`engine/menus/save.asm`):

- Saving writes the first 20 stacks to the original bag location (`wLegacyBagItems`).
- Loading checks that mirror. If it still matches, the bag is used as stored. If it
  doesn't (save from an original game, the color or shiny patch, or the bag was changed
  elsewhere), the mirror becomes the start of the bag and
  any stacks 21-50 this game had stored are kept after it.

So an original game, or a save editor using the original layout, sees and can edit the
first 20 stacks, and stacks 21-50
survive the round trip. One side effect: if the other game adds an item that is also
among the hidden stacks, the bag ends up with two stacks of it.

## Instant battle start

Wild, trainer and Safari Zone battles open straight on the battle menu. From the moment
the battle is triggered the screen is black for about half a second (wild) or three
quarters of a second (trainer), then the finished battle screen appears and the
opponent's cry plays. In the original that takes about 8 and 10 seconds, with INSTANT
TEXT on.

Skipped: the screen transition, the silhouettes sliding in, "Wild X appeared!" /
"X wants to fight!" / "X sent out Y!" / "Go! Z!", the trainer pics, the Poké Ball poof,
the growing animation, the cries (except the opponent's, which is played without
waiting) and every pause in between.

Kept as in the original:

- Everything after the battle menu first opens. Switching, the opponent's next Pokémon
  and the trainer's defeat scene animate as before.
- Link battles, so both games stay in step. Their intro is unchanged.
- The old man's catching demonstration.
- The unidentified GHOST and the Marowak ghost in Pokémon Tower, whose messages are part
  of the story. Ordinary Pokémon Tower battles with the Silph Scope are instant.

It is always on. There is no room left on the options screen for a switch.

Because the foe's cry is played without waiting, a button can be pressed while it still
sounds, which the original game never allows. That exposed a fault in the battle sound
engine: the menu click could hang on its sound channel for four seconds, and the first
move or an attempt to run then waited for it. That is fixed; see "The click that hung"
under "Fast battles".

How it works: `hFastBattleIntro` is set when a battle begins (`SetFastBattleIntro`) and
cleared when the battle menu is about to open (`EndFastBattleIntro`). While it is set
the palettes are black and the intro code runs in its usual order with the waits,
animations, messages and sounds left out, so every variable, tile and palette ends up
where the normal intro leaves it. That was checked: at the battle menu, video memory,
the palettes, the sprite table and the hardware registers are identical to the normal
intro's, and work RAM differs only in the random numbers, the play time, the sound
engine and scratch bytes. `EndFastBattleIntro` then waits four frames for the screen to
reach video memory and restores the palettes.

Most of the half second is spent decompressing the two pics, which cannot be avoided.
The rest was loading tiles: the game copies 8 tiles per frame during VBlank, and a
battle needs over 400 (two pics, font, HUD, animation tiles). While the flag is set,
`CopyVideoData` and `CopyVideoDataDouble` jump to `home/fast_video_copy.asm`, which
writes 8 bytes at the start of each HBlank instead. The LCD is never turned off, because
a Game Boy Color shows a white screen while it is off. The timing assumes double speed
mode, which the color hack always runs in: the 8 writes are done at most 66 machine
cycles after HBlank begins and video memory stays writable for at least 83. In the
emulator there are another 56 cycles of slack.

## Differences from the original shiny patch

The RNG state uses 7 bytes of WRAM that were already unused, instead of inserting 7 new
bytes. No RAM address moves, so GameShark codes and memory maps for the color hack keep
working. Save files are unaffected either way.

In the enemy HUD the gender symbol sits at column 5 instead of column 3, because the
color hack moves the enemy level to column 6 and puts the caught icon at column 1.

Those 7 bytes turned out to be read after all: the color hack's `SetPal_PartyMenu`
colors nine two-row strips from the six-entry `wPartyMenuHPBarColors`, so the strips
under the party (the text box) took their palette from the three bytes behind it. Two
of those are random number state here, which would tint the party menu's text box at
random. The loop stops reading at six and gives the rest the palette that 0 stood for
(`color/color.asm`).

## Differences from the 2017 color IPS

The base is a later pokered-gbc than the v1.2 IPS, with the fixes made since. Visible
changes are small palette tweaks (gray Pokémon such as Magnemite are no longer olive,
and the trainer card border is red/blue instead of purple).

## Compatibility

GBC only, same as the color patch. Saves from vanilla Red/Blue, from the color patch and
from the shiny patch all load, and saves made here load back in them; see "Save files
and where things are in the ROM" for what that depends on.
