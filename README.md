# AIO - Arma Inventory Overhaul

An Arma 3 inventory built from scratch, in the look of Enhanced First Aid Kits' kit window. It replaces
the vanilla inventory with a grid: items are tiles of their own size that you drag, stack and split, and
loot has to be searched before you can see it. Ctrl+click or Shift+click on the tiles
select several of them to move together, and every box has a button that takes everything out of it ("Take
all") or puts everything of yours into the box beside it ("Put all in").

- **Hotbar on 4-0:** grenades, bandages, medicine, magazines, food and kits on a key - bandages go where you
  bleed most, tourniquets on the worst limb (ACE and ACM). Drag an item onto a slot of the "Hotbar" row in
  the inventory, or point at it and press the key; the bar shows on the screen in Arma's HUD style.

- **Grid panel in ACE Arsenal:** pick the uniform, vest or backpack tab and its grid opens beside ACE's list.
  What you add lands in the first free cell, drag tiles to sort them (R turns, stacks merge, a badge shows
  n/stack), drag them out of the panel - or right click, or the drop key (G by default) - to take them out. With no free cells ACE's
  add is taken back and the message says how much room to make. Drag a row out of ACE's list onto a free spot of
  the grid to put it in there (the wheel sets how many, Ctrl+wheel over a tile adds or takes out one). Under the
  grid a staging space holds things while you rearrange a full container - it grows as you fill it -; whatever
  is left in it is deleted when the arsenal closes. The vanilla Virtual Arsenal opens ACE Arsenal too, or is
  blocked, by server setting.

**Status:** 0.6.2, public beta: drag and drop between containers and equipment slots, searching loot,
server-checked moves in multiplayer, the grid panel in ACE Arsenal, shaped grids and items, the hotbar, the
setup wizard where you paint the compartments, your own colours and compatibility with popular mods are in.
Bugs and wishes go to Discord or the GitHub issues.
The plan is in [docs/BRIEFING.md](docs/BRIEFING.md), the design in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Requirements

- [CBA_A3](https://steamcommunity.com/workshop/filedetails/?id=450814997)
- [ACE3](https://steamcommunity.com/workshop/filedetails/?id=463939057)

Works with [Enhanced First Aid Kits](https://steamcommunity.com/workshop/filedetails/?id=3809430149) and
Enhanced Utility Pouches: kits and pouches open in windows of their own inside the inventory, things are
packed and unpacked by drag and drop. In ACE Arsenal, that mod's kits button (under the backpack) adds the picked
kit's grid to the panel - "Kit: IFAK (8/12)" under your folded uniform, vest and backpack - filled by dragging from
its list, emptied by dragging back, and shared with your containers and the staging space. Options other mods add
to CBA's item context menu (field rations, ...) show in the window's right-click menu; ACE's "Repack Magazines"
gives way to the window's own repack while that is switched on.

Works with ACE cargo: what is loaded into a vehicle (or a crate) shows in its inventory as a "Cargo" box, with
a card for each thing, Open for a crate and Unload with ACE's own time. Works with TFAR and ACRE2: the channel
and frequency of a radio show at the mouse, on the hint line and on the inspect card, and a radio of yours has
"Open radio" and "Use as active radio" in its right-click menu (TFAR's long-range backpack keeps its
frequencies while you move it around). Works with ACE vehicle lock and Zeus Enhanced. Works with ACE Interaction
Menu Expansion (AIME): its *Change Ammo Type* offers and loads only magazines that "Use items from ..." allows, its
inventory entries show only where the window opens, and its one-click pick-up from the ground opens the window while
the ground has to be searched, else puts a magazine (or a weapon you cannot wield at once) into the first container with
free cells instead of the engine's add. Works with Mavic 3 - Improved: a Mavic item dropped through the window (drag to the
ground, the drop key, Drop in the menu) is deployed as a drone, as that mod does for the engine's inventory, and a deployed drone has an ACE interaction
"Pack up drone" that checks the grid for room. Works with WebKnight's and KJW's Two Primary Weapons: the weapon on the back never shows as loot, and with
WebKnight's it comes into your hands when a move in the window empties them. With Better Inventory loaded, its handler for the vanilla inventory stays
quiet.

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
CBA setting "Inventory rules" (`aio_items_rules`), the same for everyone. The setup wizard writes it for you
(ESC > Options > Inventory setup, the "Inventory setup" button on CBA's Addon Options, Eden's Tools menu, the cog in the inventory - shown only to the server, the host,
single player and logged-in admins, other players never see it: the pause menu leaves the entry out and CBA's menu hides the button).
Its three pages:

- **General** is what holds for everything. *Containers:* for uniforms, vests, backpacks, vehicles and crates, Auto - the size
  the container's load gives (below) - or Fixed, every container of that kind the same size across x down: all uniforms 5x5 is one row
  of the page (the text's rule `all kind=uniform > grid=5x5`). A class with a rule of its own, and what a mod says about its own
  classes, still wins. *How room is worked out* tells in plain words, with the numbers as they are now, how a load turns into cells,
  how big an item is and what stacks, and holds the load per cell (`cell=`). Then the *server settings*, by topic, each with a small
  reset button while it is off its default (see "Server settings" below). At the bottom *What you changed* lists, in words, what
  single classes change on top of all that - when all uniforms are 10x10 by their kind and one is 5x5, only that one. The page's
  top row has Import, Export (the setup as text: your own rules, all of them written out, or the lines for a `cba_settings.sqf`) and Reset to default. The header's "4 changes" opens the list of what Save would store, and
  Save in the footer stores it.
- **Items** and **Containers**: you draw the cells of an item
  (an L, a T), paint the cells of a uniform, vest or backpack in colours - touching cells of one colour are one
  compartment, and it looks in the inventory exactly as painted -, build it block by block in Blocks mode, or
  make a class the same as another one (Same as: follow it with `like=` or copy its cells), set an item's weight and name next to its
  size, zoom and shift its picture in the tile where an icon is too small or too large (`icon=`, with a live preview) or give it another picture altogether (`picture=`: pick one from every item's picture, or type any texture path - the container boxes follow too), change a whole family at once - the Tree button
  shows the picked class among its relatives, and a click on one of them edits it as one rule, `class=B_Carryall_Base+` - and copy a class's config lines with Export - for a mod,
  or as a layout without a class name to share - or paste some in with Import (a layout goes to the class you have selected, so does a class this game does not have).
  A small reset button beside a field takes it back to what the class would be without a rule of its own.

It is plain text all the same. There is one preset, the default, which is realism: rifles from 4x2 to 7x2, magazines a tile or two,
backpacks with big tiles, and **nothing stacks** but a short list of consumables - vials, bandages, cannulas and syringes five to a tile,
injectors and tourniquets four, lozenges and IV lines ten, rations, splints and first aid kits five, bulky bags and devices one or two - and only where
the mod that adds them (ACE, ACM) is loaded. In crates, vehicles and piles on the ground every stack is five times larger (server setting
"Stack multiplier for crates and vehicles", 1 turns it off); what you wear keeps the plain stacks. What is worn gets a fifth more room than its load gives (a uniform is one block 6 wide and
2 to 5 rows high, a vest is magazine pouches of 1x2 and 2x2, a backpack one near-square block); vehicles and crates get as many cells as
their load. A text that names a preset of an older version (`base=realism`, `weight`, `tarkov`) reads as the default. Grids are ten cells wide.

- **Server settings:** every setting of this mod that is the same for everyone - searching, the hands' times, living persons, weight, the hotbar, repacking,
  locks, the vanilla arsenal, the stack multiplier of crates, whether players may pick their colours - is in two places at once, which are one and the same:
  a control of the wizard's General page, and a row of CBA's Addon Options, category "Arma Inventory Overhaul - Server", by topic. Change it in either and the
  other shows it - the wizard follows a change made in CBA's menu even while it is open, and what the wizard saves is what CBA's Server tab (in Eden its Mission
  tab) shows. We recommend the wizard; CBA's menu is 1:1 the same, and its first row says so. Each is a plain CBA setting under its own name
  (`aio_gui_searchTime`, `aio_weight_enabled`, ...), saved by the server, the mission or a `cba_settings.sqf`, forced or not, like the rules - so a
  `cba_settings.sqf` line `force aio_gui_searchTime = 0.6;` works, and the wizard's Export gives those lines. A setting set in the server's or the mission's
  `cba_settings.sqf` is greyed in the wizard: change it in that file. Saving in the wizard writes only what you changed, so a value the mission sets is never
  copied into the server's profile. The test builds 0.4.27 to 0.5.42 kept these settings in one text box, `aio_main_settings`; whatever is still saved
  there - in the server's profile or file, a mission or a scenario - is moved into the settings of their own by itself (the server's profile once and for
  good, a scenario as you open the wizard or CBA's menu in Eden; save the scenario then). What players set for themselves (tile scale, tile names, keys, the
  hotbar's look) stays in CBA's menu, per player, in the category "Arma Inventory Overhaul - Client". The old tables (`aio_items_sizeTable`, `stackTable`,
  `aio_storage_containerTable`) and the rules text are CBA text boxes of the Server category too (the setting names do not carry the category, so a
  `cba_settings.sqf` is the same under either).

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
- **Kits and pouches (Enhanced First Aid Kits, Enhanced Utility Pouches):** by default a kit holds what that mod's
  capacity allows and its window's grid grows as needed. Give it cells of its own and those cells are all its room - the
  capacity no longer counts, in the inventory, in kit windows ("8 / 12 cells") and in ACE Arsenal:
  `class=efak_IFAK+ > grid=4x3` (the `+` matters - the kits players carry are numbered copies of the type, `efak_IFAK_7`),
  `kind=kit > grid=12` for every kit, or `aio_grid = "4x3";` on the kit's class in a mod. The wizard's Containers step has a
  Kits chip and writes the `+` rule for you; "Back to the default" returns a kit to the capacity. That mod's own kit window and the
  "+" of its kits tab in ACE Arsenal still go by the capacity. In ACE Arsenal the kits tab shows the picked kit's grid in the panel
  (drag from the tab's list into it, out of it to remove, to and from your containers and the staging space), and an item dragged
  from ACE's list onto a kit's tile in the panel is packed into that kit - where the kit type's Arsenal setting allows it ("Remove
  only" lets things out, not in) and the kit does not follow "Use CBA default".
- **One crate, vehicle or a unit's uniform, vest or backpack:** give the object its own grid, which wins
  over every rule - `_crate setVariable ["aio_grid", "6x4+2x3", true];` (also `"24"`, `"rig:16"`, `"auto"`).
- **Mods:** add a preset of your own as a class of `CfgAioRulesets` (see `addons/items/CfgAioRulesets.hpp`; a text names it with
  `base=`, the wizard offers no choice of presets), or predefine your items in their own config class, in exactly the language of the rules text - a custom vest
  writes how its compartments are:
  ```cpp
  class CfgWeapons { class My_Vest { aio_grid = "1x3+5x7+1x3"; }; };       // grid=, also "xxxx/x--x+2x3", a canvas, "rig:16", "24"
  class CfgVehicles { class My_Pack { aio_grid = "abbbbbc/abbbbbc/-bbbbb-"; }; };
  class CfgWeapons { class My_Kit { aio_size = "2x1"; aio_stack = 1; aio_weight = 0.5; aio_name = "Short name"; }; };
  class CfgWeapons { class My_Bandage { aio_icon = "1.4@0.1,-0.05"; }; };  // icon=, the picture 1.4 times as large, moved a tenth right and a twentieth up
  class CfgWeapons { class My_Bandage { aio_picture = "my_mod\ui\bandage_ca.paa"; }; };  // picture=, shown instead of the config picture
  class CfgWeapons { class My_Bandage { aio_use = "backpack,vest"; }; };  // use=, usable from these containers even where a setting closes them (below)
  class CfgWeapons { class My_Bandage { aio_cat = "medical,misc"; }; };  // cats=, the categories it is in instead of the built-in one (below)
  ```
  `aio_size` is `size=` (`"2x1"`, a mask like `"xx/x-"`, `"mass"`), `aio_stack` is `stack=` (a number), `aio_grid` is
  `grid=` (containers: uniform, vest, backpack, crate, vehicle, kit), `aio_weight` is `weight=` in **kilograms** (not config mass)
  and `aio_name` is `name=` as plain text (a space is a space). `aio_icon` is `icon=`: how the item's picture is drawn in its
  tile for a picture that is too small or too large - `"1.4"` is 1.4 times as large (0.25 to 4), `"1.4@0.1,-0.05"` moves it too, a
  tenth of the tile across (right is positive) and a twentieth down (-1 to 1; the comma is the config's, a rules text writes
  `icon=1.4@0.1:-0.05` since its comma ends a statement). The tile cuts the picture at its edge, so it never leaves it. `aio_picture` is
  `picture=`: the texture the item shows instead of the one its config names (a file the game does not have falls back to the config
  picture and is named once in the RPT; a rules text writes `picture=/my_mod/ui/bandage_ca.paa`, slashes and `%20` for a space). `aio_use` is `use=`: the
  containers the item is whitelisted for - `uniform`, `vest`, `backpack`, `all` or `none` (a comma, a plus or a bar between; a rules text writes
  `use=backpack+vest`) - see "Use from containers". A subclass
  inherits what its parent sets, as everything in config does; `aio_grid = "";` takes it back. These sit below the server's rules text - a rule for the class still wins - and
  above the preset. Values are cut to the same limits as in the rules, and a mistake is named in the RPT. The older
  `aio_gridSize[]`, `aio_stackSize`, `aio_grids[]` and `aio_slots` still work (the new keys win). To get the lines for a
  class from what it is now, call `["V_PlateCarrier1_rgr"] call aio_items_fnc_configEntry`; `aio_items_fnc_parseConfigEntry`
  reads such lines back.

The full grammar and which answer wins are in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) ("Rules engine").

- **Living persons:** anyone can be opened from the action menu ("Inventory") - awake, unconscious or
  captive. Who may open whom, take and put items or take off worn gear are server settings on the wizard's General page, under "Living persons". Close one person to everyone with `_unit setVariable ["aio_noAccess", true, true];`;
  a container locked with `lockInventory` stays shut. A body opens whole as well, also through ACE's
  "Open <backpack>".
- **Everything nearby:** every pile on the ground and every crate within reach (setting "Reach", 3 m by
  default, on the same floor and in sight, at most ten) shows as a box of its own in the loot column; vehicles
  and bodies show when they are opened. `_object setVariable ["aio_nearby", false, true];` keeps an object
  out of that list, `lockInventory` as well. Each player can switch it off ("Show everything nearby").
- **Locks:** lock a crate or a vehicle to one side, one group or the admins: the Eden attribute *Inventory
  locked to* (category Arma Inventory Overhaul), Zeus Enhanced's right-click *Inventory lock* and module, or
  `[_crate, "side", west] call aio_locks_fnc_setLock;` (`"group"` with a group or a group's callsign,
  `"admins"`, `""` opens it again). Logged-in admins always open it, Zeus too unless the server switches
  that off (*Zeus opens locked containers*); in single player nobody is an admin. Players who may not open it
  see the crate as a locked box in the window, with a padlock and who it is for - nothing of what is inside -,
  and the engine's own inventory is locked for them as well. ACE's vehicle lock is respected: without the key
  a locked vehicle's inventory is shut.
- **Weight:** weight only colours the soldier's weight bar and drives ACE's fatigue: the bar turns yellow where
  ACE's fatigue starts to tire a jogging soldier (26.7 kg at ACE's defaults, it follows ACE's load factor and
  the soldier's performance), red at 45 kg (no sprinting, tiring faster) and ends at 60 kg (walking only), and
  its text names the next limit and what it does to movement - the wizard's General page, Weight. Nothing
  is ever refused because of weight, and no container has a weight limit: what fits into a uniform, vest,
  backpack, crate or vehicle is decided by its free cells alone (a container's config load is only used to size
  its default grid when nobody defined one). A section's caption still tells what its contents weigh.
- **Hotbar:** the keys 4 to 0 belong to the hotbar unless the setting "Hotbar" (`aio_hotbar_enabled`, the wizard's General page) is
  switched off - a server setting, the same for everyone. Only items that do something can be bound: bandages,
  tourniquets, splints and other ACE/ACM medicine are used on yourself through ACE's own treatment, grenades
  go into the hand, magazines reload the weapon in the hands, food and drink use ACE's field rations,
  Enhanced First Aid Kits open. Each player moves the bar in Arma's layout editor and chooses when it shows.
  `[0, "ACE_elasticBandage"] call aio_hotbar_fnc_bind;` and `[0] call aio_hotbar_fnc_use;` drive it from
  scripts.
- **Categories, locked compartments and single slots:** every item is in one or more categories - weapon, ammo (magazines), grenade
  (throwables and explosives), gear, medical, food, tool, misc - by a built-in mapping, which a rule or a mod can change: the rule
  value `cats=` (`class=ACE_fieldDressing > cats=medical+misc`) and the config key `aio_cat = "medical,misc";` (the wizard's Items
  step has a Category row of chips; the key is `cats=` because `cat=` is the condition on a tile's colour). The strip at the side of a
  loot box shows an item under each of its categories. A container can lock a compartment to categories: after a compartment's colon
  `grid=` takes a list joined with `|`, and the word `one` makes it a single slot that holds one item of any size.
  ```
  # a vest: two front pouches only for magazines, a loop for one grenade of any size, the back for anything
  class CfgWeapons { class My_Vest { aio_grid = "1x2:ammo+1x2:ammo+1x1:grenade|one+4x2"; }; };
  # a canvas: the side pockets a and c take medical items only
  class CfgVehicles { class My_Pack { aio_grid = "abbbbbc/abbbbbc/abbbbbc:a=medical:c=medical"; }; };
  ```
  Nothing is locked by default. An item never lands in a compartment that refuses it - dragging, quick move, Take all, the arsenals
  and scripts that add to the cargo all follow it; what the compartments refuse is put in another compartment or counts as no room.
  Over a refusing compartment the drag footprint is red with "Only magazines here". A locked compartment always shows what it takes -
  a faint picture of its category, large in the middle of an empty compartment and small on each free cell when something lies in it - and hovering it says so in the footer. A single slot draws the item scaled into it and gives it its
  own size back when you take it out. The wizard's Containers editor sets both per compartment on the Blocks way.
  The eight categories are not all there is: the wizard's General page has a Categories card where you rename them, give them another picture
  (any of this mod's icons or any item's picture), and add categories of your own. They are statements of the rules text, so they are saved on
  the server and export and import with it: `category=bandit > name=Bandit_loot picture=/a3/ui_f/data/gui/cfg/hints/gear_ca.paa` (an id of
  letters, digits and `_`, at most 16 of your own), and then `cats=bandit`, `aio_cat = "bandit";` and `grid=2x2:bandit` use it like the others.
  The strip at the side of a loot box, the Items step's Category chips and the Containers step's Accepts chips list them too. Deleting one in the
  wizard takes it out of every item and compartment that names it.
- **Use from containers:** three server settings on the wizard's General page, under "Containers and use", "Use items from the uniform / vest /
  backpack" (`aio_storage_useUniform`, `useVest`, `useBackpack`), each Everything (the game's way, the default),
  Only whitelisted or Nothing. What lies in a limited container - magazines, grenades, medicine, food, kits, radios - is
  not usable from there: its tile wears a small padlock ("Cannot be used from the backpack" in the footer), the hotbar
  refuses to bind it and counts only what it may use, and the context menu leaves out its use rows. Items opt back in
  with the rule value `use=` - in the setup wizard's Items step, the chips Uniform / Vest / Backpack in the "Use from"
  row (`kind=grenade > use=backpack`, or per class); Only whitelisted lets exactly those through, Nothing lets nothing
  through. Weapons, attachments and clothing are never limited.
  *Enforced:* the inventory window, the hotbar, the window's menus, the reload key (it loads the fullest allowed
  magazine instead), a reload from the scroll-wheel action menu or a gamepad (the magazine the game took from a closed
  container is taken back, the old one goes back into the weapon, and the fullest allowed one is loaded), and the throw
  key when only closed grenades are left (the key does nothing and says where to take one out; ACE Advanced Throwing is
  blocked through ACE's own throw block while nothing may be thrown, and the selected throwable moves off a closed one).
  *Not enforced by Only whitelisted and Nothing - a mod cannot change these:* ACE medical, field rations and every other mod
  that reads the unit's items itself (they see the backpack's bandages as real items), what ACE Advanced Throwing picks to
  throw, a grenade of a type that also lies in an open container (the game may take the copy from the closed one), a vehicle's
  guns, and scripts.
  *Strict (hidden)*, the fourth option, is the full enforcement: the blocked items are kept out of the container altogether, in a
  hidden holder on the unit (no object - a variable), so nothing but Arma Inventory Overhaul can reach them. They still show as the
  container's tiles with a small crossed eye, move, drop, go onto the ground and into crates, weigh (through ACE's virtual load)
  and keep their places; whitelisted items stay in the container and work as usual; on death everything goes into the body, on
  taking the backpack off into the backpack, while an arsenal is open into the containers. It can break mods or scripts that
  expect the items in the container - loadouts saved outside an arsenal (`getUnitLoadout`, respawn scripts) do not contain them,
  radios and kits in the holder are unknown to their mods, a Zeus editing you from afar does not see them - and may misbehave
  on respawn or with Zeus. Use it only if you need it; the setting's text says the same.
- **Multiplayer:** where things lie syncs by itself - every player sees the same arrangement, also of
  containers your scripts fill. Every change runs where the container is local and the server carries what
  moves between machines, so the server has to run the same version of Arma Inventory Overhaul. Scripts can move
  items with `aio_storage_fnc_moveEntry`, `aio_storage_fnc_equip` and `aio_storage_fnc_unequip`;
  `[cursorObject] call aio_storage_fnc_dumpPlaces` writes where things lie to the RPT. The engine's own commands (`addItem`,
  `addMagazine`, `addWeapon`, loadouts, ACE) ignore the grid: what a unit's uniform, vest or backpack then holds
  beyond its cells moves on to the next container with free cells (uniform, vest, backpack) a moment later, on the
  machine the unit is local on; what fits nowhere is, for the player's own unit, put on the ground next to him with the hint "No room
  for <name> - put on the ground" (an AI, a body or a crate keeps it as overflow, shown apart). The server setting
  `aio_storage_migrate` ("Move overfull items on": overfull items go to another container, else to the ground) switches that off.
- **Adding things from a script or another mod:** `[unit, "class", count, rounds] call aio_storage_fnc_addToUnit` (any machine; the
  last argument is optional and only for magazines, -1 or left out for full ones) puts new things into the unit's uniform, vest
  and backpack - the first with free cells, one with a slot for the item's category first - and returns how many it placed,
  `0` when the grid has no room. The engine's `addItem`, `addMagazine`, `addWeapon` and `addBackpack` stop at a container's config
  `maximumLoad`, which the grid ignores, and `addMagazine` loads an empty weapon instead of the pockets; a script that checks
  `canAdd` and then adds (or takes the thing out of a pile first) can lose the item. `addToUnit` ignores the config load, never
  loads a weapon and never drops anything on the ground: what has no room is simply not added, so compare the number returned
  with the number asked for. For a unit on another machine it runs where the unit is local and the number returned is what this
  machine's picture of the unit says will fit.
- **Loadouts beyond the config load:** a container may hold more than its config `maximumLoad`, but the engine's `setUnitLoadout` stops
  filling a container there. Loadouts set through CBA (`CBA_fnc_setLoadout`, ACE Arsenal's Load) are topped up by the mod on their own. In a
  mission use `[unit, loadout] call aio_storage_fnc_setUnitLoadout` instead of `setUnitLoadout` (any machine; it runs where the unit is local,
  adds only what the engine left out, and what then lies beyond the grid moves on as above).
- **Arsenal:** ACE Arsenal is the arsenal - `ace_arsenal_fnc_initBox` and `ace_arsenal_fnc_openBox`, its boxes,
  loadouts and Zeus arsenal work as always; the grid panel hooks into its window (also in the Eden editor), and
  free cells are the only limit on what goes in. The vanilla Virtual Arsenal is a server setting,
  `aio_arsenal_biArsenal`: `"ace"` (default - BI boxes, Eden's "Virtual" storage and Zeus open ACE Arsenal with
  the same items), `"block"` (a red screen says it is not allowed, with the text of `aio_arsenal_biMessage`;
  Zeus is never blocked) or `"vanilla"`. A mission can decide per mission with `aio_arsenal_biPassThrough`:
  `true` - always BI's window, `false` - always ACE's, unset - BI's only for missions with their own
  `arsenalOpened` / `arsenalPreOpen` handlers. It is read on each client, so set it with the public flag
  (`missionNamespace setVariable ["aio_arsenal_biPassThrough", true, true]`) or in `initPlayerLocal.sqf`.
- **Magazines:** a partly filled magazine dropped on another of the same kind is repacked with ACE's Magazine
  Repack, in the window (a click or Escape stops it, what was moved stays moved), and "Repack all" in a
  magazine's menu repacks every one of its kind in your gear. Both magazines have to lie in your own gear or in
  the same crate, vehicle or pile. Servers with their own way to refill magazines (GreenMag) switch "Repack
  magazines" (`aio_magazines_repack`) off; the fill bar on magazines that are not full is each player's own
  setting.
- **Hands:** the quick move (F, double click), Take all, Put all in and dropping with the drop key or the menu take a moment, as in Wardogs: the
  items go one after another, and the caption line of the box they come from (the bar with Take all and Sort) says how far it is - a ring that goes
  round, "Grabbing items 3 / 12" - with a red cross that cancels what still waits. The waiting tiles are tinted and faded, nothing sits on them. When an
  item's turn comes it happens exactly as it always did. A click on a waiting tile (or Cancel in the right click menu) takes that one out of the queue;
  closing the window cancels what still waits, and nothing is lost or half done, since nothing happens before its turn. **A drag never waits**, nor does
  rearranging within a container, turning an item, splitting a stack, or ACE Arsenal's panel. Putting on and taking off a uniform, vest, backpack or
  helmet is instant too, unless the server wants it to wait. The times and what waits are server settings on the wizard's General page, under "Looting and
  searching" (`aio_gui_handDrop` 0.3 s, `aio_gui_handMove` 0.4 s, `aio_gui_handEquip` 1 s - 0 is no wait; the switches `aio_gui_waitMove` and
  `aio_gui_waitDrop` on, `aio_gui_waitWorn` and `aio_gui_waitEquip` off).
- **Searching:** loot you have not searched shows as diagonally striped tiles in the size of what lies there; they turn into items one by one. The
  caption line of the box says "Searching 0:07" with a ring that goes round and a cross that stops the search of that box (the button then reads
  "Search" and goes on again). A strip of icons at the side of a loot box - all, weapons, ammunition, gear, medical, food and drink, tools, other - shows
  only that kind of item in the box (the rest fades, like with the search field; a paged box turns to its first page with a match).
  Searching can be left out for a single crate, vehicle or body: in Eden by the attribute *Skip searching* (category Arma Inventory Overhaul), in Zeus Enhanced
  by the right-click choices *Searching: turn off* / *Searching: turn on*, in a script by `[_crate, false] call aio_gui_fnc_setSearchable;` (`true` gives it back to the
  settings; the mark is public, so a player who joins later has it). The server setting *Search Zeus-placed crates and vehicles* (on by default) leaves out
  everything a game master places when switched off.
- **Big containers in pages:** a crate or vehicle taller than "Rows per page of a container" (`aio_gui_pageRows`, in "Arma Inventory Overhaul - Client",
  General, 10 rows by default, 0 or 40 for no pages) shows that many rows at a time. The bar under it turns the pages, a fade over the page's last row
  with a chip such as "+37 items on other pages" says there is more, and an item dragged over an arrow of the bar turns the page after a moment so it can be let go
  on another page. Quick move, Take all and placing use the whole container; the pages are only the view, and only the page shown has controls on the
  screen. The search field finds an item on any page (the box turns to its first page with a match, the arrows show how many matches lie before and after).
  Your own gear is never paged.
- **Where other storage opens:** your own storage column stays at the right edge of the window, and the column of what you loot (the ground, a crate,
  a vehicle, a body, what lies nearby) opens left of it, between your equipment and your storage. "Where other storage opens"
  (`aio_gui_lootSide`, in "Arma Inventory Overhaul - Client", General) can put it at the right edge instead, with your storage moving in as it did in earlier
  versions. The soldier in the middle moves with the free space without leaving third person.
- **Sounds and looting:** every kind of gear sounds like what it is - weapons, magazines, vests, helmets, medical
  items, radios -, using Arma's own sound files only; players within earshot hear someone loot (`aio_gui_soundsWorld`,
  a server setting). A movement key stops looting and closes the window (each player's setting).
  The speaker in the window's header opens a dropdown with a switch and a volume slider for each kind of sound you hear (moving items, magazines,
  opening containers, searching, other) and a master volume; they are no CBA settings but each player's own, kept in the profile. A right click on the speaker mutes everything or brings it back.
  Add your own sounds as classes of `CfgAioSounds` (see `addons/gui/CfgAioSounds.hpp`), or give an item the
  family of another with `aio_sound = "vest";` in its config.
- **Colours:** the palette button in the window's header, right of the speaker, opens a popover where you set each part of the window on its
  own, and the window follows as you drag: **Accent**, **Secondary**, **Panels**, **Transparency** (how see-through the panels are, up to 75 %),
  **Cells** (the empty grid cells and the slot boxes), **Tiles** (the item tiles' background), **Text** (captions, names and labels; the dimmer
  greys follow it) and **Lines** (hairlines, borders and the stripes of unsearched items). Each is a row; click it to open the picker under it - a
  colour square, a strip of hues and fields for red, green, blue and a hex code you can type or paste (press Return) - and click it again to fold
  it. Each choice has a button that takes it away ("Use my Arma colour", "Match accent", "Default"), and "Reset all" takes them all; a row you
  never touch keeps the look it has. Until you change it, the accent is the colour you set in Arma's Options > Game > Colors. The secondary colour
  tints the caption tabs, chips, buttons, what lights under the mouse, bar tracks and picked rows. The panels' colour and transparency change only
  the panels: the cells, slots and tiles keep their own colour and stay solid. The panels, cells and tiles are kept dark and the text is lightened
  where it would be hard to read, so everything stays readable: a lighter colour comes back as the lightest they may have. Your choices are kept
  in your profile (`aio_gui_palette`); the setup wizard and the ACE Arsenal panel use them the next time they
  open. A server can switch the palette off with "Players may pick their colours" (`aio_gui_playerColours`, on the wizard's General page): there is
  no button then, and everyone sees the Arma colour of their profile and the standard look.

## The vanilla inventory

Gone while this mod is loaded. The Gear key, ACE's "Inventory" and "Open backpack", crates, vehicles and
bodies all open Arma Inventory Overhaul, and there is no setting to bring the vanilla one back. Should another
mod or a script open it anyway (Better Inventory, `createDisplay "RscDisplayInventory"`), it is closed again
at once; should the window ever fail to open, nothing opens and the RPT says why.
