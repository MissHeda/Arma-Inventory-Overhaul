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
  What you add lands in the first free cell, drag tiles to sort them (R turns, stacks merge, a badge shows
  n/stack), drag them out of the panel - or right click, or Delete - to take them out. With no free cells ACE's
  add is taken back and the message says how much room to make. Drag a row out of ACE's list onto a free spot of
  the grid to put it in there (the wheel sets how many, Ctrl+wheel over a tile adds or takes out one). Under the
  grid a staging space holds things while you rearrange a full container - it grows as you fill it -; whatever
  is left in it is deleted when the arsenal closes. The vanilla Virtual Arsenal opens ACE Arsenal too, or is
  blocked, by server setting.

**Status:** 0.4.0, in testing: drag and drop between containers and equipment slots, searching loot and
server-checked moves in multiplayer are built, and this version adds the grid panel in ACE Arsenal, shaped
grids and items, a setup wizard where you paint the compartments, and cells as the only room (no weight limit).
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
(ESC > Options > Inventory setup, Eden's Tools menu, the cog in the inventory): you draw the cells of an item
(an L, a T), paint the cells of a uniform, vest or backpack in colours - touching cells of one colour are one
compartment, and it looks in the inventory exactly as painted -, build it block by block in Blocks mode, or
make a class the same as another one (Same as: follow it with `like=` or copy its cells), set an item's weight and name next to its
size, zoom and shift its picture in the tile where an icon is too small or too large (`icon=`, with a live preview) or give it another picture altogether (`picture=`: pick one from every item's picture, or type any texture path - the container boxes follow too), change a whole family at once - search with wildcards (`B_Bergen*`), switch the list to Tree, pick a class and everything built on
it is edited as one rule, `class=B_Carryall_Base+` - and copy a class's config lines with Export - for a mod, or as a layout without a class name to share - or paste some in with Import (a layout goes to the class you have selected, so does a class this game does not have); its start page shows
what you changed. It is plain text all the same.
It builds on a preset: Default (relaxed: realistic-ish sizes, containers a fifth roomier than their load),
Realism (realistic sizes: longer rifles, magazine-rig vests, a fixed grid per backpack size, stacks as in
Default; `base=tarkov` of older texts reads as Realism) or Weight-like (an item takes as many cells as it
weighs). Grids are ten cells wide.

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
  `kind=kit > grid=12` for every kit, or `einv_grid = "4x3";` on the kit's class in a mod. The wizard's Containers step has a
  Kits chip and writes the `+` rule for you; "Back to the preset" returns a kit to the capacity. That mod's own kit window and its
  kits tab in ACE Arsenal still go by the capacity. In ACE Arsenal an item dragged from ACE's list onto a kit's tile in the panel
  is packed into that kit, where the kit type's Arsenal setting allows filling it.
- **One crate, vehicle or a unit's uniform, vest or backpack:** give the object its own grid, which wins
  over every rule - `_crate setVariable ["einv_grid", "6x4+2x3", true];` (also `"24"`, `"rig:16"`, `"auto"`).
- **Mods:** ship presets of your own as classes of `CfgEinvRulesets` (see `addons/items/CfgEinvRulesets.hpp`),
  or predefine your items in their own config class, in exactly the language of the rules text - a custom vest
  writes how its compartments are:
  ```cpp
  class CfgWeapons { class My_Vest { einv_grid = "1x3+5x7+1x3"; }; };       // grid=, also "xxxx/x--x+2x3", a canvas, "rig:16", "24"
  class CfgVehicles { class My_Pack { einv_grid = "abbbbbc/abbbbbc/-bbbbb-"; }; };
  class CfgWeapons { class My_Kit { einv_size = "2x1"; einv_stack = 1; einv_weight = 0.5; einv_name = "Short name"; }; };
  class CfgWeapons { class My_Bandage { einv_icon = "1.4@0.1,-0.05"; }; };  // icon=, the picture 1.4 times as large, moved a tenth right and a twentieth up
  class CfgWeapons { class My_Bandage { einv_picture = "my_mod\ui\bandage_ca.paa"; }; };  // picture=, shown instead of the config picture
  class CfgWeapons { class My_Bandage { einv_use = "backpack,vest"; }; };  // use=, usable from these containers even where a setting closes them (below)
  ```
  `einv_size` is `size=` (`"2x1"`, a mask like `"xx/x-"`, `"mass"`), `einv_stack` is `stack=` (a number), `einv_grid` is
  `grid=` (containers: uniform, vest, backpack, crate, vehicle, kit), `einv_weight` is `weight=` in **kilograms** (not config mass)
  and `einv_name` is `name=` as plain text (a space is a space). `einv_icon` is `icon=`: how the item's picture is drawn in its
  tile for a picture that is too small or too large - `"1.4"` is 1.4 times as large (0.25 to 4), `"1.4@0.1,-0.05"` moves it too, a
  tenth of the tile across (right is positive) and a twentieth down (-1 to 1; the comma is the config's, a rules text writes
  `icon=1.4@0.1:-0.05` since its comma ends a statement). The tile cuts the picture at its edge, so it never leaves it. `einv_picture` is
  `picture=`: the texture the item shows instead of the one its config names (a file the game does not have falls back to the config
  picture and is named once in the RPT; a rules text writes `picture=/my_mod/ui/bandage_ca.paa`, slashes and `%20` for a space). `einv_use` is `use=`: the
  containers the item is whitelisted for - `uniform`, `vest`, `backpack`, `all` or `none` (a comma, a plus or a bar between; a rules text writes
  `use=backpack+vest`) - see "Use from containers". A subclass
  inherits what its parent sets, as everything in config does; `einv_grid = "";` takes it back. These sit below the server's rules text - a rule for the class still wins - and
  above the preset. Values are cut to the same limits as in the rules, and a mistake is named in the RPT. The older
  `einv_gridSize[]`, `einv_stackSize`, `einv_grids[]` and `einv_slots` still work (the new keys win). To get the lines for a
  class from what it is now, call `["V_PlateCarrier1_rgr"] call einv_items_fnc_configEntry`; `einv_items_fnc_parseConfigEntry`
  reads such lines back.

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
  ACE's fatigue starts to tire a jogging soldier (26.7 kg at ACE's defaults, it follows ACE's load factor and
  the soldier's performance), red at 45 kg (no sprinting, tiring faster) and ends at 60 kg (walking only), and
  its text names the next limit and what it does to movement - CBA settings Enhanced Inventory > Weight. Nothing
  is ever refused because of weight, and no container has a weight limit: what fits into a uniform, vest,
  backpack, crate or vehicle is decided by its free cells alone (a container's config load is only used to size
  its default grid when nobody defined one). A section's caption still tells what its contents weigh.
- **Hotbar:** the keys 4 to 0 belong to the hotbar unless the CBA setting "Hotbar" (`einv_hotbar_enabled`) is
  switched off - a server setting, the same for everyone. Only items that do something can be bound: bandages,
  tourniquets, splints and other ACE/ACM medicine are used on yourself through ACE's own treatment, grenades
  go into the hand, magazines reload the weapon in the hands, food and drink use ACE's field rations,
  Enhanced First Aid Kits open. Each player moves the bar in Arma's layout editor and chooses when it shows.
  `[0, "ACE_elasticBandage"] call einv_hotbar_fnc_bind;` and `[0] call einv_hotbar_fnc_use;` drive it from
  scripts.
- **Use from containers:** three server settings under "Use from containers", "Use items from the uniform / vest /
  backpack" (`einv_storage_useUniform`, `useVest`, `useBackpack`), each Everything (the game's way, the default),
  Only whitelisted or Nothing. What lies in a limited container - magazines, grenades, medicine, food, kits, radios - is
  not usable from there: its tile wears a small padlock ("Cannot be used from the backpack" in the footer), the hotbar
  refuses to bind it and counts only what it may use, the context menu leaves out its use rows, and the reload key loads
  magazines only from containers that allow it. Items opt back in with the rule value `use=` - in the setup wizard's
  Items step, the chips Uniform / Vest / Backpack in the "Use from" row (`kind=grenade > use=backpack`, or per class);
  Only whitelisted lets exactly those through, Nothing lets nothing through. Weapons, attachments and clothing are never
  limited. What a mod cannot do: the game's own throw key, ACE's own medical and self-interaction menus, a gamepad reload and
  scripts still take from any container.
- **Multiplayer:** where things lie syncs by itself - every player sees the same arrangement, also of
  containers your scripts fill. Every change runs where the container is local and the server carries what
  moves between machines, so the server has to run the same version of Enhanced Inventory. Scripts can move
  items with `einv_storage_fnc_moveEntry`, `einv_storage_fnc_equip` and `einv_storage_fnc_unequip`;
  `[cursorObject] call einv_storage_fnc_dumpPlaces` writes where things lie to the RPT. The engine's own commands (`addItem`,
  `addMagazine`, `addWeapon`, loadouts, ACE) ignore the grid: what a unit's uniform, vest or backpack then holds
  beyond its cells moves on to the next container with free cells (uniform, vest, backpack) a moment later, on the
  machine the unit is local on; what fits nowhere stays shown as overflow. The server setting
  `einv_storage_migrate` switches that off.
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

Gone while this mod is loaded. The Gear key, ACE's "Inventory" and "Open backpack", crates, vehicles and
bodies all open Enhanced Inventory, and there is no setting to bring the vanilla one back. Should another
mod or a script open it anyway (Better Inventory, `createDisplay "RscDisplayInventory"`), it is closed again
at once; should the window ever fail to open, nothing opens and the RPT says why.
