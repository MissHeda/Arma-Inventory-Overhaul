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

Settings the server forces (`cba_settings.sqf`): `einv_items_rules`, the presets, locks, sounds, hotbar.
A client can see them and cannot change them.

## A. Multiplayer

- [ ] Two players look into one crate: A moves a tile, B sees the new place without reopening.
- [ ] Both grab the same item at once: one gets it, the other sees the refusal, nothing is duplicated.
- [ ] Crate, vehicle, ground pile: take, put, Take all, Put all in, Sort; a player who joins later sees the same places.
- [ ] Vehicles: from outside (Gear key and the action menu; a car, a truck, a helicopter) the cargo shows as a section with the ground
      beside it; inside as driver and as passenger the Gear key opens the vehicle's cargo, W/S/A/D do not close the window, it stays
      open and moves work while it drives, a drop goes into the vehicle; ACE interaction "Inventory" on a car, a helicopter, a boat
      and a static weapon (not on a locked one, not from a seat); with ACE a "Cargo" section under it (Open a loaded crate, Unload);
      with `ace_vehiclelock_LockVehicleInventory` on, a locked vehicle without a key shows as locked. The RPT has `asked:` and
      `open: ... kind vehicle rows x cols ...` for each, and no `Error`.
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
- [ ] Searching a crate: the UNSEARCHED block opens after about 2 s, then the hatched tiles reveal one by one, also on a painted compartment's cells.
- [ ] Holes in grids: no hover on a hole, the footprint turns red over one, a drop beside a hole.
- [ ] L-shaped items: tile border, R turns around the grabbed cell, a small item fits into the L's corner.
- [ ] Grids 10 wide: cell 37 px at 1080p, the storage column scrolls, the camera stays visible while looting.
- [ ] Painted compartments: where two touch there is a gap as wide as between flowed blocks, along the whole column or row
      line, and each compartment lies on its own faint rounded panel, so every compartment reads as a block (the owner's
      15-compartment canvas: each one tellable from its neighbours); compartments line up as painted; every cell the same size
      with the same gap, one-cell compartments too; a wide compartment under two narrow ones shows the gap between two of its
      own cells, inside its one panel; an L-shaped one's panel follows its cells with no brighter overlap; the ring `aaa/aba/aaa`
      (the ring's panel open in the middle, the inner cell on a panel of its own); flowed containers have the same panels. The
      same in the window, a kit window and the wizard's "This is how it looks" preview (Paint and Blocks alike). Tiles,
      footprints, selection frames and the band exactly on their cells, a tile over a gap inside its compartment hovered and
      dropped on all along, the gap between two compartments no cell (no hover, no footprint); a wide canvas in a column and in
      a kit window: nothing cut on the right.
- [ ] Section captions: Take all / Put all in and Sort sit right of the tab, as high as it and in its text size, the labels in
      the middle of their buttons both ways (the same on all UI sizes), Sort with its icon; Sort lays out an own container, a
      crate, the ground and a kit window, and is greyed while a move out of that container is under way;
      none on a body's worn gear, on a living person's gear that the settings keep look-only, nor in the Arsenal; a narrow window
      drops Sort first, then Take all, before the tab is cut under three letters.
- [ ] Text follows the tile size (issue #10): at 1920x1080 set "Tile scale" (`einv_gui_cellScale`) to 1.3 and open the window -
      section captions and chips (Backpack, Tactical rig, Take all, Put all in, Sort, the weight, the search chip), the column
      titles, the box's name, "+N empty rows", the page bar's words, a kit window's title row, the footer's key hints, hint and
      version and the window title are about a fifth larger than at the default 1.1 (a third over 1.0), nothing overlaps or is cut, Take all and Sort are as wide
      as their labels; at 0.8 the words are as at 1.0; at 1280x720 (or a small UI size) the captions stay readable (12 px); in ACE
      Arsenal's panel the words follow the panel's own capped tiles and the panel still fits.
- [ ] Sealed body containers (issue #6): kill a soldier with a full backpack and loot him - his uniform, vest and backpack
      each show one hatched block of 3 rows marked UNSEARCHED beside their box (the same size for a small pouch and a big
      backpack), no tiles, no weight in the caption, no Take all or Sort, no strip, a chip that says no time; the hint over the
      block and the caption says nothing of the load; Put all in from your gear does not go into them. With "Search starts on
      click" on: the chip says Unsearched, a click on Search or on the block starts it (the block's ring turns, "Searching..."),
      the cross stops it ("Stopped"). After about 2 s the block turns into the real grid with every item a hatched footprint,
      then the items are found one by one; closing and opening the body keeps what was found; a second player still sees it
      sealed. An empty backpack opens after the 2 s and shows its empty grid. With the setting off every block starts by itself.
      A living person (search persons on) the same.
- [ ] Tarkov reveal everywhere (issue #16): a crate, a vehicle opened from outside and the vehicle you sit in (searching on),
      a pile with "Search the ground" on, a bag lying about and a backpack opened from inside a crate each start as the
      UNSEARCHED block; Search opens it after about 2 s into the grid with hatched footprints, then the tiles reveal one by
      one. A pile you dropped an item onto (nothing else in it) is open to you at once.
- [ ] Parallel searches (issue #16): open an AI's body, click Search on the uniform, then at once on the vest: both rings turn
      and both chips count down, neither waits for the other; the cross stops only its own box, Search resumes it. Set
      "Search time: vests" to 3 on the General page: the vest takes three times as long as the uniform; "Search time:
      bodies" at 2 doubles both; a factor at 0 shows that kind at once. Frame time stays flat with five boxes searching.
- [ ] Search chip width (issue #16): the chip reads "[ring] Unsearched [Search]" (sealed) or "[ring] Searching 0:07 [x]" with
      one even gap between the parts and no empty space before the button; it keeps its place while the seconds tick and is
      remade when the time goes from 1:00 to 0:59.
- [ ] A drag over a sealed block (issue #16): drag a bandage from the ground onto a body's unsearched backpack block: the block
      tints red and reads "Search it first", letting go there moves nothing and the footer says "Search it first".
- [ ] Search bypass (issue #17): kill an AI with a full backpack, do not search it, drag the backpack onto the ground and right
      click > Open it: it is an UNSEARCHED block, and so is it in a crate you drag it into. Search it there to the end, then
      drag it back onto the body's backpack slot: on him it is open to you with every item found, while a second player
      (multiplayer, body local to the server and to a headless client) still sees it sealed until he searches it. Search a second body's vest on the body,
      then drop it: on the ground it is open to you at once with every item found. Drop your own backpack: no block for anyone
      while "Search the ground" is off.
- [ ] Items onto a body (issue #18): kill a soldier and open him with a pile on the ground beside you (drop a helmet, a vest, a rifle and a bandage there). Search his vest and backpack to the end, then drag the bandage from the Ground section onto the vest's grid and from your own gear onto the backpack's: both go in (multiplayer too, with the body local to the server, to a headless client and to a player); a sealed block takes nothing. Drag the helmet onto the doll's "Headwear" slot: green, it goes on, his old helmet lies on the cell the new one came from; the same for the vest and backpack (the old one comes with what it holds); the rifle on any doll slot is red "That does not go there", a helmet on his vest slot too; an item out of an open kit is red. A living person's doll takes nothing, whatever the settings say.
- [ ] Loot and own apart (issue #7): open a body - the loot column reads "Loot - <name>" with a blue strip under its title, a
      cooler pane ringed in blue and blue-tinted caption tabs; the body's uniform, vest and backpack read "Pockets - <name>",
      "Tactical rig - <name>", "Backpack - <name>", yours "Pockets", "Tactical rig", "Backpack" in the plain "Your gear" column with the
      orange accent; a crate reads "Loot - <crate>", the ground "Loot - Ground", what lies around "Loot - Nearby"; the same with
      "Where other storage opens" (`einv_gui_lootSide`) on either choice; ACE Arsenal's panel looks as before.
- [ ] Sort cycles: the button reads "Sort: Size" (or the last order used) and a click sorts by the next one - Name (A to Z), Weight
      (heaviest first), Size (largest first), Type (weapons, ammo, gear, medical, the rest) - with every Sort button of the window
      (all sections, an open kit's window) changing its words at once and the caption line not moving; the tooltip names what the next
      click sorts by; the order survives closing the window and restarting the game; a second player looking into the same crate sees
      the same places; Sort on an empty container and a kit still works.
- [ ] Kits (EFAK) open and pack by drag; the kit window's title row: Take all and Sort as tall as the cross, the fill text and
      the name centred in the row's height beside them; radios (TFAR / ACRE2) hint, menu, Open radio; ACE cargo cards, Unload.
- [ ] Kits (issue #19): an IFAK with contents in capacity mode - its window's title says "n / 35 mass" with n > 0, and a full IFAK
      refuses one more bandage ("Not enough space"); in the debug console `[["efak_IFAK_1"] call efak_core_fnc_getUsedCapacity,
      [["efak_IFAK_1"] call efak_core_fnc_getContents] call efak_core_fnc_getUsedCapacity]` - the first (the class, which
      `fnc_canPack` and `fnc_fillState` now both pass) is the used mass with no RPT error; if only the second is, switch both.
- [ ] Kits (issue #19), two players: B opens an IFAK lying in a crate, A packs a bandage into it and takes one out - B's kit window
      follows within a second; EFAK's own window used on A's own IFAK the same for A's open kit window.
- [ ] Kits (issue #19): `inheritsFrom (configFile >> "CfgWeapons" >> "efak_IFAK_1")` is `efak_IFAK` (rules `class=efak_IFAK+` reach
      the instances); a rule giving IFAKs `stack=3` leaves two IFAKs two tiles with no count badge, the wizard offers no Stack for a kit.
- [ ] Kits (issue #19): the CBRN bag (Enhanced Utility Pouches) takes an empty uniform let go on a free cell, on that cell; arrange
      an IFAK, save and load the loadout in ACE Arsenal - the kit comes back with its contents (its arrangement inside may start
      fresh under its new instance class); a full backpack with an IFAK as the last thing saved and loaded - the IFAK is there.
- [ ] Magazine repack by drop, Repack all, the fill bar.
- [ ] Surplus moves on: `player addItemToUniform` of more than the uniform's grid holds (a loop of 30 bandages, with the window
      shut and open): within a second the rest lies in the vest, then the backpack, none of it as overflow while a cell is
      free; a full unit keeps it as overflow (red); `addItem` / `addMagazine` / `addWeapon` and a loadout set the same way. On
      an AI in the group (listen server and dedicated), on a body opened from the window and on a looted person. ACE Arsenal
      open: nothing moves, an add with no free cell is taken back; after the close the surplus moves on first and the notice
      names only what fits nowhere. The setting "Move overfull items on" off: nothing moves. The RPT: no `Error`, no item lost
      or doubled (count before and after).
- [ ] Sounds, a movement key closes the window.
- [ ] Pages: a crate with more than 10 rows of loot shows a bar; arrows turn the page; a dragged item held over an arrow turns it; the search finds an item on another page; holding F over a crate stays smooth.
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
- [ ] Tab switch folds anew (issue #3): open the vest and backpack sections by hand in the uniform tab, switch to the vest tab -
      only the vest's section is open, uniform and backpack folded, staging as it was, order uniform, vest, backpack, staging,
      scroll kept; the same for the backpack tab and for picking a kit (IFAK) in ACE's left list (its sections open, they fold by hand).
- [ ] Kit grid (issue #4), once in the default (capacity) and once with a rule giving the kit cells (`class=efak_IFAK+ > grid=4x3`,
      `einv_compat_efak_fnc_roomMode` says "cells"): pick the IFAK in the left list, drag a row of ACE's right list onto a free cell
      and onto a taken one, drag from staging into the kit and a kit tile out to staging, move a tile inside the kit and turn it (R),
      drop one outside the panel, Delete, right-click Remove, Ctrl+wheel; a kit lying in the staging space and one in the vest.
- [ ] Kit grid (issue #19): picking an IFAK, an AFAK and a pouch of Enhanced Utility Pouches in the left list each shows that kit's
      grid; with the IFAK's field packing off and Arsenal packing on, staging -> kit and kit -> staging work like ACE's list; with
      Arsenal packing off both are red "This kit cannot be filled in the arsenal" and moving inside the kit still works; filling
      the kit with EFAK's own kits tab redraws the grid at once; "+" an IFAK from ACE's list and pick it - its grid takes items
      within a second (the prototype made ready); a kit packed in a kit there takes a drop on its tile.
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
- [ ] General, What you changed (issue #15): turn a server setting off its default, set Backpacks to Fixed 8x6, change the cell size, add a
      category, give one class a rule on Items - each is a row ("Search on click: on » off", "Every backpack: compartments 8×6") and the
      header says "N changes from the default setup"; the cross takes one back and the control above follows; the header chip's list
      (marked new / changed) and Save cover the same; Reset to default empties the list.
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
- [ ] Kits (with Enhanced First Aid Kits and Enhanced Utility Pouches): the Kits chip lists IFAK, AFAK, MFAK and the pouches, no
      numbered `efak_IFAK_7` anywhere, also not in Tree; the IFAK says "Now: capacity 35 (EFAK)" (the mission's capacity setting
      shows) and the note; paint 4x3 and Apply - Review shows `class=efak_IFAK+ > grid=4x3`, the card "4x3 (your rule)"; after
      Save a carried IFAK's window shows a 4x3 grid and "n / 12 cells", takes items only while a cell is free (never "not enough
      space" by mass), refuses with "No room" when full, an IFAK already fuller than 12 cells shows the rest apart and loses
      nothing; hint and inspect card say cells; Back to the preset returns the capacity and the open grid; `kind=kit > grid=12`
      and a test addon's `einv_grid = "3x3";` on `efak_IFAK` do the same; Export and Import of the IFAK's line. ACE Arsenal: drag
      bandages from ACE's list onto the IFAK's tile in the panel - with the grid, as many as there are cells ("Only 3 of 5 fit"),
      without it, as many as the capacity takes; a kit type set to "nothing" in its Arsenal setting says it cannot be filled there;
      EFAK's own kits tab still goes by the capacity. Multiplayer: two players packing the same kit of a crate one after the other.
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
- [ ] Medical defaults (issue #9, ACE + ACM + ACME + EFAK loaded): in a box, `ACE_fieldDressing` stacks 2, `ACM_Vial_Morphine` and `ACME_MannitolVial` 3 on 1x1, `ACM_Paracetamol`, `ACM_Syringe_10` types and `ACM_OxygenTank_425` (1x2) obey their rule although they are magazines, `ACM_BloodBag_*` and `ACE_plasmaIV_*` do not stack, `efak_IFAK_1` is 2x1 and `efak_MFAKPlus_1` 3x3; the check script reports no size or stack differences.
- [ ] Weight tiers: no sprint from Overloaded, walking from Critical, ACE fatigue follows.
- [ ] Zeus Enhanced: Inventory lock in the right-click menu and the module.
- [ ] Reload with an empty weapon (take the magazine out of the rifle first): R with a magazine only in the vest loads it; with
      the backpack on "Nothing" and magazines in vest and backpack loads the vest's, never the backpack's; with magazines only in
      the backpack the popup says to take one out and nothing loads; the RPT shows no `did not go into` line. The same with a
      pistol, a launcher and the grenade launcher's second muzzle (switch to GL, R). Drag a magazine from the vest onto the empty
      rifle, onto its magazine slot, and use "Load into" in the menu: it loads; read the RPT for `only without a muzzle name` /
      `only as a plain magazine`.
- [ ] Reload with use limits (issue #2): backpack on "Nothing", a partly used magazine in the rifle, allowed magazines in the vest
      and a full one in the backpack. R once: one animation, the vest's fullest magazine goes in, the old one goes where the game
      puts it (moved to the vest if it landed in the backpack), no hint, no second animation; hold R: still one reload. Fire the
      weapon empty and R: the vest's again. Drag the magazine out of the rifle in the window, close it, R: loads at once from the
      vest. Only backpack magazines left: R loads nothing and the popup says to take one out. With every limit on "Everything"
      R is the game's own (it may take the backpack's). The RPT shows no `asked for ... but the game loaded` and no `could not be
      loaded` line.
- [ ] AIME (Workshop 1376867375): self interaction > Change Ammo Type lists only the magazines the settings allow (backpack on
      Nothing: its magazines are not listed, and with nothing else a "take one out first" entry), loads the fullest of the class,
      also into an empty weapon; Inventory on a vehicle shows once (not twice with ACE interaction), not for a locked one or one
      out of reach; Open backpack on a living person only where "Living persons" allows; the click on a ground pile with a single
      item opens the window (diagonal stripes) while ground searching is on, and picks it up at once with searching off.
- [ ] Performance: a big mod pack, a crate with 300 items, the window opens in under a second.
- [ ] The RPT after every test: no `Error`, read every `einv` line.
