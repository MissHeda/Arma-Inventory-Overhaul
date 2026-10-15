# Changelog

All notable changes to Enhanced Inventory. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 0.4.7 - unreleased

### Added

- Tile scale (`einv_gui_cellScale`, 0.8 to 1.3, per player): larger or smaller cells and pictures, from the next opening. Where both columns would no longer fit the screen the largest scale that fits is used and the RPT says so once; ACE Arsenal's panel caps it for itself so its ten columns still fit beside ACE's list.
- Rounds on magazines (`einv_gui_magazineText`, per player, beside the fill bar): off hides the "17/30" on magazine tiles and keeps the fill bar.
- Camera when opening (`einv_gui_cameraDefault`, per player): the soldier (third person, as before) or off (first person). The header's camera button still turns it for the open window; the choice is no longer remembered in the profile.
- The RPT names why the window closed, one line each time: `window closed: <reason>` (a movement key, Escape, the Gear key, the close button, the unit died or passed out, the vanilla inventory under it, another mod or script, ...).
- Weight: the CBA setting "Weight tiers" (`einv_weight_enabled`) switches the tiers off completely - no sprint block, no walking only, no extra fatigue, no tier messages; the weight card shows only the kilograms and ACE's own fatigue works alone.
- ACE interaction "Inventory" on other people (new optional addon `compat_ace_interaction`, loads with ACE's interaction menu): opens them as the action menu's "Inventory" does, under the same "Living persons" settings and reach.
- Setup wizard: the CBA setting "Who may open the setup" (`einv_setup_access`, default Admins only) keeps the wizard to the server, logged-in admins, CBA's whitelist and Zeus; others get "Inventory setup is for admins on this server." Eden and CBA's Addon Options are unaffected.
- Setup wizard: "Everything else" on the Start page - one size and stack for items no rule answers, and a grid for uniforms, vests and backpacks no rule answers, with Apply and Clear. It writes the new rules selector `all` (`all > size=1x1 stack=10`, `all kind=uniform|vest|backpack > grid=6x4`), which is asked after the preset and before the built-in answer, so it fills only the gaps; a preset's rules without conditions (Default's `size=1x1 stack=1`) give way to it. Review words it.

### Changed

- The context menu holds only what belongs to what is under the mouse. A tile: Inspect, Equip / Attach to / Load into where they apply, Drop, Select all in its container, and the item's own rows (Open kit, Unpack everything, Open radio, Use as active radio, Repack all, the hotbar's, other mods' CBA rows, Open arsenal on an ACE arsenal box). A worn slot: Inspect and Drop (to the ground), a weapon's Take off for each part, the radio rows. A selection of several tiles: Deselect. Free cells: Select all. Moving over is the double click and the drag, dropping is Delete, taking a worn item off is Ctrl+click, sorting is the Sort button.
- The Sort button on a section's caption line and on a kit window's title row cycles through the orders and says which it sorts by: "Sort: Name", "Sort: Weight" (heaviest first), "Sort: Size" (largest first, as Sort always did) and "Sort: Type" (weapons, ammo, gear, medical, the rest). A click steps to the next order and sorts by it, every Sort button on the window changes its words at once, and the choice is kept per player in the profile. The container is sorted where it is local, so everyone looking into it sees the same places.

### Removed

