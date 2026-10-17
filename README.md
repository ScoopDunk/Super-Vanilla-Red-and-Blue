# Super Vanilla Red and Blue

Pokémon Red and Blue in full Game Boy Color, with quality-of-life changes and speedups,
and nothing about your Pokémon changed. The original Red/Blue sprites stay. Pokémon are
stored exactly as on the cartridges, so trades work with Red, Blue, Yellow, Gold, Silver
and Crystal, and save files move both ways between this and the original games.

## Download

The patches are on the [Releases](../../releases) page: **Super Vanilla Red** and
**Super Vanilla Blue**. No ROMs are provided; you need your own copy of the game.

## How to patch

1. Get the clean ROM that matches the patch:

   | Patch | Base ROM | CRC32 | SHA-1 |
   | --- | --- | --- | --- |
   | `Super-Vanilla-Red.ips` | Pokemon - Red Version (USA, Europe) (SGB Enhanced) | `9F7FDD53` | `ea9bcae617fdf159b045185467ae58b2e4a48b9a` |
   | `Super-Vanilla-Blue.ips` | Pokemon - Blue Version (USA, Europe) (SGB Enhanced) | `D6DA8A1A` | `d7037c83e1ae5b39bde3c30787637ba1d4c48ce2` |

2. Apply the patch with [Rom Patcher JS](https://www.marcrobledo.com/RomPatcher.js/)
   (in the browser) or [Floating IPS](https://github.com/Alcaro/Flips).
3. Give the result a `.gbc` extension. It should match:

   | Patched ROM | CRC32 | SHA-1 |
   | --- | --- | --- |
   | Super Vanilla Red | `497FE9F5` | `db94217e7ce6bea5fe34f6f2d1416475b8257e9c` |
   | Super Vanilla Blue | `5D200CED` | `c40fc6e4aad8113e6f8a88d51e953d1d9e9044cd` |

To keep playing an existing game, put its save next to the patched ROM under the same
name (`Super Vanilla Red.gbc` and `Super Vanilla Red.sav`, for example). A save made here
loads on the original game too.

Requires a Game Boy Color, a Game Boy Advance, or an emulator in Game Boy Color mode.
Runs on real hardware and on emulators such as SameBoy, Gambatte, mGBA and VBA-M.

## Features

### Graphics

- Full Game Boy Color palettes throughout, with the original Red/Blue sprites
- Gen 2 style HP bar, and an EXP bar in battle and on the status screen
- A Poké Ball icon next to wild Pokémon you have already caught
- Every Pokémon has its own party icon, in its battle colours (party menu, nickname
  screen, Bill's PC)

### Shiny and gender preview

- A sparkle next to any Pokémon that will be shiny in Gen 2
- A ♂/♀ symbol showing the gender Gen 2 will give it
- Shown in battle, on the status screen and in Bill's PC
- Wild Pokémon can roll shiny at the standard 1 in 8192 (see below)

### Speed

- Hold B to run: on foot at bike speed, on the bike at twice that. Surfing is as fast as
  biking, and twice as fast with B
- INSTANT TEXT option
- Battles start at once: no transition, no slide-in, no opening messages
- BATTLE ANIMATION: ON / OFF / FAST (FAST also removes every pause that only paces a
  battle)
- HP/EXP BAR SPEED option: NORMAL / 2x / INSTANT
- Saving no longer waits on "Now saving..."

### Convenience

- 50-slot bag
- START sorts the items in the bag and in the PC's item lists
- Cut, Surf and Strength by pressing A in front of a tree, water or a boulder
- When a Repel wears off, the game offers to use another
- The low health alarm rings three times and stops
- Bill's PC shows how many Pokémon are in the current box
- After a catch goes to the box, a message says how many places are left

### Bill's PC: MOVE PKMN

A Gen 3 style box screen, beside the original WITHDRAW, DEPOSIT and RELEASE lists.

- The box as a 5×4 grid of icons, with the party beside it
- Pick up a Pokémon and put it down anywhere: reorder, deposit, withdraw, or swap two
- Change boxes with left/right on the box's title, or pick one from the box list
- Carry a Pokémon from one box to another
- Quick mode (START): A picks up and puts down without the menu
- SORT a box by Pokédex number, level or name
- Shiny marks on the icons
- The box list shows how full every box is (BOX 3  12/20)
- STATS and RELEASE from the grid

### Compatibility

- Pokémon data is identical to the cartridges': trades and battles with Red, Blue and
  Yellow, and Time Capsule trades with Gold, Silver and Crystal
- Save files work both ways with the original games
- Two link cable freezes that could happen before a trade or battle starts are fixed
- Every feature is in both Red and Blue

## Shiny and gender indicators

Generation 1 Pokémon have no shiny flag and no gender. Gold, Silver and Crystal work both
out from a Pokémon's DVs, the hidden values every Red/Blue Pokémon already has. This game
reads those same DVs and shows you the answer early: a sparkle if the Pokémon will be
shiny in Gen 2, and the gender Gen 2 will give it. The rule is Gen 2's own, so what you
see here is what you will see after a Time Capsule trade.

The indicators are display only. Nothing is written to the Pokémon, and no shiny or
gender data is added, because none exists in Gen 1. Every Pokémon is stored exactly as a
regular cartridge stores it: same format, same values. Trades with unmodified Red, Blue
and Yellow and Time Capsule trades with Gold, Silver and Crystal were tested, and
species, DVs, stat experience, moves, PP, level, OT, ID and nickname all arrive
unchanged. Save files move freely between this game and the original games.

One thing to know: the game uses the shiny patch's random number generator, so wild
Pokémon can roll shiny DVs at the standard 1 in 8192. That changes the dice, not the
data. The DVs it rolls are ordinary values that any cartridge Pokémon can hold.

## Building from source

This repository is the game's full source: the pokered disassembly with the Full Color
hack and every change above. Install the tools as described in [INSTALL.md](INSTALL.md)
(RGBDS 1.0.x), then run `make` to build `pokered.gbc` (Super Vanilla Red) and
`pokeblue.gbc` (Super Vanilla Blue). `make compare` checks both against the checksums of
the released games. [NOTES.md](NOTES.md) explains how each feature works and where it is
in the source.

## Credits

- Pokémon Red and Blue: Game Freak, Nintendo, Creatures
- pokered disassembly: the [pret](https://github.com/pret/pokered) team
- Full Color hack ([pokered-gbc](https://github.com/dannye/pokered-gbc)): FroggestSpirit,
  Drenn and dannye
- Shiny + Gender Indicators + RNG Patch: NoraInTheFuture
- Running with B: based on the Pokémon Fast Red patch (original author unknown)
- Instant text: modeled on [Shin Pokémon Red and Blue](https://github.com/jojobear13/shinpokered)
  by jojobear13
- Box count, box space messages, short low health alarm: ideas from
  [pureRGB](https://github.com/Vortyne/pureRGB) by Vortiene, rewritten for this game
- Unique party icons: pret wiki tutorial "Add All Unique Party Menu Sprite Icons" by
  dannye; icons drawn by Blue Emerald, Chamber_, Soloo993 and others
- Item sorting: pret wiki tutorial "Add Item Sorting In Bag" by devolov
- 50-slot bag: pret wiki tutorial "Increase Bag Space" (credits Vortiene)
- No save delay: pret wiki tutorial "Remove Artificial Save Delay"
- Field moves from the overworld: pret wiki tutorial "Use Cut, Surf, and Strength From
  the Overworld"
- Home bank space: pret wiki "Free MORE some space in the Home BANK" (code by Rangi42,
  from Red Star/Blue Star) and the pokeyellow wiki "Free some space in the Home BANK"
  (credits Vortiene)
- Built with [RGBDS](https://github.com/gbdev/rgbds)
- Everything else (instant battle start, fast battles, bar speed option, Repel prompt,
  link fixes, the MOVE PKMN box screen) and putting it all together: ScoopDunk

## Disclaimer

This is a fan project, not affiliated with or endorsed by Nintendo, Game Freak or
Creatures. Pokémon is a trademark of Nintendo, Creatures and Game Freak. Only patches are
distributed here; no ROMs.
