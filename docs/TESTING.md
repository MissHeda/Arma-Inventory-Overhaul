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
- [ ] Crate, vehicle, ground pile: take, put, Take all, Put all in; a player who joins later sees the same places.
- [ ] A client (not the host) drops a worn backpack, picks it up, swaps backpacks. `einv_storage_debugDrop` on.
- [ ] A client with another rules text gets the hash warning once; the rules setting cannot be changed on a client.
- [ ] Staging in the Arsenal on a client: move in and out, the crate is deleted on close, nothing lands on the server.
- [ ] Locks: side, group, admins, Zeus; a locked crate shows as locked for the other player.
- [ ] Living persons: open another player, take and put with the server settings.

## B. Inventory window

- [ ] Backpack slot: put on, swap, take off, drop (menu, Delete, drag to the ground), contents survive.
- [ ] Weight bar: colour by tier, the texts (next limit, effect), the preview on pick-up, no ticks.
- [ ] Right-click on another tile while a menu is open opens the new menu; right-click on empty space closes.
- [ ] Count badges `n/stack` only for stackable classes; magazine rounds bottom left; hotbar slots alike.
- [ ] Searching a crate: tiles reveal one by one, the ring follows a tile drawn in beside a painted compartment's gap.
- [ ] Holes in grids: no hover on a hole, the footprint turns red over one, a drop beside a hole.
- [ ] L-shaped items: tile border, R turns around the grabbed cell, a small item fits into the L's corner.
- [ ] Grids 10 wide: cell 37 px at 1080p, the storage column scrolls, the camera stays visible while looting.
- [ ] Painted compartments: 1:1 where drawn at the cell pitch, a gap only where two compartments meet, none inside one
      (`abbbbbc/abbbbbc/-bbbbb-`: `b` one whole block); tiles, footprints and the selection drawn in beside the gap,
      hovered up to the cell's edge; the ring `aaa/aba/aaa`.
- [ ] Kits (EFAK) open and pack by drag; radios (TFAR / ACRE2) hint, menu, Open radio; ACE cargo cards, Unload.
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

- [ ] Panel only on the uniform, vest, backpack tab; as tall as the side lists; ACE's colours.
- [ ] Add an item: it lands on the grid; no free cell: taken back with ACE's message; greyed rows light up again.
- [ ] Re-sort by drag, R, stacking; drop outside removes; right-click Remove / Remove all of this kind; Delete.
- [ ] Drag a row of the list onto a cell; a plain click stays ACE's; wheel sets the count while dragging;
      Ctrl+wheel over a tile adds or removes one; plain wheel scrolls.
- [ ] Staging grows with its contents, scrolls, the footer warns, deleted on close.
- [ ] Sections fold and stay folded per class; the container's picture in the header.
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
- [ ] Review: edit the text, Import, Copy, Save to the server (admin) and to the mission, Undo / Redo, Reset,
      personal presets.
- [ ] After Save the inventory shows the drawn shape; an old setting with `base=tarkov` still loads.
- [ ] The class index builds without stutter, shows progress, mod names are right.
- [ ] Button widths at UI size small; 4:3.

## E. Other

- [ ] Weight tiers: no sprint from Overloaded, walking from Critical, ACE fatigue follows.
- [ ] Zeus Enhanced: Inventory lock in the right-click menu and the module.
- [ ] Performance: a big mod pack, a crate with 300 items, the window opens in under a second.
- [ ] The RPT after every test: no `Error`, read every `einv` line.