- The context menu rows "Move over", "Move N items over", "Drop N items", "Sort <container>" and "Take off" (a worn slot keeps "Drop"; "Take off" put the item into the player's own gear first, which Ctrl+click on the slot still does).

### Fixed

- The name at the mouse is no longer covered by the accent ring of a slot: the ring round the slot under the mouse (the Backpack slot's, over "Carryall Backpack (Coyote)") was made after the name and drawn over it; the name, and the comparison card, are now made again over anything made after them.
- Turned items: the picture of a turned tile, and of a dragged item held turned (also from ACE Arsenal's list), turns a quarter clockwise round the tile's middle and fits the turned box, instead of showing squashed and out of its tile.
- The context menu no longer hides behind the tiles: it is a layer of its own that takes the focus and is made again on top when anything is drawn after it; a menu on a tile whose crate was redrawn by another player's change closes. A section's button no longer keeps the focus after its click.
- The window closing at once with some mods loaded: when another mod lets the engine open the vanilla inventory as well, the window no longer opens on top of it (made a frame later as its child, it was closed along with it); the guard closes only the vanilla inventory (IDD 602), never the window or another mod's display, and opens the window again should it have been closed with it.
- ACE Arsenal: dragging from ACE's list into the grid works on the first press: the row is taken where the press was, the drag starts after 5 pixels in any direction (up and down too), and a press is no longer forgotten in the frame it came. A press on ACE's "-"/"+" never drags; an item ACE would not add says "ACE does not allow this item here" instead of doing nothing.
- ACE Arsenal: the panel's title, its name and the hint line are sized in ACE's own grid, as ACE's list beside them, instead of the inventory window's units, which stood a size off ACE's texts on some screens.
- ACE Arsenal: the list no longer goes grey after a click on a row. ACE looks at its list again at every pick and greys every row by the container's weight (a backpack with a load of 0, like ACE's Telescopic Ladder given cells by the rules, refuses everything), and only the "+" of the row picked was lit again; now the whole list is lit again by free cells a frame after each pick, as it is after an add. What the grid has room for stays lit; adding already ignored the weight.
- The small stutter on every move: an answered move draws again only the sections it touched (and the weight card and hotbar counts when it was the soldier's own gear) instead of building the whole window, the camera on the soldier is no longer restarted by every build or fold, and ACE's weight arriving a moment later redraws only the weight card. "Log window timings (debug)" (`einv_gui_debugTiming`, per player, off) writes build and redraw times to the RPT.
- A magazine dragged into the weapon in the hands plays the weapon's reload animation again (with or without the looting animation; in the looting pose the soldier straightens up for it), not only its sound.
- The weapon no longer comes out of the inventory lowered: closing the window gives the soldier his weapon back as he held it when it opened.
- Another person's night vision slot is captioned "Night vision" (was "Eyewear", which read as the goggles' slot).

## 0.4.0 - unreleased

### Added

- ACE Arsenal panel: a grid panel on ACE's own display for the selected uniform, vest or backpack tab. Items ACE adds land on the grid, tiles are re-sorted by drag, a tile dropped outside leaves the container, and an add with no free cell is taken back with ACE's message.
- Arsenal staging space: a grid under the container that holds items while the soldier rearranges; it is deleted with ACE's window and grows with its contents.
- Arsenal list drag and wheel: a row of ACE's list can be dragged straight onto a cell, the wheel sets the count while dragging, Ctrl+wheel over a tile adds or removes one. The panel's sections fold.
- Backpack as the fourth slot of the gear row (headgear, uniform, vest, backpack).
- Shaped grids: `grid=` takes a mask (`grid=xxxx/x--x+2x3`, `x` a cell, `-` a hole) and a whole container can be one canvas with a letter per compartment (`grid=abbbbbc/abbbbbc/-bbbbb-`), drawn where it was painted.
- Shaped items: `size=xx/x-` makes an L of three cells; the footprint follows the shape in both orientations, and R turns it. Place records gain an optional rotation.
- `like=CLASS`: a class takes another class's resolved size, stack and grid.
- Config keys for mod authors, written exactly like the rules: `einv_grid = "1x3+5x7+1x3";` (any `grid=` value, shapes and canvases too) on a custom uniform, vest, backpack, crate or vehicle class, and `einv_size = "2x1";` (also a mask like `"xx/x-"`), `einv_stack = 10;`, `einv_weight = 0.5;` (kilograms, as `weight=`), `einv_name = "Short name";` on any item. A subclass inherits them as config does. They sit below the server's rules text and above the presets; the older `einv_gridSize[]`, `einv_stackSize`, `einv_grids[]` and `einv_slots` still work, the new keys win. A value that cannot be read is named in the RPT once.
- `einv_items_fnc_configEntry [class]` writes the config lines of a class from what it is now (only the keys that differ from what the class gets without the rules text, from its own config and the preset), and `einv_items_fnc_parseConfigEntry [text]` reads such lines back, one class or several - for the wizard's export and import.
- Grids up to 10 cells wide.
- Presets Default and Realism. Default gives containers 20 % more room; Realism is the former Tarkov preset and stacks as Default does.
- Setup wizard: paint the compartments with colours, a Blocks mode for the block-by-block editor, "Same as another class" (follow with `like=` or copy the cells), a plain preset choice on Start with the cell size under Advanced, a welcome page and a "What you changed" list that removes a rule or jumps to its class.
- Setup wizard, Items: a Weight field (kilograms, as `weight=`) and a Name field next to size and stack, with the same Apply, Discard and Back to the preset; a field emptied takes its own value away.
- Setup wizard, Containers and Items: Export copies the config lines of the picked class (`class CfgVehicles { class B_Carryall_blk { einv_grid = "1x3+5x7+1x3"; }; };`, worked out from the draft, so a design can be exported before Save; for an edit of a whole tree one line per class), and Import applies pasted config lines - or rules, as Review's Import reads them - to the draft in one undo step.
- Setup wizard, class lists: the search takes wildcards (`B_Bergen*`, `*Carryall*`, `?` for one character), and a List | Tree switch shows a class with every class built on it as an indented tree with counts ("Up one level" starts it at the parent, which finds a family that shares a hidden `_Base` class). A class picked in the tree is edited with everything built on it: Apply writes one rule `class=X+ > ...` instead of one per class, a class with a rule of its own further down keeps it, and the lists say which rule covers a class ("your rule", "inherited from X", "preset").
- Window details: a right-click on another tile while a menu is open moves the menu, and counts and fill texts sit on a dark pill so white pictures do not hide them.

### Changed

- Cells are the only room: what fits into a container is decided by free grid cells alone. Weight is still shown and drives the weight bar and ACE fatigue, but no move is refused because of it.
- The own arsenal window is replaced by the panel inside ACE Arsenal (the vanilla Virtual Arsenal handling stays, with "ace" in place of "enhanced").
- The weight bar loses its yellow and red ticks: the fill colours by tier and the texts name the next limit and its effect on movement.
- Stackable tiles show n/stack in a flat box bottom right, nothing for a stack of one.
- Backpacks with load 0 take an own grid and are listed by the wizard.
- The engine's own commands (`addItem`, `addItemToUniform`, `addMagazine`, `addWeapon`, loadouts, ACE, mission scripts, the arsenals) no longer overfill a container: whatever a unit's uniform, vest or backpack holds beyond its grid is moved on to the next of its containers with free cells (uniform, then vest, then backpack) by the machine the unit is local on, a moment after its cargo changed - on the player's loadout change, the engine's Take / Put / InventoryClosed, a loadout set, a changed rule set and while a window shows the overflow, bodies and looted persons included. What fits nowhere stays overflow, as before; nothing is dropped or copied. Nothing moves while ACE Arsenal or the vanilla arsenal is open (the arsenal gives back what has no free cell), and once it closes the surplus moves on before the overflow is reported.
- The wizard has four steps: Start, Items, Containers, Review.
- The window is the only inventory. The unit's `InventoryOpened` handler always keeps the vanilla one away (on a respawn, a team switch and in Zeus remote control as well), and a vanilla inventory that another mod or script brings up anyway is closed at once - by its load event and by a check every quarter second, with the window open or not. Crates, the ground, vehicles, bodies and persons open here for every player.
- A window that cannot be created opens nothing (the RPT says why) instead of falling back to the vanilla inventory.
- Section captions: "Take all", "Put all in" and a new "Sort" button (the context menu's Sort row stays) stand beside the tab as high as it and in its text size, with the labels centred in their buttons both horizontally and vertically - the engine centres them now, so the button no longer reads lopsided. Sort is on every container section the player may change, also on kit windows, and is greyed while a move out of it is under way; the tab gives up room to the buttons first, then Sort goes, then Take all.
- Kit windows: Take all and the new Sort button are as tall as the cross, and the name and the fill text are centred in the title row's height.
- The ACE Arsenal panel is drawn like one of the inventory's columns: the inventory's glass and corner radius instead of ACE's black block, the container's picture and name in a title row of the columns' title size (the font no longer ACE's RobotoCondensed, 0.66 UNIT, centred on the picture) with a hairline under it, one padding (0.4 UNIT) round and between all bands so the picture, tabs, grids and loads sit on common edges, the staging subtitle in the caption's size, and the hint line in the inventory footer's size under a hairline.

### Removed

- The container weight limit: `roomByWeight`, `getLoadState`, the "Limit by room only" setting, the load bars, "full" chips, red free cells, weight marks and every TooHeavy path. `getMaxLoad` stays only to size a container's default grid.
- The own arsenal window.
- The greyed "Groups" step of the wizard; group rules (`@group > ...`) are edited in the Review step's text.
- The vanilla inventory: the setting `einv_gui_replaceVanilla` ("Replace the vanilla inventory"), `einv_gui_fnc_openVanilla` and every path to it - the fallback when the window cannot open, the backpack-only vanilla view of a person, the vanilla route for locked containers, the hint that shared containers always open here, the hotbar's "Put on the hotbar" / "Take off the hotbar" entries of CBA's vanilla item menu, and the lock addon's closing of the vanilla display.

### Fixed

- Better Inventory (workshop 2791403093) no longer pulls its vanilla display in over the window: a vanilla inventory that loads is closed at once (display load event, plus a check every quarter second), and its Shift/Ctrl stack move, which needs state only its own display sets up, stays off while the window is open.
- A backpack dropped to the ground no longer vanishes. The cause, found in game: `removeBackpack` leaves the backpack just taken off in a plain holder of the engine's own until the end of the frame and deletes both then - the pile search took that holder for a pile with something in it and put the new backpack into it. A backpack now joins only a pile of ours (`GroundWeaponHolder_Scripted`) or a fresh one, the backpack taken off is marked so its holder is never a target, and the RPT names the pile a backpack goes onto.
- Setup wizard, Containers: Paint and Blocks preview the same configuration identically and as the inventory shows it - a painted layout that matches the flow is handed over without positions - and the Paint canvas cells are the same size as the Blocks cells.
- Taking a backpack off no longer loses it: the slot is read again a frame later when the engine is late, an arrived backpack is also recognised by the pile's count, and a failed drop puts the backpack back on.
- `hasSpace` counts partial stacks, and the arsenal lights its rows by the same answer.
- A press on the blank part of ACE's list no longer drags the old selection.
- The arsenal's hint no longer sinks under ACE's list: the focus leaves the list while the mouse is over the panel, and goes back to it when the mouse leaves, so ACE's arrow keys work without a click on the list first.
- The staging holder is made only when the soldier is this machine's own root, and a local-only root is never broadcast.
- Legacy place records without a rotation element are read without an out-of-range select.
- The wizard no longer uses commands newer than 2.16; Apply in the cell editor stays off until the drawing changed; `size=mass` items stay within the 8-wide item drawing.
- The count badge keeps its right alignment without a theme box.
- The Ctrl state follows every mouse and key event.
