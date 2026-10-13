# Enhanced Inventory

An Arma 3 inventory built from scratch, in the look of Enhanced First Aid Kits' kit window. It replaces
the vanilla inventory with a grid: items are tiles of their own size that you drag, stack and split, and
loot has to be searched before you can see it. Ctrl+click, Shift+click or a frame dragged over the tiles
select several of them to move together, and every box has a button that takes everything out of it ("Take
all") or puts everything of yours into the box beside it ("Put all in").

- **Hotbar on 4-0:** grenades, bandages, medicine, magazines, food and kits on a key - bandages go where you
  bleed most, tourniquets on the worst limb (ACE and ACM). Drag an item onto a slot of the "Hotbar" row in
  the inventory, or point at it and press the key; the bar shows on the screen in Arma's HUD style.

- **Grid panel in ACE Arsenal:** pick the uniform, vest or backpack tab and its grid opens beside ACE's list.
  What you add lands in the first free cell, drag tiles to sort them (R turns, stacks merge), drag them out of
  the panel - or right click, or Delete - to take them out. With no free cells ACE's add is taken back and the
  message says how much room to make. Drag a row out of ACE's list onto a free spot of the grid to put it in
  there (the wheel sets how many, Ctrl+wheel over a tile adds or takes out one). Under the grid a staging space
  holds things while you rearrange a full container - it grows as you fill it -; whatever is left in it is
  deleted when the arsenal closes. The vanilla Virtual Arsenal opens ACE Arsenal too, or is blocked, by server setting.

**Status:** in development, all seven phases built and in testing: two looks (Tarkov, Glass), drag and
drop between containers and equipment slots, searching loot, server-checked moves in multiplayer.
The plan is in [docs/BRIEFING.md](docs/BRIEFING.md), the design in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Requirements

- [CBA_A3](https://steamcommunity.com/workshop/filedetails/?id=450814997)
- [ACE3](https://steamcommunity.com/workshop/filedetails/?id=463939057)

Works with [Enhanced First Aid Kits](https://steamcommunity.com/workshop/filedetails/?id=3809430149) and
Enhanced Utility Pouches: kits and pouches open in windows of their own inside the inventory, things are
packed and unpacked by drag and drop. Options other mods add to CBA's item context menu (field rations, ...)
show in the window's right-click menu; ACE's "Repack Magazines" gives way to the window's own repack while
that is switched on.

Works with ACE cargo: what is loaded into a vehicle (or a crate) shows in its inventory as a "Cargo" box, with
a card for each thing, Open for a crate and Unload with ACE's own time. Works with TFAR and ACRE2: the channel
and frequency of a radio show at the mouse, on the hint line and on the inspect card, and a radio of yours has
"Open radio" and "Use as active radio" in its right-click menu (TFAR's long-range backpack keeps its
frequencies while you move it around). Works with ACE vehicle lock and Zeus Enhanced.

## Building

Built with [HEMTT](https://github.com/BrettMayson/HEMTT) 1.11.2:

```bash
hemtt launch
```

`hemtt launch test` loads the test scene with TFAR, `hemtt launch acre` the same scene with ACRE2 (the two
never load together).

`tools/generate_ui_textures.py` draws the window's textures (needs Pillow and ImageToPAA from Arma 3
Tools).

## For mission makers and admins

How big items are, how many share a tile and how containers are split up is one text of rules, the
CBA setting "Inventory rules" (`einv_items_rules`), the same for everyone. The setup wizard writes it for you
(ESC > Options > Inventory setup, Eden's Tools menu, the cog in the inventory) - you draw the cells of an item
(an L, a T) and of a uniform, vest or backpack on a canvas, click the gaps between cells to split it into
compartments, or link it to another class, and its start page shows what you changed -, but it is plain text.
It builds on a preset: Default (relaxed: realistic-ish sizes, containers a fifth roomier than their load),
Realism (realistic sizes: longer rifles, magazine-rig vests, a fixed grid per backpack size, stacks as in
Default) or Weight-like (an item takes as many cells as it weighs). Grids are ten cells wide.

- **Your own classes and kits:** `class=X+` covers X and every class built on it, from any mod -
  `class=My_Medic_Kit+ > size=2x2 stack=1 weight=1.5 name=Medic_kit`. A later rule beats an earlier one.
  In `name=` an `_` is a space. A compartment can be drawn cell by cell, rows split by `/`, `x` a cell and
  `-` a hole: `class=My_Vest > grid=xxxx/x--x+2x3`, and so can an item, whose `size=xx/x-` makes an L. A whole
  container can be drawn as a canvas, a letter per compartment, and its compartments stay exactly where they
  were drawn: `class=My_Pack > grid=abbbbbc/abbbbbc/abbbbbc/-bbbbb-/-bbbbb-` is a column of three pouches
  either side of the main compartment, `grid=aaa/aba/aaa` a ring with a cell of its own inside. A backpack
  whose config holds nothing (a cosmetic one, some radio packs) has no cells until a rule gives it some:
  `class=My_Radio_Pack > grid=4x3`.
  `class=My_Vest > like=V_PlateCarrier1_rgr` gives a class another one's size, stack, grid and rule weight,
  and follows it when that changes; `like=X grid=6x4` changes one.
- **One crate, vehicle or a unit's uniform, vest or backpack:** give the object its own grid, which wins
  over every rule - `_crate setVariable ["einv_grid", "6x4+2x3", true];` (also `"24"`, `"rig:16"`, `"auto"`).
- **Mods:** ship presets of your own as classes of `CfgEinvRulesets` (see `addons/items/CfgEinvRulesets.hpp`),
  or set `einv_gridSize[]`, `einv_stackSize`, `einv_grids[]` or `einv_slots` on your items.

The full grammar and which answer wins are in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) ("Rules engine").

- **Living persons:** anyone can be opened from the action menu ("Inventory") - awake, unconscious or
  captive. Who may open whom, take and put items or take off worn gear are server settings under
  "Living persons". Close one person to everyone with `_unit setVariable ["einv_noAccess", true, true];`;
  a container locked with `lockInventory` stays shut. A body opens whole as well, also through ACE's
  "Open <backpack>".
- **Everything nearby:** every pile on the ground and every crate within reach (setting "Reach", 3 m by
  default, on the same floor and in sight, at most ten) shows as a box of its own in the loot column; vehicles
  and bodies show when they are opened. `_object setVariable ["einv_nearby", false, true];` keeps an object
  out of that list, `lockInventory` as well. Each player can switch it off ("Show everything nearby").
- **Locks:** lock a crate or a vehicle to one side, one group or the admins: the Eden attribute *Inventory
  locked to* (category Enhanced Inventory), Zeus Enhanced's right-click *Inventory lock* and module, or
  `[_crate, "side", west] call einv_locks_fnc_setLock;` (`"group"` with a group or a group's callsign,
  `"admins"`, `""` opens it again). Logged-in admins always open it, Zeus too unless the server switches
  that off (*Zeus opens locked containers*); in single player nobody is an admin. Players who may not open it
  see the crate as a locked box in the window, with a padlock and who it is for - nothing of what is inside -,
  and the engine's own inventory is locked for them as well. ACE's vehicle lock is respected: without the key
  a locked vehicle's inventory is shut.
- **Weight:** weight only colours the soldier's weight bar and drives ACE's fatigue: the bar turns yellow where
  ACE's fatigue starts to tire a jogging soldier (26.7 kg at ACE's defaults, it follows ACE's load factor and the
  soldier's performance), red at 45 kg (no sprinting, tiring faster) and ends at 60 kg (walking only) - CBA
  settings Enhanced Inventory > Weight. Nothing is ever refused because of weight, and no container has a weight
  limit: what fits into a uniform, vest, backpack, crate or vehicle is decided by its free cells alone (a
  container's config load is only used to size its default grid when nobody defined one). A section's caption
  still tells what its contents weigh.
- **Hotbar:** the keys 4 to 0 belong to the hotbar unless the CBA setting "Hotbar" (`einv_hotbar_enabled`) is
  switched off - a server setting, the same for everyone. Only items that do something can be bound: bandages,
  tourniquets, splints and other ACE/ACM medicine are used on yourself through ACE's own treatment, grenades
  go into the hand, magazines reload the weapon in the hands, food and drink use ACE's field rations,
  Enhanced First Aid Kits open. Each player moves the bar in Arma's layout editor and chooses when it shows.
  `[0, "ACE_elasticBandage"] call einv_hotbar_fnc_bind;` and `[0] call einv_hotbar_fnc_use;` drive it from
  scripts.
- **Multiplayer:** where things lie syncs by itself - every player sees the same arrangement, also of
  containers your scripts fill. Every change runs where the container is local and the server carries what
  moves between machines, so the server has to run the same version of Enhanced Inventory. In multiplayer,
  crates, the ground, vehicles and bodies always open in Enhanced Inventory, also for players who switched
  the replacement off. Scripts can move items with `einv_storage_fnc_moveEntry`, `einv_storage_fnc_equip`
  and `einv_storage_fnc_unequip`; `[cursorObject] call einv_storage_fnc_dumpPlaces` writes where things lie
  to the RPT.
- **Arsenal:** ACE Arsenal is the arsenal - `ace_arsenal_fnc_initBox` and `ace_arsenal_fnc_openBox`, its boxes,
  loadouts and Zeus arsenal work as always; the grid panel hooks into its window (also in the Eden editor), and
  free cells are the only limit on what goes in. The vanilla Virtual Arsenal is a server setting,
  `einv_arsenal_biArsenal`: `"ace"` (default - BI boxes, Eden's "Virtual" storage and Zeus open ACE Arsenal with
  the same items), `"block"` (a red screen says it is not allowed, with the text of `einv_arsenal_biMessage`;
  Zeus is never blocked) or `"vanilla"`. A mission can decide per mission with `einv_arsenal_biPassThrough`:
  `true` - always BI's window, `false` - always ACE's, unset - BI's only for missions with their own
  `arsenalOpened` / `arsenalPreOpen` handlers. It is read on each client, so set it with the public flag
  (`missionNamespace setVariable ["einv_arsenal_biPassThrough", true, true]`) or in `initPlayerLocal.sqf`.
- **Magazines:** a partly filled magazine dropped on another of the same kind is repacked with ACE's Magazine
  Repack, in the window (a click or Escape stops it, what was moved stays moved), and "Repack all" in a
  magazine's menu repacks every one of its kind in your gear. Both magazines have to lie in your own gear or in
  the same crate, vehicle or pile. Servers with their own way to refill magazines (GreenMag) switch "Repack
  magazines" (`einv_magazines_repack`) off; the fill bar on magazines that are not full is each player's own
  setting.
- **Sounds and looting:** every kind of gear sounds like what it is - weapons, magazines, vests, helmets, medical
  items, radios -, using Arma's own sound files only; players within earshot hear someone loot (`einv_gui_soundsWorld`,
  a server setting). While the window looks into something (a body, a crate, a pile) the soldier lowers his weapon and
  looks into his gear, kneeling at bodies and low things, so others see who loots (`einv_gui_animation`, a server
  setting: off, while looting, always); a movement key stops looting and closes the window (each player's setting).
  Add your own sounds as classes of `CfgEinvSounds` (see `addons/gui/CfgEinvSounds.hpp`), or give an item the
  family of another with `einv_sound = "vest";` in its config.

## The vanilla inventory

Replaced. Players or missions can switch the replacement off in the CBA settings ("Replace the
vanilla inventory") - in multiplayer only for the player's own gear -, and should the window ever fail to
open, the vanilla one opens instead.
