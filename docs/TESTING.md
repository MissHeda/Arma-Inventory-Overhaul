# Testing 0.4.0

Everything below was built and checked in code only, unless marked tested. Tick what passed, note what failed
with the RPT lines (`%LOCALAPPDATA%\Arma 3\*.rpt`, search for `Error` and `einv`).

## Two instances on one machine

HEMTT launches the dev build with file patching. Two ways:

- **Listen server, two clients.** `hemtt launch test` opens the test scene in Eden; Play > Play in Multiplayer
  hosts it. Then a second instance joins: `hemtt launch -Q test -- -connect=127.0.0.1 -port=2302 -name=Second`
  (`-Q` skips the rebuild, `-name` gives it its own profile). The host is server and client in one; the second
  instance is the real client case, where moves go through the server.
- **Dedicated server, two clients.** `hemtt launch -e arma3server_x64.exe -- -config=server.cfg -port=2302
  "-mod=..."` with the mission exported from Eden to `mpmissions` and listed in `server.cfg`; then
  `hemtt launch -Q -i 2 test -- -connect=127.0.0.1 -port=2302`. Put `kickDuplicate = 0;` into `server.cfg`,
  or the second client is kicked for carrying the same Steam id.

Settings the server forces (`cba_settings.sqf`): `einv_items_rules`, the presets, locks, sounds, animation, hotbar.
A client can see them and cannot change them.

## A. Multiplayer

- [ ] Two players look into one crate: A moves a tile, B sees the new place without reopening.
- [ ] Both grab the same item at once: one gets it, the other sees the refusal, nothing is duplicated.
- [ ] Crate, vehicle, ground pile: take, put, Take all, Put all in, Sort; a player who joins later sees the same places.
- [ ] A client (not the host) drops a worn backpack, picks it up, swaps backpacks.
- [ ] A client with another rules text gets the hash warning once; the rules setting cannot be changed on a client.
- [ ] Staging in the Arsenal on a client: move in and out, the crate is deleted on close, nothing lands on the server.
- [ ] Locks: side, group, admins, Zeus; a locked crate shows as locked for the other player.
- [ ] Living persons: open another player, take and put with the server settings.

## B. Inventory window

- [ ] Backpack slot: put on, swap, take off (Ctrl+click), drop (menu Drop, Delete, drag to the ground), contents survive.
- [ ] Context menu rows: a tile has Inspect, Equip / Attach to / Load into where they apply, Drop, Select all (and the item's own
      rows - Open kit, Open radio, other mods' CBA rows, Repack all, the hotbar's); no "Move over", no "Sort". A worn slot has
      Inspect and Drop only (no "Take off"); a weapon also Take off for each part. Several selected tiles: only Deselect (double
      click, drag and Delete still move and drop them). Free cells: Select all; the free cells of an open kit's window have no menu.
- [ ] The name at the mouse is never under a frame: hover the Backpack, Vest and Uniform slots, a weapon card and a hotbar slot - the
      accent ring never lies over "Carryall Backpack (Coyote)"; Ctrl+click tiles while hovering one, hover a vest in a crate (the
      comparison card) and leave the mouse still while a move redraws the window.
