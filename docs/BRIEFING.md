# Arma Inventory Redesign - briefing for a new model

How to use it:
1. Send the **Master prompt** block as the first message.
2. Give the model the files under **Attachments**. Without them it can only guess the design. A model
   with file access (Claude Code started in `GitHub Repos`) can read them from
   `../Enhanced-First-Aid-Kits` instead.
3. Then work phase by phase and test every phase in game yourself before the next one.

## Attachments (from the EFAK repo)

| File | What for |
|---|---|
| `addons/gui/defines.hpp` | Colours, grid, window geometry, pixel snapping - the design system |
| `addons/gui/RscBase.hpp`, `addons/gui/RscDialog.hpp` | Base classes (rounded panel `EFAK_PANEL`) and every control of the kit window - template for style and structure |
| `addons/gui/ui/*.paa` | Icons, corners, gloss, toggles, scroll thumb - copy into the new mod |
| `tools/generate_ui_textures.py` | Draws those textures and converts them to PAA - extend it for grid cells, tile backgrounds, the "?" of hidden items |
| `addons/gui/functions/fnc_createPanel.sqf`, `fnc_setBar.sqf` | Rounded panels at run time, fill bars with warning colours |
| `addons/gui/functions/fnc_fillList.sqf`, `fnc_openPouch.sqf`, `fnc_openMenu.sqf` | How lists, the window and drop down menus are built |
| `addons/core/script_component.hpp`, `addons/main/script_macros.hpp` | CBA macro setup |
| `.hemtt/project.toml` | HEMTT template including launch configs |
| `Optiwand/.github/workflows/check.yml` | CI: `hemtt check` on every push, HEMTT pinned to the local version |
| Screenshots of the kit window | So the model sees the look |

## Master prompt