- [ ] Weight bar: colour by tier, the texts (next limit, effect), the preview on pick-up, no ticks.
- [ ] Right-click on another tile while a menu is open opens the new menu; right-click on empty space closes.
- [ ] Count badges `n/stack` only for stackable classes; magazine rounds bottom left; hotbar slots alike.
- [ ] Searching a crate: tiles reveal one by one, the ring follows a tile on a painted compartment's cells.
- [ ] Holes in grids: no hover on a hole, the footprint turns red over one, a drop beside a hole.
- [ ] L-shaped items: tile border, R turns around the grabbed cell, a small item fits into the L's corner.
- [ ] Grids 10 wide: cell 37 px at 1080p, the storage column scrolls, the camera stays visible while looting.
- [ ] Painted compartments: 1:1 where drawn at the cell pitch; every cell the same size with the same gap everywhere, also
      where two compartments touch and for one-cell compartments (no cell narrower or cut at a seam, in the window, in a kit
      window and in the wizard's "This is how it looks" preview); tiles, footprints and the selection exactly on their
      cells, hovered up to the cell's edge; the ring `aaa/aba/aaa`.
- [ ] Section captions: Take all / Put all in and Sort sit right of the tab, as high as it and in its text size, the labels in
      the middle of their buttons both ways (the same on all UI sizes), Sort with its icon; Sort lays out an own container, a
      crate, the ground and a kit window, and is greyed while a move out of that container is under way;
      none on a body's worn gear, on a living person's gear that the settings keep look-only, nor in the Arsenal; a narrow window
      drops Sort first, then Take all, before the tab is cut under three letters.
- [ ] Sort cycles: the button reads "Sort: Size" (or the last order used) and a click sorts by the next one - Name (A to Z), Weight
      (heaviest first), Size (largest first), Type (weapons, ammo, gear, medical, the rest) - with every Sort button of the window
      (all sections, an open kit's window) changing its words at once and the caption line not moving; the tooltip names what the next
      click sorts by; the order survives closing the window and restarting the game; a second player looking into the same crate sees
      the same places; Sort on an empty container and a kit still works.
- [ ] Kits (EFAK) open and pack by drag; the kit window's title row: Take all and Sort as tall as the cross, the fill text and
      the name centred in the row's height beside them; radios (TFAR / ACRE2) hint, menu, Open radio; ACE cargo cards, Unload.
- [ ] Magazine repack by drop, Repack all, the fill bar.
- [ ] Surplus moves on: `player addItemToUniform` of more than the uniform's grid holds (a loop of 30 bandages, with the window
      shut and open): within a second the rest lies in the vest, then the backpack, none of it as overflow while a cell is
      free; a full unit keeps it as overflow (red); `addItem` / `addMagazine` / `addWeapon` and a loadout set the same way. On
      an AI in the group (listen server and dedicated), on a body opened from the window and on a looted person. ACE Arsenal
      open: nothing moves, an add with no free cell is taken back; after the close the surplus moves on first and the notice
      names only what fits nowhere. The setting "Move overfull items on" off: nothing moves. The RPT: no `Error`, no item lost
      or doubled (count before and after).
- [ ] Sounds, the looting pose, a movement key closes the window.
- [ ] Hotbar 4 to 0: bind by drag, use, the HUD strip.
- [ ] No vanilla inventory: the Gear key, ACE's "Inventory" on an unconscious soldier, ACE's "Open backpack", a crate and a
      vehicle all open ours; after a respawn, a team switch and in Zeus remote control as well; with Better Inventory
      loaded `findDisplay 602` stays null; the setting "Replace the vanilla inventory" is gone from the CBA menu.

## C. ACE Arsenal panel

- [ ] Panel only on the uniform, vest, backpack tab; as tall as the side lists; the inventory's glass and corner radius.
- [ ] Add an item: it lands on the grid; no free cell: taken back with ACE's message; greyed rows light up again.
- [ ] Re-sort by drag, R, stacking; drop outside removes; right-click Remove / Remove all of this kind; Delete.
- [ ] Drag a row of the list onto a cell; a plain click stays ACE's; wheel sets the count while dragging;
      Ctrl+wheel over a tile adds or removes one; plain wheel scrolls.
- [ ] Staging grows with its contents, scrolls, the footer warns, deleted on close.
- [ ] Sections fold and stay folded per class; the title row: the container's picture, its name beside it in the title size of
      the inventory's columns and centred on the picture, a hairline under it; picture, tabs and grids on one left edge, the
      weights on one right edge, the same room round everything; the staging subtitle on the caption's baseline.
- [ ] The first press on a tile drags; ACE's arrow keys work after hovering the panel; Escape closes ACE; search.
- [ ] The hint at the mouse lies above ACE's list.
- [ ] Loadout load and import, Remove all, picking another backpack: the panel rebuilds.
- [ ] A load-0 backpack with an own drawing holds items in the Arsenal.
- [ ] Vanilla Virtual Arsenal: setting ace / block / vanilla; Zeus and Eden.
- [ ] Eden's ACE Arsenal: the panel and drag on the clone.

## D. Setup wizard

- [ ] Opens from ESC > Options, the cog in the inventory, Eden's Tools menu; every button works in Eden.
- [ ] Start: switch Default / Realism / Weight, "Keep my own rules", What you changed (remove, jump), Advanced.
- [ ] Items: search, kind chips, "Only classes with own rules" lists no containers, steppers, drawing an L,
      Apply / Discard / Back to the preset, the preview.
- [ ] Containers: search, chips, load-0 backpacks listed, Paint (colours, drag-painting, the preview with gaps),
      Blocks mode and switching between the two, Same as (Follow, Copy cells, Unlink), Fill / Clear, rows up to 40,
      the limits 400 cells and 24 compartments.
- [ ] Items: the Weight field (kg, a comma works, empty is config's own, "abc" is refused with a hint) and the Name field:
      Apply writes `weight=` and `name=` next to size and stack, the inventory shows them, emptied they go; Back to the preset
      takes all four away.
- [ ] Search with wildcards in Items, Containers and Same as: `B_Bergen*`, `*Carryall*`, `*_F`, `B_?ergen*`; a plain word still
      finds itself anywhere; the page count and Ctrl+F keep working.
- [ ] Tree view (List | Tree beside the search): pick a backpack, switch to Tree - the rows are indented with counts; "Up one
      level" finds the family under its hidden `_Base` class; the arrow at a row starts the tree there; "Start at picked".
      Click a row: the editor says "Applies to X and the N classes built on it"; Apply writes ONE `class=X+ > grid=...` rule
      (Review's text), every row then says "inherited from X"; give one deeper class its own grid - it keeps it after a second
      tree Apply; "Only this class" and Back to the preset in tree mode; Undo; the same on Items with size and weight.
- [ ] Export / Import in both editors: Export on one class and on a tree (one line per class), alone and as a client in
      multiplayer (a box to copy by hand); Import of those lines, of rules and of nonsense ("Nothing to import"), one Undo each.
- [ ] Review: edit the text, Import, Copy, Save to the server (admin) and to the mission, Undo / Redo, Reset,
      personal presets.
- [ ] After Save the inventory shows the drawn shape; an old setting with `base=tarkov` still loads.
- [ ] The class index builds without stutter, shows progress, mod names are right.
- [ ] Button widths at UI size small; 4:3.

## E. Other

- [ ] Config keys (a test addon with `einv_grid = "1x3+5x7+1x3"` on a vest and a backpack class, `einv_size = "xx/x-"`,
      `einv_stack`, `einv_weight = 0.5`, `einv_name` on a few items): the window shows the compartments, the L, the stack,
      the weight in kg and the name; a subclass that sets nothing has the same; `einv_grid = ""` on a subclass takes it back;
      a rule for the class in the rules text beats the key; the older `einv_grids[]` still works and loses to `einv_grid`;
      a wrong value (`einv_size = "2x"`) is one RPT line `Config of <class>:` and the other keys still count.
- [ ] `copyToClipboard ([["B_Carryall_blk", true]] apply {_x call einv_items_fnc_configEntry} joinString endl)` after changing a
      class in the wizard gives its lines; `[text] call einv_items_fnc_parseConfigEntry` on them gives the class and the values
      back (`einv_grid` as the rules write it).
- [ ] Weight tiers: no sprint from Overloaded, walking from Critical, ACE fatigue follows.
- [ ] Zeus Enhanced: Inventory lock in the right-click menu and the module.
- [ ] Performance: a big mod pack, a crate with 300 items, the window opens in under a second.
- [ ] The RPT after every test: no `Error`, read every `einv` line.