```text
You are helping me build an Arma 3 mod from scratch: a complete replacement of the vanilla
inventory (RscDisplayInventory, IDD 602) with a Tarkov-style grid inventory, in the visual design
of the kit window of my mod Enhanced First Aid Kits (EFAK). I attached EFAK's GUI files - treat
them as the design system.

Name: Enhanced Inventory, prefix einv. Repo: C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign.
Phase 1 is built - read the repo before changing anything.

## What this is - and what it is not
- Built from zero: our own display, our own data layer, our own rendering. Nothing is patched into
  RscDisplayInventory and no vanilla list or slot control is reused. It is not a reskin or an
  extension of the vanilla screen like Better Inventory. The vanilla inventory does not stay as a
  fallback either: since 2026-10-14 it is blocked completely.
- Tarkov-like: items are tiles of a fixed size on container grids; you drag, rotate and stack them;
  loot has to be searched before you see what it is.
- Modern: tiles instead of text lists, instant visual feedback, short animations, consistent
  shortcuts, readable at UI size "small" on 1080p.

## Toolchain and conventions
- HEMTT 1.11.2 (hemtt build / check / launch / release), CBA_A3 macros (GVAR, FUNC, QUOTE, ARR_N,
  PREP via XEH_PREP.hpp, Extended Event Handlers). ACE3 is a dependency.
- Layout: addons/main (version, macros) + one addon per feature, named after what it does. No addon
  called "core".
- CI: .github/workflows/check.yml runs hemtt check on every push and PR, HEMTT pinned to 1.11.2
  (copy of the attached Optiwand workflow).
- Everything in the repo is English: code, comments, docs, stringtables (only <English>).
- Comment style: explain WHY in plain sentences, like the attached EFAK files.
- CBA settings: ordered by topic, then numbers > switches > lists > text boxes. Descriptions are
  wrapped with \n about every 40 characters, paragraphs separated by \n\n, and never contain a
  scope line like "Your own setting".
- Bump PATCH in addons/main/script_version.hpp on every bug-fix round.
- Never commit or push unless I ask. Never start Arma - I test myself. End every answer that changes
  code with the command to launch it:
  cd "C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign"; hemtt launch
- Write SQF files with real newlines; watch out for backslashes in paths (\A3\..., \z\...).

## Design system (from EFAK's gui/defines.hpp)
- Window: centered, height 0.95 * safezoneH. Wider than EFAK's because of the three columns:
  width min(1.6 * height as square, 0.96 * safezoneW). Row unit ROW = window height / 37; text sizes
  0.68-0.8 ROW. Grid cells are square (EFAK's SQUARE macro), start at 1.4 ROW. Fonts
  PuristaMedium / PuristaSemibold (RobotoCondensed earlier).
- Colors (RGBA): window 0.04,0.045,0.055,0.78 | card 1,1,1,0.035 | field 1,1,1,0.06 |
  field hover 1,1,1,0.1 | raised 1,1,1,0.15 | menu 0.075,0.083,0.1,0.97 with edge 1,1,1,0.14 |
  line 1,1,1,0.07 | text 0.925,0.933,0.949,1 | text2 0.639,0.675,0.725,1 |
  muted 0.412,0.443,0.494,1 | accent (orange) 0.961,0.647,0.141,1, hover 1,0.733,0.29,1,
  soft 0.961,0.647,0.141,0.22 | on-accent 0.086,0.094,0.114,1 | gain 0.298,0.765,0.541,1 |
  loss 0.941,0.333,0.353,1 | info 0.294,0.612,0.961,1 | greyed 1,1,1,0.3
- Every colour defined once as numbers, then as config {..} and SQF [..] - like EFAK's defines.hpp.
- Rounded corners and gloss come from textures (corner_*_ca.paa, gloss_*_ca.paa), toggles from
  toggle_on/off_ca.paa, a custom scroll thumb, and flat "ghost" buttons. Reuse the attached icons;
  new textures come from an extended copy of generate_ui_textures.py, not from hand-drawn files.

## Window layout (three columns, like Tarkov)
- Header: title, total weight as a bar (kg or lb, following ACE's setting), search field,
  auto-sort, close.
- Left - equipment slots as cards: headgear, facewear, NVG, binocular, the assigned items (map,
  compass, watch, radio, GPS/terminal), uniform, vest, backpack, primary, handgun, launcher. Each
  weapon card shows its attachment slots (muzzle, rail, optic, bipod) and loaded magazines as
  small slots of their own.
- Middle - the player's own containers as grids, top to bottom: uniform ("pockets"), vest ("rig"),
  backpack. Each under a header with picture, name and a mass bar.
- Right - what is being looted: ground, crate, vehicle cargo or a body; several sources as tabs.
  A dead body shows its own equipment slots and grids like the left and middle columns, so it can
  be stripped piece by piece.
- A hover card instead of tooltips: name, description, mass, size, ammo, source mod.
- A right-click context menu in EFAK's menu style: equip, unload, open, split, examine, drop, and
  for EFAK kits rename / open kit.

## Grid model
- Every item has a size in cells (w x h), every container a grid (columns x rows).
- Item size, first match wins:
  1. a config property on the item class that other mods can set: einv_gridSize[] = {w, h};
  2. our own compat table for vanilla/ACE items that come out wrong;
  3. rules by kind and mass. Starting values, to tune in game: handgun 2x1, rifle 4x2 to 6x2 by
     mass, launcher 6x2, magazine 1x1 / 1x2 / 2x2 by mass, small item 1x1, heavy item 2x2, loose
     uniform 2x2, vest 3x3, headgear 2x2, backpack by its maximumLoad.
- Grid size from the engine's capacity: cells = maximumLoad / mass per cell (CBA setting, start
  at 6), laid out at a fixed width per kind (uniform 4, vest 5, backpack 6, crates and vehicles
  10). getContainerMaxLoad gives maximumLoad by class. Ground holders have no limit: the ground
  grid grows with its contents.
- The engine stays the truth. A move needs free cells AND the engine's room (canAdd...,
  load, maximumLoad). When either says no, say which: "No room" or "Too heavy".
- Rotation: R while dragging swaps w and h, the tile's picture turns with it.
- Stacking: identical simple items (CfgWeapons items, magazines with a capacity of 1 such as
  grenades) share one tile with a count, up to a stack limit by size. Magazines with ammo never
  stack - each shows its ammo as a thin bar. Shift+drag splits a stack.
- Arma does not know where an item lies. Store the layout per container with setVariable on the
  container object (uniformContainer / vestContainer / backpackContainer, the holder, the
  vehicle): a list of [entryId, class, x, y, rotated, count]. Instances of a class map to its
  entries in order.
- Reconcile on every open and on every outside change (scripts, Arsenal, ACE, other players):
  drop entries whose items are gone, place new items first-fit (largest first). Items the engine
  accepted but the grid has no room for go into an overflow row - never hide or delete anything.
- Auto-sort re-packs a grid, largest first.

## Searching (uncover), like Tarkov
- Loot this player has not searched yet shows as hidden tiles: the right size, a "?", no picture
  and no name. Opening the container starts the search: tiles reveal one after another from the
  top left, each taking time by its size (CBA setting), with a progress ring on the tile being
  searched and a rummaging sound. Closing the window pauses the search; reopening continues it.
- What has been revealed is per player: keep it on the container with setVariable WITHOUT the
  public flag (that stays on this client) as a set of entry ids. Entries someone else adds are
  hidden again; whatever this player puts in is known at once. Own gear is never hidden.
- CBA settings (server): search bodies / crates and vehicles / loose ground items as separate
  switches, time per cell. Mission makers exempt an object with
  _box setVariable ["einv_noSearch", true, true] - arsenal boxes, base supply.
- Optional, setting default off: unknown item classes must be examined once (context menu, short
  timer) before their name and picture show. Known classes are kept per player in
  profileNamespace.

## Modern feel
- Tiles: rounded, tinted by category (weapon, ammo, medical, gear, misc), picture fitted with
  ST_KEEP_ASPECT_RATIO, short name top right, count or ammo bottom right.
- Drag: the tile follows the mouse as a ghost; the footprint under it lights up live in gain green
  (fits) or loss red (doesn't). Dropping on a container header or a slot card sends it there.
- Shortcuts: double click quick move to the other side (Ctrl+click until 0.2.1, now select), Alt+click equip, Shift+drag split, R rotate
  while dragging, double-click open / inspect, Del drop to the ground, Esc or the Gear key
  (actionKeys "Gear") closes.
- Animations with ctrlCommit, 0.1-0.15 s: fades, tiles sliding into place after a sort. No
  animation may delay input.
- Sounds for pick up, drop and search, from vanilla config classes (check that they exist).

## Arma UI pitfalls (learned the hard way)
- Draw order = config order; a clicked/focused control is drawn on top. Overlays (edit boxes,
  buttons over lists) must come AFTER the list in the config, or clicks land on the list.
  Created controls draw over earlier ones - create the drag ghost and the hover card last.
- Faded or disabled controls still swallow clicks (seen in EFAK and ACE Arsenal). Hide them with
  ctrlShow false, and do hit testing yourself: compute the cell from getMousePosition and the
  grid's origin instead of trusting which control got the event.
- Controls in a controls group are positioned relative to the group and move with its scroll
  (ctrlScrollValues). Keep ONE function that maps screen position <-> cell.
- See-through panels must meet on whole pixels (EFAK's SNAP_* macros) - an overlap shows as a
  darker line, a gap as a lighter one. Draw a grid as one background plus line controls, not one
  control per cell.
- Verify in phase 1 that ctrlSetAngle turns a picture without distorting it on a non-square
  screen. Fallback: keep the icon upright and only swap the tile's shape.
- A full crate means hundreds of tiles: measure ctrlCreate, reuse tile controls (a pool) when a
  grid is rebuilt instead of deleting and re-creating them.
- An edit box swallows the KeyDown of Return - use onKeyUp for "Enter confirms".
- Tooltips (ctrlSetTooltip) are plain text only.
- HashMaps compare by reference: use count _map == 0, not isEqualTo createHashMap.
  {...} forEach _hashMap: _x is the KEY, _y the value. Objects are not valid HashMap keys - keep
  per-object state with setVariable, or key by hashValue.
- [a, b] select cond evaluates both sides - use if/else when one side could error.
- Commas inside QUOTE() in configs need ARR_2/ARR_3.

## How the inventory works underneath
- Take over: player addEventHandler ["InventoryOpened", {...; true}] - returning true blocks the
  vanilla display; open our own dialog with the container(s) from the event. Also hook ACE's "open
  inventory" interactions and vehicles. (No keybind to open the vanilla one - dropped 2026-10-14.)
- No "move item" command exists. Moving = remove + add, with the right command per kind: items
  (addItemCargoGlobal), magazines with their ammo (magazinesAmmoCargo / addMagazineAmmoCargo),
  weapons with attachments (weaponsItemsCargo / addWeaponWithAttachmentsCargoGlobal), backpacks
  with contents (everyContainer, everyBackpack). Cargo has no "remove one item": clear and re-add,
  or work on the unit (removeItem, removeItemFromUniform/Vest/Backpack). CBA has
  CBA_fnc_removeItemCargo / removeMagazineCargo / removeWeaponCargo / removeBackpackCargo - check
  how they treat attachments and partly used magazines before relying on them. Check room first
  (canAdd, canAddItemToUniform/Vest/Backpack, load, maximumLoad, config mass).
- Slots: uniform/vest/backpack/headgear/goggles/NVG/binocular/weapons + attachments + loaded
  magazines. For atomic changes on the unit, getUnitLoadout / setUnitLoadout.
- Multiplayer: ground holders, vehicles and bodies are shared. Route changes to shared containers
  through the server (remoteExec, one change at a time per container) so two players can't take
  the same item. Use the Global commands. Unit commands on a body (removeVest, ...) must run where
  the body is local. Broadcast a container's layout once when the window closes, not on every
  move.
- Performance: build each grid once on open, then update only what changed (Take/Put event
  handlers, a cheap content check at a low rate while open). Cache displayName / picture / mass /
  size per class in a HashMap. Never rebuild everything every frame.

## Compatibility to keep in mind
- Other mods add controls to the vanilla display (ACE, TFAR/ACRE, EFAK itself). They won't appear
  in ours - integrate the important ones (there is no vanilla fallback since 2026-10-14).
- Unique items change class (TFAR/ACRE radios, EFAK/EUP kit instances like efak_IFAK_7) - size and
  category must come from the base class.
- EFAK/EUP: show a kit's player-given name via efak_core_fnc_getKitLabel (returns "" when there is
  none - then the normal displayName) and open kits with efak_core_fnc_openKit [unit, class]. Only
  use functions marked "Public: Yes" in EFAK's addons/*/functions.

## Plan - one phase at a time, wait for my test before the next
1. Skeleton: HEMTT project, main addon, the feature addon(s), CBA settings stub, check.yml. An empty
   window in the EFAK design that opens instead of the vanilla inventory.
   Plus one test grid with a few hard-coded tiles to settle cell size, pixel snapping and
   rotation early.
2. Data layer, read-only: item sizes, container grids, layout store + reconcile. Show the slots,
   uniform/vest/backpack grids, ground/crate/vehicle/body, weights, the hover card. A debug
   function that prints a container's layout to the RPT.
3. Moving in singleplayer: drag & drop with rotation and the live green/red footprint, room checks
   (grid + mass), quick move, stacking and splitting, drop to the ground, auto-sort.
4. Equipment slots: equip/unequip every slot, weapons with attachments and magazines, stripping
   bodies.
5. Searching: hidden tiles, reveal timer, sounds, settings, exemptions, the optional examine.
6. Multiplayer safety: server-routed changes for shared containers, layout sync, body changes where
   the body is local, search state per player.
7. Polish and compat: search field (dims what doesn't match), context menu, ACE (weight, magazine
   repack, medical items), TFAR/ACRE radios, EFAK/EUP names and open kit.

Not now, unless I ask: loading magazines round by round, quick slots / hotbar, weapon presets, a
stash between missions, durability or armour values.

Start with phase 1. Before writing code, list the files you will create.
```

## Working with it

- **One phase per chat section.** Test every phase yourself and report problems with a screenshot
  and the RPT excerpt (`%LOCALAPPDATA%\Arma 3\*.rpt`).
- **Always send the exact error text** from the RPT, not just "doesn't work".
- **When it drifts from the design**, put a screenshot of the EFAK window next to it and say "like
  this".
- **When it doesn't feel like Tarkov**, say what Tarkov does differently in one sentence - the model
  knows Tarkov's inventory, it needs to know which part you mean.
- **Restart long chats** at some point. Attach this file plus the current state of the files again.
