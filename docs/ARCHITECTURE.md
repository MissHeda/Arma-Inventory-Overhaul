# Arma Inventory Overhaul - architecture

This is the contract every file of the mod is written against, as the mod is on this branch (the 0.4 line). Function names,
arguments, HashMap keys and settings named here are binding: several people (and agents) write different files at the same time
and only meet through these interfaces. If something turns out wrong, fix it here and in the code together. How the mod got here
is the dated build log `docs/HISTORY.md`; this file describes only what is true now. `docs/BRIEFING.md` has the goal and the first
plan; the plan behind the rules engine and the wizard is `docs/design/design_synthesis.md` with the corrections in
`docs/design/design_critic.md`.

## 1. Overview

### What the mod is

Arma Inventory Overhaul replaces the vanilla inventory (`RscDisplayInventory`) with a window of its own, built at run time from
controls: nothing is patched into the vanilla display, and the vanilla inventory never opens while the mod is loaded - there is
no setting to bring it back and no fallback to it (section 4, Opening).

- **A grid inventory.** An item is a tile with a footprint in cells (a rectangle, or a shape such as an L); a container (uniform,
  vest, backpack, crate, vehicle, pile on the ground) is a set of compartments of cells. Where an item lies is stored per
  container and is the same on every machine.
- **Cells are the only room.** What fits into a container is decided by its free cells alone. Weight limits no container; it only
  slows the soldier who carries it (the `weight` addon: the bar, the tiers, ACE fatigue). The one kind rule left is that a
  backpack does not go into a backpack.
- **One look, four places.** Glass, in the feel of Arma's and ACE's menus: the equipment column, a live camera on the soldier in
  the middle, the storage column (uniform, vest, backpack) and, only while looting, the loot column. Kits and pouches of Enhanced
  First Aid Kits float as windows of their own. Loot has to be searched before it is seen.
- **A rules engine** decides every item's size, stack, container grid, weight and name from one text, the CBA setting
  `einv_items_rules`, built on the one preset there is, the default (section 2); **a setup wizard** edits that text - and the server
  settings, one more text (section 8) - without writing them by hand (section 6).
- **The ACE Arsenal panel.** There is no arsenal window of our own: while the uniform, vest or backpack tab of ACE Arsenal's left
  bar is open, the same window engine draws that container's grid and a staging space beside ACE's list (section 5).
- **Multiplayer by authority.** Every change to a container is a transaction run by the machine where that container's root is
  local; the server is the hub between machines (section 3).

CBA_A3 and ACE3 are hard requirements. Everything else (Enhanced First Aid Kits and Enhanced Utility Pouches, ACE cargo, ACE
vehicle lock, ACE magazine repack, TFAR, ACRE2, Zeus Enhanced, ACE Interaction Menu Expansion) is optional: its addon is skipped when the mod is missing
(`skipWhenMissingDependencies`), and the window calls another mod's functions only behind `isNil` guards.

### Toolchain and conventions

The short version; the full list is in [`docs/BRIEFING.md`](BRIEFING.md).

- HEMTT 1.11.2 (`hemtt check`, `build`, `launch`), run by `.github/workflows/check.yml` on every push. Minimum game version 2.16:
  no SQF command newer than that. CBA macros (`GVAR`, `QGVAR`, `FUNC`, `QFUNC`, `EFUNC`, `LLSTRING`, `CSTRING`, `ARR_N`), `PREP`
  lines in each addon's `XEH_PREP.hpp`. Prefix `einv`, mainprefix `z`; the version is in `addons/main/script_version.hpp`.
- One addon per feature, named after what it does, plus `main`. Everything in the repo is English, stringtables only `<English>`.
  A function file has the header of the existing ones (Author, description, Arguments, Return Value, Example, Public); comments
  explain WHY, in plain sentences. CBA setting descriptions are wrapped with `\n` about every 40 characters, no scope line;
  settings are ordered by topic, then numbers, switches, lists, text boxes. Never start Arma from a tool; commit and push only
  when asked.
- Shared constants live in `addons/main/script_macros.hpp`: `STORAGE_COLS` 10, `MAX_ROWS` 40, `MAX_BLOCKS` 24, `MAX_CELLS` 400,
  `SHAPE_MAX` 8, `BATCH_MAX` 25, `NEARBY_MAX` 10, `NEARBY_DZ` 2, `MASS_TO_KG`, `KG_TO_MASS`, `CATEGORY_*` (MISC 0, GEAR 1, WEAPON
  2, AMMO 3, MEDICAL 4), `TIER_*` (LIGHT 0 to CRITICAL 3). Config mass is counted in tenths of a pound; `MASS_TO_KG` turns it into
  kilograms.
- Controls cannot be saved with a game, so every control lives in `uiNamespace`. Eden runs no postInit and no CBA frame handlers:
  what must work there is registered in preInit and driven by a `Draw3D` handler or by the display's own events (sections 4 to 6).
- Tests: `tools/check_default_ruleset.sqf` (section 2) and the mission `.hemtt/missions/EINV_Test.VR` (full gear, a crate, an ACE
  Arsenal box, a vehicle, a body, loot on the ground); `tools/generate_ui_textures.py` draws `addons/gui/ui/`; `python -I tools/find_dead_code.py` lists
  the functions, preInit variables and defines nothing uses.

### Addons

| Addon | Does |
|---|---|
| `main` | version, macros and the shared defines of `script_macros.hpp`; the registry of the server settings and the one CBA text that holds them (section 8). |
| `items` | what an item is (`einv_items_fnc_getInfo`) and the rules engine behind it: text, presets, compile, resolve. |
| `storage` | what a container holds and where it lies; what a unit wears; the transactions, hub, places sync and loadouts that change anything. |
| `gui` | the window: engine, Glass theme, layout, tiles, drag, menus, searching, sounds, people, CBA item menu, kit windows. |
| `weight` | the soldier's load: `weight=` overrides into ACE's virtual load, the tiers Light, Heavy, Overloaded, Critical and their effects. |
| `locks` | who may open a crate or vehicle: one side, one group or the admins; the engine lock per client and the guard on every op. |
| `setup` | the setup wizard (General, Items, Containers) and its entry points. |
| `arsenal` | the grid panel on ACE Arsenal's display and the handling of the vanilla Virtual Arsenal. |
| `hotbar` | seven keys, 4 to 0, that use what lies on them; the HUD bar and the window's hotbar row. |
| `magazines` | repacking partly filled magazines in the window (needs `ace_magazinerepack`). |
| `compat_efak` | Enhanced First Aid Kits and Enhanced Utility Pouches: kits as floating windows, packing by drag and drop. |
| `compat_ace_cargo` | what ACE cargo has loaded in a vehicle or crate, as a "Cargo" section with Open and Unload. |
| `compat_ace_vehiclelock` | ACE's vehicle lock as one more lock of ours. |
| `compat_ace_interaction` | ACE interaction "Inventory" on people, the action menu's entry as an ACE action. |
| `compat_zen` | Zeus Enhanced: the "Inventory lock" menu and module. |
| `compat_aime` | ACE Interaction Menu Expansion (AIME): its "Change Ammo Type" and inventory actions under this mod's rules. |
| `compat_tfar` | TFAR radios: channel and frequency at the mouse, "Open radio", "Use as active radio", long-range settings kept through moves. |
| `compat_acre` | the same for ACRE2, and the dummy radio ACRE2 keeps in the radio slot fixed. |

`gui` requires `storage`, `locks` and `weight`; `arsenal` requires `ace_arsenal` and `setup`; `hotbar` and `magazines` require
`gui`.

## 2. Rules engine (items)

Size, stack, container grid, weight and name of every item come from one text of rules, the CBA setting `einv_items_rules`, built
on a preset (`CfgEinvRulesets`, `addons/items/CfgEinvRulesets.hpp`). Everything that asks "what is this item" asks
`einv_items_fnc_getInfo`; nothing else decides a size. The text is short on purpose: a preset does the bulk, the text only says
where a setup differs.

### The text (`fnc_parseRules`, `fnc_writeRules`)

Statements are separated by commas; a line break counts as a comma. The writer always joins with `", "`, in the order header,
categories, groups, rules, and a rule's values in the order `like`, `size`, `stack`, `grid`, `weight`, `name`, `icon`, `picture`, `use`, `cats`. Read and written again, a text
stays the same, so two setups that mean the same compare as texts.

| Statement | Example | |
|---|---|---|
| header | `einv1 base=default cell=5` | only as the first statement. `base=` a preset id or `none`; `cell=` config mass per grid cell, 1 to 50, two decimals. No header reads as `einv1 base=default`; a newer `einvN` warns and reads what it can. |
| category | `category=bandit > name=Bandit_loot picture=/a3/ui_f/data/gui/cfg/hints/gear_ca.paa` | a category of the setup's own on top of the eight built-in ones (`ITEM_GROUPS`): an id of `a-z 0-9 _`, at most `CAT_ID_MAX` 24 long, its `name=` (written as a rule's, at most `CAT_NAME_MAX` 30 characters) and the `picture=` it is drawn with (written as a rule's), both optional - `category=bandit` alone is legal. The same id again: what the later statement sets counts, field by field. For one of the eight ids it gives that category another name or picture (it never goes away; a statement that sets neither is left out). At most `MAX_CUSTOM_CATEGORIES` 16 of the setup's own; an id that `cats=` would read as a built-in word (`fnc_builtinGroup`: `tools`, `magazine`, `other` ...) or that means something else where a category stands (`CAT_ID_RESERVED`: `one`, `single`, `all`, `more`, `none`) is refused. Parsed into the AST's `categories`, `[[id, name, picture], ...]` in text order, and written right after the header (`fnc_writeRules`). Only the text defines categories: a preset has no say. Items and compartments name them through `cats=` and `grid=`; the lists of the window and of the wizard come from `fnc_categories`. |
| group | `@rifle_mags: kind=magazine mass<=20` | an id of `a-z 0-9 _`. The same id twice in one layer means either. An own group replaces the preset's group of that name; `@itself` inside it means the preset's definition (`@mag_rifle: @mag_rifle` then `@mag_rifle: class=X+` adds X). A definition that does not hold up (unknown group, a loop, deeper than `MAX_GROUP_DEPTH` 4) is left out and the one below counts again. |
| rule | `kind=grenade > stack=3` | conditions, then what it sets; the `>` only reads better. No condition means every item. A later rule beats an earlier one, field by field. |

Conditions - all must hold; `|` means either, `!` in front means not; at most `MAX_ALTERNATIVES` 64 choices:

| Condition | |
|---|---|
| `kind=rifle\|handgun` | the kinds of `fnc_getFacts`: `rifle`, `handgun`, `launcher`, `binocular`, `muzzle`, `optic`, `rail`, `bipod`, `headgear`, `nvg`, `vest`, `uniform`, `map`, `gps`, `radio`, `compass`, `watch`, `item`, `magazine`, `grenade`, `backpack`, `goggles`, `vehicle`, `crate`, `kit`, `unknown`. A `kit` meets `kind=item` too; `kind=kit` only kits. |
| `cat=medical` | `misc`, `gear`, `weapon`, `ammo`, `medical` (`CATEGORY_NAMES`). |
| `class=X`, `class=X+`, `class~abc` | that class; X and every class built on it (any mod's); a part of the class name, `MIN_SEARCH` 3 letters at least. Class case is kept in the text and matched in lowercase. |
| `addon=x`, `addon~abc` | the CfgPatches class that brought it in. |
| `well=X` | a magazine of that magazine well. |
| `for=X` | a magazine the weapon X loads. |
| `mass<=20`, `rounds>=50`, `load>160` | config mass, a CfgMagazines count, a container's maximumLoad (the size proxy); `=`, `<`, `<=`, `>`, `>=`. |
| `@group`, `@a\|@b` | a member of that group. |
| `all` | everything else: not a test of the item but the rule's place - asked after the preset, before the built-in answer. `all > size=1x1 stack=10`; further conditions narrow it (`all kind=uniform\|vest\|backpack > grid=6x4`). Only in a rule (a group with `all` is left out), never `!all`, written first wherever it was typed, once. Parsed as `[false, "all", "", []]`; `fnc_compileCond` makes it a condition that always holds (cost 0). |

Values - what a rule sets. `like` is written first, the others in any order:

| Value | |
|---|---|
| `like=CLASS` | everything the rules make of that class but its name; see "like=" below. A class token: letters, digits, `_`. |
| `size=2x3` (alias `shape=`) | the footprint, across and down, at most `STORAGE_COLS` and `MAX_ROWS` when read (cut with a warning). `size=mass`: as many cells as it weighs (the rules' weight if set) per cell - rifles and launchers two rows high, everything else near square. `size=xx/x-` is a mask: rows from the top split by `/`, `x` a cell, `-` a hole, so `xx/x-` is an L of three cells in a 2x2 box. A value of only `x`, `-`, `/` is a mask, any other made of letters, digits, `/` and `@` is a named shape, which is not read (warned, the rest of the rule kept). A mask is one block (no `+`, no letters), at most `SHAPE_MAX` 8 each way (a larger one keeps its top left 8x8, with a note), at least one cell, read to its smallest form (edge rows and columns of holes go) and written back the shortest way (`size=xx/xx` comes back `2x2`). Whatever the rule says, the resolved footprint is cut to `SHAPE_MAX` each way: the wizard draws an item on a board that size. |
| `stack=10` | 1 to `MAX_STACK` 999. |
| `grid=...` | containers only, see below. |
| `weight=1.25` | the item's weight in kg instead of config's: digits and one dot, rounded to the gram, at most `MAX_WEIGHT` 1000. |
| `name=Field_kit` | the name it shows, at most `MAX_NAME` 100 characters: `_` is a space and `%5F` an underscore; letters, digits, `-` and `.` stand as they are, every other character is `%XX` per UTF-8 byte (`Field kit (3)` is `Field_kit_%283%29`). `fnc_encodeName` writes it, `fnc_decodeName` reads it. |
| `icon=1.4`, `icon=1.4@0.1:-0.05` | how the item's **picture** is drawn in its tile: `SCALE` or `SCALE@ACROSS:DOWN` (`fnc_parseIcon` reads it, `fnc_formatIcon` writes it). The scale is 0.25 to 4 (`ICON_SCALE_MIN`, `ICON_SCALE_MAX`) times the picture as it is fitted into the tile, about the tile's middle; the offsets are -1 to 1 (`ICON_OFFSET_MAX`) of the tile's width across (positive: right) and of its height down (positive: down); all to two decimals, a value past a limit is cut down with a warning. `icon=1` is the plain picture and a legal value (it takes back what a broader rule set). A comma ends a statement, so the text's offsets are split by `:` - the writer always writes the colon; config's `"1.4@0.1,-0.05"` is read as it stands, and a comma typed into a rules text is read as the colon (a number on its own right after an `icon=` with one offset is its second one). Parsed into the rule's values as `"icon"`, `[scale, across, down]`. Not taken by `like=`. |
| `picture=/A3/Weapons_F/Data/UI/gear_acc_rail_ca.paa` | **which picture** the item shows instead of the one its config names (`fnc_parsePicture` reads it): a texture path of at most `PICTURE_MAX` 260 characters with a file name that has an extension. In a rules text it is written the way `name=` is, but for a path (`fnc_encodeName` / `fnc_decodeName` with their `path` switch): letters, digits, `-`, `_`, `.` and `/` stay, a backslash is written `/` (the setting's text box cleans a backslash out - `fnc_sanitizeText` now turns one into a `/` instead of dropping it, so a path typed there keeps its folders), a space is `%20` and every other character `%XX` per UTF-8 byte; read back, `/` is the backslash of the engine's own paths. Parsed into the rule's values as `"picture"`, the path with backslashes. Whether the file exists is asked by `fnc_getInfo` (`fileExists`, with and without the leading backslash), not by the reader: a missing file falls back to the config picture and is named once per path in the RPT. Not taken by `like=`. |
| `use=backpack+vest` | **which containers it may be used from** even where a setting closes them (`fnc_parseUse` reads it, `fnc_formatUse` writes it; section 3, "Use from containers"): any of `uniform`, `vest`, `backpack` joined with `+` (a comma would end the statement; config's `einv_use` also takes a comma or a bar), `all` for the three, `none` for no container - the one value that takes back what a broader rule whitelisted. Words are lowercase or not, plurals are read, a word that is none of these is left out with a note. Written always in the order uniform, vest, backpack. Parsed into the rule's values as `"use"`, an array of those words (`[]` for `none`). Only means something for the kinds that are used from where they lie (`USE_ITEM_KINDS` in storage: magazine, grenade, item, kit, radio). Not taken by `like=`. |
| `cats=medical+misc` | **which categories it is in** instead of the built-in one (`fnc_parseGroups` reads it, `fnc_formatGroups` writes it): any of `weapon`, `ammo`, `grenade`, `gear`, `medical`, `food`, `tool`, `misc` (`ITEM_GROUPS`) or the id of a category the text defines (`category=`), joined with `+`; plurals and a few words (`magazine`, `throwable`, `explosive`, `clothing`; `GROUP_ALIASES`) are read as the built-in category they mean (`fnc_builtinGroup`), any other word that is an id (`a-z 0-9 _`, `CAT_ID_PATTERN`) is kept as the id of a category of the setup's own - whether the setup defines it is asked later, not by the reader, which also reads a mod's config before the rules exist -, anything else is left out with a note, a value with no readable word is left out. Written in the order of `fnc_orderGroups`: the eight as `ITEM_GROUPS` lists them, then the others alphabetically, so a text reads and writes the same under any setup. Parsed into the rule's values as `"cats"`, an array. The strip at the side of a loot box shows an item under each of its categories, and a compartment that accepts only some categories (`grid=`, below) takes it when it is in one of them. The key is `cats=`, not `cat=`: `cat=` is the condition on the tile's colour (`CATEGORY_NAMES`). Not taken by `like=`. |

`grid=` takes one of these (`fnc_parseGrid`, `fnc_formatGrid`):

- `auto` - maximumLoad / mass per cell, laid out by the kind's pattern; `24` - that many cells, laid out the same way and met
  exactly; `120%` - that share of auto, 10 to 500 %.
- a pattern, `rig` or `rig:16` (the cells given or from the load): `pockets`, `pockets_mixed`, `rig`, `mixed`, `plate`, `long`,
  `single`, `wide` (`GRID_PATTERNS`). Patterns and the older container table make rectangles only.
- compartments exactly, joined by `+`: `6x4+2x3`; a piece may be a shape `xxxx/x--x` (a ring of 6 cells; a hole is a cell the
  compartment does not have), mixed with the rest: `xxxx/x--x+2x3`. A piece without digits is a shape, one with digits is `WxH`; a
  shape with no hole left is written `WxH`.
- a canvas: rows split by `/`, `-` no cell, `a` to `z` a cell of that compartment, cells of one letter being one compartment
  wherever they lie. `abbbbbc/abbbbbc/abbbbbc/-bbbbb-/-bbbbb-/-bbbbb-/-bbbbb-` is a backpack of 1x3 left, 5x7 middle, 1x3 right,
  all top-aligned; `aaa/aba/aaa` a 3x3 ring with a cell of its own inside. The compartments keep their places on the canvas. A
  canvas of one row with no `-` must name its compartments a, b, c in the order they start (`aaabb`), so a mistyped pattern
  (`rigg`) stays no grid. Joined with `+` the canvas is one piece of the flow; there is one canvas per grid (the compartments of a
  second one flow, with a message). The writer gives letters in the reading order of each compartment's first cell, puts the
  canvas where its first compartment stood, and writes a single compartment as `WxH` or a mask. `/` is a legal character; a row is
  never empty, so `//`, which a `cba_settings.sqf` takes for a comment, never occurs.
- **attributes** after a compartment's colon (`fnc_parseGrid` reads them, `fnc_formatGrid` writes them): a list of categories joined
  with `|` (the eight of `ITEM_GROUPS` or a category of the setup's own, as `cats=`) and the word `one`. `2x2:ammo|grenade` accepts only items in one of those categories; no list
  accepts everything, as every compartment did. `1x1:grenade|one` (or `1x1:grenade:one`) is a **single slot**: it holds one tile
  whatever the item's size, and the item takes the whole compartment (section 3, "Categories and single slots"). On a canvas each
  letter has its own after the canvas, `aab/aab:a=ammo:b=grenade|one`; a canvas of one compartment is a plain piece and takes the
  plain form. A compartment without attributes is written exactly as before, so no older text changes; the block of the parsed spec
  then has its four elements, with attributes six (`[cols, rows, holes, pos, accepts, single]`). Only compartments written out can
  carry them: `auto`, a number of cells, a share and a pattern say nothing about single compartments (a note, the attributes are
  left out). Commented examples (the comments are not part of the text; a rules text has none):

  ```
  # a vest: two front pouches only for magazines, a grenade loop (one grenade of any size), the back for anything
  grid=1x2:ammo+1x2:ammo+1x1:grenade|one+4x2
  # a backpack on a canvas: both side pockets take medical items, the main compartment anything
  grid=abbbbbc/abbbbbc/abbbbbc:a=medical:c=medical
  ```

What may stand in a statement: letters, digits, space, tab and `_ + . / % : | @ ! < > = ~ -`. Never a `;`, a quote, `#` or a
backslash: CBA's export, import and every `cba_settings.sqf` split lines at `;`, and the preprocessor reads the others. The
EDITBOXes (rules and the three tables) use `einv_items_fnc_sanitizeText` as CBA's sanitizer, which turns `;` and line breaks into
commas and drops quotes, `#` and backslashes as they are typed.

Left out, each with a warning that names it (RPT on load, the General page's notes): a statement with any other character, an unknown
key, a condition after a value, a header that is not first, a statement that sets nothing, statements past `MAX_STATEMENTS` 500; a
text over `TEXT_MAX` 16384 characters reads as the default. One typo never costs the rest.

### Limits

| Limit | Value | Where it bites |
|---|---|---|
| `STORAGE_COLS` | 10 | cells across every compartment, grid and canvas; places stored at eight columns stay valid |
| `MAX_ROWS` | 40 | rows of a compartment or of an item read from `size=WxH` |
| `MAX_BLOCKS` | 24 | compartments of one container |
| `MAX_CELLS` | 400 (`STORAGE_COLS` x `MAX_ROWS`) | cells of all compartments together, holes not counted |
| `SHAPE_MAX` | 8 | an item's mask or footprint, each way |
| `MAX_STACK`, `MAX_WEIGHT`, `MAX_NAME` | 999, 1000 kg, 100 | `stack=`, `weight=`, `name=` |
| `ICON_SCALE_MIN`, `ICON_SCALE_MAX`, `ICON_OFFSET_MAX` | 0.25, 4, 1 | `icon=` scale and offsets (`addons/main/script_macros.hpp`) |
| `PICTURE_MAX` | 260 | characters of a `picture=` path (`addons/main/script_macros.hpp`) |
| `CELL_MIN`, `CELL_MAX` | 1, 50 | the header's `cell=` and the slider |
| `PERCENT_MIN`, `PERCENT_MAX` | 10, 500 | `grid=120%` |
| `MAX_STATEMENTS`, `TEXT_MAX` | 500, 16384 | statements and characters of a text |
| `MAX_GROUP_DEPTH`, `MAX_CHAIN`, `LIKE_DEPTH` | 4, 4, 8 | groups in groups, presets on presets, `like=` after `like=` |

A value past a limit is cut down to it and said so; one that cannot be read is left out. The window makes a control per cell,
which is why a typo in a rule must not build tens of thousands of them.

### Which answer wins (`fnc_resolve`)

Each field - footprint, stack, grid, weight, name, icon, picture, use, cats - goes to the first layer that has an answer, highest first:

1. **forced** - rifles, handguns, launchers, binoculars, uniforms, vests and backpacks always stack 1 (`KINDS_SINGLE`), whatever
   any rule says: each carries attachments or contents of its own, and a tile moves only one of them.
2. **the older tables** - `einv_items_sizeTable`, `einv_items_stackTable`, `einv_storage_containerTable`, compiled as `class=X+`
   rules appended after the text's own, each table sorted shallow-first (fewest parents first) so the nearest class listed wins.
   They sit in the same layer as the text but come after it, so a table beats the text.
3. **the own text** - `einv_items_rules`, a later rule before an earlier one.
4. **the item's mod config** - `einv_size`, `einv_stack`, `einv_grid`, `einv_weight`, `einv_name`, `einv_icon`, `einv_picture`, `einv_use`, `einv_cat`, written as the rules write the same
   value ("Config keys of an item" below); for a field those leave open the older `einv_gridSize[]`, `einv_stackSize`,
   `einv_grids[]`, then `einv_slots`. Grids and slots from config stay within the limits above. The text above still overrides all
   of it, so a server's rules have the last word over any mod.
5. **the preset chain** - `base=` and its own bases, up to `MAX_CHAIN` deep, a derived preset's rules before its base's, a later
   rule before an earlier one. `einv_items_stackSmall`, when moved off its default 10, is this layer's last word on `@item_small`:
   it beats the preset's stacks, not a rule or a mod.
6. **everything else** - the text's rules with `all` (`fnc_compileRules` puts them in `"fallback"`, tag `all:<i>`, the i-th rule of
   the text; `byKind` gains a fifth and sixth element, their indices and fields), later rule first. They answer only what every layer
   above left open - never over a rule, a table, a mod or a preset rule with a condition. A preset's rules **without** conditions are
   the preset's own everything else (the default's first rule `size=1x1 stack=1` reaches every item, so without this `all` could never
   set a size or stack under `base=default`): a field only such a rule answered is asked of the `all` rules again and keeps the preset's
   answer where they have none (`_caught` in `fnc_resolve`; `fnc_explain` then takes the field out of that preset line's wins). A
   preset's own `all` rule is left out with a warning. `fnc_configEntry`'s bare answer drops `fallback` with `own`.
7. **builtin** - 1x1, stack 1, a grid by load - `grid=120%` for a uniform, vest or backpack (`BUILTIN_WORN_GRID`: a fifth more room than the load gives), `grid=auto` for the rest -, config weight, config name, the plain picture (`ICON_PLAIN`, `[1, 0, 0]`), config's own picture (the resolved `picture` is ""), no container whitelisted (the resolved `use` is `[]`).

Only the rules that can be about the item's kind are asked (`fnc_compileRules` sorts them by kind), and a layer is left as soon as
nothing it could still set is open. Afterwards `size=mass` becomes cells, stacks become whole numbers of at least 1, the footprint
is cut to `SHAPE_MAX`, and non-containers get no grid. `fnc_explain [class, compiled]` lists every layer that has a say, highest
first, with what it sets and wins (for the debug console; the wizard words the answer and its source with
`einv_setup_fnc_answerText`). The `src` tags are `own:<i>`, `legacy:<setting>:<i>`, `mod:<config key>`, `preset:<id>:<i>`,
`all:<i>`, `builtin` and `forced`.

For a container **object** (`einv_storage_fnc_getBlocks`), its own `einv_grid` beats all of these for its compartments (section
3). Mass per grid cell: the header's `cell=`, else the nearest preset in the chain with a `cell` over 0, else the slider
`einv_items_massPerCell` (default 5); clamped to 1 to 50.

### Config keys of an item (`fnc_getFacts`, `fnc_readConfigKeys`)

A mod author predefines what an item is in the item's own class, in the language of the rules text: every value is a STRING (a
NUMBER for stack and weight) written as the rules write the same value, so there is one grammar to learn. They are the "mod config"
layer above: a server's rules text still beats them, and they beat a preset.

| Key | On | Value | Same as |
|---|---|---|---|
| `einv_size = "2x1";` | any item | `WxH`, a mask like `"xx/x-"`, or `"mass"` | `size=` |
| `einv_stack = 10;` | anything but a rifle, handgun, launcher, binocular, uniform, vest or backpack (those stay 1) | a whole number, 1 to `MAX_STACK` | `stack=` |
| `einv_grid = "1x3+5x7+1x3";` | uniform, vest, backpack, crate, vehicle, kit | anything `grid=` takes: `"auto"`, `"24"` (a plain number `24` too), `"120%"`, `"rig:16"`, compartments, shapes, a canvas | `grid=` |
| `einv_weight = 0.5;` | any item | kilograms, 0 to `MAX_WEIGHT`, rounded to the gram | `weight=` (kg, not config mass) |
| `einv_name = "Short name";` | any item | the name as it shows, at most `MAX_NAME` characters; a space is a space | `name=`, but plain text (the rules text writes `_` for a space and `%XX` for the rest) |
| `einv_picture = "a3\ui_f\data\gui\cfg\hints\gear_ca.paa";` | any item | the texture it shows instead of its config `picture`: backslashes or slashes, spaces as they are (`fnc_parsePicture` with `encoded = false`) | `picture=` (config writes the plain path, the rules text the encoded one) |
| `einv_use = "backpack,vest";` | any item | the containers it may be used from where a setting closes them: `uniform`, `vest`, `backpack`, `all` or `none`, joined with a comma, a plus or a bar (`fnc_parseUse`). `""` takes an inherited value back, so `"none"` says no container | `use=` (config writes the comma, the rules text the plus) |
| `einv_cat = "medical,misc";` | any item | the categories it is in instead of the built-in one: `weapon`, `ammo`, `grenade`, `gear`, `medical`, `food`, `tool`, `misc` joined with a comma, a plus or a bar (`fnc_parseGroups`). `""` takes an inherited value back | `cats=` (config writes the comma, the rules text the plus) |
| `einv_icon = "1.4@0.1,-0.05";` | any item | how the picture is drawn in its tile: a scale 0.25 to 4, and after an `@` how far it is moved across and down, -1 to 1 of the tile (a comma or a colon between the two); a plain number `1.4` is the scale alone | `icon=` (config writes the comma, the rules text the colon) |

- **Read by the rules' own readers.** `fnc_readConfigKeys` hands the size to `fnc_parseRules` and the grid to
  `fnc_parseGrid`/`fnc_formatGrid`, so the limits, the cuts and the words of a message are those of the rules. A value that cannot be
  read is left out, one past a limit is cut down, and the reason goes to the RPT once per class (`Config of <class>: ...`, the
  facts are kept); one wrong key never costs the others. Spaces in a size or grid are ignored (`"1x3 + 5x7"`).
- **Where.** On the item's own class: CfgWeapons for uniforms, vests, headgear and most items, CfgVehicles for backpacks, crates and
  vehicles, CfgMagazines, CfgGlasses. The grid of a uniform, vest or backpack belongs to the item class, not to the container class
  it brings along. `einv_storage_fnc_getBlocks` needs nothing of its own for it: it asks `getInfo "grid"`.
- **Inheritance.** Config reads these as it reads everything: a subclass has its parent's value unless it sets its own, key by key
  (`getText`, `getNumber` and `isText` walk the parents). `einv_grid = "";` (an empty text for any key) on a subclass takes an
  inherited value back. New keys win over the older ones, so a key the parent set beats an older key (`einv_grids[]`) set on the
  subclass: set the new key on the subclass to override.
- **The older keys stay as aliases.** `einv_gridSize[] = {w, h}` is `einv_size`, `einv_stackSize` is `einv_stack`, `einv_grids[] =
  {{cols, rows}, ...}` and `einv_slots = N` are `einv_grid`. For one field the new key wins; then `einv_gridSize[]` /
  `einv_stackSize`; for the grid `einv_grids[]`, last `einv_slots`. The `src` tag says which one answered (`mod:einv_grid`,
  `mod:einv_gridSize`, ...).
- **One object** can still carry its own grid, which beats everything: `_crate setVariable ["einv_grid", "6x4+2x3", true]` (section
  3). Same name, different place: the class's config key is for every object of the class, the variable for one.
- `fnc_getFacts` keeps the readable keys in `"mod"` by field: `"size"` ([w, h, holes] or `"mass"`), `"stack"`, `"grid"` (a spec),
  `"weight"` (kg), `"name"`, `"icon"` (`[scale, across, down]`), `"picture"` (a path), next to the older `"gridSize"`, `"stackSize"`, `"grids"`, `"slots"`.

Two public functions turn the keys into a snippet and back, for mod authors and for the setup wizard's export and import:

- `einv_items_fnc_configEntry [class, all = false, compiled = nil]` -> STRING: the lines for a class from its current answer, in one
  line, `class CfgVehicles { class B_Carryall_blk { einv_grid = "1x3+5x7+1x3"; }; };`. The root is the class's own. Only the keys that
  differ from what the class would get without the rules text and the older tables - from its own config, the preset the rules
  are built on, and the built-in answer - are written, and only those that apply (no stack for a vest, no grid for a rifle). So a
  vest whose size the preset gives and whose grid was painted yields its grid alone, and the preset stays the server's choice.
  `all` writes every key that has an answer (a weight, a name, an icon and a picture only where something sets them; the icon with the comma
  config uses). `compiled` reads the class by
  another set of rules, the wizard's draft (its own rules are the ones left out). `""` for a class no config knows or when
  nothing differs. The lines go inside the class's definition in the mod's config; another mod's class is patched with an
  external class declaration and that mod in `requiredAddons`.
- `einv_items_fnc_parseConfigEntry [text, messages = nil]` -> `[[class, keys], ...]`: reads such lines - one class or many, under
  their root or without it; comments, `class X;` declarations, parents (`class X: Y`), other properties and nested classes are
  skipped - into `keys`, a HashMap by lowercase config key (`"einv_size"`, `"einv_stack"`, `"einv_grid"`, `"einv_weight"`,
  `"einv_name"`, `"einv_icon"`, `"einv_picture"`, `"einv_use"`, `"einv_cat"`) with the values as the rules write them (size and grid STRING, stack and weight NUMBER, name
  STRING, icon `[scale, across, down]`, picture STRING); only keys
  that could be read, and only classes that have one. What was left out is added to the `messages` array when one is given, else
  to the RPT. A text over `CONFIG_TEXT_MAX` 65536 characters is not read.

### like=CLASS

`class=My_Vest > like=V_PlateCarrier1_rgr grid=6x4`: when the rule matches, every field of `LIKE_FIELDS` (footprint, stack, grid,
weight - never the name or the picture) that is still open and not set by the rule itself takes what `fnc_resolve` makes of the source class
right then, through the same compiled rules (its own rules, mod config and presets). A later change to the source follows. The
source's grid becomes the compartments it really has (`einv_storage_fnc_blocksFor` with its class, kind and load, as `["blocks",
...]` - "auto" by the target's load would be another grid); a source that is no container gives "auto". Its weight is taken only
when a rule or its own `einv_weight` sets one on it, else -1 and the target keeps its own config weight. A higher rule still wins a field, and the like
rule closes the fields it fills. A circle, more than `LIKE_DEPTH` 8 like= one after the other, or a class no config knows gives
the built-in answer for those fields (src `builtin`) and one RPT line per problem (`einv_items_likeWarned`). `fnc_explain` counts
`LIKE_FIELDS` as set by such a rule.

### Presets

A preset is a class of `CfgEinvRulesets` with `name`, `description`, `revision` (shown only; `base=` always means the preset as
installed), `base`, `cell` (-1 to leave it to its base or the slider), `rules[]` (statements of the same language, one per
element, no commas) and `class Groups` (labels and examples of the groups). The group ids are what own rules refer to and a preset's id
is what a text names in `base=`: never rename one. Other mods may add presets as classes there; the wizard offers no choice among them.

- **`default`** (revision 4) is the one preset this mod ships, and it is realism: rifles 4x2 to 7x2 by mass, handguns 2x1,
  launchers 6x2, magazines 1x1, 1x2 or 2x2 by mass, belts 2x2, rockets 1x3 and 2x3, grenades 1x1, optics, muzzles and small items 1x1 up
  to 3x2 by mass, belts 2x2, helmets 2x2, uniforms 2x2, vests 3x3, backpacks 4x4, 5x5 and 5x6 by load (up to 160, up to 280, above) - and
  **nothing stacks** but the groups `@stack_20`, `@stack_10`, `@stack_5` and `@stack_2`: consumables of ACE, ACM and the vanilla first aid kit,
  by class (`class=ACE_fieldDressing|ACM_IV_16g+|...`). The rules are keyed by class, so a mod that is not loaded matches nothing; a name with a
  plus is that class and everything built on it, used where all of them are of the same sort. A rule of the text for a class wins over them like
  over any preset rule. The medical list of issue #9 (ACE, ACM, ACME and Enhanced First Aid Kits: one `class=` rule per size and stack, vials by `class~`) sits after the `@stack_*` groups and wins over them. It sets **no grid**: a uniform, vest or backpack gets the built-in answer (`grid=120%`, `einv_storage_fnc_blocksFor`),
  a crate or vehicle `auto`, so the text's rules with `all` - the General step's kind sizes - decide for every container no class rule, table or mod
  answers. The groups are a partition (an item is in at most one, `medical` and the `stack_*` groups excepted, which are only handles), so a rule for
  one never reaches into another. Kits of Enhanced First Aid Kits are items to `kind=` as well, so the item groups size them; none of
  these gives a kit a grid.
- **`realism`, `weight` and `tarkov` are read as `default`.** `PRESET_ALIASES` maps them in `fnc_parseRules` (one RPT line,
  `einv_items_aliasWarned`) and in `fnc_compileRules`' chain (another mod's preset built on one of them), unless a preset of that
  name exists. A text that says `base=weight` therefore loads, without an error, with the default's sizes - the old presets' own rules are gone.

### What `fnc_getInfo` returns

`[class, compiled (opt), cache (opt)] call einv_items_fnc_getInfo` -> HashMap (Public). Without `compiled`: the rules in effect,
cached per lowercase class in `einv_items_info`. With `compiled` (a wizard's draft) and a `cache`: kept there; with `compiled` and
no cache: not kept. Callers must not modify it. The config part comes from `fnc_getFacts` (cached for good in uiNamespace
`einv_items_facts`), the rest from `fnc_resolve`.

| Key | Type | |
|---|---|---|
| `class` | STRING | configName; for an unknown class the input |
| `name`, `short` | STRING | the rules' `name=`, else displayName; displayNameShort or else the name |
| `description`, `picture` | STRING | descriptionShort (may hold `<br/>`), config `picture`; "" for none |
| `category`, `kind` | NUMBER, STRING | `CATEGORY_*`; the kinds above. MEDICAL if `ACE_isMedicalItem` is 1 or ItemInfo type is 401/619; WEAPON for rifle, handgun, launcher; AMMO for magazine, grenade; GEAR for uniform, vest, headgear, goggles, nvg, binocular, backpack |
| `mass` | NUMBER | effective mass in config units: the rules' `weight=` / `MASS_TO_KG`, else config mass |
| `size` | ARRAY | `[w, h]`, upright - the box around the footprint |
| `footprint` | ARRAY | `[w, h, holes]` upright, holes the indices `row * w + col` of cells it does not take, `[]` for a full rectangle |
| `footprintTurned` | ARRAY | the same turned a quarter clockwise (`fnc_turnMask`, `fnc_footprintAs`) |
| `cells`, `shape` | NUMBER, STRING | `w * h` less holes; the size as the rules write it, `"2x3"` or `"xx/x-"` |
| `stack` | NUMBER | how many may share a tile, at least 1 |
| `capacity` | NUMBER | a magazine's rounds, 0 for everything else |
| `maxLoad` | NUMBER | uniform/vest: maximumLoad of its containerClass; backpack, crate, vehicle: maximumLoad; else 0. A size proxy only, never a limit |
| `grid` | ARRAY | containers: the grid spec (`fnc_parseGrid`: `["auto"]`, `["cells", N]`, `["percent", P]`, `["pattern", name, N]`, `["blocks", [[cols, rows, holes, pos], ...]]`), `[]` for anything else. The categories a compartment accepts are cut down to those that exist (`fnc_cleanGrid`): a compartment whose list ends up empty takes anything again, so a category taken out of the text never leaves a compartment that accepts nothing |
| `src` | HashMap | field -> where it came from |
| `configMass`, `configDisplayName`, `configShort` | | config's values, whatever the rules say |
| `weightOverride`, `nameOverride` | NUMBER, STRING | the rules' weight in kg (-1 for none), the rules' name ("" for none) |
| `picture`, `pictureOverride`, `configPicture` | STRING | the texture the item shows: the rules' (`picture=`, `einv_picture`) when `fileExists` says it is there - `pictureOverride` is the rules' path whether it is or not, "" for none -, else config's `picture`, which `configPicture` keeps whatever the rules say. Every drawing of the item reads `picture` |
| `use` | ARRAY | the containers it may be used from where a setting closes them: any of `"uniform"`, `"vest"`, `"backpack"` in that order, `[]` for none (`use=`, `einv_use`, `fnc_parseUse`). Read by `einv_storage_fnc_useState` |
| `cats` | ARRAY | the categories the rules or the item's config put it in (`cats=`, `einv_cat`, `fnc_parseGroups`) that exist - one the setup does not define is dropped here -, in the order of `fnc_orderGroups`; `[]` when none does |
| `groups` | ARRAY | the categories it is in: `cats` when it has some, else the built-in one (`fnc_defaultGroup`, worked out from the item's facts and kept there as `"group"`) - never empty. Read by the strip of a loot box, by `einv_storage_fnc_blockMode` for the compartments that accept only some categories, and by the wizard's Category row |
| `icon` | ARRAY | how the picture is drawn in the item's tile: `[scale, across, down]`, the scale a factor (0.25 to 4), the offsets a share of the tile's width and height (-1 to 1); `[1, 0, 0]` (`ICON_PLAIN`) for the plain picture. From `icon=` / `einv_icon` (`fnc_parseIcon`); every picture of the window draws by it (section 4, "Grids and tiles") |
| `lc`, `root`, `rounds`, `lineage`, `addon`, `mod` | | from `fnc_getFacts`: lowercase class, config root, a CfgMagazines `count`, lowercase classes from itself up, the CfgPatches class, what its own config says (`einv_size` and the other keys, "Config keys of an item") |

`fnc_getFacts` takes kinds from config by weapon `type` and ItemInfo type (its header lists them); any other CfgWeapons class is
`item` - CBA's misc item class counts there although it inherits the bipod type; CfgMagazines with count 1 and mass up to 15 are
`grenade`; CfgVehicles with `isBackpack` 1 are `backpack`, others of `AllVehicles` `vehicle`, the rest `crate`. A class no config
knows is `unknown`, under its own name. An `item` that Enhanced First Aid Kits registers as a kit is **`kit`** (a pouch of Enhanced
Utility Pouches too): `fnc_kitTypes` reads that mod's registry `EFAK_Kits` from config once (uiNamespace `einv_items_kitTypes`,
lowercase prototype -> `[prototype, instances, capacity]`), and `fnc_kitOf [class]` (public) -> `[prototype, n, instances, capacity]`
or `[]` names the type's own class (n 0) and the instance classes that mod makes of it, `<prototype>_<n>` for n 1 to `instances` -
the same list `efak_core_fnc_isKit` reads, without that mod's functions, so Eden and the menus know it too. A kit's `maxLoad` is the
capacity the registry gives its type (a mission's CBA setting for it is that mod's; `einv_compat_efak_fnc_capacity` reads it). To
`kind=` a kit is an `item` as well (`KINDS_AS_ITEM`): `fnc_matches` lets `kind=item` reach it and `fnc_compileRules` puts the item
rules into its `byKind` bucket, so servers' `kind=item` rules and the presets' item groups size and stack it as before, while
`kind=kit` reaches only kits. Kits are containers (`KINDS_CONTAINER`): their grid comes from the rules and config keys like any other, but only counts where a rule or
a config key sets it (section 7, compat_efak).

### Functions

| Function | Public | |
|---|---|---|
| `fnc_getFacts [class]`, `fnc_getInfo [class, compiled, cache]` | Yes | config facts; the answer above |
| `fnc_configEntry [class, all, compiled]`, `fnc_parseConfigEntry [text, messages]` | Yes | an item's config keys as a snippet, and back ("Config keys of an item") |
| `fnc_readConfigKeys [found]` | No | the seven config keys read by the rules' readers -> `[canonical, compiled, messages]` |
| `fnc_footprintAs [class or info, rot]` | Yes | `[w, h, holes]` as it lies, upright or turned |
| `fnc_parseRules [text]` | Yes | -> AST: `version`, `base`, `cell` (-1 for none), `groups` `[[id, conds], ...]`, `rules` `[[conds, values], ...]`, `warnings`; a condition is `[negated, key, op, values]` (a group reference has key `"@"`), a rule's values a HashMap of `like`, `footprint`, `stack`, `grid`, `weight`, `name`, `icon`, `picture` |
| `fnc_writeRules [ast, header = true]` | Yes | -> canonical text |
| `fnc_compileRules [text, legacy = true]` | Yes | -> compiled; `legacy` reads the tables and stackSmall too |
| `fnc_currentRules []` | Yes | the rules in effect, compiled again first when `fnc_rulesInputs` changed |
| `fnc_explain [class, compiled]`, `fnc_encodeName [text, path = false]`, `fnc_decodeName [text, path = false]`, `fnc_getProtection [class]` | Yes | every layer's say; `name=` encoding (with `path`: the `picture=` form, `_` stays and `\` is `/`); the zones a vest, uniform or helmet covers (with `fnc_getArmor`: ACE's own armor number) |
| `fnc_parseGrid [text]`, `fnc_formatGrid [spec]`, `fnc_parseMask`, `fnc_formatMask`, `fnc_turnMask` | No | grid specs and masks; `fnc_parseMask` is the one reader of masks, for items and compartments alike |
| `fnc_parseIcon [text]`, `fnc_formatIcon [icon, separator = ":"]` | No | the value of `icon=` / `einv_icon`: `"1.4@0.1:-0.05"` -> `[[1.4, 0.1, -0.05], notes]` (`[]` when unreadable; limits cut with a note) and back, the colon for a text, `","` for config |
| `fnc_parsePicture [text, encoded = true]` | No | the value of `picture=` / `einv_picture` -> `[path, notes]` (`""` when unreadable or too long) |
| `fnc_parseUse [text]`, `fnc_formatUse [containers, separator = "+"]` | No | the value of `use=` / `einv_use` -> `[containers, notes, readable]` (the containers in the order uniform, vest, backpack, `[]` for none), and back (`"none"` for `[]`) |
| `fnc_builtinGroup [word]`, `fnc_orderGroups [list]` | No | which of the eight a word means (itself, a `GROUP_ALIASES` word, a plural; `""` for none); a list of categories in the stored order (the eight, then the rest alphabetically, no doubles) |
| `fnc_categories [compiled]`, `fnc_categoryInfo [id, compiled]` | Yes | the ids of every category there is, the eight then the setup's own in definition order (the rules in effect, or a compiled draft); a category's `name` (the wizard's chips), `label` (the strip's tooltip), `only` ("Only ... here"), `picture` (the setup's, only where the game has the file), `nameSet`, `pictureSet`, `builtin`, `known`: the name the setup gave it, else the one this mod ships (`STR_einv_setup_Cat_<id>`, `STR_einv_gui_Group_<Id>`, `STR_einv_gui_Only_<id>`), for an own category with none its id as words |
| `fnc_cleanGrid [spec, ids]` | No | a grid spec with the categories its compartments accept cut down to the ids given (default: those that exist); read by `fnc_getInfo` and by `einv_storage_fnc_getBlocks` for an object's own `einv_grid` |
| `fnc_parseGroups [text, key]`, `fnc_formatGroups [groups, separator = "+"]`, `fnc_defaultGroup [facts]` | No | the value of `cats=` / `einv_cat` -> `[groups, notes, readable]` and back; the built-in category of an item, the mapping that used to live in the window (medical, weapon, grenade - the kind grenade and a mine or charge -, ammo, gear, food, tool, misc) |
| `fnc_compileCond`, `fnc_matches`, `fnc_parseTable [text, type, warnings]`, `fnc_sanitizeText` | No | conditions; the older tables; the EDITBOXes' sanitizer |
| `fnc_resolve [facts, compiled]` | No | -> `footprint`, `stack`, `grid`, `weight` (kg, -1), `name` ("" none), `src` |
| `fnc_setBy [info, field]` | Yes | who set a field, from its `src` tag: `"rule"` (`own:`, `legacy:` but the stack slider, `all:`), `"config"` (`mod:`), `"preset"` (`preset:`, the stack slider), `"default"` (`builtin`, `forced`) |
| `fnc_kitTypes []`, `fnc_kitOf [class]` | No, Yes | Enhanced First Aid Kits' kit types from its config registry; which kit type a class is (above) |
| `fnc_rulesInputs []` | No | `[rules text, size table, stack table, container table, stackSmall, massPerCell]` |
| `fnc_loadRules [text]` | No | compiles when the inputs changed; a text stands in for the setting (testing, `einv_items_rulesOverride`), `""` ends that |
| `fnc_checkServerRules [published]` | No | warns once when the server reads the same settings differently |

The compiled form is plain data, no code (it is kept in missionNamespace): `text`, `ast`, `base`, `chain`, `cell`, `warnings`, the
categories (`categoryIds`, the eight then the text's own in definition order; `categoryDefs`, id -> `[name, picture]` the text gives it; a use of an id the text does not define is a warning, "There is no category 'x'"), the groups (`groups`, `groupKeys`, `groupSource`, `groupOrder`), the rules (`own` = the text's, then the tables'; `preset`; each
`[conds, values, tag, text, kinds]`), `byKind` (kind -> indices and fields, so an item meets only the rules that can be about it)
and `hash`.

### Caching, the event and the server's hash

- missionNamespace: `einv_items_ruleset` (compiled; nil until the first compile), `einv_items_rulesInputs`,
  `einv_items_rulesInputsKey`, `einv_items_rulesRevision` (from 0, +1 per compile), `einv_items_info` (lowercase class -> getInfo,
  replaced by an empty map on every compile, which is all a changing `like=` source needs), `einv_items_rulesOverride`,
  `einv_items_likeWarned`, `einv_items_aliasWarned`.
- `einv_items_rulesHash` - public, set by the server (not in Eden): `[inputsKey, hash, version]`. The server also sends it as the
  CBA event `einv_items_rulesPublished [published]`; a client joining later finds the variable set. A client compares only a hash
  it compiled from the same settings and says once, in the RPT and in chat, when it reads them differently (another version of the
  mod or of a preset).
- uiNamespace (not in save games): `einv_items_facts`, `einv_items_presetCache`.
- The local CBA event **`einv_items_rulesChanged [revision]`** is raised by `fnc_loadRules` on every machine after a compile.
  Listeners: gui (an open window is built again after a held tile is let go), setup (an open wizard takes the new setup in),
  weight (the player's virtual load is worked out again).
- Eden runs no setting scripts, so `fnc_getInfo` calls `fnc_currentRules` while `einv_items_ruleset` is nil or
  `cba_settings_ready` is not set, and that compiles the current text whenever `fnc_rulesInputs` differs from what it compiled.

### Settings of the engine

All global, each runs `fnc_loadRules` when it changes: `einv_items_rules` (EDITBOX, default `einv1 base=default`),
`einv_items_massPerCell` (the fallback, default 5), `einv_items_stackSmall` (default 10) and the older tables
`einv_items_sizeTable` (`class:WxH, ...`), `einv_items_stackTable` (`class:N, ...`), `einv_storage_containerTable` (`class:N` or
`class:WxH+WxH`), which still work and win over the text. Section 8 lists them all.

### What the wizard writes (`einv_setup_fnc_upsertRule`, `fnc_upsertRules`)

`fnc_upsertRule [class, set, remove, tree = false]` writes what the Items or Containers step sets for one class into the draft, as that
class's own rule `class=X > ...`; `fnc_upsertRules [[class, set, remove, tree], ...]` does the same for several classes in one undo step
(the editors' import). `set` is a HashMap of `footprint` (`"2x3"` or a mask), `stack`, `grid` (as `fnc_formatGrid` writes it), `like` (a
class), `weight` (kg), `name`, `icon` (`[scale, across, down]`), `picture` (a path) and `use` (an array of container words); `remove` is an array of fields to take away. The rules written for exactly that class
(`einv_setup_fnc_ownClassRules`) become one; whatever else they set stays. The rule goes **last**: later rules win, so a broader rule
further down (a group, a kind) would otherwise still decide what the class gets and the step would show something other than what
was just applied. A rule left with nothing to set goes altogether. It returns false for a class name the language cannot hold, and ends
in `fnc_commit` (an undo step, the step drawn again).

With `tree` the rule is `class=X+ > ...`: one rule for X and every class built on it, instead of one per class (the tree view's edits,
see "Trees and mass edits"). The rules written for exactly `class=X+` become one in the same way. Where it goes follows the engine's
order, later wins, field by field: it must beat what is broader (a group, a kind, a parent's `class=P+`) and lose to what is narrower,
so a class that was set apart stays apart. The rules that are only for classes inside the tree - `class=Y` or `class=Y+` for a Y of
`fnc_classTree`'s set below X, hidden bases included - are moved behind it; everything else stays in front. X itself is edited with its
tree: what the edit sets or removes is also taken out of X's own rule `class=X`, which would otherwise win over the tree's rule on X
alone. A tree that holds nothing but X is written as X alone.

`fnc_upsertKinds [[kind, set, remove], ...]` writes the General step's size for a kind of container, keyed by the rule's selector
(`fnc_allRule [rules, kinds]`: `all kind=uniform` for one of `GENERAL_KINDS`, `all` alone, in any order of kinds): found anywhere in the text and
edited in place (a new one goes last), other values kept, a rule left with nothing goes; other hand-written `all` rules are not touched. One
`fnc_commit`. `fnc_kindRule [kind]` reads it back as `["auto"]`, `["fixed", across, down]` or `["other"]` (a grid the row cannot show as a size).
`tools/check_default_ruleset.sqf` round-trips `einv1 base=none, all > size=1x1 stack=10, kind=uniform|vest|backpack all > grid=6x4`.

### `tools/check_default_ruleset.sqf`

Not part of the mod; copied into a mission and started with `[] execVM "check_default_ruleset.sqf"` with the mods to check
(vanilla, ACE, a large pack). It checks that the shipped `default` preset gives every item the size and stack, and every container
the compartments, it is meant to (rifles 4x2 to 7x2, backpack tiles, nothing stacking but the `@stack_*` classes, containers from 120 % of
their load as a block, pouches or a near-square block), that the groups are a partition, that texts and names round-trip, that
`base=tarkov`, `realism` and `weight` read as `default` and that canvases (`grid=aaa/aba/aaa`) round-trip. The summary shows as a hint;
every finding goes to the RPT and the clipboard.

## 3. Storage

What a container holds, where it lies on its grid, what a unit wears, and every change to any of it. All functions are `Public:
No` unless noted. Entries and sections are HashMaps.

### Entries (`fnc_getContents [container]`)

One entry per tile, weapons first, then backpacks, magazines, items. Weapons and backpacks are a tile each (every one may carry
other attachments or contents); every magazine is a tile (own rounds), except the ones that stack (grenades and the like, `getInfo
"stack"` over 1), which share a tile only with the same rounds; plain items are counted together by class and split at their stack
size - along the places' records when they carry counts (two stacks of one class can lie apart, see below). A null container gives
`[]`.

| Key | |
|---|---|
| `class` | STRING |
| `count` | NUMBER, at least 1 |
| `ammo`, `capacity` | NUMBER, rounds in a magazine and in a full one; 0 for anything else |
| `attachments` | ARRAY, a weapon's `weaponsItemsCargo` entry, `[]` otherwise |
| `container` | OBJECT, a uniform, vest or backpack lying here: its own container object from `everyContainer`; objNull otherwise |
| `key` | STRING, the key of its place record (`fnc_entryKey`) |
| `strict` | BOOL, it lies in the unit's hidden holder, not in the cargo (Strict mode, below). Not the window's `hidden`, "not searched yet" (`fnc_markHidden`), which only the window sets |

**Stacks apart** (`fnc_getContents`, `fnc_stackCounts`). A pile of one key (`fnc_entryKey`) is cut along the places' records of that
key: the n-th record is the n-th tile and holds as many as its eighth element (the count) says, so 5 and 1 of a class that stacks
to 10 are two tiles. The cargo is the truth for the total; records only say how it is arranged, so the two are reconciled and the
tiles always add up to what the cargo holds (`fnc_stackCounts [total, stack, counts]`): a total below the records takes the
difference from the last tiles first (a tile at zero is gone); a total above lets a record without a count take up to a full stack,
tops up the last tile that has room with what is still left, then opens new tiles (full stacks, then the remainder). Records
without a count (an older save, a loadout) stand for "as many as the cargo gives": with none at all that is the old cut - full
stacks first, then the remainder. A tile of the hidden holder (Strict mode) and anything that does not stack have no counts.

`fnc_getLayout` adds `block`, `col`, `row`, `w`, `h` (as it lies), `holes`, `rotated` and `overflow`. Every nested container gets
two local marks as it is read: `einv_storage_itemClass` (its compartments go by the item, since its container object is only a
Supply class) and `einv_storage_parent` (what it lies in, for `fnc_rootOf`). `fnc_entryToArray` / `fnc_entryFromArray` carry an
entry over the network, never with a tile's controls in it.

**Keys** (`fnc_entryKey`): `class|w<hash>` a weapon by what is on it, `class|m<rounds>` a magazine, `class|c<id>` a uniform, vest
or backpack lying in a container (the id is its tag; untagged, `class|c`), else the lowercase class. Identical keys are identical
items: which of two lies where nobody can tell, so no two machines map the same records to different items. `fnc_payloadKey` gives
the key a payload will have once it lands, so the record written for a dropped cell matches the item the moment it arrives.
`fnc_layoutKey [class]` is the kind of a class for the layout's second pass: the lowercase `ace_arsenal_uniqueBase`, else the
lowercase class.

### Compartments (`fnc_blocksFor`, `fnc_getBlocks`)

`fnc_blocksFor [class, kind, maxLoad, spec, cell]` -> `[[cols, rows, holes, pos], ...]`. It works on the class alone, so the
wizard can show a container nobody carries. `spec` is a parsed grid (section 2). `holes` are the indices `row * cols + col` of
cells a shaped compartment does not have, `[]` for a full rectangle (every pattern gives that); `pos` `[x, y]` is the
compartment's top left cell on its canvas, `[]` for one the window flows (patterns, `WxH`, shapes, `einv_grids[]`, the open grid).
Readers with `params ["_cols", "_rows"]` or `["_cols", "_rows", "_holes"]` stay valid. The order is the pieces' order, a canvas's
own in reading order of each one's first cell; that index is the place record's `block`. Every compartment keeps cells of its own,
numbered from its own top left corner, wherever it is drawn. No cells at all gives `[[STORAGE_COLS, 0, [], []]]`.

Patterns by kind when none is named - worked out from the load alone, never from the class's name, so two containers with the same load
look the same: uniform - `block`, one compartment `UNIFORM_COLS` 6 wide and as many rows as the load asks for, `UNIFORM_ROWS_MIN` 2 to
`UNIFORM_ROWS_MAX` 5 (6x2 for a plain uniform); vest - `pouches`, a tall 1x2 and a square 2x2 after each other as a real magazine rig has them, as many as
the load asks for, at most `VEST_POUCHES_MAX` 20; backpack and kit - `single`, one compartment as near square as `STORAGE_COLS` allows; crates and
vehicles - `wide`, one compartment `STORAGE_COLS` wide. By name a rule or config key can also ask for `pockets` (1x2, at most six), `pockets_mixed`, `rig`
(1x2), `mixed`, `plate` and `long` (at most sixteen), `pouches` and `block` (`grid=rig:16`). A given number (`24`, `einv_grid = "24"`, `einv_slots`) is met exactly; one from the load is a rough measure. The load is
`fnc_getMaxLoad` (config `maximumLoad`, -1 for a weapon holder or null): since weight limits nothing, it only sizes the "auto",
"percent" and "pattern" grids.

`fnc_getBlocks [container]` finds what to ask for a real one. First answer wins:

1. The object's **`einv_grid`**: a STRING grid as in `grid=` (`"6x4+2x3"`, `"rig:16"`, `"xxx/x-x"`, a canvas, `"auto"`), set by a
   mission with the public flag on a crate, a vehicle, or a unit's uniform, vest or backpack container: `_crate setVariable
   ["einv_grid", "6x4+2x3", true]`. One that cannot be read is named in the RPT once (cache `einv_storage_objectGrids`) and the
   rules count instead. Scripts of this mod may give the compartments as they are, `[[cols, rows], ...]`: taken exactly, never cut
   to `MAX_ROWS` (the Arsenal's staging space).
2. The rules for its class (`getInfo "grid"`): the older container table, the text, the class's own config `einv_grid = "..."` (a
   mod's word for every container of that class, a subclass inherits it; section 2, "Config keys of an item") or else the older
   `einv_grids[]` / `einv_slots`, the preset, else "auto". For a unit's uniform, vest or backpack the class is the item's; for a
   crate or vehicle its own, `typeOf`.

The ground has no compartments and no limit: `[]`; the window draws it as one open grid, `STORAGE_COLS` wide, always a row more
than it needs and at least three rows. A key (a holder that is no object, `"kit:..."`) has the compartments its holder type's
`"blocks"` gives (`einv_storage_holderTypes`), `[]` - an open grid that grows - when it gives none: a kit has those of a grid a
rule or its config gives it (`einv_compat_efak_fnc_kitBlocks`), else none. `fnc_getLayout`, `fnc_hasSpace` and `fnc_findEntry`
(`"open"`) ask `fnc_getBlocks` for keys as for objects. A uniform or vest container's class derives from a weapon holder, so `fnc_isGroundHolder`
excludes `ContainerSupply`: only a pile is a ground. A backpack with a load of 0 takes an own grid like any other.

### Places and the layout (`fnc_getLayout`)

`[holder, entries, _, places, order]` -> HashMap: `entries` (all, placed), `blocks` (as `fnc_blocksFor`; the open grid's with the rows it
needs now), `overflow` (entries with no room), `records` (canonical), `drift` (the records laid out from are not exactly
`records`) and `revision`. A holder is a container or the key of a grid with no object, `"kit:" + lowercase class`, laid out like
the ground.

It is a **pure function** of the holder's places (`fnc_readPlaces`), its entries and the rules, so every machine draws the same
picture from the same data. Nothing is written in it; the authority persists the picture when records drifted (`fnc_normalize`).
In order:

1. **exact** - the n-th record of a key goes to the n-th entry of that key (entries of one key come in a fixed order, full stack
   tiles first), when its size matches the way round it says, its compartment exists and its cells are free.
2. **kin** - every record still unused, in order, goes to the first unplaced entry of the same kind (`fnc_layoutKey`) whose size
   matches either way round, when free: a repacked magazine, a radio that got its instance class, a kit made ready keep their
   place.
3. **first fit** - the rest, in the `order` asked for - largest first (then category, kind, key, index) when none is: compartment
   after compartment, row by row, upright, else turned. A square rectangle never turns; a shape in a square box turns when turned
   it takes other cells. Only a Sort asks for another order (`fnc_opSort`), one of `SORT_MODES` (main's `script_macros.hpp`):
   `"size"` as above, `"name"` by the item's name (`getInfo "name"`, lowercase), `"weight"` heaviest first by what the tile weighs
   (`fnc_getMass`: attachments and a container's contents count) then by name, `"type"` weapons, ammo, gear, medical, the rest (the
   category) then by kind, largest first and name; every order ends on key and index, so the same contents come out the same
   everywhere. Anything else is `"size"`. The result is written to the places, so a name sorted by one machine's language reads the
   same on all.

An entry no compartment has room for (a script or another mod added it) is `overflow`: shown apart, never lost. On a unit's
uniform, vest or backpack the surplus is moved on to the unit's next container with free cells (section "Surplus" below); what
fits nowhere stays overflow.

**Place records** are `[key, col, row, w, h, block, rot]` and, for a tile of a class that stacks in a container, `[..., count]`:
`w` and `h` as it lies, `rot` 0 upright or 1 turned a quarter clockwise, always written with `rot`, `count` the items the tile holds
(`fnc_writePlaces` keeps a whole number from 1 up that has a `rot` before it; a kit's records and a loadout's have none). The layout
writes the count of every stackable tile it placed; `fnc_getLayout` reports no drift for a record that only lacks the count the
picture gives it, so older places are not all written again at once. A record without it (saved places, loadouts, snapshots, payloads of older shape; six
elements) reads as turned when its `w` is not the upright one, and `fnc_getLayout` counts no drift for that alone. The holes of a
shaped item always come from its class at use time (`einv_items_fnc_footprintAs [class, rot]`), so only `rot` is stored and
synced.

**Rotation convention.** Turned is a quarter clockwise (the picture is not turned, see "Grids and tiles"): the cell `(c, r)` of an upright
mask `cols` wide and `rows` high lies at `(rows - 1 - r, c)` of the turned one (`fnc_turnMask`). Two ways round only, never upside
down.

**Holes are seeded.** `fnc_seedTaken [blocks]` starts the taken-rows of every layout with the holes of shaped compartments, and
`fnc_cellsFree [taken, col, row, w, h, holes]` / `fnc_takeCells` ask and mark cell by cell with an item's own holes left out.
`fnc_getLayout`, `fnc_plan`, `fnc_opPut` and `fnc_opPlaceMany` all work from these, so `fnc_hasSpace`, `fnc_findEntry`, quick
moves and the authority agree on what fits: nothing lies on or across a hole, and a small item may lie in the corner an L leaves
open (`fnc_overlaps` is the same test for a kit's grid).

**Op cells.** An op that names a cell takes `[col, row, block]` (the tile's own size, the way it lies) or `[col, row, block, w, h,
rot]` - `w` and `h` as it will lie, `rot` 1 turned. `fnc_setPlace [holder, entry, cell, add]` changes one record (on the authority
only; inside a phase through its buffer); `[]` as the cell takes the record out.

### Categories and single slots (`fnc_blockMode`, `fnc_slotOf`)

A compartment may carry two attributes (section 2, `grid=`): the categories it **accepts** and whether it is a **single slot**. They are the
fifth and sixth element of its block, `[cols, rows, holes, pos, accepts, single]`; a block without them has four, and `count _x > 4`
is the test for "this container has any" (`fnc_getLayout` and the others make none of the checks below for the rest, so an ordinary
container costs nothing). `fnc_blocksFor` carries them through; the patterns and the older tables make none.

`fnc_blockMode [block, groups]` -> -1 the compartment refuses the item (it accepts a list, and none of the item's `groups` is in it), 0 it
takes it like any compartment, 1 it takes it as a single slot. It is the one question every place that looks for a spot asks, so an item
never lands in a compartment that refuses it, on any machine:

- **The layout** (`fnc_getLayout`, a pure function of places, entries and rules): a record, kin or first-fit spot in a refusing
  compartment is passed over - a stale record (the rules changed, a script put the item there) is not honoured, the entry lies in
  another compartment or is overflow, and `fnc_normalize` writes that picture. So `fnc_hasSpace`, `fnc_hasRoom`, the arsenals' overflow
  checks (`getLayout` for the unit's containers), the migration of surplus and Strict mode's return from the hidden holder
  (which only add to the cargo and let the layout place) follow without a line of their own.
- **Ops that name a spot**: `findSpots` (op put, move, split) passes refusing compartments over - a cell asked for in one is not free,
  the item goes to the first fit or, for a split, the nearest spot, and `elsewhere` says so; `opPlaceMany` (op place, swap, the plan's
  moves in the same holder) answers `"WrongKind"` for a cell in a refusing compartment; `fnc_plan` (quick move, Take all, Put all,
  the migration) skips them per target. `hasSpace` and `findSpots` agree because both go through the layout.
- **Single slots.** A single slot holds one tile - a stack counts as one - and the tile takes the whole compartment: `fnc_slotOf [block]`
  -> `[0, 0, cols, rows, holes]`. The layout writes the entry with that box, `rotated` false and `"single"` true, and its record is
  `[key, 0, 0, cols, rows, block, 0]` (a record in a slot is kept for any entry the slot accepts, its own size aside); the slot is
  free only while none of its cells is taken, so the ordinary cell logic keeps a second item out. `findSpots` returns a seventh
  element, the spot's holes, and a single slot as `[0, 0, block, cols, rows, 0, holes]`; `opPlaceMany` replaces any cell asked for in a
  slot by the slot's. An item lifted out lies at its own size again: the window reads `"single"` of the entry (`fnc_startDrag`) and
  a cell without a size is the item's own (`opPlaceMany`). The slot's box is a plain rectangle (or a shape with holes), so every
  existing cell test, the plan's and the window's, treats it like a tile of that size.

The categories a compartment accepts are those that exist: `fnc_getInfo` cuts the list of `"grid"` down to the setup's categories (`fnc_cleanGrid`) and `fnc_getBlocks` does the same for an object's own `einv_grid`, so a category taken out of the text, or named in a text written for another setup, never leaves a compartment that accepts nothing for good - one with no category left takes anything again. The wizard's *Delete* on a category of its own does the same to the draft's text (section 6).

A kit's grid (`compat_efak`) honours both wherever it is laid out (room checks, first fit; `fnc_kitBlocks` carries the two
elements on). A cell named in a kit (`fnc_opKitPlace`, `fnc_putIntoKit`, both through `fnc_cellFree`) is checked as the slot's box
in a single slot, but its categories are not asked there: the next layout puts a tile in a refusing compartment where it is accepted.

### Room (`fnc_hasSpace`, `fnc_hasRoom`, `fnc_plan`)

- `fnc_hasSpace [container, entry]`: a free spot in one of the compartments, laid out once more with the entry added from the
  places everyone shares; nothing is kept. The ground and a kit without a grid of its own always have room (they grow); a kit with
  one is laid out like a container, what it holds read through its holder type's `"entries"`. A stackable entry **first fills the
  partly filled tiles of its own key** (a magazine only stacks with the same rounds; two partial tiles of a class are two tiles,
  each with its own room) - the layout never merges into a tile - and only what is left needs free spots, one per stack's worth.
  That is exactly what a put without a cell does (`fnc_opPut`), so the answer holds for Quick move, Take all and the plan.
- `fnc_hasRoom [container, entry]`: `fnc_hasSpace` plus the one kind rule left, `fnc_backpackIntoBackpack` (reason
  `"NoBackpack"`). The cargo commands add whatever they are given, so a window, mission or mod asks this before it puts anything
  in. `fnc_moveEntry` and `fnc_unequip` ask when they get no cell; the machine that runs the op asks again and decides.
- `fnc_plan [items, targets, options]` -> `[assigned, left]`: where several things go when moved together - the first target, in
  the order given, with a spot for each, largest first (option `"order"`: `"given"` keeps the order), counting what is already
  planned. Options `"start"` ([holder, compartment] tried first) and `"lifted"` (items treated as gone from where they lie).
  `"ground"` as a target always has room and takes no cell. Nothing is asked of any machine but this one. An item never goes into
  a target that is the container it is or lies in it (`fnc_liesIn`). **A stackable tile first fills the stacks of its key in a
  target that are not full** (what its put does) and only the rest takes a spot, one tile's worth; one that fits into the stacks
  that are there is assigned with the cell `[]`, and what is planned into a target counts for the items after it. A tile planned
  into the holder it lies in joins nothing (op `placeMany` lays it down) and always takes a spot.

### Moving what a tile stands for

There is no "remove one item" command and a unit's containers cannot be written anew, so everything moves by taking out and
putting in with the cargo commands.

- `fnc_snapshot [container, itemClass]` -> everything a container holds in a form `fnc_restore` can put back: `[items, magazines,
  weapons, backpacks, nested [[class, object, snapshot], ...], [place records, tag], carried variables]`; `tag` is `[id, item
  class, parent]` or `[]`; the carried variables `[[name, value], ...]` are those in `einv_storage_carryVariables` (TFAR keeps a
  long-range radio's settings on the backpack object, and every move makes a new object). A moved backpack keeps its inside
  arrangement and id.
- `fnc_removeEntry` / `fnc_removeSameClass` take an entry out and hand a **payload** on: `["weapon", weapon array]`, `["magazine",
  class, [rounds, ...]]`, `["backpack", class, snapshot]` or `["item", class, count, snapshot or []]`; `fnc_addPayload` puts one
  in and reports what arrived (with `fnc_clearCargo`, `fnc_restore`, `fnc_normalizeWeapon`, `fnc_addWeapon`). Taking out uses
  negative counts, as ACE does (`addItemCargoGlobal` with -n, `addMagazineAmmoCargo` for that magazine by its rounds,
  `addWeaponCargoGlobal`, `addBackpackCargoGlobal`). **Only what really left - read off the cargo before and after - is handed
  on**, and `fnc_restore` only refills a container `fnc_clearCargo` really emptied: that is what keeps an item from being copied
  or lost. Of several identical uniforms, vests or backpacks the engine picks which leaves; `fnc_removeSameClass` takes all of the
  class out, hands the wanted one on by uid and puts the others back, verified.
- `fnc_makePayload [class, count, rounds]` and `fnc_addNew [container, class, count, cell]` -> `""` / `"NoRoom"` / `"NoBackpack"`
  / `"Failed"` make what did not exist (the Arsenal's adds), a free spot when no cell is given; `fnc_countClass [container,
  class]` counts by class. `addNew` and everything else adds by the cargo commands, never by `canAdd`.
- **Stacks apart** (`fnc_opPut`, `fnc_opTake`, `fnc_opMove`, `fnc_opSplit`, `fnc_setCount`, `fnc_findSpots`). The records are
  changed in step with the cargo, in the phase's buffer, so the stack the player chose is the one that gains or gives items. The
  first view of a container in a phase (`fnc_findEntry`) puts the picture's records into the buffer before any op changes the cargo,
  so every stackable tile has a record with its count. `take` of part of a stack lowers its tile's count (`fnc_setCount`), of a whole
  tile removes the record. `put` of a payload of a class that stacks (items, magazines of one number of rounds, not into the hidden
  holder, not a uniform, vest or backpack): **without options it joins** the tiles of its key that have room, in their order,
  and what is left opens new tiles (this is what Quick move, Take all, Sort, the plan and settlement do); with **`separate`**
  (6th argument) it joins nothing and lies at the cell as a tile of its own (a count above one stack is cut into full tiles, the
  others go to the first fit); with **`merge into`** (7th, `[col, row, compartment]` of a tile of the same key) that tile is
  filled first, then as without. Only the tiles that open need a free spot (`fnc_findSpots`: the cell asked for, else the first fit,
  upright then turned); a payload that fits into the room of the tiles it joins needs none, so the check of `move` asks for what
  really moves. Extra of a put: `[landed cell (the joined tile's cell for a pure join), elsewhere]`. `move` passes both on to its
  put. **Op `split`** `[holder, entry array, count, cell]` (within one holder, in `GVAR(ops)`; a kit type names none, so the window
  does nothing for kits): the tile gives up `count` (its record's count down) and the same number lie as a new tile on the cell, or -
  cell `[]` or not free - on the free spot nearest to the source tile (its compartment first, then the others; upright, then turned);
  no spot is `"NoRoom"` with nothing changed; the cargo is not touched, so it is a change of records only (the lock and person guards
  treat it like `place`). Stackable payloads of mixed rounds and anything that cannot be told by record (the hidden holder, an
  overflow tile) are left to the reconciliation, which does the same sum in tile order. `GVAR(stackSplits)` (`einv_storage_stackSplits`,
  set true in preInit on every machine) is what the window reads to ask for the new behaviour at all; false switches it off, the
  records already written stay. The Arsenal's `fnc_remove` of part of a stack lowers its tile's count the same way and `fnc_addNew`
  with a cell lays the new items down as a tile of their own.
- **Nested containers.** A uniform, vest or backpack lying in a container carries a tag `[uid, itemClass, parent]`
  (`fnc_tagNested`, ids `<machine id>-<n>` from `fnc_newUid`) and travels with its places in payloads. Whether variables on nested
  objects reach every machine is not known, so both ways are kept: tag and places stay on the nested object, and in multiplayer a
  copy goes onto the outermost container, `einv_storage_nested = [[netId, uid, itemClass, places], ...]`. Readers take the
  object's own tag first, else the copy's; for places the higher revision of the two (the object's own on a tie, the copy only
  when its uid matches); `fnc_verifyChain` brings objects up to their copies. It needs the same `netId` on every machine.

### Authority and transactions

**Authority.** A container is changed only where its root is local (`fnc_rootOf [holder, hint, what]`, public): the unit for a
unit's uniform, vest or backpack and whatever lies in them, else the object itself (crate, vehicle, pile, body); for a kit the
root of the container it lies in. `what` `"top"` gives the outermost container, `"parent"` the one it lies in. `fnc_verifyChain
[holder, root]` walks the real cargo (`everyContainer`, three levels) before an op, so a holder no longer under its root is
`"Moved"`. `fnc_isLocalRoot [root]` says whether a phase on that root runs on this machine at once without the hub: single player
and Eden always; in multiplayer only this machine's own player unit, an object made on this machine only and marked
**`einv_storage_localOnly`** (the Arsenal's staging space; the hub could not even see it), and, on the server, objNull. Everything
else goes through the hub, also on the hosting player's machine and for a unit remote controlled with Zeus. `fnc_inReach` is the
reach check (`REACH_SLACK` 2 m beyond the setting).

**Requests** - `einv_storage_fnc_request [phases, callback, args, silent, requester]` (public). A phase is `[root, ops]`, ops on
one root; an op is `[name, args]` from `einv_storage_ops`: `place` (one tile to another cell of one holder), `placeMany` (several
lifted and put down at once, refused as a whole when any cell is not free), `sort` (`[holder, order]`, the order one of `SORT_MODES` -
name, weight, size, type; laid out where the root is local), `normalize`, `migrate`, `move` (within one root), `take`,
`put`, `split` (part of a stack to a tile of its own, within one holder), `putGround` (on the server), `takeOff`, `putOn`, `repack`, and compat's `kitTake`, `kitPut`, `kitPlace`, `kitMove`,
`kitRemoveIfEmpty`. An op's input may be a ref `["#ref", phase, op, n]` to the n-th payload an earlier op produced. Each op
answers `[status, produced, extra]`, status `""` or a reason (`"Gone"`, `"Taken"`, `"NoRoom"`, `"NoBackpack"`, `"Moved"`,
`"OutOfReach"`, `"Bounced"`, `"Failed"`, a guard's reason such as `"Locked"`, ...). The phases are copied; what the caller holds
never changes. Phases that may run here run at once (`fnc_requestNext`); from the first that may not, the hub carries on. The
answer is the callback's `[id, summary, revisions, args]` (`fnc_onAnswer`); the summary is `[per phase per op [status, extra],
[went back, into the vehicle, onto the ground], pile or objNull]`. A transaction that needs the hub before `fnc_hubReady` does not
start: every op `"NotReady"`.

**Running a phase.** `fnc_execute [ops, context, journalKey, continuation, args]` runs one phase on the root's authority: per op
the holder check (`fnc_verifyChain`), the requester's reach and every guard in `einv_storage_guards` (`CODE [op, args, requester,
root] -> "" or reason`: the window's `einv_gui_fnc_personGuard`, the locks' `einv_locks_fnc_guard`, ACRE2's slot guard) - reach
and guards not for settlement -, then the op. Reads and `fnc_setPlace` go through the phase's buffer (`einv_storage_buffer`);
every holder touched is laid out and written **once** at the end. Phases are journaled (`einv_storage_journal`, key
`"id|phase|attempt"`, kept `JOURNAL_KEEP` 300 s): a phase the hub sends again is answered from it and never runs twice, and a
script error stops the phase and `fnc_phaseFinalize` answers it from the journal a frame later (`fnc_nextFrame` works in Eden).
`fnc_tick` runs at most `PHASE_FRAME_OPS` 30 ops a frame, whole phases only.

**The hub** (server: `fnc_hubStart`, `fnc_hubNext`, `fnc_hubRoute`, `fnc_hubPhaseDone`, `fnc_hubTick`, `fnc_hubDisconnect`) routes
each phase to its root's owner, never to two owners of one root at once (`LOCALITY_SETTLE` 1 s after a change of owner), re-sends
an unanswered phase every `PHASE_RESEND` 10 s, holds payloads in escrow while they travel, treats a root whose owner left for
`ROUTE_TIMEOUT` 15 s as `"Moved"`, and re-routes a leaving player's phases (`PlayerDisconnected`, `allUsers` as a safety net). In
multiplayer the requester must be the unit of the machine that sent it. **Handshake:** a client greets (`einv_storage_hello
[machine id, version]`, every 5 s until answered, `fnc_greetServer`) and the server answers `einv_storage_welcome [version]`;
`fnc_hubReady` is true in single player, on the server and on a client after a welcome with the same version. Before that the
window refuses moves that need the hub ("Waiting for the server"): a server without these events would drop what the client
already took out.

**Settle** (`fnc_settle [transaction, results, step]`) is the rule that nothing is lost or doubled: whatever an op produced and no
later op consumed is put somewhere, in three steps. Step 1, back where it came from - one phase per origin root; what came off a
slot (op `takeOff`) goes **back on that slot** (op `putOn`) while it is still empty, so a backpack whose drop went wrong is on the
back again rather than nowhere. Step 2, the requester's vehicle, when alive (a forced put, room not asked). Step 3, the ground
(`putGround` at the transaction's ground point, else the terrain under the requester). Settlement phases skip reach and guards; a
step the requester cannot run itself goes to the hub as a silent transaction whose first phase counts as run and carries the
payloads by refs.

**Ground.** `fnc_groundPos` takes the surface under the feet when the move is asked for (`where`); `fnc_getGroundHolder [where,
ignore, fresh]` finds the nearest non-empty server-local pile within `GROUND_RANGE` 2 m that can be seen (`fnc_isNear`), else
makes a `GroundWeaponHolder_Scripted`; never an empty pile. In multiplayer only the server picks a pile. Seated, a drop goes into
the vehicle's cargo; with nothing under the feet (swimming, falling) it is refused.

The pile is the scripted holder because the engine garbage-collects a `GroundWeaponHolder` it takes for empty, and a backpack is an
object attached to the holder, not cargo the engine counts: a pile holding only a backpack was deleted, backpack included (the dated
record is in `docs/HISTORY.md`). `GroundWeaponHolder_Scripted` is the same holder the engine never
deletes, so the mod deletes it itself: `fnc_pruneScriptedPile [pile]`, called by `fnc_execute` for every ground pile a phase touched
and by `fnc_opPutGround` for the piles a bounced put-down left empty. A pile of that type that is local and, a frame later, still
holds no item, weapon, magazine or backpack is deleted (a frame, so the answer and the window's redraw finish first). Engine-made
`GroundWeaponHolder`s and `WeaponHolderSimulated` are never touched. `fnc_getGroundHolder` still finds both kinds
(`isKindOf "GroundWeaponHolder"`), and `fnc_getNearby` lists the scripted one (a `WeaponHolder`) only while it holds something.

### Places sync (`fnc_writePlaces`, `fnc_flushPlaces`, drift)

Places are `einv_storage_places = [revision, records]`, public, on the container (kits: the mission variable
`einv_storage_places_kit_<class>`), written only by the authority (`fnc_writePlaces [holder, records, force]`: revision = the
higher of the one read and the last written, plus one; records canonical; not written when unchanged unless forced; -1 and an RPT
error on a machine that is not the authority). The player's own containers are set at once and **broadcast at most every
`OWN_WRITE_DELAY` 2 s** (`einv_storage_dirty`, `fnc_flushPlaces`, also when the window closes and when the player dies, so a
body's places are public for its looters); any other write is public at once. In multiplayer the authority looks again after
`HEAL_DELAYS` 1.5 s and 6 s whether an older write of a previous authority overtook its own, and writes its own again.
`fnc_readPlaces [holder, asStored]` (public) returns `[revision, records]`, the fresher of the object's own and the nested copy.
**Drift:** a holder whose places disagree with its cargo (something came or went without a place) is noted by the window
(`einv_gui_drift`) and reported after `DRIFT_WAIT` 1 s as a silent op `normalize [holder, revision, hashValue records]`; the
authority lays the holder out and writes the picture (`fnc_normalize`, `fnc_opNormalize`; a stale viewer copy at most every
`FORCE_REPEAT` 30 s) - exactly what every viewer already shows, so nothing visibly moves. `fnc_dumpPlaces [holder]` (public)
writes revision, records, nested tags and this machine's drawn view to the RPT and returns the text.

### Surplus (`fnc_opMigrate`, `fnc_requestMigrate`, `fnc_queueMigrate`, `fnc_tickMigrate`)

The engine's own commands (`addItem`, `addMagazine`, `addWeapon`, loadouts, ACE, the arsenals, scripts) know nothing of our cells and
fill a uniform, vest or backpack until its mass is reached. Cells are the only room, so what the layout has no room for
(`overflow`) is passed on: **uniform -> vest -> backpack**, to the first later container with free cells. What fits nowhere stays
overflow, shown apart as before. Never dropped, never copied.

- **Op `migrate [unit]`** (`fnc_opMigrate`; root: the unit, holders: its three containers, so they are verified and written once at
  the end of the phase). For the uniform, then the vest: `fnc_plan` puts the overflow (largest first) into the containers after it
  and each tile moves with op `move` (`fnc_opMove`: spot checked first, out and in verified, back into the source when it did not
  arrive; a stray it could not land goes back into the source forced, only what even that cannot take is produced and settles).
  Each container is planned from the places the moves before wrote (the phase's buffer), so no two moves plan one cell. The person
  guard lets it through for any requester.
- **Request** (`fnc_requestMigrate [unit, requester, tries]`): looks first, from the cargo and places this machine reads, and asks
  for a silent transaction of one op only when some overflow has a free cell after it. The requester is the unit itself (a looter's
  window passes the player); the player's own unit and single player run at once, any other unit goes through the hub to its owner;
  an answer that says the op did not run queues the unit again (`MIGRATE_RETRY`, `MIGRATE_TRIES`).
- **Triggers** only note a unit local here (`fnc_queueMigrate`, `MIGRATE_DELAY` 0.3 s, a waiting unit keeps its earlier time);
  `fnc_tickMigrate`, a `MIGRATE_TICK` per-frame handler, looks at up to `MIGRATE_PER_TICK` of them. Nothing raises an event for
  `addItem`, so: CBA's polled `loadout` and `unit` player events (the player), `Take` / `Put` / `InventoryClosed` on `CAManBase` (any
  unit local here), every loadout set (`fnc_onLoadoutSet`; `einv_storage_migrateUnit` tells the owner when it was set elsewhere), a
  changed rule set, and the window: `einv_gui_fnc_requestNormalize` asks for every person whose uniform, vest or backpack shows an
  overflow tile (bodies and looted persons included), every `DRIFT_REPEAT`. An AI whose gear a script filled, and nobody looks at,
  waits for one of these.
- **Arsenals.** While ACE Arsenal (display 1127001) or the vanilla one is open (`ARSENAL_OPEN`) nothing migrates: they add and take
  back on their own (section 5 - ACE's panel still takes back an add with no free cell). `fnc_onClosed` and `fnc_biLeaveAlone` ask once
  after the close, before `fnc_reportOverflow`, which then names only what has nowhere to go.
- **Locality, no loss, no copy.** Only the unit's authority changes its containers, one phase at a time per root, journaled (a phase
  the hub sends again is answered from the journal and never runs twice); every move is verified by counting, and a tile that did not
  land goes back to where it was taken from. A change of owner between request and run is `"Moved"` or runs on the new owner, which
  plans again from what it finds. The server setting `einv_storage_migrate` (default on) switches the whole thing off.

### Equipment (`fnc_getEquipment`, slots, putting on and off)

`fnc_getEquipment [unit]` (public) reads `getUnitLoadout`: `primary`, `launcher`, `handgun`, `binocular` as `[class, muzzle, rail,
optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod]` (`[]` when empty) and `uniform`, `vest`, `backpack`,
`headgear`, `goggles`, `map`, `gps`, `radio`, `compass`, `watch`, `nvg` as class or "". Slot ids are `primary`, `primary_optic`,
`primary_mag`, ... (`fnc_getSlot`); `fnc_slotAccepts` is the one gate every equip path asks, `fnc_slotFor` names the slot an item
goes in, `fnc_partFor` the part of a weapon a magazine or attachment fits. `fnc_putOn` / `fnc_takeOff` run where the unit is local
and are checked afterwards: the new item must be in the slot or whatever went on comes off again and the old one goes back
(`"Bounced"`); what is still in the slot after a take-off is not handed on. Missions use `fnc_equip [unit, slot, holder, entry]`,
`fnc_unequip [unit, slot, holder, cell]` and `fnc_moveEntry [from, to, entry, count, cell, requester]` (public).

### Sections for the window

`fnc_getSections [unit]` gives the unit's own storage in order uniform, vest, backpack (only those it has), each `{id, title,
class, container}`. `fnc_getLootSections [container, secondary, opened, nearby]` gives what is looted: a body's virtual `worn`
section (`entries`, one per worn thing, each with its `slot`) then its uniform, vest and backpack; `ground`; a crate or vehicle as
`container`; the uniforms, vests and backpacks opened from inside a container; and what lies around. Every section of a container
carries `holder`, `root`, `parent`, `nearby`, `folded` (crates found around start folded) and `side` ("loot"); `fnc_orderSections`
puts a section with a `parent` right below its parent's. `fnc_getNearby [unit, range, max]` (public): every pile that holds
something and every crate within `einv_storage_nearbyRange`, same floor and in sight (`fnc_isNear`), nearest first, at most
`NEARBY_MAX`; not vehicles, bodies, persons, hidden, carried, loaded or locked objects, nor `einv_nearby = false` on the object.
Whether a pile holds something is asked of the engine's cargo lists, not of `fnc_getContents` (the window asks every second).

### Loadouts

CBA's loadouts carry the arrangement. `fnc_onLoadoutGet` (event `CBA_loadoutGet`) writes `einv_layout = [1, [uniform, vest,
backpack]]` into the extended info - the records of `fnc_readPlaces` with the key cut down to `fnc_layoutKey` of its class - and
`fnc_onLoadoutSet` (`CBA_loadoutSet`) writes them back with `fnc_writePlaces` where the unit is local, else sends them to its
machine (`einv_storage_loadoutPlaces`, `fnc_onLoadoutPlaces`). Only well-formed records are kept; a record the new items do not
match drops out at the next layout, and a loadout without the key leaves everything to the first fit. Both handlers are registered
in preInit on every machine, Eden too.

**The container load.** The engine's `setUnitLoadout` stops filling a uniform, vest or backpack at its config `maximumLoad`, which the grid does not
respect, so a saved loadout would come back short. `fnc_onLoadoutSet` therefore calls `fnc_topUpLoadout [unit, loadout]` (where the unit is local at
once and a frame later, else it sends `einv_storage_topUpLoadout` to the unit's machine) before the places are written: for the uniform, vest and
backpack the loadout names (a different worn class is skipped) the intended items are compared with `getUnitLoadout` as a map - an item by class,
a magazine by class and rounds, a weapon by class and attachments without its loaded magazines, a backpack by class - and only the positive
difference is added to the container object with `addItemCargoGlobal`, `addMagazineAmmoCargo`, `addWeaponWithAttachmentsCargoGlobal` or
`addBackpackCargoGlobal` (classes the game lacks are left out as the engine left them), so a second pass adds nothing. The layout and
`fnc_queueMigrate` do the rest. Every path through `CBA_fnc_setLoadout` is covered, ACE Arsenal's Load and the loadouts screen included; a plain
`setUnitLoadout` raises no event, so scripts that need this call the public **`einv_storage_fnc_setUnitLoadout [unit, loadout]`** (`setUnitLoadout`
plus the top-up and the migrate note, on any machine: a unit that is not local gets a `einv_storage_setUnitLoadout` CBA event).

### The backpack take-off path

The drop of any worn slot (menu Drop, a drag to the ground): `einv_gui_fnc_doUnequip` -> `fnc_sendMoves` (`unequip` to `"ground"`:
phase 0 `takeOff` at the unit, phase 1 `putGround` at objNull = the server, its payload a ref) -> `fnc_request` ->
`fnc_requestNext` runs phase 0 here (`fnc_opTakeOff` -> `fnc_takeOff`: `fnc_snapshot`, **`removeBackpack`** - the unit is local
there; the delayed `removeBackpackGlobal` showed the slot still worn, handed nothing on and lost the backpack when the engine then
removed it - the slot read again, payload `["backpack", class, snapshot]`), then phase 1 in the same frame on a server or in
single player, else through the hub (`fnc_opPutGround` -> `fnc_getGroundHolder` -> `fnc_addPayload` with `addBackpackCargoGlobal`;
the pile is never made in one frame and filled in another), then `fnc_settle` and the answer. Safety nets: a backpack still worn
after `removeBackpack` is looked at a frame later and put back on from its snapshot if the engine took it off late;
`fnc_addPayload` counts a backpack as arrived also by one more `everyBackpack` object; settlement step 1 puts it back on the back
while the slot is empty. `fnc_putOn` uses `addBackpack`, which fills the container at once.

**Dragged out of the window.** `einv_gui_fnc_updateDrag` makes the target `["ground", -1, 0, 0, true, ""]` outside every panel, and
`fnc_endDrag` gives a slot's item to `fnc_doUnequip [unit, slot, "ground", []]` - the menu Drop's own call, only inside the mouse-up
event instead of a frame later. The window makes no pile, asks no hook (`ground` is asked only by `fnc_quickUnequip`,
`fnc_dropToGround`, `fnc_quickMove`), and `fnc_settle` works from the phases, not the window's in-flight record; with no pile in
reach `fnc_getGroundHolder` makes one. The step that differs from a vest's is the engine's cleanup of a pile holding only a backpack,
an object of its own and no item cargo, which the scripted holder avoids (see Ground above). A backpack joins only a pile of ours
(`GroundWeaponHolder_Scripted`) or a fresh one, and the backpack just taken off is marked (`einv_storage_takenOff`) so that the plain
holder the engine keeps it in until the end of the frame is never taken for a pile. `fnc_opPutGround` writes one RPT line per
backpack, "Backpack CLASS goes onto pile NETID".

### Use from containers (`fnc_useState`, `fnc_useCarried`, `fnc_reloadGuard`)

Three global CBA settings, topic "Use from containers" (`addons/storage/initSettings.inc.sqf`): `einv_storage_useUniform`,
`einv_storage_useVest`, `einv_storage_useBackpack` - "Use items from the <container>" - each a list **Everything** (`USE_ALL`
"all", the default and how the game works), **Only whitelisted** (`USE_LIST` "list"), **Nothing** (`USE_NONE` "none") or
**Strict (hidden)** (`USE_STRICT` "strict": Only whitelisted, and what is blocked is kept out of the container's cargo altogether -
the next section). They decide what counts as *usable* while it lies in the player's own uniform, vest or backpack: a magazine to
reload from, a grenade to throw, a bandage or a bottle, a kit, a radio. Items opt back in per container with the rule value `use=`
(section 2; the wizard's "Use from" chips): on Only whitelisted and Strict an item counts when its `info "use"` lists that
container, on Nothing nothing does, whitelisted or not. Only the kinds in `USE_ITEM_KINDS` (magazine, grenade, item, kit, radio)
are ever limited - a rifle, an attachment or a uniform in the backpack is stowed, not used. A crate, the ground or a body are never
limited.

- **The question** is `einv_storage_fnc_useState [class, container]` -> `""` (nothing limits it), `"allowed"` (whitelisted on a
  limited container) or `"blocked"`; `fnc_useKind [container object]` says which of the player's three a container is (`""` for any
  other), `fnc_useMode [container]` is the setting's answer. Each setting runs `fnc_useRefresh` when it is set or changed, which
  keeps `GVAR(useActive)`: while all three are on Everything every function above answers at once, so the default costs one
  variable read where it is asked.
- **What is checked** (the practical, robust set - things this mod owns): the window's tiles (a small padlock in the corner,
  `fnc_createTile`; the footer hint says "Cannot be used from the backpack" or "Whitelisted: can be used from the backpack",
  `fnc_updateHover`); the context menu (the hotbar's bind row is gone because `einv_hotbar_fnc_canBindFrom` refuses, a radio's
  Open radio and Use as active radio are not offered, and a CBA row that uses the item up - ACE rations, medical items - is left out,
  `fnc_cbaOptions`); the hotbar (a drag or the menu cannot bind an item from a blocked container - "Cannot be used from the
  backpack" -, and the slot's count, the magazine the key loads, the kit it opens and the grenade it takes only look at what
  `fnc_useCarried [unit, [items, magazines, magazinesAmmoFull]]` leaves, which takes one entry out for every item lying in a
  blocked container; a key pressed with everything blocked says "Cannot be used from the backpack - take it out first",
  `fnc_useBlockedIn`); and the engine's reload key.
- **The reload key** (`fnc_reloadGuard`, called by the one KeyDown handler on the main display from postInit, which also calls
  `fnc_throwGuard` and swallows the key when either says so - two handlers were one too many: the engine went by the throw guard's
  `false` for R although the reload guard returned `true`, and reloaded by its own pick as well, issue #2). The engine decides which
  magazine it loads and takes it from any container; a mod cannot change that, and `Reloaded` cannot be cancelled. So **with any
  limit active the key is the mod's alone** - the game's "Reload" action keys, plain, on foot, with a rifle, pistol or launcher in
  the hands, and at least one magazine the muzzle takes (none: the key is the game's, which has nothing to load either). A key held
  down (`RELOAD_GUARD_GAP` 0.6 s, `GVAR(reloadAt)`) or a reload under way (`weaponState` entry 6, the magazine reload phase, above 0)
  is swallowed; a full magazine in the weapon does nothing, as in the game; otherwise the fullest usable magazine (`fnc_reloadPick`)
  is loaded with `fnc_loadMagazine` (below: the game's `LoadMagazine` action for that one magazine, or by hand into an empty muzzle).
  With only blocked magazines a line names the containers to take one out of. A load that fails swallows the press too (an RPT
  WARNING) and clears the repeat gap - the engine's own reload is never let in while a limit is active. ACE's `isReloading` is
  **not** asked here: ACE sets it in its own KeyDown handler for this very press, and the guard took its own press for a reload
  under way and swallowed it without loading. With every setting on Everything the guard answers `false` at once: reloading is the
  game's, untouched. A vehicle's gun is not caught.
- **One reload, one token** (`GVAR(reloadToken)`). `fnc_loadMagazine` writes `[unit, weapon, "creator:id", class, rounds, old
  magazine, source container, counts of the old magazine per container, until]` right before the `LoadMagazine` action. The
  first `Reloaded` event of that unit spends it (`fnc_onReloaded`), whatever it shows, so nothing runs twice for one reload: when
  the loaded magazine is the one asked for (by id, or by class and rounds when the id cannot be told), the reload stands and a frame
  later `fnc_reloadTidy` moves the magazine the game put away out of a container that is blocked for it into the container the new
  one came from, when that has room - once. When the game loaded another one, an RPT INFO says so and the undo below decides. The
  token runs out after `RELOAD_TOKEN_MAX` 12 s and is cleared when a magazine is taken out of a weapon (`fnc_takeOff`).
- **Nothing waits for ever**. `einv_storage_fnc_reloadBusy` (the hotbar's magazine and throwable keys, AIME's menu, the undo's
  delayed load) is the player's weapon reload phase (`weaponState` entry 6) or ACE's `ace_common_isReloading`, the flag believed
  for `RELOAD_BUSY_MAX` 5 s from the first time it was seen set, then ignored until it was seen cleared once. The undo's busy mark
  is a time, `GVAR(undoUntil)` (`UNDO_BUSY_MAX` 3 s), not a flag, so a script error in the middle of `fnc_reloadUndo` cannot disable
  `fnc_onReloaded` for good. A magazine taken out of a muzzle (`fnc_takeOff`, slots `mag` and `mag2`) clears the hand-load note,
  the reload token and the repeat gap and renews the notes of where the magazines lie (`fnc_useTrack`).
- **Loading by hand is free of the limits**. The settings are about using items in the field (R, hotbar, ACE actions), not about handling the gear in the window: a magazine dragged from any container (also a blocked backpack, and a Strict one's hidden entries, which `fnc_removeEntry` takes out of the holder) onto a weapon or its magazine slot, or loaded with the menu's "Load into", goes in. `fnc_weaponPart` notes every magazine it puts on (`fnc_noteHandLoad`: `GVAR(handLoad)` = `[unit, weapon, class, until]`, `HAND_LOAD_WINDOW` 1.5 s), and `fnc_onReloaded` leaves a loaded magazine of that weapon and class alone while the note stands (one event answers it and clears it) - should `addWeaponItem` raise `Reloaded`, the undo would take back a load the player chose. The setting texts say so.
- **A reload by the scroll menu, a gamepad button or a script** (`fnc_onReloaded`, the CAManBase event `Reloaded` from postInit):
  the engine has loaded a magazine by then and `Reloaded` cannot be cancelled, so it is undone afterwards, and only when it is sure.
  `fnc_useTrack` keeps `GVAR(useIds)`, "creator:id" -> "uniform" | "vest" | "backpack" for every magazine of the player that
  lies in a container, taken from the location `magazinesAmmoFull` gives (entry 4; entries 5 and 6 are the id and creator),
  else from the containers' own lists when exactly one container holds a magazine of that class and rounds. It is renewed once a
  second (`TRACK_TICK`), after each answered transaction (`fnc_onAnswer`) and on `Take`, `Put` and `InventoryClosed`. A loaded
  magazine keeps its note (the animation takes seconds and a note taken in the middle must not erase the origin); notes of magazines
  the unit no longer has go. On `Reloaded` the loaded magazine is found in `magazinesAmmoFull` by class and rounds (exactly one
  such, else nothing is done), its id is looked up, and when the note says a container where `fnc_useState` is "blocked" for the
  class, `fnc_reloadUndo` runs a frame later. A magazine that is not noted, or is allowed, is left to the game.
  `fnc_reloadUndo` (on the unit's machine - the unit is local, so are its containers): checks that the weapon still holds that
  magazine in that muzzle (`weaponsItems` entry 4, or 5 for a second muzzle), counts the magazine per container, takes it out with
  `remove<Primary|Handgun|Secondary>WeaponItem`, counts again - the game either let it go (then it is put into the container it came
  from with `addMagazineAmmoCargo [class, 1, rounds]`) or put it into the cargo (then it is moved to that container, or stays where
  it is when the container will not take it) - and a magazine nowhere is put back into the weapon with `addWeaponItem`. Then the old
  magazine (`Reloaded`'s last argument, when it has rounds) is taken out of whichever container holds one with those rounds and put
  into the weapon, and given back to the container when that does not hold. A line says "Cannot reload from the backpack."; if a
  magazine that may be used is left (`fnc_reloadPick`, the fullest) and the undo left the muzzle empty, `UNDO_RELOAD_WAIT` later it is put in by hand with `fnc_loadMagazine` - an undo never starts a reload of the game's, so it cannot loop. Its own `addWeaponItem` restores are noted as hand loads (`fnc_noteHandLoad`), so a `Reloaded` they raise is not undone in turn. Never done twice (`GVAR(undoUntil)`, a time that runs out), and not when the magazine's origin is unknown. Untested in the game: the exact shape
  of the `Reloaded` arguments and whether `removePrimaryWeaponItem` returns the magazine to the cargo are checked by counting, not
  assumed.
- **Loading a chosen magazine** (`einv_storage_fnc_loadMagazine [unit, weapon, muzzle, entry]`, public): the one way every reload of
  this mod ends - the key's guard, the undo of a refused reload, the hotbar, `compat_aime`'s menu. `entry` is a row of
  `magazinesAmmoFull` (seven items). A muzzle that holds a magazine gets the game's `LoadMagazine` action with its animation,
  after the reload token above is written. An
  **empty** muzzle - no magazine in the weapon - is loaded by hand: the magazine is taken out of the container it lies in
  (`addMagazineAmmoCargo [class, -1, rounds]`, counted before and after), put in with `fnc_weaponPart` (below), the window's reload
  gesture and sound play (`einv_gui_fnc_playReload`, when loaded), `fnc_queueMigrate` and `fnc_useTrack` follow; a magazine that did
  not go in is put back and only then the action is tried. Why: the reload key's guard used to load its pick with the action alone,
  which is not reliable for a weapon with no magazine in it (Mia, 0.5.13: R does nothing with an empty weapon, whatever lies where,
  and a popup says the backpack's magazines do not work). Found by reading, not by running the game: untested in Arma. `fnc_reloadPick` chooses: the fullest usable
  magazine the muzzle takes, ties by uniform, vest, backpack. `fnc_weaponPart` puts a magazine on a weapon (the window's drag onto a
  weapon or a magazine slot, the menu's "Load into", the direct load above) with `addWeaponItem` and looks at `weaponsItems` after
  each try: `[weapon, [class, rounds, muzzle], true]`, then without the muzzle (first muzzle only), then the plain class with the
  rounds set by `setAmmo`; a form that was needed is told in the RPT (INFO), none working a WARNING. Handgun, launcher and a second
  muzzle (a grenade launcher, slot `mag2`) go through the same code by their slot id; a second muzzle is one in `muzzles[]` that
  is neither `this` nor the first.
- **The throw key and ACE's advanced throwing.** The engine takes the throwable of the selected class from the unit's magazines -
  the order of its containers is believed to be uniform, vest, backpack (the order of the unit's loadout; not verified, and not
  relied on) - and nothing a mod runs can say from which. What is done instead keeps a closed throwable from being the choice:
  `fnc_throwState` splits the throwables the unit carries (the magazines of the `Throw` weapon's muzzles) into those with a copy in
  an open container and those only in closed ones. `fnc_throwGuard` (a KeyDown handler beside the reload key's): the game's "Throw"
  key (`actionKeys "Throw"` and `"ThrowGrenade"`, plain) is swallowed with a line when only closed ones are left; if some may be
  thrown and the selected one may not, the selection is moved on (`fnc_throwSelect`, in the order of `throwables`) and the key is the
  game's. ACE's advanced throwing has no key to swallow - its "Prepare grenade" (`ace_advanced_throwing_prepare` in "ACE3 Weapons",
  Shift+G by default) is a CBA keybind that runs in CBA's own handler. So `fnc_throwTick` (`THROW_TICK`) sets ACE's `blockThrow`
  status effect (`ace_common_fnc_statusEffect_set`, reason `einv_storage`) on the unit while nothing may be thrown: ACE's
  `canPrepare` asks it. It also puts a throwable in the hands away for the weapon then, and moves a closed selection to an open one.
  `fnc_throwGuard` says why when ACE's key is pressed (looked up with `CBA_fnc_getKeybind`) but cannot hold it back itself.
- **What cannot be blocked, and why.** The throwable the game takes when the selected class also lies in an open container (it may
  take the closed copy) and what ACE's advanced throwing picks when it cycles (`ace_weaponselect_fnc_selectNextGrenade` reads
  `throwables`; the selection is corrected a quarter of a second later). ACE's own medical, rations and repack and every other mod
  that reads the unit's items: they use the engine's commands on the unit, their code is compiled final and cannot be filtered - and
  they see a backpack's bandages as real items. A vehicle's guns. Scripts and other mods that use `addItem`/`removeItem`. The
  setting texts and the README say so.

### Strict mode (`fnc_opStrict`, the hidden holder)

The fourth answer of each "Use items from ..." setting, **Strict (hidden)** (`USE_STRICT`): everything Only whitelisted does, and
what it blocks - items of the limited kinds (`USE_ITEM_KINDS`) that are not whitelisted for that container - does not lie in the
container's cargo at all. Then nothing outside this mod can reach it: not ACE medical, rations, repack or any mod that reads the
unit's items (their code is compiled final and cannot be filtered), not the engine's reload or throw, not ACE's advanced throwing,
not a script's `items` or `magazines`. Everything else stays as it was: the window shows the items as the container's contents, they
move, drop, weigh and keep their places; whitelisted items stay physically in the container and work. Mia's word for the setting's
text: it can break things, say so - the setting's description does.

**The holder is no object.** It is the public variable **`einv_storage_hidden`** on the unit: `[[uniform list, vest list, backpack
list], [uniform container, vest container, backpack container]]`, each list `[[class, count, rounds], ...]` with -1 rounds for an
item that is no magazine (`fnc_hiddenAmmo`; a magazine or grenade keeps one entry per rounds), and per list the container object
its things were taken out of (`fnc_hiddenLists` reads it well-formed, `fnc_hiddenWrite` writes it public, empty it goes away).
Weighed against the alternatives: a `GroundWeaponHolder_Scripted` or `WeaponHolderSimulated` attached to the unit and hidden would be
an object in the world - found by `nearestObjects`, by every loot and cleanup script that walks weapon holders, by Zeus's "add all
objects", kept by the engine in a plain holder of its own for the frame a backpack comes off, needing `hideObjectGlobal` on the
server, an attach that vehicles and ragdolls can break, a deletion of its own on death, respawn and disconnect, and it would still
exist when its unit is gone. A backpack-like container object has a load limit and all of that. A variable has none of it: it goes
where the unit goes (locality, Zeus remote control, a player who left and whose unit stays), reaches every machine and every player
who joins later (public object variables are synchronised to JIP), cannot be found by `fnc_getNearby`, `fnc_getGroundHolder`, ACE
cargo, body search, drag and carry or the engine's garbage collector, and is deleted with the unit. Its things exist as data only -
which is exactly what Strict asks for - and the kinds that are ever limited are all data: a class, a count, rounds. Weapons, clothing
and nested containers are never limited and never in it.

**Merged view.** `fnc_getContents` of a unit's uniform, vest or backpack (`fnc_getOwner` tells the unit and the kind) appends the
holder's list of that kind after the cargo's entries, stacked like cargo (`_fnc_addStacked`), each entry marked `strict`. The keys
are the keys their cargo twins would have, so the places need no change when a tile goes into or comes out of the holder, the layout
(`fnc_getLayout`), the room checks (`fnc_hasSpace`, `fnc_plan`), the mass of a section (`fnc_getMass`), `fnc_findEntry`, the Arsenal
panel (through `fnc_getContents` and `fnc_countAll` + `fnc_hiddenCounts`), `fnc_countClass` and `fnc_addNew`, the EFAK kit finder
(`einv_compat_efak_fnc_locate`, `fnc_getSections` + `fnc_hiddenClasses`) all see one container, and every machine the same one.
The window draws a `strict` tile with a crossed eye (`icon_eye_off_ca`) after the padlock (`fnc_createTile`; it was keyed `hidden` until 0.5.0, the window's "not searched yet", so the eye was never reached and a Strict tile showed as "?") and the footer says
"Hidden: kept out of the backpack, so nothing else can use it" (`fnc_updateHover`); `fnc_getSignature` watches the holders of the
people shown, so a move into or out of one redraws.

**Moves.** Two primitives route the physical item. `fnc_removeEntry` of an entry marked `strict` takes it out of the holder
(`fnc_hiddenTake`: the owner's list of that kind, the entry of that class and rounds, at most as many as are there; written public
at once; noted "out" in the journal like any take). `fnc_addPayload [container, payload, raw]` asks `fnc_hiddenRoute [container,
class]` first - a unit's container, its setting Strict, the holder in force for the unit (`fnc_hiddenActive`: alive, `isPlayer`, not
in Eden, no arsenal open on this machine), the class `"blocked"` by `fnc_useState`, and the holder's list of that kind empty or
taken out of this very container - and puts a `magazine` or `item` payload into the holder instead (`fnc_hiddenPut`: adds to the
list, records the container, writes public; always arrives whole). `raw` skips the route: for giving the holder back. `fnc_opPut`
marks the tile it adds to its view the same way. So every path that already existed works unchanged: a drag into a Strict backpack
from a crate goes physically out of the crate and into the holder; a drag out of the backpack goes out of the holder and physically
onto the ground, into a crate, into a slot; a quick move between the unit's own containers goes list to cargo or cargo to list by the
target's whitelist; the Arsenal's adds, settlement's "back where it came from" and `fnc_moveEntry` all go through the same two
functions. Counts are verified where the engine is involved (before and after, as always) and inherent where the list is.

**Reconcile - op `strict [unit]`** (`fnc_opStrict`, root the unit, holders its three containers, in `einv_storage_ops`; the person
guard lets it through like `migrate`, `fnc_execute` walks the containers and drops their views). Asked for by the same look as the
surplus: `fnc_requestMigrate` puts `["strict", [unit]]` in front of `["migrate", [unit]]` when `fnc_hiddenDue` says the holder and
the cargo disagree with the settings - the holder keeps things of a kind that is not Strict any more or while the holder is not in
force; a list taken out of a container that is not the one worn now; a hidden entry whitelisted meanwhile; a blocked item lying in
a Strict container's cargo (a script's `addItem`, a loadout, ACE, the engine). The triggers are the surplus's (`fnc_queueMigrate`:
the player's loadout and unit events, `Take`/`Put`/`InventoryClosed`, loadouts, changed rules, the window's drift look, both
arsenals closing) plus a sweep every `STRICT_SWEEP` 3 s over every unit and body local here that carries a holder
(`fnc_hiddenSweep`; also run when a setting changes, `fnc_useRefresh`). Per container, in order: (1) *out of the holder* - what
no longer belongs there goes back into the container raw and verified; a list whose recorded container is not the one worn now
follows that container when it is still an object anywhere (the dropped backpack gets its things, as it got its cargo) and is gone
with it when it was deleted (an RPT line; the cargo was gone with it as well - a `setUnitLoadout` replaced it); with no container of
the kind another of the unit's takes it, else a pile at its feet; (2) *into the holder* - every blocked tile in a Strict container's
cargo is taken out (`fnc_removeEntry`) and put in again (`fnc_addPayload`, which routes). The holder is written on the unit after
every step and public once at the end, so a script error cannot give anything back twice or hide it twice; the phase is journaled
like any other, so the hub never runs it twice. Nothing in Eden.

**Moments the op cannot wait for** - `fnc_hiddenReturn [unit, kinds]`, a synchronous raw return where the unit is local, written
after each kind: **death** (`Killed` on `CAManBase`, every machine, where the body is local: the body's containers hold everything,
so looters find it; the body may change hands any moment, so no transaction), **a uniform, vest or backpack coming off**
(`fnc_takeOff` returns that kind before its snapshot, so the dropped backpack carries its hidden things), **ACE Arsenal opening**
(`ace_arsenal_displayOpened` on the own unit: the arsenal, its panel and the loadouts saved there see the real gear; `fnc_hiddenActive`
keeps the holder out of force while any arsenal display is open, the vanilla one is caught by the sweep, and `fnc_onClosed` /
`fnc_biLeaveAlone` ask `fnc_requestMigrate` after the close, which hides again).

**Edge cases, decided.**

- *Respawn:* the body got everything back at death; the new unit starts without a holder and hides what its loadout brought a moment
  later (the unit event queues it). A loadout saved with `getUnitLoadout` or `CBA_fnc_getLoadout` **outside an arsenal** does not
  contain hidden items - they are in no cargo -, so a mission that saves loadouts on its own and gives them back at respawn loses
  them; one saved in an arsenal has them. Not injected into `CBA_loadoutGet` on purpose: a loadout that carried them and was set
  with `setUnitLoadout` while the holder still kept them would double them.
- *A loadout set by CBA (`CBA_loadoutSet`, local unit):* the holder is discarded (`fnc_onLoadoutSet`) - a loadout is the unit's whole
  gear, the old containers' contents are gone with them, and the new one's blocked items are hidden a moment later. Set by plain
  `setUnitLoadout` (a script, Zeus's vanilla arsenal): no event; the op finds the recorded containers deleted and discards the lists
  (case 1 above) - the same outcome, a tick later. Should the engine ever keep a container object across a loadout set, the old
  hidden things stay with it: the player has more than the loadout says, never less.
- *Disconnect:* a unit deleted at disconnect takes its variable with it, as it takes its cargo. A unit kept as an AI is server-local
  and `isPlayer` false: the server's sweep returns everything into its containers within `STRICT_SWEEP`. Nothing to do on the
  leaving client, which gets no reliable moment.
- *Zeus remote control:* the unit's owner changes; the variable is already everywhere; `isPlayer` stays true; the Zeus's machine runs
  the op through the hub as for any unit that is not `player`. When the Zeus lets go the unit is an AI again and the owner's sweep
  returns the holder. A Zeus editing a remote player's loadout through an arsenal on the Zeus's machine sees that player's cargo
  without the hidden items (the arsenal is not open on the owner's machine).
- *Locality change mid-transaction, JIP, the hub:* the holder is written only by the owner inside its ops; a phase answered by the
  journal is never run twice; a public object variable reaches a new owner before any phase for it (the hub waits `LOCALITY_SETTLE`)
  and a JIP player with the object.
- *Weight:* `einv_weight_fnc_getExtraLoad` adds the whole rules mass of every hidden entry (not only the override's difference, since
  no cargo weighs it) to the virtual load ACE carries, and the tier look (`TIER_CHECK_INTERVAL`) queues an update when the holder
  changed, since a move from a crate into the holder raises no loadout event. The section header's weight counts the merged entries.
- *Kits and radios:* a hidden EFAK kit still opens from the window (the kit finder sees the holder) and its contents live with EFAK
  by the kit's class; EFAK's own interactions do not see it, which is the point. A hidden TFAR or ACRE radio is unknown to its mod
  while hidden (settings are kept by class by those mods; untested whether either reclaims a radio nobody carries).
- *A `migrate` and a `strict` op in one phase:* strict first; hidden tiles occupy cells in the merged view, so the surplus is
  computed on the same picture every machine draws.

**What Strict still cannot cover.** Loadouts read outside an arsenal (above). A mod that writes into the container with the engine's
commands sees its item for up to `MIGRATE_DELAY` + a tick before the op hides it (ACE could use a bandage in that window). A phase
that hits a script error between `fnc_hiddenPut`'s write and the journal's "in" note doubles that one item (same frame; the
settlement puts the payload down as well). Whitelisted items are physical and as reachable as ever. A vehicle's guns. Untested in
the game, like the rest of Use from containers.

### Public functions and tables

Public: `einv_storage_fnc_useState`, `fnc_useKind`, `fnc_useMode`, `fnc_useCarried`, `fnc_useBlockedIn`, `fnc_useKindName`, `fnc_loadMagazine`, `fnc_reloadBusy`,
`fnc_hiddenCounts`, `fnc_hiddenClasses`,
`einv_storage_fnc_request`, `fnc_moveEntry`, `fnc_equip`, `fnc_unequip`, `fnc_getEquipment`, `fnc_getNearby`,
`fnc_readPlaces`, `fnc_rootOf`, `fnc_dumpPlaces`, `fnc_addNew`. Other addons extend the storage only through tables they fill in
preInit: `einv_storage_ops` (op name -> function name), `einv_storage_guards`, `einv_storage_carryVariables` and
`einv_storage_holderTypes` (a holder that is no object, by the part of its key before `:`; `kit` from compat_efak: `entries`,
`blocks` (its compartments, `[]` for an open grid; left out, open), `root`, `verify`, and the names of its ops for `take`, `put`,
`place`, `move`; it names no `split`, which tells the window that a kit's stacks are not kept apart). The mission variable
`einv_storage_stackSplits` (true on every machine once the storage is loaded) is what the window reads before it asks for stacks
apart, split or merge; setting it false switches that behaviour off.

## 4. GUI window engine (gui)

Everything on the window except the dim layer is created at run time; a build deletes what the last one made and makes it again.
Functions are `Public: No` unless noted (`fnc_open`, `fnc_openPerson`, `fnc_playSound`, `fnc_requestRebuild` are public).

### Opening, attaching, building

- **Opening.** The unit's `InventoryOpened` handler (`fnc_onInventoryOpened`, put on whichever unit the player is by
  `fnc_initUnit` from the CBA `unit` event: the first body, a respawn, a team switch, the soldier a Zeus remote controls) answers
  the engine with **true, always**, which keeps the vanilla display away, and the window opens a frame later (`fnc_open`).
  Every way into the engine's inventory ends in that handler: the Gear key, `action ["Gear" | "OpenBag", container]` from a
  script, ACE's "Inventory" on the unconscious, ACE's backpack interaction and "Open <backpack>" on bodies, the vehicle and crate
  actions, the setup wizard handing the inventory back. For a unit that is not `ACE_player` nothing opens (the answer is still
  true); a person who may not be opened (`einv_noAccess`, an ACE dragging clone, out of reach) gets a hint instead of a window.
- **No vanilla inventory.** There is no setting that brings it back, no bypass and no fallback: a window that cannot open
  (`fnc_open` returns false, the RPT says why) opens nothing. A vanilla display that comes up anyway - Better Inventory patches
  `RscDisplayInventory` and runs its own XEH `InventoryOpened` handler, another mod's handler may answer the engine after ours,
  any mod or script may `createDialog` it or run `action ["Gear"]` - is closed at once by `fnc_guardVanilla` (controls hidden,
  `closeDisplay 2`, and again a frame later), whether the window is open or not. It closes only IDD 602 (`findDisplay 602`; a
  display handed in that is not 602 is ignored), never the window or anything over it (a cutRsc, another mod's dialog), and
  writes one INFO line per display saying where it stood: no window open, over the window, beside it, or **under** it - the
  window was made as its child dialog and closes with it, so it is opened again a frame later on the same unit and containers
  (at most once every `REOPEN_PAUSE` 2 s). `fnc_open` never makes the window over a vanilla inventory: while `findDisplay 602`
  is open, or a display the guard closed is still held (uiNamespace `einv_gui_closing` - the engine may stop listing a closing
  display and still hold it, and a dialog made then hangs under it all the same), it closes it and tries again next frame (at
  most `OPEN_TRIES` 10; held but no longer listed after that, the window opens anyway). The guard's second close, a frame after
  the first (a display closed inside its own load event is not always gone), is the guard called again with the display
  (`[display, true]`), never a bare `closeDisplay`: it looks where the window stands, and a close of a display the window hangs
  under is told and followed by the reopen. It closes the display object itself, never `closeDialog` (topmost dialog, maybe the
  window); the window has no `InventoryClosed` handler, so the engine raising that event for the closed display touches nothing
  of it (`einv_storage` only notes the unit for its surplus check).
  Three places call the guard: an `Extended_DisplayLoad_EventHandlers` entry on
  `RscDisplayInventory` (`gui/CfgEventHandlers.hpp`; CBA raises that event from `BIS_fnc_initDisplay`), a per-frame handler
  every `GUARD_INTERVAL` 0.25 s from `XEH_postInit` for a display that loaded without raising it, and the check each
  `CHECK_INTERVAL` in `fnc_onFrame` while the window is open. The display's `onLoad` is deliberately not patched in config: it
  would replace the `BIS_fnc_initDisplay` call that raises CBA's load event for every other mod's handler, close at the very
  moment the handler does, and fight Better Inventory's patch of the same attribute over load order. Better Inventory's put/take
  stack move is held off with its `bettInv_stackMove` flag while the window is open.
- **Other mods' `InventoryOpened` handlers.** A unit has any number of them, and which answer the engine goes by is the engine's
  (Better Inventory's runs from CBA's, SFX Project: Remastered adds a plain one that only plays sounds and answers nothing, once
  `findDisplay 46` exists - after this mod's postInit). The window does not depend on it: the display that opens anyway is closed
  by the guard and the window opens a frame later. But the handler (`fnc_initUnit [unit, again]`) is kept behind the others: put
  on at the CBA `unit` event with `again`, once more `HANDLER_RECHECK` 3 s after `findDisplay 46` exists (`XEH_postInit`), and
  whenever a vanilla inventory came up although the handler had answered within `ASK_FRAMES` frames (`einv_gui_askedFrame`, set
  first thing in `fnc_onInventoryOpened`) - the RPT says "The unit's handler had answered true for it - another handler's answer
  let it open" and "The unit handler goes behind the other handlers of the event again" (at most every `HANDLER_PAUSE` 5 s, so two
  mods that both want the last place cannot loop). Only this mod's handler, by its id, is removed and added again - never
  `removeAllEventHandlers`, so the other mods' sounds and work go on. A vanilla inventory the handler was **not** asked for (a
  script's `createDialog`, the handler taken off) with no window open opens the window in its place on the player's own gear
  ("Nothing asked for the window"). That is a guess, and what the engine names always wins over it (in 0.4.9, a display whose
  load came before the handler's event queued the guess first, and a vehicle opened showed only the soldier's own gear): it is made a
  frame later and only when the handler was not asked in the frame the display came up or since and no asked opening waits for
  the display (`einv_gui_askedFrame`, `einv_gui_openWaiting`); it gives way while it waits in `fnc_open` (argument 4, the frame
  the display came up in); and a window made on it (`einv_gui_openGuess`) closes when the handler is then asked with something
  to loot, which opens a frame later (RPT `replaced: ...`). Where the engine really takes the last handler's answer, being last keeps the display from
  opening at all; where it does not, the guard path is all that runs.
- **Closing.** Every way the window closes itself goes through `fnc_closeDisplay [reason]` (sets `einv_gui_closeReason`, then
  `closeDisplay 2`), and `fnc_onUnload` writes one INFO line `window closed: <reason>`: `a movement key` (`"move"`), `Escape`
  (set by `fnc_onKeyDown` where it leaves Escape to the engine, inventory only), `the Gear key`, `the close button`,
  `the soldier was taken away from what he looted` (`"taken"`, `fnc_checkTaken`), each rule of `fnc_onFrame`'s must-close
  check by name (the unit died, is unconscious, is no longer `ACE_player`, the person out of reach, their backpack gone, may no
  longer be opened, the `keepOpen` hook), `stepped aside for another mod's dialog`, `the vanilla inventory under it was closed`,
  `the window could not attach`, and `display lost` (the frame found the display gone without its unload event and ends the
  window as any close). No reason given means another mod or a script closed it (`closeDialog` / `closeDisplay`, the exit code
  is logged); on a display the window is a guest on, that display closed. `"move"` and `"taken"` are the two reasons that come as a key (no closing sound for `"taken"`).
- **Attaching.** `fnc_attach [display, unit, container, secondary, hooks = createHashMap, driver = "pfh"]` -> BOOL makes any
  display that carries the dim layer (`IDC_DIM` 9601) and the first control (`IDC_FIRST` 9602) **the window**: it sets the unit
  and containers, starts all window state afresh, adds the mouse handlers, builds once and starts the frame. It refuses when
  another display is the window (one session at a time; uiNamespace `einv_gui_display`). The inventory attaches with no hooks, ACE
  Arsenal's panel with a table of them. `fnc_onUnload` stops the frame and empties hooks and zones. A top-level control with
  `IDC_KEEP` 9603 survives the build's sweep.
- **State** (documented variable by variable in `gui/XEH_preInit.sqf`): who and what - `einv_gui_unit`, `container`, `secondary`,
  `person`, `personMode`; the frame - `frameDriver`, `nextCheck`, `nextSignature`, `hooks`; what the build made (controls, so in
  uiNamespace) - `created`, `grids`, `slots`, `hint`, `windows`, `scrollRestore`; the mouse - `hover`, `press`, `dragging`,
  `dragTarget`, `dragSize`, `dragRot`, `dragCount`, `dragGroup`, `selection`, `emptyPress`; the moves - `inFlight`, `answers`,
  `drift`; view state kept for the mission - `collapsed`, `expanded`, `opened` (nested containers opened in the loot column,
  `[class, object, parent]`), `filter`; and `nearby`, `searchQueue`, `panels`, `equipmentRect`.
- **Frame drivers.** `fnc_startFrame [driver]` / `fnc_stopFrame`, kept as `einv_gui_frameDriver = [driver, id]`: `"pfh"` is a CBA
  per-frame handler, `"draw3d"` a Draw3D mission event handler (the only one that runs in Eden). Either calls `fnc_onFrame`.
  `fnc_later [code, args]` runs code a frame later: controls must not be deleted inside their own event.
- **`fnc_build [display]`** takes the kit windows away, reads each column's scroll by its id, deletes the registered controls (on
  another mod's display - the `guest` flag - only those), reads the theme, draws header, layout and footer, starts or stops the
  camera (on when `cameraOn`, the layout returned a rectangle and the unit is on foot), and ends with what floats: kit windows
  (`fnc_drawWindows`), the name at the mouse and the inspect card (`fnc_drawTopLayer`), moves under way (`fnc_drawPending`), the
  selection, a repack in progress, the hook `afterBuild`. Controls made later draw over earlier ones - the only z-order the engine
  has.
- **Clicks that are heavy run through one gate** (`fnc_coalesce [key, code, args, gap, debounce]`, `fnc_coalesceRun`, `fnc_coalesceTick`, `fnc_coalesceDrop`; state
  `GVAR(coalesced)`, key -> `[code, args, due or -1, rests until, gap]`, emptied by `fnc_attach` and `fnc_onUnload`; Mia, 0.5.7: spamming a section's fold button took the
  game to 15 fps because every click ran `fnc_build`). A click changes its **state at once** (cheap: `GVAR(collapsed)`, `expanded`, `opened`, `cameraOn`, `sortMode`, `groupFilters`,
  `windowOrder`, `GVAR(filter)`, `GVAR(pageWanted)`) and asks the gate for the **work**. Throttle, the default: the first request of a quiet moment runs at once (so a single click is
  as fast as before and runs where it did - the callers that rebuild still come through `fnc_later`); a request while the key rests only marks it due, **with the latest code and
  arguments** (latest wins), and `fnc_onFrame` runs it through `fnc_coalesceTick` when the rest is over - one run per key however many clicks came, nothing queued per click.
  After a run the key rests for `gap` (`COALESCE_GAP` 0.1 s; `COALESCE_REQUEST` 0.3 s for Sort, Take all / Put all in and the kit's unpack, which plan a container or reach the authority) or
  `COALESCE_REST` 1.5 times the time the run took, whichever is longer, so a slow build is left alone longer (about two thirds of the time stays for the frames). Debounce: nothing runs until
  `gap` after the last request (`COALESCE_TYPING` 0.15 s, the search field). Idle keys are forgotten by the tick. A window covered by another one runs nothing (the tick comes after the
  covered exit of `fnc_onFrame`). Keys in use: `"build"` (`fnc_buildSoon`: `fnc_toggleSection`, `fnc_toggleRows`, `fnc_toggleCamera`, `fnc_openNested`, `fnc_closeNested`, ACE cargo's
  `toggleOpen`; a direct `fnc_build` drops the waiting one with `fnc_coalesceDrop`, it draws the same state), `"windows"` (`fnc_windowsSoon`: `fnc_openWindow`, `fnc_closeWindow`; `fnc_drawWindows` drops it),
  `"filter"` (`fnc_filterSoon`: the search field's `EditChanged` as a debounce, the category strip's `fnc_setGroup` as a throttle; Escape in the field applies at once and drops it),
  `"page|<holder>|<compartment>"` (`fnc_pageSoon`: the page arrows and the words; `GVAR(pageWanted)` moves from where the last click left it, the run shows that page on the grid
  looked up again then - a drag turns the page with `fnc_turnPage` directly), `"sort|<holder>"` (`fnc_sortHolder`: each click steps the order and relabels every Sort button at once,
  one sort goes out with the latest order and the profile is saved then, not per click), `"take|<holder>"`, `"put|<holder>"`, `"unpack|<key>"`, `"soundmenu"`. Why not fold only the
  section in place: a section's controls lie in the column's one scroll group and are positioned from a layout that also feeds the grids, panels, hover geometry, `foldAreas`, `sectionInfo`
  and the drag's cells of everything below it; moving them would repeat all of that, so the build stays and the column-keep path (below, "Columns") keeps the scroll. Not gated: moves and
  answers (they come from the server's pace), the quick-move key (see below) and the drag.
- **Drawing only what changed** (`fnc_refresh [display]` -> `""` / `"redraw"` / `"build"`): the signature is
  `fnc_getSignature` -> `[own, list, loot, storage, card]` - `own` the unit's loadout less what its uniform, vest and backpack
  carry; `list` sections shown (also the worn containers as objects, and whether each opened container still lies where it was
  opened); `loot` / `storage` per section of the loot / own storage column `[number, [cargo all the way down, places
  revision]]` (the engine's lists themselves, compared as arrays - no `str` of a full crate every second); `card` ACE's `vLoad` on the unit and its three containers and the weight limits' key. `own` or `list` changed, or a
  section came or went: `fnc_build`. Else `fnc_redrawTiles [lootNumbers, ownNumbers]` draws the changed sections' tiles (own
  sections only in the inventory; false before touching anything when compartments, overflow, the button, the folded-rows line or
  the caption's weight label no longer fit) and, when `storage` or `card` changed, the **parts** are drawn again
  (`fnc_redrawPart`). Called once a second by `fnc_onFrame` (`SIGNATURE_INTERVAL`) and by `fnc_afterAction` after every answer -
  a move no longer builds the window. Tiles still flagged `pending` whose request was answered fade back in (`fnc_drawPending`).
  **A redraw keeps what did not change** (`fnc_drawTiles [display, grid, layout, theme, before]` -> the old tiles not kept): an
  old tile that looks exactly as a new entry would (class, `hidden`, `strict`, compartment, cell, `w`, `h`, `rotated`, `holes`, count, rounds,
  capacity, attachments, `picture`, `icon`, overflow) is that tile again - the same HashMap (the hands' queue holds it), its
  controls untouched, the new entry's keys merged in and the ones it lost dropped, its light reset (only a tile the hover lit - the tile's `lit` - is
  touched; no control of another kept tile gets a command) and, when it was `pending` and
  is not `queued`, faded in; everything else is made by `fnc_createTile` and the old controls left over are deleted. Tiles go on
  the grid in the layout's order either way. One item taken from a pile of ninety makes one tile less instead of ninety again, and
  the queue's marks on the tiles that stayed stay (`fnc_drawQueue` finds their surfaces unchanged).
- **Parts** (`fnc_drawPart [display, key, parent, rect, code, args]`, uiNamespace `einv_gui_parts`, emptied by each build): an
  outer `EINV_Group` made by the build where the piece belongs (so it keeps its z-order) holding an inner group the piece is drawn
  in; a redraw deletes the inner group, leaves its `slots` / `infoAreas` entries as dead stubs (numbers stay valid), and draws into a
  new one. The weight card (`fnc_drawWeightCard`, split out of `fnc_drawEquipmentCards`) and the hotbar strip are parts.
- **The camera is kept** across builds while `einv_gui_cameraFor` (`[unit, rect]`, set by `fnc_cameraStart`) is unchanged; another rect
  (a pile appearing after a drop opens the loot column and moves the free middle) only moves
  and re-aims the camera that is there (`camSetPos`, `camSetTarget`; the light follows) - ending it ("terminate") leaves the player in first person, which
  made a drop throw him out of third person before 0.5.0 - and only the camera switch, another soldier or a vehicle end it
  (`fnc_cameraStop`). The view the player had when the camera began (`cameraView`, kept with his unit in `einv_gui_cameraView`) is
  switched back to whenever the camera ends: window closed, camera off, a vehicle. `einv_gui_debugTiming` (client,
  default off) writes `timing: build 12.3 ms (N controls on the display, N of them shown: PanelRect N, ...)` (the controls by class,
  the eight most) with `timing: build parts (ms) - sweep 2.1, contents 1.0, columns 30.2, footer and camera 0.8, kit windows and
  top layer 0.3, under way and selection 0.2, signature 0.9`, `timing: redraw 2.1 ms (N loot and N storage sections, N tiles kept,
  N made in N ms, signature N ms)`, `timing: search found an item - N ms (its tile drawn anew in place | the window built anew, ...)`,
  `timing: drag ...` and, every 1500 frames, when a drag starts and when the window closes, `timing: frames idle 0.06 ms avg 0.45
  max (n 800, 1 over 1 ms) / hover held ... / hover same ... / hover new ... / drag ...` followed by `timing: frame parts - whole
  frame 4.02 ms avg 9.80 max (249 fps) / start ... / hover ... / search ... / queue ... / answers ... / check ... / contents ... - N
  controls on the display, N shown; N tiles, N cell squares (N shown)` to the RPT. The frames line is the script's share of a frame
  (`fnc_frame` times `fnc_onFrame`, `fnc_logFrame` keeps the tally; the driver takes it only when the setting was on as the window
  opened): "hover held" is a mouse moving inside the cell it was in, "same" one that found what it had found, "new" one that found
  something else. The parts line splits it: `fnc_onFrame` says where each part begins (`NOTE_PHASE` in `defines.hpp`,
  `fnc_notePhase`; an `isNil` each while the setting is off) - start, queue, lift, drag, hover, search, warm, answers, check,
  contents (the once-a-second signature with its redraws and builds) - each with its average per frame and the most one stretch
  took, and "whole frame" is the engine's last frame (`diag_deltaTime`) each frame, the game's FPS. The rest of a frame is the
  engine drawing the display's controls (and the camera's view): idle script cost against the whole frame says which of the two a
  low FPS is, and the control counts say how much the engine has to draw.
- **`fnc_onFrame`** each frame: hover, the drag, the focus rule, kit windows moving, the search animation; every
  `CHECK_INTERVAL` 0.25 s the "stay open" checks; once a second `fnc_refresh` with the **signature** ("Drawing only what changed"
  above). Nothing is built while a tile or frame is held. A window covered by another display (`fnc_isCovered`) keeps still and
  only checks whether to close.
- **Moves under way.** The window predicts nothing: `fnc_sendMoves` turns each move into phases (at most `BATCH_MAX` moves per
  transaction, the next chunk when the answer came; kinds `move`, `equip`, `unequip`, `swap`, `sort`, `placeMany`, `exchange`; a kit
  through its holder type's ops). Moved tiles stay faded and cannot be lifted, their target cells outlined (`einv_gui_inFlight`,
  `fnc_drawPending`) until the answer and the new places arrived (`einv_gui_answers`, finished by `fnc_afterAction`, at the latest
  `ANSWER_WAIT` 3 s after the answer; given up after `PENDING_TIMEOUT` 15 s); each sounds when finished. The flash on the tile where an item landed
  (`fnc_flashTile`, also the search's reveal) is deleted once it has faded (uiNamespace `einv_gui_flashes`, `[control, when it has faded]`): one made for every finished
  move of a long Take all used to stay on the window, invisible, until the next build. What a finished move touches: its source and target tiles (made or removed), the marks of the entries on them, the chip's count (written in place), the flash, the bars of paged boxes only where what they say changed - no
  other tile gets a command and no box moves unless its rows' shape changed. On
  `einv_items_rulesChanged` an open window is built again once a held tile is let go.
- **The hands' queue** (`fnc_queueMoves`, `fnc_queueTime`, `fnc_queueTiles`, `fnc_queuedSlot`, `fnc_drawQueue`, `fnc_animateQueue`,
  `fnc_runQueue`, `fnc_cancelQueued`, `fnc_boxStep`, `fnc_unmarkQueued`, `fnc_queueColor`; state `GVAR(handQueue)`, `handStarted`, `handLast`, `handId`,
  `handBoxes`, `instantFrame` in `XEH_preInit.sqf`). What takes the hands is not sent at once but waits in the window's own queue, one entry per move,
  its tile tinted and its box's caption line counting it; only the first runs, and when its time is up it is sent through `fnc_sendMoves` as any move (so
  the transaction, the authority, the guards, the answer and the hint are exactly those of a move that was never queued - nothing is reserved, changed or
  checked early; a refusal, Gone or NoRoom shows its hint and the next entry goes on). The funnel is `fnc_sendMoves` itself: unless the option `"now"` is
  set it hands its moves to `fnc_queueMoves` first, which answers `[moves to send now, how many were queued]`; the rest goes on in the same call, and the
  call answers true when it queued something. Every caller gets it without a change: the quick move and double click, the drop key and Drop, Take all /
  Put all in (`fnc_sendPlan`, one entry per move), the menu's Equip, the kits' ops (`einv_compat_efak`).
  **What waits is decided by `fnc_queueTime [move]`** -> `[kind, seconds]` (`""` and 0 for no wait). A **drag never waits**: `fnc_endDrag` sets
  `GVAR(instantFrame)` to `diag_frameNo` before it sends and `fnc_queueTime` answers `""` for the rest of that frame, so `fnc_applyMove`,
  `fnc_dropToGround`, `fnc_doEquip`, `fnc_doUnequip`, `fnc_doSwap`, `fnc_applySwap` and a group's `fnc_sendPlan` go out at once from a drag (a frame number
  instead of a flag: nothing to reset should a script error end `fnc_endDrag` early). Otherwise by the kind of move and four server switches: `drop` (to
  `"ground"`, `"vehicle"` or a pile - `einv_gui_handDrop` seconds, `einv_gui_waitDrop`, on), `move` (to a different holder, and an `exchange` -
  `einv_gui_handMove`, `einv_gui_waitMove`, on: the quick move, Take all, Put all in and the menu's moves), `equip` (`equip`, `unequip`, `swap` -
  `einv_gui_handEquip`; by the slot: `uniform`, `vest`, `backpack` and `headgear` follow `einv_gui_waitWorn`, off, every other slot `einv_gui_waitEquip`, off);
  `""` and no wait for a move within one holder, `placeMany`, `sort`. A kind with 0 seconds or its switch off is never queued. Not queued either: any window
  that is not the inventory (ACE Arsenal's panel does not use `fnc_sendMoves` anyway), a move with nothing of it on the window (no tile found by
  `fnc_queueTiles`, no slot drawn: say a kit unpacked from the menu with its window closed), and one whose tile or worn item already waits (dropped, no
  second entry). An entry is a HashMap: `id`, `move`, `options` (a copy with `now`; `label` only on the last entry of a call), `hand`, `time`, `sources`
  (`[holder, key, block, col, row]` as the moves in flight name them), `slot` (`[unit, slot]` of a worn item a take off or swap lifts), `hint`, `box` and
  what `fnc_drawQueue` keeps (`fx`, `tiles`, `marks`, `marked`, `slotAt`). `fnc_queueTiles [entry]` takes the entry's `hint` first (the tile HashMaps the
  caller queued it for, which are the window's own while their controls are there - no grid is looked at), else finds the tiles by those sources as
  `fnc_drawPending` finds a move in flight's, through an index of each grid's tiles by cell that the caller can share between the entries of a pass (`cache`
  argument; nothing scans every tile per entry).
  **The box and its count.** `fnc_queueMoves` names for each entry the box whose caption line says it - the container it takes from, else the one it goes to,
  else the first of the player's own, each only if its section drew room for a chip (`statusParent` in its `sectionInfo`) - and what the box is doing, `verb`:
  `grab` (out of the loot column), `put` (from an own container into a loot box), `drop`, `gear` (equip kinds), else `move`. `GVAR(handBoxes)` holds one HashMap
  per box with something waiting: `holder`, `verb`, `total` and `done` of this run. `fnc_queueMoves` adds one to `total`, `fnc_runQueue` and
  `fnc_cancelQueued` call `fnc_boxStep [entry, sent]` (done + 1, or total - 1), and the record goes when `done >= total`. The chip says "Grabbing items"
  + `done + 1` / `total` (`fnc_updateStatus`, `fnc_animateStatus`; "Section bars: the activity chip and the strip of categories" in "Layout").
  **How a waiting tile looks.** `fnc_drawQueue` is called at the end of `fnc_drawPending` (every build, every redraw of tiles, every settle), after a kit
  window is drawn and, once a frame at most, by `fnc_animateQueue` when `GVAR(queueDirty)` says entries were queued or cancelled - from `GVAR(queueFrom)`,
  the first place that needs a pass: entries added at the end leave those in front alone, so a held quick move key costs a pass over what it added, not over
  the queue (a cancel or a finished entry asks for all). It **marks, and makes no control for a tile**: the tile is flagged `pending` (so nothing can lift or act
  on it; `fnc_startDrag` also looks in the queue) and `queued` with the entry's id, its controls fade as a move in flight's do (`DRAG_SOURCE_FADE`) and its
  surface is painted a tint of the accent colour (`fnc_queueColor`, `fnc_paintSurface`; the mouse's light and a redraw that puts the colour back
  (`fnc_updateHover`, `fnc_drawTiles`) ask `fnc_queueColor` too, so the tint is not lost). That is all - no ring, no number, no disc. A worn item to be taken
  off has no surface to paint: one panel in the soft accent colour lies over its slot (the entry's `fx`, in the slot's group where it has one). A mark is kept
  as long as the tile still has the surface it was made over (`marks`; a redraw of a section makes new controls, so those entries are marked again; a slot entry
  compares the slot's record, `slotAt`). An entry whose tile lies on a page of a paged box that is not shown is flagged on that tile (`queued`) and has no tint:
  the box's bar counts it (`fnc_updatePageBars`, called at the end of `fnc_drawQueue`, which also asks `fnc_updateStatus` for the chips). `fnc_refresh`'s settle
  leaves tiles that are `queued` alone, so a queue is not faded in and out at each answer. `fnc_unmarkQueued [tile, keepFade]` takes a mark off (colour back,
  flag gone; unfaded and no longer `pending` unless the move is on its way: `keepFade`) - for a cancelled or refused entry and, with `keepFade`, for one that
  was just sent.
  **Running it.** `fnc_onFrame` calls `fnc_animateQueue` each frame while the queue holds something and the window is not covered (the time it stood still does
  not count, as for the search): it calls `fnc_runQueue` when the head's time is up and nothing else - no control is made or touched per frame, and the work of a
  frame does not grow with the length of the queue. What waits is also kept in an index by cell, `GVAR(handWaiting)` (`fnc_queueIndex` adds and takes out,
  `fnc_queueWaits [source]` asks): `fnc_queueMoves`, Take all and Put all in ask it instead of passing the queue. **Cancelling:** a left press on a queued tile or
  slot (`fnc_onMouseButton`) or "Cancel" in its menu (`fnc_contextMenu`) calls `fnc_cancelQueued [id]`; the cross in the box's chip calls
  `fnc_cancelQueued [0, box]` (every entry of that box; `[0]` is all): the entries leave, their tiles are free and their own colour is back, the others are marked
  again in the next frame, once (`queueDirty`). `fnc_queueMoves` adds the entries of a call without drawing (the marks of a Take all of N come once, in the next
  frame, or with the next `fnc_drawPending`) and the tiles are found through one shared index, so a call is N lookups. What a finished entry costs: `fnc_runQueue`
  -> `fnc_sendMoves` -> answer -> `fnc_refresh` redraws only the touched sections (`fnc_redrawTiles`; a build only when sections came or went or the unit's gear
  changed, as for any move), and `fnc_drawQueue` marks only the entries on those redrawn tiles. The queue is dropped by `fnc_attach` and `fnc_onUnload`: closing
  the window (Escape, the Gear key, a movement key, ...) cancels everything that still waits, which only waited - a move already sent finishes on its own. Take
  all / Put all in skip tiles that wait (`handQueue` sources next to `inFlight`'s). Walking does not cancel (only `einv_gui_moveToStop` closes the window while
  looting, as ever). The target cells of a queued move are not reserved or outlined: something else put there meanwhile makes it land elsewhere ("Put elsewhere")
  or bounce, as for any move whose cell was taken. Times do not depend on weight.
- **The quick move key held down** (`fnc_onKeyDown`, `fnc_quickAction` argument 3, `fnc_quickMove`, `fnc_roomFor`). What a repeat costs, and what it does not: it never reaches
  the network - a queued move is only added to `GVAR(handQueue)`; the server hears of it when its wait is over (`fnc_runQueue` -> `fnc_sendMoves`, one transaction per
  entry, as for a move never queued). With the hands' time at 0, or its switch off, a move goes out at once; `fnc_sendMoves` now flags and fades the tiles it takes from the moment it
  records the transaction in flight (before, `fnc_drawPending` did at the next build, so a repeat before the answer sent the same tile again). Per repeat the work is
  bounded and does not grow with the queue: a tile that is `pending` is skipped before anything is asked; a container or kit tile is left to the first press;
  `fnc_roomFor [container, tile, reserve]` replaces `einv_storage_fnc_hasSpace` (a whole layout for each of up to three containers, and `fnc_applyMove` once more - now told
  `roomChecked`): per container it keeps, for the container's signature (places revision and the counts of items, magazines, weapons and backpacks), the taken cells
  (`einv_storage_fnc_seedTaken`, `takeCells`), the free cell count, the cells the waiting moves to that container take (read from the queue when the picture is made) and the exact
  answers asked so far; a plain rectangular tile needs one look for a free spot (`cellsFree`, upright then turned) and `free - waiting` to cover it, and with `reserve` the cells it
  takes count as waiting at once. A stackable or shaped tile, and any tile for which no spot is found, gets `hasSpace`'s exact answer, once per signature and kind of tile; room is
  refused on the cells' word only when the waiting moves have filled it. `fnc_cancelQueued` empties the cache. The queue itself: `fnc_queueMoves` finds a tile by its `hint`
  (no grid scan), checks `fnc_queueWaits` (index by cell) and adds to the index; `fnc_drawQueue` starts at `GVAR(queueFrom)`. Not per repeat: any build, any redraw of
  tiles beyond the once-a-second signature, any sound.

### Geometry and the cell

`UNIT = safezoneH / 40` (a row, about 27 px at 1080p). Everything see-through meets on whole pixels (`SQUARE`, `UNSQUARE`,
`SNAP_*`). Header `HEAD_Y = safezoneY + UNIT * 0.6`, `HEAD_H = UNIT * 1.6`; content from `CONTENT_Y = safezoneY + UNIT * 3` to
`CONTENT_B = safezoneY + safezoneH - UNIT * 2.6`; footer `FOOT_Y`, `FOOT_H = UNIT * 1.4`; `MARGIN_X = SQUARE(UNIT * 1.2)`.

**The header's buttons** (`fnc_drawHeader`, right to left: Close, camera, speaker, the search field, the cog) are 1.6 UNIT squares with a 0.3 UNIT gap, each on a piece of the
window's glass (the `panel` colour) with the theme's `button` film over it from `fnc_headerStyle [theme, on]` -> `[surface, surface under the mouse, ink]`: the
panel colour one step lighter, as the buttons in the columns, and one step lighter again under the mouse (`buttonHover` at 0.75 of its alpha, at least 0.04 over the
surface) - dark like the inventory, no bright grey. A button that is on (Mia, 0.5.5) has the same surface and shows it by the `accent` ink on its icon and a thin
accent line (2 pixels) inside its bottom edge, made before the button so its hit area lies over it; the camera draws the line only while it is on (the toggle
rebuilds), the speaker's is kept in uiNamespace `einv_gui_soundLine` and shown by `fnc_updateSoundButton`. The search field is on the same
footing (Mia, 0.5.7: it was lighter): the glass `_fnc_place` lays down and ONE film, `headerStyle`'s surface, which `fnc_drawFilter` takes as its 5th argument -
no frame of its own under the field's. The speaker's controls and its rectangle are kept in uiNamespace `einv_gui_soundButton` and `einv_gui_soundAnchor`
(the dropdown opens under it and right-aligned to the window's right edge, `CONTENT_X + CONTENT_W`); `fnc_updateSoundButton` recolours it in place (accent icon and line while the dropdown is open, muted icon, dimmed, while nothing is audible).

**`fnc_getCell`** -> `[cellW, cellH]`, whole pixels, the same across and down: `round(((UNIT * 1.45) min UNSQUARE(safezoneW / 52))
/ pixelH)`. Every grid uses it. 52 cells across is what two columns of `STORAGE_COLS` 10 cells with their boxes (13 cells each),
the equipment column and the middle take at 16:9 - 37 px at 1920x1080, which leaves the middle 5 UNIT for the soldier while
looting. Times the player's **tile scale** `einv_gui_cellScale` (0.8 to 1.3), capped so both columns (`COLUMN_W(cell)`, the
same macro `fnc_layoutGlass` sizes them with), three `COLUMN_GAP`s and `CELL_FIT_LEFT` 16 UNIT of equipment column still fit
`CONTENT_W` - never below the cell at scale 1; 1.3 just fits at 1920x1080 (48 px), 4:3 caps it at about 30 px. A cap is said
once in the RPT. The cell is worked out at the first ask after `fnc_attach` and kept in uiNamespace `einv_gui_cell` until
`fnc_onUnload`: a changed scale shows at the next opening, and nothing drawn meanwhile differs. A window with less room caps it
for itself with **`fnc_capCell [pixels, where]`**: ACE Arsenal's panel (`einv_arsenal_fnc_panelRect`) so its `STORAGE_COLS`
cells fit within a third of the screen and left of ACE's list; its grids, kit windows and ghosts follow.

**The text scale** (`fnc_textScale`, issue #10): the window's words grow with its tiles. The factor is the cell the window really
has (`fnc_getCell`, after `fnc_capCell` where a window caps it) over the cell at tile scale 1 (`CELL_BASE_PX`, the same base
`fnc_getCell` starts from), at least `TEXT_SCALE_MIN` 1 (a tile scale under 1 leaves the words as they were), at most
`TEXT_SCALE_MAX` (= `CELL_SCALE_MAX` 1.3), and at least what brings a caption's words (`TEXT_REF` 0.42 UNIT) to `TEXT_MIN_PX` 12
pixels - 1080p at tile scale 1 gets 1.06, a lower resolution more (up to the cap). It is kept in uiNamespace `einv_gui_textScale`
with the cell and UNIT it was worked out for, so it changes only when they do. **`TEXT_UNIT`** = `UNIT * TEXT_SCALE` is what the
words and the rows that hold them are measured in: the section's caption line (`CAPTION_LINE` TEXT_UNITs), its tab, buttons
(0.6, labels `TEXT_REF`), weight (0.46), box name and fold line (`fnc_drawSection`, and the weight's measure in `fnc_redrawTiles`),
the activity chip's place and size (handed to `fnc_updateStatus` in `statusRect` / `statusSize`), the column title row (1.1, words
0.66; `fnc_drawColumn`), the empty storage line (`fnc_layoutGlass`), the page bar's words (the bar keeps `PAGE_BAR_H`), a kit
window's title row, its buttons and name (`fnc_drawWindow`), the footer's key caps (0.9, `fnc_uiKeyHint`'s default too), version and
hint box (`fnc_drawFooter`; the hint's words, fixed by `EINV_FooterHint`, take the factor as the structured text's `size`, kept on
the footer's own hint control as `einv_gui_textScale` - another window's hint line carries none and stays as it is) and the window
title (`fnc_drawHeader`; its buttons keep the header's height), ACE cargo's cards (`compat_ace_cargo`'s `fnc_drawSection`, its own
`TEXT_UNIT`; their tab and hairline take the loot colours) and the Arsenal panel's staging subtitle and its prediction of the caption
line (`einv_arsenal_fnc_layout`: `TEXT_UNIT * CAPTION_LINE + UNIT * 0.25`). `fnc_buttonWidth` and `fnc_sortChip` measure with the sizes they are
handed, so the buttons widen with their labels. The equipment column, the menus, the inspect and comparison cards keep their
sizes; what lies on a tile goes by the cell already.

### Themes

`fnc_themeBase` returns a HashMap with every key; a look copies it and overrides. There is one look, **Glass** (`fnc_theme`, id
`"main"`, in the feel of Arma's and ACE's menus and Enhanced First Aid Kits); `einv_gui_styles` holds that one entry, kept as a
list so a look could be added. `fnc_theme` adds `equipmentPanel` (a pane under the equipment cards), `titleIcons` and `onAccent`.
**The camera** on the soldier in the middle (`einv_gui_cameraOn`) starts as `einv_gui_cameraDefault` says at every opening
(`fnc_open`: `"soldier"` the third-person camera, `"off"` none - the world as seen from his eyes, darker dim); the header's
button (`fnc_toggleCamera`; an accent icon and line while the camera is on, the plain surface with the icon at 45 % strength while it is off; not drawn at all and
a no-op where a server or mission forces the setting - `fnc_cameraForced`, a CBA priority of 1 or more on `server` or `mission`)
turns it for that window only, a step aside (`fnc_stepAside`, `einv_gui_cameraNext`) brings it back
as it was. It is no longer kept in the profile.

| Key | |
|---|---|
| `id`, `name`, `font`, `fontBold`, `upper` | style id and name; `PuristaMedium`, `PuristaSemibold`; captions in capitals (`fnc_caption`) |
| `radius` | panel corner radius as a height (0 = square; Glass `UNIT * 0.45`) |
| `dim`, `dimCamera`, `panel`, `panelBorder` | the screen's dim colour without and with the camera; column background (`[]` for none), 1 px frame |
| `lootPanel`, `lootBorder`, `lootAccent`, `lootTab`, `lootLine` | the loot column's look (issue #7; `[]` in `fnc_themeBase`: as the own column): its pane, a ring round it (`fnc_uiRing`), the 2 px strip under its title and its title icon (`fnc_drawColumn`), its sections' caption tab, fold line and hairline (`fnc_drawSection`; the activity chip takes the tab's colour). Glass: a steel blue, `[0.45, 0.62, 0.82]`, the pane `[0.035, 0.05, 0.07, 0.92]` |
| `inspectBg`, `tooltipBg`, `card` | the inspect card and kit windows; the comparison card and mouse tooltip; section header and card |
| `slot`, `slotEmpty`, `slotBorder`, `slotCaption` (`"none"`, `"above"`, `"tab"`, `"inside"`), `slotCaptionBg`, `slotIcon`, `slotAccent`, `hatch` | slots |
| `cell`, `tileBg` (five colours by `CATEGORY_*`), `tileBorder`, `tileName`, `tileCount` (`"text"`, `"pill"`, `"badge"`), `tileCountBg`, `tileCountColor`, `tileAmmoBar` | grid cells and tiles |
| `raised` | the small flat box of a stack's "3/10" and a hotbar slot's count |
| `text`, `text2`, `muted`, `accent`, `accentSoft`, `line`, `gain`, `loss`, `warn`, `info` | colours |
| `barTrack`, `barFill`, `button`, `buttonHover`, `buttonText`, `keyBg`, `keyText`, `keyRound` | bars, buttons, key hints in the footer |

The Arsenal panel has no theme of its own: it is drawn in Glass as it is, with its radius, panel colour, fonts and text colours.

### The UI kit

`fnc_uiPanel`, `fnc_uiLabel`, `fnc_uiIcon`, `fnc_uiPicture`, `fnc_uiFrame`, `fnc_uiBar`, `fnc_uiRing`, `fnc_uiShape`,
`fnc_uiHatch`, `fnc_uiKeyHint` and `fnc_uiButton [display, parent, rect, id, text, icon, theme, code, disabled, textSize, centred, hitPad]`
(left click runs `code` with `[1, id]`, right click `[-1, id]`; **the hit area is the drawn button and 2 pixels (`pixelW`, `pixelH`) on each side**, for every button
(Mia, 0.5.5: easy to hit by a hair, but a button must not take the clicks of the room beside it). `hitPad` - `[x, y]` or `[left, top, right, bottom]` - is kept as the
12th argument only so that old callers work: whatever is asked is cut to that, the section captions' and the kit windows' large zones included, see "Hit areas" under Section) take a `parent` (`controlNull` for the display, a group for relative coordinates), snap to
pixels and register top-level controls in `einv_gui_created`.
A **centred** button (`centred` true: the section buttons, the kit windows' buttons, the red Arsenal screen's OK) leaves the centring to the
engine: its label is a centred `EINV_LabelCenter` as wide as the room between the paddings (`BUTTON_PAD` 0.3 of the height each
side; beside an icon, which keeps to the left padding, the room right of it and its gap `BUTTON_GAP` 0.22), and starts above the
button's middle by `TEXT_MID` 0.66 of its font height, so the line of capitals sits in the middle of the height too - a left-aligned
label started where the *measured* text would be centred, and `getTextWidth` is short of what the engine draws, so it stood right of
the middle. `fnc_buttonWidth [text, icon, height, size, theme]` gives the width that fits such a button (paddings, icon, gap and the
text with `TEXT_SLACK`).
`fnc_safePicture [path]` -> path or "": a file path (`\` or `/`) ending .paa/.jpg/.png, or none when its .paa exists, that
`fileExists` finds - asked once per path (uiNamespace `einv_gui_pictures`); `#(...)` passes. `fnc_uiPicture`
draws nothing for ""; the wizard's index and editors, the Arsenal header and ACE cargo's cards ask it too (`picture = "picturething"`).
`fnc_uiItemPicture [display, parent, box, texture, icon, colour, clip, events, share]` -> the control is how the **item's
own picture** is drawn wherever it is (tiles, slots, the equipment cards, the inspect card, the dragged ghost; see "Grids and
tiles"): the picture of `fnc_uiPicture` made `icon` (`getInfo "icon"`, `[scale, across, down]`) larger or
smaller about the box's middle and moved by the offsets, which are a share of the `clip` rectangle's (the tile's, the slot's)
width and height. The plain icon (`ICON_PLAIN`) is the one control it was. Otherwise the image is measured by the texture's own
shape (`getTextureInfo`), not by the control it is fitted into: where it stays inside `clip` (half a pixel of give) it is still one
control, where it would reach out it is made inside an `EINV_Group` of exactly `clip`, which cuts it - the group is what comes
back, the picture is `getVariable "einv_gui_inner"`. `fnc_uiPictureRounded [display, parent, rect, texture, radius, film, backdrop, icon, events]` draws the same for the editor's picture of a crate or vehicle on its grey (which not every mod's pictures share - ACE's is lighter than BI's, and a script cannot read a picture's pixels - so the backdrop's colour is laid over the edges of the image in `FADE_STEPS` strips of falling strength, clipped to the round box, and no rectangle shows); `fnc_uiPictureCut [display, parent, box, texture, icon, clip, radius, events]` draws a picture by `icon=` cut at a round box: one that reaches out of the box is three groups as `fnc_uiPanel` has three rectangles (the middle and the two sides between the corners), each holding the whole picture, so the box's round corners show the backdrop instead of the group's square ones; `fnc_uiBoxPicture [display, parent, rect, theme, own, preview, icon, radius, events]` is what fills such a box: the rules' picture `own` (`picture=`, on the slot surface with a little air) else the editor's `preview`, both by the class's `icon=` and cut at the box; `[]` when there is neither (the caller shows its icon). A group over a tile reports the buttons and the wheel as the display does (`events`, true except in the wizard's
preview) and hands the wheel to the scrolling group it lies in, `fnc_passWheel` (`WHEEL_STEP` 3 `UNIT`): a group nested in a
column takes the wheel from it (`fnc_createGrid`), and its picture, larger than it, would make it scrollable - its scroll is put
back to the top at every turn, and again for `UNSCROLL_FRAMES` frames from `fnc_onFrame` (`fnc_unscroll`): the engine scrolls the group after
the handler ran, so a reset in the handler alone left it one step down each turn.

### The hook table (window engine for other displays)

The rule that keeps the inventory safe: **with an empty hook table every function of the gui addon behaves as the plain
inventory.** A hook may only be asked through `einv_gui_fnc_hook [name, args, default]`: absent gives the default; a flag gives
its value; code is called with `args` and its answer used unless nil. `fnc_isInventoryMode` is true with no hooks, and every
inventory-only feature asks it: nearby boxes, selecting, the band, group drags, Take all / Put all in, the hotbar, repacking.

| Hook | Arguments | Answer | Asked in |
|---|---|---|---|
| `guest` | flag | true: the display is another mod's - sweep only what was registered, mouse handlers only on our own groups, the display's handlers never answer "taken" | `fnc_build`, `fnc_attach` |
| `theme` | `[theme]` | nothing - edits the theme | `fnc_build` |
| `context` | `[context]` | nothing - edits what the window shows (`ownSections`, `storageSections`, `cameraOn`, ...) | `fnc_build` |
| `layout` | `[display, theme, context]` | where the soldier stands `[x, y, w, h]` or `[]` - replaces the look's layout | `fnc_build` |
| `header`, `footer` | `[display, theme]` | nothing - replace `fnc_drawHeader`, `fnc_drawFooter` (`{}` draws none) | `fnc_build` |
| `camera` | `[rect]` | nothing - with it the gui's own camera is never started or stopped | `fnc_build` |
| `afterBuild` | `[display]` | nothing | `fnc_build`, the last line |
| `footerKeys` | `[]` | `[[key, text], ...]` - replaces the footer's key hints | `fnc_drawFooter` |
| `keepOpen` | `[]` / flag | BOOL - replaces the inventory's must-close rules (they read `ACE_player`, wrong in Eden and Zeus) | `fnc_onFrame` |
| `frame` | `[display, mouse, now]` | nothing - every frame, also while dragging, not while covered | `fnc_onFrame` |
| `focusAll` | flag | true: every control with the focus but a field goes back to the sink while no button is held | `fnc_onFrame` |
| `wheel` | `[scroll, mouse]` | BOOL, true = taken - only while nothing is dragged, once per turn | `fnc_onMouseZ` |
| `mouseDown`, `mouseUp` | `[button, mouse, shift, ctrl, alt]` | BOOL, true = taken - before the right click | `fnc_onMouseButton` |
| `click` | `[kind "single" / "double", target, shift, ctrl, alt]` | BOOL, true = handled - a click that did not become a drag | `fnc_onMouseButton` |
| `key` | `[display, key, shift, ctrl, alt]` | BOOL, true = handled - after the hotbar and selection keys, before the drop key and the Gear key | `fnc_onKeyDown` |
| `submit` | `[edit]` | nothing - Return in a field | `fnc_onKeyDown` |
| `dragCheck` | `[dragTarget, entry, sourceGrid, slotSource]` | the target as it is to stand, `[]` for none, nil to leave it - last of everything | `fnc_updateDrag` |
| `drop` | `[kind, sourceIndex, tileIndex, slotSource, entry, count, targetIndex, col, row, w, h, targetSlot, place, rot]` (**14**) | BOOL, true = handled - after the `!fits` exit | `fnc_endDrag` |
| `ground` | `[source, count]` | BOOL, true = handled - `source` is `[unit, slot]` or `[grid index, tile index]`, count -1 for all | `fnc_quickUnequip`, `fnc_dropToGround`, `fnc_quickMove`, just before each falls back to the ground |
| `fold` | `[container]` | BOOL, true = the window keeps its folds itself (`einv_gui_collapsed` is left alone, the window is drawn again) | `fnc_toggleSection` |
| `signature` | `[]` | `[holder, ...]` - holders the window draws itself, beside the unit's sections; their cargo and places are part of the "storage" signature, so a change there (a move inside the Arsenal's staging space) builds the window | `fnc_getSignature` |
| `menu` | `[display]` | choices - replace the default, `[]` = no menu, nil = the default | `fnc_contextMenu` |
| `filter` | `[]` | nothing - after the tiles were dimmed and hidden for the search and the categories | `fnc_applyFilter` |
| `tileBadge` | `[class]` | a texture or `""` - a mark `SQUARE(UNIT * 0.42)` in a tile's top left corner | `fnc_createTile`, `fnc_drawSlot` |
| `hint` | `[kind "tile" / "slot" / "none", class, record]` | parts `[[text, colourKey], ...]` after the gui's own; for `"none"` the whole idle hint | `fnc_updateHover` |
| `inspectRows` | `[class, count, ammo, attachments]` | rows `[label, text]` or `[label, fraction, text]` before the Mod row | `fnc_drawInspect` |

ACE Arsenal's panel is the only window that attaches today. It sets `guest`, `theme`, `header`, `layout`, `footer`, `camera`,
`keepOpen`, `frame`, `mouseDown`, `mouseUp`, `click`, `wheel`, `dragCheck`, `drop`, `ground`, `signature`, `fold`, `menu` and `hint`; `context`,
`afterBuild`, `footerKeys`, `focusAll`, `key`, `submit`, `filter`, `tileBadge` and `inspectRows` are asked for but set by nobody,
kept as the surface for a later window.

`drop`'s `place` is false when the cell is taken in a kit's grid (whose layout finds another); `rot` is 0 upright, 1 turned. **The
click target** (the `click` hook; element 8 of `einv_gui_press`) is a HashMap: `type` (`"tile"`, `"slot"`, `"cell"`, `"none"`),
`grid`, `tile` (-1 unless a tile), `cell` `[col, row]`, `slot` (an index into the slots), `source`. A window that listens also
gets presses on empty slots, free cells and nothing (nothing is lifted from them), and a Shift double click counts as a double
click.

**Source grids and zones.** A grid with `"source"` (a STRING) is a place things come from and never a target: `virtual`, no
container, never faded by the search nor searched. A tile on it may carry `dragEntry` (class, `w`, `h`, `count` = how many may go
at once, `ammo`, `capacity`, `attachments`, `controls`), `dragStart` (the first count, 1; Shift takes the stack), `grab`, `size`;
a drag from it is **always ended by the `drop` hook**, `fnc_endDrag` then only cleans up. Zones are `uiNamespace einv_gui_zones =
[[rect, id], ...]`, emptied by every build and filled by whoever draws the area; over one (and no slot or grid) the target is
`["zone", index, 0, 0, true, ""]` and only the `drop` hook acts on it.

### Layout

`| equipment | free middle | loot | storage |` (`fnc_layoutGlass`). **Where the loot column goes** is the client setting
`einv_gui_lootSide` (read at every build, so an open window follows at its next one): `left` (default) puts the storage column at the right
edge always, looting or not, and the loot column left of it; `right` is the order before the setting, `| storage | loot |`, with the loot
column at the right edge and the storage column moving in once something is looted. The columns have the same widths either way, so the
free middle is as wide in both and only lies against the other column; the camera is told the new rectangle and moves (see "The camera is
kept"), the storage column is made at the same x with its scroll kept by its id. A window that reserves the right edge for itself
(`rightColumn`) always gets the `right` order. Nothing else goes by the order: quick move and the drags go by a grid's `side` (`"own"` /
`"loot"`), kit windows (`fnc_placeWindow`) by the free middle and `GVAR(panels)` - a kit opened from the storage column while a loot
column shows now opens in the middle, one column away from its tile - and the inspect card and the footer by the screen. The context (`fnc_build`) carries `unit`, `container`,
`secondary`, `equipment` (`fnc_getEquipment`), `ownSections`, `lootSections`, `looting`, `cameraOn`; a window that attached may
add `rightColumn`, `rightKeep`, `rightGrow` (reserve and grow the loot column's place; the rect comes back as `rightRect`) and
`storageSections`. The layout answers where the soldier stands, or `[]` when the middle is too narrow; on 4:3 the middle gives way
first, then the equipment column. Every panel goes into `einv_gui_panels`: an item let go outside all of them goes on the ground.

- **Equipment column** (`fnc_drawEquipmentCards`): the weight card; three weapon cards (primary, handgun, launcher: the picture,
  every attachment slot and loaded magazines as small slots; the weapon in hand in the accent colour); the gear row **headgear |
  uniform | vest | backpack**; a row of small slots (goggles, NVG, binocular, map, GPS, radio, compass, watch); and, when the
  hotbar is loaded and on, its row. The backpack is a slot like the other three - record `slot` "backpack" and `unit`, each card
  `(width - 3 gaps) / 4` wide, at most 4.6 UNIT - so a backpack dropped on it goes on and the worn one goes where the dragged one
  lay; dragged off, it leaves with its contents, never into itself or another backpack. Anything let go on the column goes into
  the slot that takes it (`slotFor`); the gear row is drawn first, so a backpack let go anywhere there lights its slot, worn or
  not.
- **Columns** (`fnc_drawColumn [display, rect, sections, theme, title, icon, drawer, id]`): a panel, a title row, a scroll group
  with one section per container. **Loot and own apart** (issue #7): the own column is titled "Your gear" (`Column_Storage`), the loot
  column "Loot - <what>" (`Column_LootOf`: the body's or person's name, the crate, "Ground", "Nearby"; `fnc_layoutGlass`), and the
  column with id `"loot"` takes the theme's loot look - `lootPanel` pane, a `lootBorder` ring, a 2 px `lootAccent` strip under the title
  and the title icon in it - in either order of `einv_gui_lootSide`, since it goes by the id, not the side of the screen. In the loot
  column a uniform, vest or backpack's caption names its wearer, "Backpack - Miller" (`Section_OwnedBy`, `einv_storage_fnc_getOwner`,
  `fnc_ownerName`: ACE's name, else the unit's displayName), and its tab, fold line and hairline take `lootTab` / `lootLine`. ACE
  Arsenal's panel draws a `"storage"` column with `"own"` sections and is untouched; the column's `id` (`"storage"`, `"loot"`) is how `fnc_build` keeps its scroll
  (`fnc_scrollPixels`, restored a frame later through `einv_gui_scrollRestore`). Cells are controls created directly in the group:
  a nested group would eat the wheel. **A column scrolled down keeps its group:** `fnc_build` notes each column group with a scroll (its id, `scrollPixels`) and hands it over in
  uiNamespace `keepColumns` (id -> [group, panel and title controls, [rect, title, icon]], what `fnc_drawColumn` stores on the group as `columnParts`/`columnKey`), spares those controls in its
  sweep and, in `fnc_drawColumn`, a column drawn again in the same rect with the same title and icon draws its sections into the old group first, deletes what stood in it in the same call
  (a group never stands empty, as the wizard's General page) and sets the scroll at once from `keepPixels`; the frame-later put-back (`scrollRestore`) stays. A column that moved, was named otherwise or
  was not drawn again has its old controls deleted. Before this a fold or unfold showed the column at its top for a frame (Mia, 0.5.3).
- **Section** (`fnc_drawSection`): a caption tab (folds it, `fnc_toggleSection`; the contents' weight on the right,
  `fnc_loadText`, only told), a box with the container's picture and short name, and the grid. **The tab is one of the line's chips** (Mia, 0.5.7: its edges were sharp): a pill as high as the buttons (0.6 UNIT, in the middle of the
  `CAPTION_LINE` 0.8 UNIT line with a gap above the container's top edge), the theme's radius at most half its height, the same 0.42 UNIT of text set the way a centred button
  sets it (`TEXT_MID`), the fold arrow in its left end; its hit area the drawn pill and two pixels; what the search tints on a folded box is its pieces, painted as a
  surface (`fnc_paintSurface`). The fold line of a tall box (`Rows_Show`), the tab of a locked box and the tab of ACE cargo's cards are round too. Beside the tab, the buttons, centred: "Take all" (loot) or "Put all in" (own) (`fnc_takeAll`, `fnc_putAll`,
  `fnc_putAllTarget`: from the contents, not from what is drawn; what is not searched stays) and "Sort: Name" with
  `icon_sort_desc_ca` (`fnc_sortHolder [holder, root, step]` - the storage's op "sort"; the only way to sort, the context menu has no
  row for it; on every container section of the inventory the player may change, also an empty one, never on a section that only
  shows - `virtual`). **The Sort button cycles:** its label names the order the player sorts by now - Name, Weight, Size or Type
  (`SORT_MODES`, `fnc_sortText`) - and a click steps to the next one and sorts by it (`step`). The order is each player's own,
  `einv_gui_sortMode` in the profile, and travels as the op's second argument and the move's `"order"`; the op runs where the
  container's root is local and writes the places everyone reads (section 3, `fnc_getLayout`). The button is as wide as the widest
  of its four labels (`fnc_sortChip`), so the caption line never moves; every Sort button on the window - sections and kit windows
  (`fnc_drawWindow`) - is registered with its label and hit area (`fnc_sortButtons`, uiNamespace `einv_gui_sortButtons`, emptied by
  each build) and changes its label and tooltip in place when any of them is clicked. The tooltip says what the next click sorts by.
  The tab gives up room down to three characters, then the last button goes, then the one before it; both are drawn disabled
  while a move out of the section is under way. A cross on a container opened from inside another (`fnc_closeNested`). Beyond the keys of the storage's
  sections (section 3) a section may say `drawer` (a function name another addon draws it with: ACE cargo's cards), `placeholder`
  (a container the unit lacks: a hatched box that is its slot when it has an `owner`), `worn` + `unit` (a body's compact doll,
  `fnc_drawEquipmentDoll`), `locked` (a padlock and one muted line, nothing of what it holds; `lockTip` adds an open padlock). Own
  sections start open, crates found around start folded; `einv_gui_collapsed` holds the containers the player turned the other
  way. **Hit areas** (Mia, 0.5.5, 0.5.7): the caption line is `CAPTION_LINE` 0.8 UNIT high; its buttons are 0.6 UNIT high and centred on it, and **every hit area is the drawn
  thing and 2 pixels on each side** - `fnc_uiButton` cuts any `hitPad` it is asked for to that (see "The UI kit"), the tab and chevron (`fnc_toggleSection`), a nested container's cross
  and the fold line (`EINV_Hitbox` made with the same 2 pixels) the same. The kit window's buttons and cross and the header's four buttons are buttons and have only that. Nothing reaches
  over the empty room between the lines, and nothing over a grid's cells. (The larger zones of 0.5.1 - `CAPTION_HIT_UP` and the like, a cell high - are gone.)
- **Section bars: the activity chip and the strip of categories** (`fnc_updateStatus`, `fnc_animateStatus`, `fnc_stopStatus`, `fnc_drawGroupStrip`,
  `fnc_paintGroupStrip`, `fnc_setGroup`, `fnc_itemGroup`, `fnc_boxGroup`, `fnc_matchesGroup`). **The chip** is the one place the hands' queue and the search show
  how far they are: in the caption line of a box, right of the buttons, as high as they are, up to the weight - and over the weight (hidden while the chip stands,
  `statusCover`) where there is too little room beside it for a ring, a few words and the button. `fnc_drawSection` only says where: it puts `statusParent`,
  `statusRect`, `statusSize` and `statusCover` into the section's info (`sectionInfo`) and draws nothing. `fnc_updateStatus` (the end of every `fnc_drawQueue`, so of
  every build, redraw and settle, and `fnc_revealTile`, `fnc_stopStatus`, `fnc_animateStatus` asking) makes, keeps and deletes the chips: for each info it works out
  what the box does - `hands` (a record in `GVAR(handBoxes)`, which comes first) or `search` (entries of `GVAR(searchQueue)` for its container; stopped when it is in
  `GVAR(searchPaused)`) - and leaves a chip alone whose `signature` ([kind, stopped]) and controls are still right. A chip is a pill (the theme's radius, at most half its height, like the buttons beside it) in the tab's colour, a ring
  (`search_ring_32` as the track, `search_ring_08` over it as the arc, `STATUS_ARC`), a label and a button: a red round button (a circle with the cross; the word "Search" on an accent pill for a stopped box) set in from the chip's edge on three sides by 0.12 of its
  height, so the chip's round end shows round it; one hit box, that button and two pixels, that lights it under the mouse and runs `fnc_stopStatus` a frame later (hands: `fnc_cancelQueued
  [0, box]`; search: stop or resume). The words are sized for their longest (the count at its largest, "99:59") so the chip does not move; where even that does not fit
  the label says the count or the time alone. `fnc_onFrame` calls `fnc_animateStatus` while `GVAR(statusLive)` (the caption lines hold a chip): one `ctrlSetAngle` on each
  ring (`STATUS_SPIN_SPEED` degrees a second) and a `ctrlSetText` only when the words changed - the hands' count when an entry finished, the search's time once a second;
  a chip whose box has nothing left asks `fnc_updateStatus`, which deletes it and shows the weight again. **The strip** (`fnc_drawGroupStrip`) is one rounded bar (`slotCaptionBg`, the theme's radius at most half its width, `SQUARE(UNIT)` wide) holding a column of
  white pictures between a loot box's picture and its grid - All (`slot_cat_all_ca`), then every category there is (`fnc_stripEntries`: `einv_items_fnc_categories`, each with `fnc_groupTexture` and the `label` of `fnc_categoryInfo`): weapons (`slot_rifle_ca`), ammunition (`slot_magazine_ca`), grenades (`slot_grenade_ca`), gear (`slot_vest_ca`), medical
  (`slot_cat_medical_ca`), food and drink (`slot_cat_food_ca`), tools and electronics (`slot_radio_ca`), other (`slot_cat_misc_ca`), the four `slot_cat_*` drawn by
  `tools/generate_ui_textures.py` (`--only name,name` makes just those), then the setup's own (the picture it gave them, else `icon_star_ca`), and a built-in category too wears the picture the setup gave it. The strip has `STRIP_SLOTS` 9 fields (the eight built-in categories fill them with All); with more categories the last field is "more" (`icon_chevron_down_ca`, tooltip "More categories (1 of 2)"): All stays on top, the categories come 7 at a time, and a click on "more" (`fnc_stripMore`) gives the same fields the next group's picture, tooltip and category - nothing is made or deleted, a field a short last group leaves over is hidden - and goes round to the first; the group shown is kept per box in `GVAR(stripPages)` until the window is attached again, the strip's `strip` info entries are `[id, field, picture, hit]` (the id changes with the group, "" for a hidden field) and `fnc_paintGroupStrip` lights "more" while the chosen category is on another group. Only for a section in the loot column with a container and a grid of its own (not the player's
  own containers, not a kit's grid, not a locked or placeholder section), and where the column can spare `strip + gap` beyond the grid: the strip takes its room from the
  box's picture (which gives way in half cells) and never from the grid; there is no dropdown where it does not fit, the strip is left out. Its height is the box's or the
  grid's, a pitch of `STRIP_ICON_MIN` 0.75 to `STRIP_ICON` 1.1 UNIT per picture (the section grows when that is more), the pictures 0.78 of the pitch or of the width at most. Each picture has a
  field - exactly its share of the bar, as wide as the bar, the first with the bar's round top corners and the last with its bottom ones (`fnc_uiSurface` with the corner mask, so a lit field
  ends where the bar ends: Mia, 0.5.7, the fields were a hair smaller than the element behind them) -, the picture and a hit box (tooltip: the category's name, hover lights the field a
  little, a click runs `fnc_setGroup` a frame later); the chosen one is a lighter field (`[1,1,1,0.15]`) with a white picture, no accent colour (`fnc_paintGroupStrip`).
  `fnc_setGroup [container, group]` toggles (the chosen group again, or "all", is none), stores it in `GVAR(groupFilters)` and calls `fnc_applyFilter [true]`. **A category hides, the
  search field dims** (Mia, 0.5.7: "only items of this kind"): `fnc_applyFilter` sets the tile's `filteredOut` and hides the controls of every tile that is not of the chosen group (a tile not
  searched yet is of none), makes or shows the squares of the cells such a tile lies on (grid `filterCells`; `fnc_drawCells` makes none under a tile) and hides them again under a tile that is back,
  so the box reads as a grid with only that kind in it; `fnc_updateHover` does not find a `filteredOut` tile (its cells are found as free cells), though the cells stay taken in the layout:
  a drop there is refused as on any tile. The state of a tile is kept on its first control (`einv_gui_fx`: 0 shown, 1 dimmed, 2 hidden, none = made new): controls made new take their state at
  once, with no fade (a page turned to in a filtered box showed every tile at full strength for the tenth of a second the fade took), the typing and the strip's own passes (`jump`) fade as before.
  `fnc_itemGroup [class]` is the first of the item's "groups" (`einv_items_fnc_getInfo`: what `cats=` / `einv_cat` say, else the built-in mapping `einv_items_fnc_defaultGroup`, which used to live here; section 2) and `fnc_matchesGroup [class, group]` is true when the chosen category is any of them - an item in several categories shows under each; nothing is kept here, since the rules can move an item and `getInfo` answers from its own store until they change. The built-in mapping is the first that applies of: medical (category medical or a kit) -> weapon (rifle, handgun, launcher, muzzle, optic, rail, bipod) -> grenade (the kind grenade, or a magazine whose ammo simulates a mine or a directional bomb) -> ammo (every other magazine) -> gear (uniform, vest, backpack, headgear, nvg, goggles, binocular) -> food (ACE field rations' `acex_field_rations_hungerSatiated` / `thirstQuenched` in config, or a class name that says ration, canteen, food, drink ...) -> tool (map, gps, radio, compass, watch, an ACRE or TFAR radio or `einv_sound = "device"`, or a name that says wire cutter, cable tie, flashlight, defusal kit ...) -> other. A tile not searched yet matches no category. A category chosen at a box that the setup has since taken out matches nothing; choosing it again, or All, clears it (the window is built again when the rules change).
- **Compartments.** `fnc_flowCompartments [layout, cell]` -> `[places, height, width]`, drawn by `fnc_drawCompartments [display,
  parent, [left, top], section, layout, places, theme, window]`. Flowed compartments (`pos` `[]`) lie side by side as far as
  `STORAGE_COLS` cells reach, then on the next line, `COMPARTMENT_GAP` (0.22 cell, pixel-rounded) between blocks. A compartment
  with a `pos` lies on its **canvas** where it was drawn; the canvas is one piece of the flow. **Seams:** every cell keeps one size
  and the plain gap, but a column boundary at which some row has cells of two different compartments on its two sides, and a row
  boundary at which some column has, gets `SEAM_GAP` (= `COMPARTMENT_GAP`, so painted and flowed containers look alike) more
  room, everything beyond it moving on: column `c` starts at `c * cell + (seams before c) * gap`, rows likewise. A boundary
  where a compartment meets an empty place is none; two that touch only at a corner open the column boundary between them.
  Compartments keep their painted places relative to each other; one that reaches over a seam opened for two others (a wide one
  under two narrow ones, the ring of `aaa/aba/aaa`) has that room between two of its own cells. A canvas compartment's place is
  `[x, y, colX, rowY]` (where its columns and rows start from its corner), the canvas grows by its seams and `width` is the widest
  line (a canvas with seams across is wider than `STORAGE_COLS` cells). **Panels:** `fnc_drawCompartments` draws every panel
  before any cell: the theme's `card` behind a compartment's cells, `COMPARTMENT_PAD_PX` (0.06 cell, at least a pixel) past
  them, round up to three times that (`uiPanel`); a shaped one is `fnc_uiShape "panel"` - the cells grown by the pad, the room
  between them filled, holes open, cut into bands of non-overlapping rectangles. The flow keeps room for the pad: places move on
  by it less the pixel callers keep left of and above the block, `height` and `width` count it on both sides. Overflow grids keep
  the loss colour's lines and no panel. Tiles and every rect on a grid (`fnc_spanRect` via `fnc_tileRect`, selection, pending,
  band, drag footprint, `fnc_shapeRects` with `[grid, col, row]`) and `fnc_screenToCell` use the grid's `colX`/`rowY`, so a tile
  lands exactly on its cells and spans a seam inside its compartment as one piece. A point maps back in O(1): `floor(distance /
  cell)` names a stretch, `colAt`/`rowAt` the last column starting in it or before, and the point lies in that one or the one
  before; the room of a seam belongs to the cell before it only where the cells across it are the same grid's (a tile can lie
  over it), so the room between two compartments is no cell. The drag's geometry (`dragRoom` "geometry", "hold") uses the same
  extents and rule. `einv_setup_fnc_drawPreview` draws the same flow and panels, its cell shrinking until the width fits.
- **Grids and tiles.** `fnc_createGrid [display, parent, [relX, relY], rows, theme, section id, cols, holes, [colX, rowY]]` -> a
  HashMap: `parent`, `rel`, `cols`, `rows`, `cellW`, `cellH`, `colX`, `rowY` (where each column and row starts from `rel`; the
  plain pitch unless a canvas's seams), `colAt`, `rowAt` (per stretch of one cell, the last column or row starting in it or
  before), `cells` (a **hole** has no control: `controlNull`; nor has a cell whose square is not made yet), `cellColor`, `holes`,
  `tiles`, `section`, and from `fnc_drawCompartments` `container`, `virtual`, `kit`, `layoutKey`, `unit`, `block`,
  `pos`, `overflow`, `window`, `holder`, `root`, `side` (a source grid adds `source`). **The cells' squares** are made by
  `fnc_drawCells [display, grid]` once the tiles lie on the grid (`fnc_drawCompartments`, `fnc_redrawTiles`), and only where no tile
  lies: a cell under a tile never gets a control (a full pile of ninety tiles makes no ninety squares only to hide them); a redraw
  shows, hides or makes them as tiles went and came. Made after the tiles of their group, they still lie over nothing but their
  compartment's panel. `fnc_createTile [display, grid, entry,
  theme]` draws the surface in the category's colour over the entry's cells only (a shaped tile: runs of cells with one-pixel
  bridges; `"backgrounds"` and `"rect"` kept for hover, flash, reveal and the repack film), the picture, the short name, a
  stack's count and a magazine's fill. A **turned tile** (`rotated`; the dragged ghost held turned, also a row dragged from
  ACE's list) draws its picture **upright**, in the one plain `EINV_Picture` of any other tile, fitted with its shape kept
  (`ST_KEEP_ASPECT_RATIO`) into the turned footprint (the swapped `w` and `h` as the box). Nothing is rotated: `ctrlSetAngle` on a
  picture came out squashed or out of the tile for pictures that are not square (0.4.7 to 0.5.17 tried a square control and one in
  the picture's own proportion), so a wide texture is simply small in a tall footprint and item pictures should be square. The
  footprint itself (R, the swapped size, placement, records) is unchanged, and the ghost is drawn exactly as its tile. The
  hotbar and the inspect card draw upright as ever.
  **The picture is drawn by the item's `icon`** (`icon=`, `getInfo "icon"`, `fnc_uiItemPicture`): `fnc_createTile` (clip: the
  tile's rectangle, its box for a shaped item; an entry may carry its own `"icon"`, and `"preview"` for the wizard's tile),
  `fnc_makeGhost` (one-item ghost and the group ghosts; clip: the footprint's rectangle), `fnc_drawSlot` (clip: the slot, the
  hotbar row of the window included), the weapon cards of `fnc_drawEquipmentCards` (the card) and `fnc_drawInspect` (the lighter
  box round the picture) all draw through it, so a larger or moved picture never leaves its tile, slot or card. The Arsenal
  panel's tiles and the kit windows' are `fnc_createTile`'s. **The boxes of crates and vehicles** (`fnc_drawSection`, the loaded-cargo cards of `compat_ace_cargo`) ask `getInfo` for the object's class: `pictureOverride` shown when `picture` is it (the file is there), else `editorPreview`, drawn by `icon` (`fnc_uiBoxPicture`); a uniform, vest or backpack box is `fnc_drawSlot`, which already drew by `picture` and `icon`; a kit window's title picture is `fnc_uiItemPicture` too. `fnc_createTile`'s entry may carry its own `"picture"` (the wizard's preview of one being picked). The small title pictures (the Arsenal panel, the
  context menu) and the wizard's lists draw the plain picture. A weapon's attachment icons stay where they were.
  **Round corners** (Mia, 0.5.3: an item at the corner of a container poked over its rounded edge): the panel behind a compartment is round by `min(theme radius, 3 pad)`; `fnc_gridCorner`
  keeps on the grid `corner`, that radius less the pad in pixels (0 for a square look, a corner under 2 px, a compartment with a hole in the rows that show - its panel is a shape of rectangles -,
  the overflow, a preview; `fnc_setWindow` asks again for a page's rows). `fnc_cornerRadii [grid, box, origin]` answers `[radius, [tl, tr, bl, br]]` for the corners of the box that lie on the
  panel's (the first cell's corner to the last cell's far edge, a pixel's slack; a tile as wide as the compartment touches two), `[]` for none, in the grid's group (the default) or on the screen
  (the drag, with `fnc_gridOrigin`). `fnc_uiSurface` draws a surface square except at those corners (the middle rectangle, a strip on a side with a round corner, the quarter circles `corner_*_ca`;
  `fnc_paintSurface` colours the pieces: a corner by its text colour), `fnc_uiOutline` the nested frames or, round, `fnc_uiRing` with a mask (a ring as thick as `RING_SHARE` of its corner, drawn again
  inside itself when thinner than the outline). Used by `fnc_createTile` (surface, a themed border; the entry's `corners`; a hatched unsearched tile is hatched a little in from a round corner, and the stack's count box and the rounds' box of a tile at a round bottom corner end in from it, `fnc_createTile`),
  `fnc_uiShape` with its `round` argument (the runs of a shaped tile's surface and of the selection's fill; frames of shaped tiles stay square), `fnc_drawCells` (a corner cell's pieces are the grid's
  `cellParts` by cell number, hidden and shown with the square, deleted by `fnc_clearCells`), `fnc_hoverOutline` (given the grid), `fnc_drawSelection`, `fnc_drawPending` (a target box
  outside the rows that show draws nothing) and the drag footprint (`fnc_updateDrag`'s `_fnc_show` takes the corners: the footprint control is the middle, six hidden pieces made by `fnc_startDrag`,
  `dragCorners`, are the strips and quarter circles; a group's footprints and a shaped item's cells stay square). `fnc_flashTile` flashes a corner as a corner.
  `fnc_tileAt` and `fnc_hitsHole` miss holes. A class whose `stack` is over 1 shows **"count/stack"** ("3/10", "1/10" too) on a
  small flat box in the `raised` colour at the bottom right - one label with the box as its own background
  (`fnc_drawCountBackdrop` with "only measure", argument 11; a hotbar slot's count the same) -; one that does not stack shows nothing; a magazine's rounds then
  move to the bottom left. Counts over a picture stand on a dark pill (`fnc_drawCountBackdrop`, sized for the widest text the
  label can become, since a repack writes rounds live). The fill bar (`einv_gui_magazineFillBar`) shows on magazines that are
  not full; the rounds as words only while `einv_gui_magazineText` is on (tiles only - a weapon's magazine slot keeps them;
  without the label a repack writes no rounds, its bar still runs).
- **Tall compartments.** `fnc_viewBlocks [layout, holder]` -> `[blocks, hidden, foldable, cells, paging]` shows a tall compartment down to
  its last row in use plus `COLLAPSE_SPARE_ROWS` 2, at least `COLLAPSE_MIN_ROWS` 4, and only folds when that hides
  `COLLAPSE_HIDE_MIN` 4 rows or more; one line under the grid, "+32 empty rows (256 cells)", opens them (`fnc_toggleRows`,
  `einv_gui_expanded`). A positional compartment never folds; kit windows and the own storage column are not folded. Only the
  view: the grid stays whole. A container with rows folded away registers its fold line and its box in uiNamespace `einv_gui_foldAreas`
  (`fnc_drawSection`, emptied by each build): a drag let go on either, or on a cell that does not take the item, lays it down in the
  first free spot of the whole container (below, `fnc_updateDrag`).
- **Pages** (`einv_gui_pageRows`, client; `fnc_pageRows`: 0 or `MAX_ROWS` 40 off, else at least `PAGE_MIN_ROWS` 4). A compartment of the loot column
  (not canvas compartments, not the own storage, not kit windows) whose view - its rows down to the last in use plus the spare rows, or all of
  them where the fold would hide fewer than four - is taller than the page is cut into pages: `fnc_viewBlocks` answers `paging` per compartment,
  `[page, [[from, to], ...]]` (`fnc_pageRanges`: cut in steps of the page size, but never through a tile, so a page can be a row or two short; one tile
  taller than the page makes it grow), its `blocks` entry holds the view's rows as ever, and it neither folds nor counts in `hidden`/`foldable`: **the
  pages replace the fold** - no "+N empty rows" line, no `expanded` for it. The page is kept per container and compartment for the mission (`GVAR(pages)`,
  `fnc_pageOf`) and clamped to what exists. `fnc_drawSection` flows the compartment as its tallest page plus `PAGE_RESERVE` (the bar; the panel's pad is the flow's own),
  so turning never moves what lies below, and registers the box and the bar's name in `foldAreas`. **The grid is the whole compartment, only some rows
  show**: `fnc_createGrid` takes a window (`rowFrom`, `rowTo`; `fnc_setWindow` changes it) and starts `rowY` at the window's first row, so a cell's place is
  `(row - rowFrom) * cell` and everything built on `rowY`/`rowAt` (`fnc_spanRect`, `fnc_shapeRects`, `fnc_screenToCell`) works unchanged; the bounds that
  were `rows` for what shows are `rowFrom`/`rowTo` (`fnc_screenToCell`, `fnc_hoverGeometry`, the drag's geometry, clamp and footprint, `fnc_groupMode`,
  `fnc_swapPlan`, `fnc_drawCells`). **Every tile of the compartment stays on the grid**, in the same order, whatever page shows - the room, the queue, the
  drag's indices and the selection need them - but only the shown page's have controls: the others are bare (`offPage` true, `controls` []), skipped by
  `fnc_findTile` and `fnc_selectionTiles`/`fnc_selectSection`/`fnc_select` (selecting works on the shown page), and drawn by `fnc_createTile` when their page
  comes (`fnc_drawTiles`; the same HashMap, put back where it stood in the grid's list - `fnc_showPage` walks the list **by number**, never over a copy of it: a tile made from a
  copy would carry the controls and the box while the grid's own tile stayed bare, and the search's fading, the hover outline, the selection and the queue would not find
  them, Mia 0.5.3). **With a category chosen** the pages follow what shows: `fnc_pageStep [grid, from, step, relative]` (used by `fnc_pageSoon` and `fnc_turnPage`) steps over the pages that hold a match
(`fnc_pageCounts`) only, an absolute page is the first match from there on, and `fnc_drawPageBar` counts only those pages ("Page 1 / 2"), switches an arrow off when none lies that way and says
`Page_None` when the box has no match at all; the field of the search alone leaves the pages as they are. The pager is `fnc_drawPageBar`: a bar `PAGE_BAR_H` 1.15 UNIT tall that is **the bottom part of the compartment's panel** (Mia, 0.5.10: no gap, it no longer floats as a strip of its own): `fnc_drawPagePanel` covers the rows of the *tallest* page (a last page with fewer rows leaves no gap), round at its top corners and square at the bottom, and ends at `PAGE_BAR_TOP` (the last row's far edge and the pad under it); the bar's darker track (`slotCaptionBg`, drawn with `fnc_uiSurface`) starts there, as wide as the panel, with the panel's round bottom corners, so the panel and the bar touch and never overlap (redrawing one never hides the other). `fnc_cornerRadii` gives a paged grid no bottom corners (the panel goes on into the bar), so only the grid's top corners round its tiles. Under
  the box, **nothing lies over the tiles** (the fade strips and the chip over the page's edge of 0.5.0 are gone: they covered the first or last row's tiles).
  It is one control: a track with a round arrow button at each end (0.5.5: nearly the bar's height, 1.5 times as wide as high; a surface of its own, dimmed and inert when there is no page that way, a second surface over it
  that fades in under the mouse - `ctrlSetFade` 0.08 s in, 0.2 s out - and the search's mark at the button's corner) and, between them, one line that says where it stands and
  what lies elsewhere: "Page 2 / 5 · +180 items on other pages · 12 queued". The hit area of an arrow is its button and 2 pixels around it (an `EINV_Hitbox` made last,
  so nothing lies over it; the bar between is free). **On the last page** (not the first) the line reads "Last page · 174 items on earlier pages" (`Page_Last_None`,
  `Page_Earlier`; the matches replace the items while the search holds something), in the brightest text, and the arrow back is the emphasised one: the `buttonHover` surface
  and an `accent` icon. Whenever there is a page before, the words are a hit area of their own (the label's rectangle, an `EINV_Hitbox` with the tooltip "First page") that
  jumps to page 1 (`fnc_setPage [grid, 0]`) and lights the words under the mouse. `fnc_pageCounts` says how many tiles and matches each page holds; while the search field holds something the
  matches on other pages replace the items, and the queued count is the tiles of the box that are `offPage` and `queued` (the hands' queue marks them in `fnc_drawQueue` though
  they have no controls: an entry whose tile is not drawn has no tint). A last page that would hold no tile at all - only the spare rows after the last item in use - is not made: `fnc_pageRanges` joins its rows to the page
  before, and `fnc_viewBlocks` takes a compartment left with one page for unpaged (the fold line again). (The note drawn on the free cells of the last page, with a
  "First page" button, of 0.5.4 is gone: it lay behind the tiles' background.) The grid's `pageControls` are drawn again only when what the bar says changed (`pageSig`: build, page, page count, text, the marks, the items elsewhere); `fnc_updatePageBars`,
  called at the end of `fnc_drawQueue`, has every paged box's bar compared after a queue changed or a move finished. A dragged item turns the page over the outer `PAGE_ZONE` 0.35 of
  the bar on each side (`pageAreas`); the middle 0.3 is a `foldAreas` place where a drop is laid down in the container's first free spot. a click on the bar goes through `fnc_pageSoon` ("Clicks that are heavy run through one gate"); `fnc_turnPage [grid, step]` ->
  `fnc_setPage [grid, page, bySearch]` (state, `GVAR(pagesMoved)` for the search) -> `fnc_showPage [display, grid, page]`, which draws only this box: the page left
  gives up its cell squares, **every control its tiles ever made** (the grid's `tileControls`, which `fnc_createTile` appends to and `fnc_drawTiles` prunes: a control a tile
  no longer names - a faded copy the search's fade had touched - is cleared all the same; after every redraw `fnc_drawTiles` compares the list with the controls the grid's tiles hold, deletes
  any stray and writes `A paged box held N controls that belong to no tile - deleted` to the RPT, which says that something drew a tile twice; `fnc_createTile` also deletes the controls an entry still holds before it draws
  it again) and its panel, the window moves, the panel (`fnc_drawPagePanel`), the new tiles, `fnc_drawCells` and the bar come, then
  `fnc_drawPending` (the queue's marks are found again: tiles that are not drawn are not marked), the selection, the search's fading and the hover are redone as after `fnc_redrawTiles`. `fnc_redrawTiles`
  accepts a paged compartment as long as the page height is the one the box was made for and redraws the page it stands on (the window may move with what lies
  there: then the box is drawn from its panel on, every tile made anew and every control the old ones made deleted, `tileControls` included); the bar is drawn again when what it says changed. The wheel is not used (the column needs it). A dragged item held over the bar's outer zones
  (`GVAR(pageAreas)`, the drag's geometry "pageBoxes") for `PAGE_HOVER_TIME` 0.7 s turns the page, again every 0.7 s while it stays, before the frame's early exits;
  `fnc_setPage` drops what the drag knew of the grids ("geometry", "hold", "spot", "frame", "cells|n", "swap|...").
- **Kit windows** (`fnc_drawWindows`, `fnc_drawWindow [display, section, theme, fresh]`): a kit or pouch is a floating glass
  window - a title row (picture, name, Take all and Sort, "12 / 60 mass", a cross, all on the row's middle line; the buttons and
  the cross are a section caption's - `CAPTION_LINE` 0.8 UNIT high, labels 0.46 UNIT and centred, `fnc_buttonWidth` / `fnc_sortChip` widths -,
  right-aligned before the fill text with one gap each; the name keeps its width up to 4 UNIT, else Sort gets compact - `fnc_sortChip` argument 3: 1 the icon and "Sort", 2 the
  icon alone, the order in the tooltip (`fnc_sortText`'s third answer, `fnc_sortButtons [controls, compact]`) -, then goes, then Take all; a
  press on a button neither raises nor moves the window, record key `buttons`) and a scroll body with the kit's grid (`window` =
  its key; the body is at most `WINDOW_VIEW_ROWS` 10 rows of cells high, a taller grid or several compartments scroll inside it with the engine's own scroll bar, `fnc_gridOrigin` counting the offset). Open windows are `einv_gui_windowOrder` (bottom first), placed by `fnc_placeWindow` beside the tile they were opened from, moved by a
  press on the title, raised by any press (`fnc_raiseWindow`: that window alone is made again, last), opened by `fnc_openWindow
  [key, anchor]`, closed by the cross, Escape on the topmost, or `fnc_closeWindow [key]`. **Hit testing** is by layer (`fnc_topAt
  [point]` -> `"inspect"`, a window key or `""`): menu, inspect card, windows (top first), columns; hover, drag targets, press,
  context menu and quick move all go through it.

### Drag, selection, quick moves

- **Lift.** A press (`fnc_onMouseButton`) becomes a drag after `DRAG_THRESHOLD` 0.008 (`fnc_startDrag`: the picture follows as a
  ghost, `fnc_makeGhost`, **held by its middle** - the middle of the picture is the pointer whichever cell was pressed, and the press's grab is
  set to the middle cell, `floor(w/2)`, `floor(h/2)`, again after each turn; the source fades; a footprint shows green where it fits, red where not). A stack goes whole, **Shift**
  half; the **wheel** changes the count (`fnc_onMouseZ`), the middle button takes all; **R** turns what is held (`fnc_rotateDrag`:
  `einv_gui_dragRot` apart from `einv_gui_dragSize`, a quarter clockwise and back, the item staying held by the same cell). Column
  and window edges scroll while dragging. Nothing is lifted that could go nowhere (a living person's item the player may not
  touch).
- **What a locked compartment shows** (`fnc_drawBadge`, called at the end of `fnc_drawCells`, so after every draw of tiles, a page turned and a move). A compartment that accepts only some categories or is a single slot says so when something lies in it too, by the **watermark**: an empty compartment shows its first category's picture (`fnc_groupTexture`) large and faint in the middle, one with something in it the same picture, half a cell, on each free cell while at most `WATERMARK_CELLS_MAX` 12 are free (alpha 0.12, single slots 0.2). It is made over the tiles and kept in the grid's `badge` list, deleted and made again with the cells; 1 control for an ordinary compartment's nothing, 1 to 12 for a locked one. There is **no badge in the corner** since 0.5.12 (the film with the category pictures and the "1" of a single slot, `BADGE_ICONS_MAX`, was taken out: Mia found the faint pictures enough; the function keeps its name). A single slot without a category has no picture to show and only the hover hint. Hovering a tile or a free cell of such a compartment says what it takes in the footer (`fnc_updateHover`, the `cell` case and the tile's own: "Only medical items here" in the accent colour, and "holds one item, whatever its size" for a single slot) - the hint line is this window's tooltip, and a control over the cells would take the mouse from the tiles.
- **Categories, single slots and hidden tiles in a drag** (`fnc_updateDrag`, `fnc_swapPlan`, `fnc_endDrag`, `fnc_startDrag`, `fnc_groupMode`).
  A grid carries its compartment's `"accepts"`, `"single"` and `"holes"` (`fnc_drawCompartments`). Over a compartment that accepts only
  other categories than the item's `groups` the footprint is red, the reason is `"WrongKind"` and the hint says "Only magazines here"
  (`Hint_Only` with the `only` name of `fnc_categoryInfo`; let go, `fnc_flashHint` says "This compartment takes other things"). Over a single
  slot the footprint is the slot, whatever the item's size or turn and wherever in it the mouse is (col 0, row 0, the compartment's
  columns and rows, its holes), and a taken slot is the same swap or merge candidate as any tile (`fnc_swapPlan` takes the slot as the
  footprint, sends the other tile to the cell the dragged one came from at its own size, or whole into a single slot there, and
  refuses with `"WrongKind"` when that compartment would not take it); `fnc_endDrag` sends the slot's cell. A tile lifted out of a slot
  is held at its own size (`fnc_startDrag` reads the entry's `"single"`). A group is never "kept" in a restricted compartment
  (`fnc_groupMode`): it is packed by the plan, which asks every compartment. `fnc_roomFor`'s quick look at free cells gives way to
  `hasSpace` for a container with such compartments. **A tile hidden by the chosen category or the search field** (`"filteredOut"`, set by
  `fnc_applyFilter`) is no tile to the drag: its cells are not "taken" and not under the mouse for a swap or a merge (`"cells|n"` keeps them
  as a third list); a footprint on them goes to the first free spot of the box from elsewhere - `place` false, the footprint is the
  compartment at half strength, the hint "Goes to the first free spot of this box - not onto a hidden item" - and is refused within one
  box. Take all in a box with a category or the search field active plans only the tiles that match (`fnc_takeAll`).
- **What a lift costs.** It makes few controls and reads little: the green highlight of each slot that takes the item (some fifteen
  controls with round corners) is made once per build by `fnc_glowSlot` into uiNamespace `einv_gui_glowCache`, ahead of time by
  `fnc_warmTargets` (one of the player's own slots per idle frame from `fnc_onFrame`, `glowNext` remembers how far), and a drag only
  shows it (`fnc_showTargets`, `dragGlow`) and hides it again (`fnc_endDrag`); a build empties the cache. `fnc_showTargets` reads
  the unit's equipment once and only for an item that may go on a weapon's part; `einv_storage_fnc_slotAccepts` answers a part slot
  from the item's kind before it looks at the weapon, and keeps what each weapon takes in `einv_storage_compatSets` (class names in
  lower case, config read once). `fnc_select "only"` draws no frames again when the tile is the selection already; a group makes
  footprints, shapes and pictures only when its tiles lie in one compartment (the only case `fnc_groupMode` keeps their
  arrangement).
- **What a hovering frame costs.** `fnc_updateHover` runs when the mouse moved and at every check. Where every grid (its window,
  the box its column shows, its origin, the box of its cells that show), slot and info area lies is `fnc_hoverGeometry`'s answer, kept in
  uiNamespace `einv_gui_hoverGeom` and handed out again while the lists of grids, slots and info areas are the same arrays with as
  many entries, no window or the inspect card moved, the groups they lie in (their scroll and `contentH` are read per call, a
  handful of commands) did not change, no scroll waits to be put back, and `CHECK_INTERVAL` has not passed; `force` always works it
  out again. The lookup then compares boxes (only a grid whose cells that show hold the mouse is asked, `fnc_screenToCell` with its
  4th argument so no group chain is walked) instead of walking the groups of every grid and slot. Once a tile or a slot is found,
  the box of its cell (or slot) that no earlier grid or slot reaches into is kept as `einv_gui_hoverHold` with the hover it belongs
  to: a mouse moving inside it, with the same geometry and layer, ends the call after the stamp check - no lookup, no hint, no
  name or card made again. Only a changed target does work: the light, the name at the mouse or the comparison card (a control
  made then, never per frame), the hint's text. A free cell is held like a tile ("nothing" never is: a redraw resets the hover to `[]`, and
  a held `[]` would not notice a tile that came there).
- **The hover outline.** What the mouse is on gets, besides the lighter surface of a tile, an outline in the accent colour. An item
  tile or a free cell of a grid has the frame of the Ctrl selection (`fnc_hoverOutline`: square, two pixels thick like
  `fnc_drawSelection`'s, no fill, snapped to whole pixels - round at the corner of the compartment's panel it touches, "Round corners" above): a tile around its box (`rect`, w x h cells as it lies, a turned one too)
  or, shaped, on its own cells (`fnc_uiShape` "frame", two pixels). A slot - weapon, attachment, worn gear, the small gear slots,
  hotbar - keeps the **round ring** (`fnc_uiRing`, radius = the theme's `radius` at most a quarter of the slot's height, the same
  as the slot's own panel in `fnc_drawSlot`), so the ring follows the slot's corners; only the grids' tiles and cells are square.
  A free cell of a grid that holds things (not a virtual or
  overflow grid) around that one cell (`fnc_spanRect`), found as the hover `["cell", grid, column, row]` when `fnc_tileAt` finds no
  tile - such a hover has no name and the idle hint, and nothing else reads it (the clicks and keys look at `"tile"` and `"slot"`
  only). There is one outline at a time, `einv_gui_hoverRing`, the slot's, tile's or cell's: `fnc_updateHover`'s light makes it in
  the column's group when the hover changes (so it scrolls and clips with it, and lies under the name at the mouse; a grid on the
  display itself asks `fnc_raiseTooltip`) and deletes it when the hover leaves - nothing per tile, nothing per frame. `fnc_startDrag`
  deletes a lifted tile's outline (the footprint shows instead), `fnc_endDrag` clears `hoverHold` so the next frame gives what is
  under the mouse its outline again; `fnc_redrawTiles` and `fnc_build` delete it with the groups it lay in. A tile waiting in the
  hands' queue shows it too. The round rings (`fnc_uiRing`) are the slots' outline and the border of cards and popovers.
- **What a frame of a drag costs.** `fnc_updateDrag` works out only what changed. Every frame it reads the middle button and holds
  or edge-scrolls the columns (each column's box is worked out at its first frame, element 3 of its `dragScroll` entry), then
  compares the mouse and what is held (`dragCount`, `dragRot`, `count inFlight`) with the last frame (`dragRoom` "frame"); nothing
  changed, it stops there. Mouse moved: the ghost, the counter (a rounded chip - a group of `fnc_uiPanel` and a label, `einv_gui_dragCounter`, its label in the group's variable `einv_gui_label`) and a kept group's pictures follow it. What lies under the mouse is
  read from `dragRoom` "geometry" - every slot's `fnc_slotRect` and every target grid's visible box, origin and visible cells,
  worked out at the first frame and again only after a column scrolled - and gives the "spot": the slots whose box holds the mouse,
  the grid and cell (`fnc_screenToCell`'s rule, a cell before a hole), the equipment column, or off the grids the storage column, a
  zone and the panels. Only when the spot or what is held changed do the target branches run, followed by the footprint and its
  shapes, the counter's text, `fnc_dragHint` and the `dragCheck` hook. A grid cell into which no slot, other grid or the equipment
  column reaches is held (`dragRoom` "hold"): while the mouse stays in it under the same layer (`fnc_topAt`), a frame only moves the
  ghost. Which tile lies on each cell and which cells a tile other than the lifted one takes are worked out once per drag and grid
  (`dragRoom` "cells|n") and answer `fnc_tileAt` and the free-cell test without a pass over the tiles. The answers per target stay
  (`slot|n`, `forecast|kg`, `mass`, `taken`, `backpack|n`, `fromGround`, ...). A build ends the drag and `fnc_startDrag` makes a new
  `dragRoom`, so nothing kept goes stale. With `einv_gui_debugTiming` on, `fnc_startDrag` puts `timing` into `dragRoom`, each frame
  notes its parts (scroll, ghost, find, target, hint) and `fnc_logDrag` writes `timing: drag N ms avg, N ms max over N frames (start N ms;
  slowest frame: ...; target worked out anew in N frames)` - from `fnc_endDrag`, and from `fnc_build` and `fnc_onUnload`, which end a drag without it.
- **What lies over what, and where the picture is.** The engine draws the focused control - with the group it lies in - over every other,
  so while something is held (an item, a hotbar binding) the focus goes to the search field's sink whatever has it, mouse button down or
  not (`fnc_takeFocus`, from `fnc_startDrag` and every frame of `fnc_onFrame`; a field being typed in keeps it): the ghost, the
  footprint (made before it) and the name at the mouse then lie over every column, panel and tile. The ghost is moved to the pointer less
  half its size; a position that is not a finite number (`fnc_isFinite`) is never handed to the control - the picture stays and the RPT
  says once per drag what was not a number (mouse, cell and size, picture offset).
- **The footprint under a held item.** A single item's corner is the cell its picture's corner is nearest to: the cell under the mouse plus
  `floor(across - w/2 + 0.5)` (and for rows), `across` being how far the mouse is across that cell (0 to 1, `_fnc_across`) - for an even
  width or height the half of the cell the mouse is in matters, and is part of the frame's "spot" (no "hold" then). Then it is
  **clamped into the compartment** (`0` to `cols - w`, `0` to `rows - h`): near a border the footprint stops at the edge and stays
  valid instead of hanging out red. Groups keep the arrangement they had by the middle cell of the grabbed tile.
- **A folded container takes it anywhere** (`GVAR(foldAreas)`). Over a container whose empty rows are folded away, and no cell works for the
  item (taken, or taller than the visible rows), an item from another container is laid down in the first free spot of the whole container
  when `einv_storage_fnc_hasSpace` says there is one (asked once per drag and container, "autofit|n"): the target's place is false (no cell,
  as for a kit's grid), `fnc_endDrag` sends a move without a cell and the layout finds it; the footprint is the visible compartment at half
  strength and the hint says "Goes to the first free spot - the folded rows too". The same for the fold line under the grid and the
  container's box (single items only; the fold areas' boxes are worked out with the rest of the drag's geometry). Not within one container.
- **Where it lands** (`fnc_updateDrag`; `einv_gui_dragTarget` is `["grid", gridIndex, col, row, fits, why not, "", place, unit, swap plan, cell under the mouse]`,
  `["slot", ...]`, `["kitTile", ...]`, `["hotbar", slot, ...]`, `["repack", ...]`, `["zone", ...]`, `["ground", ...]` or
  `["group", ...]`): on a grid the footprint must lie inside the compartment on free cells (a hole is red; an item's own holes
  over free cells are fine; cells a move under way goes to count as taken), another container must be able to carry it
  (`fnc_checkTouch`; `fnc_backpackIntoBackpack` is the one kind rule), and a uniform, vest or backpack never goes into itself
  (`fnc_liesIn`). On an own slot it fits when `slotAccepts` says so, and its footprint (green or red) is round like the slot - all four corners with the radius of the slot's own panel and ring (the theme's `radius`, at most a quarter of the slot's height; `_fnc_slotCorners` in `fnc_updateDrag` hands `_fnc_show` the radius in pixels and a third element true, which also rounds it for a shaped item) on weapon, attachment, worn-gear, small-gear and hotbar slots, drawn by the same six pieces as a grid footprint at a panel's corner (`dragCorners`, made at the lift); the equipment column as a whole stays a plain faint rectangle; worn gear over the same slot of another unit is exchanged
  (`fnc_canSwap`, `fnc_doSwap`); outside every panel it goes on the ground. `fnc_endDrag` hands the result to `fnc_sendMoves` (or
  the `drop` hook).
- **Tile onto tile: a swap** (`fnc_swapPlan`, `fnc_applySwap`). Where a grid drop is refused as `"NoRoom"` for taken cells - and only
  there: the whole of a stack held, nothing from a slot or a group, no kit's grid or ACE's list; a
  kit's tile, a magazine that repacks and every other answer of a tile come first - `fnc_updateDrag` asks `fnc_swapPlan` once per
  hovered footprint (`dragRoom` `swap|grid|col|row|w|h|rot|moves under way`, from the same `cells|n` the free-cell test uses). It is a
  swap when the footprint, as held, covers the cells of exactly one other tile (the rest free or the dragged tile's own) of another
  class (the same class would only merge), that tile is searched and not on its way, and it finds a free spot at the cell the dragged
  tile came from - as it lies, else turned a quarter, its corner on the dragged tile's corner; cells the dragged tile leaves are free,
  and on one compartment neither new footprint may touch the other. The usual rules hold both ways (`fnc_checkTouch` on each side,
  `fnc_backpackIntoBackpack`, `fnc_liesIn`, another player's kit via `checkTile`); a pile on the ground never loses its last tile
  that way (the engine deletes an empty pile). Weight asks nothing. The target is `["grid", ..., place, objNull, [index of the other
  tile, cell of the dragged tile, cell of the other]]` (cells `[col, row, compartment, w, h, rot]`); both footprints are drawn in the
  `accent` colour (`dragFootprint` on the new cells of the dragged tile, `dragSwapFootprint`, made at the lift, on the other tile's new
  ones, cut to what its column shows) and the footer says "Swap places with <name>". `fnc_endDrag` calls `fnc_applySwap`: within one
  container one `placeMany` of the two tiles (op `placeMany` lifts both, so each other's cells are free, and refuses as a whole);
  between two containers one move of the kind `exchange` in `fnc_sendMoves` - four steps `take A` (A's root), `take B` (B's root),
  `put A` at B's cell (B's root), `put B` at A's cell (A's root), placed in the phases by the usual rule (one phase when the roots are
  the same, else A's take, B's take and put, A's put), so through the hub as any move, each machine running its own ops with its own
  guards and reach checks. It counts for two moves in a chunk, has two records (one per tile; the answer says "moved N of 2" when one
  failed), fades both tiles and outlines both target cells while under way. Nothing is lost or doubled: a take that did not go leaves
  its tile where it is, a put that did not fit bounces and settlement (`fnc_settle`) puts the payload back where it came from.
- **Group mode** (`einv_gui_dragGroup`, `fnc_groupMode`): whole stacks, no turning, no wheel; over a grid *keep* (one compartment,
  every tile's cell free or lifted), *pack* (`einv_storage_fnc_plan` into the hovered container: an outline green, amber or red,
  "4 / 6" on the counter), *kit* (the kit decides) or *none* (into itself, a slot, a person's container the player may not put
  into). `fnc_sendPlan` sends keep and pack: tiles that stay in their holder are one `placeMany`, the others one move each with
  the planned cell.
- **Selection** (inventory only): click selects, Ctrl+click toggles, Shift+click takes the range, Ctrl+A the section
  (`fnc_selectSection`). A press on an empty cell is only a click that clears the selection (`einv_gui_emptyPress`, `[Ctrl held, mouse]`); dragging
  from it does nothing - there is no frame to drag out. Refs
  are `[holder, key, compartment, col, row]` (`einv_gui_selection`), found again on every build by `fnc_selectionTiles`; one side
  at a time (`own` or `loot`); searched tiles only. **Double click** - or the quick move key, F by default (CBA keybind `einv_gui_quickMove`, `fnc_isQuickKey`, read by `fnc_onKeyDown` since CBA's keys do not run in a dialog; both do `fnc_quickAction`; held, the key repeats and each repeat is a press: the first press of a hold (`GVAR(quickHeldKey)`, cleared by the display's KeyUp) does all a double click does, the repeats only queue - a tile that waits or is on its way costs nothing, and what opens (a nested container, a kit) or puts on is the first press's) - moves a tile over (`fnc_quickMove`: from own gear into the
  loot column's containers in order, else the ground; from loot into uniform, vest, backpack; the room is asked of `fnc_roomFor`, see below), opens a kit or nested container, or
  moves a whole selection (`fnc_quickMoveGroup`); Ctrl+click on a slot takes off (`fnc_quickUnequip`); the **drop key** (CBA
  keybind `einv_gui_drop`, G by default, read like the quick move key by `fnc_isDropKey`, modifiers respected; the footer shows it,
  `fnc_dropKeyName`, and leaves the hint out while it is unbound; no other key drops, Delete included; the hotbar's strip clear and
  the Arsenal's panel use the same key) and "Drop" put the selection on the ground - with
  nothing selected, the key drops the tile under the mouse, or the item of the worn slot there (`fnc_doUnequip` to the ground).
  Alt+click has no meaning of its own any more (it was the quick equip: putting on is a drag onto a slot, a double click on the
  ground and the menu's Equip). **Shift+click** on a stack (two or more) splits it - half onto the nearest free cell as a stack
  of its own (`fnc_splitStack`, an `applyMove` from = to with `separate`) - but only while `einv_storage_stackSplits` is true;
  with it false it is the range select as before. In the same way a drop on a free cell passes `"separate"` (`fnc_endDrag`,
  `fnc_applyMove`, `fnc_sendMoves`: the `put` and `move` steps get it as their sixth argument, a part of a stack within one holder
  becomes the op `split`). **A drop onto a stack of the same key with room left merges** (`fnc_swapPlan` answers the plan with
  `merge` true as its fourth element and the number that fit as its fifth, `fnc_updateDrag` shows the footprint in the accent
  colour and "Add to the stack of ...", `fnc_endDrag` sends it through `fnc_applyMove` with the option `"mergeInto"`
  `[col, row, compartment]` of that stack): as many join as fit (all, or what the wheel left), the rest stays where it lay; within
  one container it is a take and a put with `merge into` in one phase, across containers the `move` or `put` gets it as its
  seventh argument. A merge needs no free spot. Quick move, Take all, Sort and the group packs never ask for either option and so
  keep filling partial stacks.

### Menus, hints, the weight card

- **Context menu** (`fnc_contextMenu`, `fnc_openMenu [display, choices, at]`, `fnc_closeMenu`): a choice is `[text, args, code,
  options]`; options `icon`, `color`, `tooltip`, `enabled` (false: muted, the click swallowed, the menu stays), `separator`. What
  a tile, a slot and free cells offer is in `fnc_contextMenu`'s header; kits, arsenal boxes, radios and the hotbar add theirs.
  **The menu offers only what belongs to what is under the mouse.** A tile: Inspect, the per-item rows (Equip, Attach to / Load
  into, the magazines' Repack all, the hotbar's bind and unbind, Open / Close of a container lying there, Open kit and Unpack
  everything, a radio's Open and Use as active, other mods' CBA rows), Drop, Select all in the container, an arsenal box's Open
  arsenal; in an open kit's window Inspect, the per-item rows and Drop. A slot: Inspect, the radio rows, Drop (to the ground), a
  weapon's Take off for each part, other mods' CBA rows. A selection of several: Deselect. Free cells: Select all (an open kit's
  have no menu). There is no row for a move, for Sort or for Take off: a double click moves a tile or a selection over (a kit and
  a uniform, vest or backpack lying in a container open on it instead, so those are dragged), a drag moves it anywhere, G
  drops, Ctrl+click on a slot takes the item off into the player's own gear (`fnc_quickUnequip`), and Sort is the button on the
  caption line.
  **Settings for ...** (last row, set apart by a line): for whoever may open the wizard (`einv_setup_fnc_canOpen`, asked at every
  menu) on a tile, a worn slot, the box of an opened uniform, vest or backpack and the free cells of a crate or vehicle. It calls
  `einv_setup_fnc_openFromGame [step, class]`, which takes the step's *index*: the menu finds it by id (`"items"` or
  `"containers"`, by the item's kind: uniform, vest, backpack, crate, vehicle, kit open Containers) in `einv_setup_steps`, so a
  reordering of the pages changes nothing here.
  **Right click with a menu open:** `fnc_openMenu` keeps the menu's rectangle (uiNamespace `einv_gui_menuRect`, cleared by
  `fnc_closeMenu`); a right press beside it closes it and goes on as an ordinary right click, so the tile under the mouse gets its
  menu in the same go (on empty space nothing opens); a press on the menu and every left press are the menu's.
  **The menu's layer.** The menu is one full-screen `EINV_Group` (uiNamespace `einv_gui_menu` = `[layer]`) made last, with the
  mouse handlers the columns get, and it takes the focus into a one-pixel button on its card, as the wizard's popovers do: the
  engine draws the focused control over all others, and a column whose Sort or Take all button kept the focus after its click
  drew its tiles over the menu. `fnc_closeMenu` hides the layer and leaves its deletion to the next frame
  (`einv_gui_windowTrash`: a right press beside the card closes it from the layer's own event) and gives the focus back to a
  field that had it, else to the search field's sink. Anything registered on the display after the menu (its layer no longer the
  last of `einv_gui_created`: a slot's hover ring) makes it again on top - **`fnc_raiseMenu`**, asked twice a frame by
  `fnc_onFrame` and by `fnc_redrawTiles`: same choices and place (`einv_gui_menuState`), the row under the mouse lit.
  `fnc_redrawTiles` closes instead a menu opened on a tile of a section it drew anew (`einv_gui_menuFor`: its rows name the tile
  by its index). A build closes it as ever. The focus rule of `fnc_onFrame` also sends back a non-field control in one of the
  window's own groups once no button is held, so the name at the mouse and the inspect card are not drawn under a column either.
  The Arsenal panel's menu (guest) is the same.
- **Use from containers in the window.** While one of the settings "Use items from ..." limits something (`einv_storage_useActive`),
  a tile of the player's own uniform, vest or backpack (`einv_storage_fnc_useKind` of the grid's container) that cannot be used
  from there (`einv_storage_fnc_useState` is "blocked") wears a small padlock (`icon_lock_ca`) in its top left corner, beside the
  window's own badge if it has one (`fnc_createTile`; never in the wizard's preview), and its footer hint says "Cannot be used from
  the backpack", or - on a limited container where the item is whitelisted - "Whitelisted: can be used from the backpack"
  (`fnc_updateHover`). A tile the Strict setting keeps in the unit's hidden holder (the entry's `strict`, section 3, Strict mode)
  wears a crossed eye (`icon_eye_off_ca`) after the padlock, and the hint says "Hidden: kept out of the backpack, so nothing else
  can use it"; nothing else about it looks different. The context menu leaves out what would use it: the hotbar's bind row (it refuses, section 7), Open radio and Use
  as active radio, and CBA rows that use the item up (`fnc_cbaOptions`: the `consume` flag on `UNIFORM_CONTAINER`,
  `VEST_CONTAINER`, `BACKPACK_CONTAINER`). Moving, equipping, loading into a weapon and dropping are never limited.
- **The footer's key hints** (`fnc_drawFooter`, `fnc_uiKeyHint`): Esc Close, the quick move (the player's key, F by default - `fnc_quickKeyName` -,
  or the double click while it has none), the drop key (the player's, `fnc_dropKeyName`; no hint while unbound), the hotbar's range, Ctrl+click Select and the right mouse button Options, in that
  order. The spacing is one rule (`fnc_uiKeyHint`): every cap is the same height in whole pixels and a mouse cap is a one-letter cap's square
  with a smaller picture; the caps of one key and the cap and its words are `0.3` of the cap's height apart, the next hint `0.9`
  after the words, which are measured as they are (the label has the slack, `TEXT_SLACK`, the advance does not). `fnc_drawFooter` measures the hints first (`fnc_uiKeyHint`
  with `only measure`), leaves out from the last backwards what does not fit before the version, Esc staying, and hides the hint line
  (`einv_gui_hint`) when less than `UNIT * 6` is left between the hints and the version; contextual hints (R rotate, the drag's keys) come in the hint line, not here. A mouse button in a key hint is ACE's own
  picture, not words: a key string may carry the tokens `@left`, `@right`, `@scroll` and `@double` (two left clicks), alone or after
  modifiers joined by `+` (`"Ctrl+@left"`: a key cap `Ctrl`, then a cap with the mouse picture). The pictures are
  `\z\ace\addons\interaction\UI\mouse_left_ca.paa`, `mouse_right_ca.paa` and `mouse_scroll_ca.paa` (`MOUSE_ICON_PATH`; ACE has no
  double click or middle button picture); a picture that is not there (`fnc_safePicture`) falls back to the words ("Right click").
  There is no card of keys at the mouse any more (0.4.24 had one; it was taken out again).
- **A hotbar slot's binding is dragged** (`fnc_startStripDrag`, `fnc_updateStripDrag`, `fnc_stripTarget`, `fnc_endStripDrag`;
  `einv_gui_stripDrag` = `[slot number, ghost, strip box, ghost offset, ghost size]`): a press on a filled slot of the strip
  (`fnc_onMouseButton`) records `einv_gui_press` with the slot's number as its tenth element, and `fnc_onFrame` starts this drag
  instead of `fnc_startDrag` once the mouse moved. The item's picture follows the mouse as a ghost the size of the slot (it fades
  where it would be removed), the slot under it lights up as any hover does, and the footer says what letting go does (`Hint_Strip*`).
  Let go on another slot: `einv_hotbar_fnc_moveSlot` (the two swap); anywhere outside the strip's box (the slots' union, a margin
  around it): `einv_hotbar_fnc_unbind` (the item is not touched); on the strip between its slots: nothing. The press stays
  in `einv_gui_press` meanwhile, so nothing is built; a build, the window closing or another window covering this one ends it
  without a change.
- **Keys held back.** What `fnc_onKeyDown` has no use for goes no further than the window (inventory only; it returns true, so the engine
  does not act on it): not to the soldier's actions, the weapon, ACE's or another mod's keys behind the window. What stays the engine's:
  Escape (it closes the dialog), PrintScreen, and talking - the keys of the actions in `PASS_ACTIONS` (Chat, the push to talk family,
  VoiceOverNet, NextChannel, PrevChannel), which is how TFAR's and ACRE2's keys still reach their mods - and a key typed into a field
  (decided earlier). Mouse buttons and the wheel are left as they were: the display's mouse handlers answer true only for what the window
  took, since an answer of true on every click would keep the window's own buttons from their clicks.
- **Hints:** `fnc_updateHover` names what the mouse is on in the footer; `fnc_showHint [text, colourKey]`; `fnc_flashHint [reason,
  details]` (a reason key such as `"NoRoom"`, `"LookOnly"`, `"Locked"`, `"NoBackpack"`, any other text as it is, `""` nothing);
  `fnc_dragHint`; `fnc_infoHint [kind, args]` for the weight card and each caption. The **inspect card** (`fnc_inspect`,
  `fnc_drawInspect`) and the **comparison card** (`fnc_compareRows`, `fnc_drawCompare`, `einv_gui_compareTooltip`: over a vest,
  uniform, helmet or backpack that is not the soldier's own, "vs. <worn item>" with Armor, Covers, Space, Weight) float over the
  columns. **The name at the mouse lies over every highlight.** It is one label (`fnc_makeTooltip`, made by `fnc_drawTopLayer` after
  each build, uiNamespace `einv_gui_tooltip`), and the engine draws what is made later over what is made before, so a ring made on
  the display after it - the hover ring of a slot that lies on the display, as the equipment's gear row does (a slot in a group has
  its ring in that group, under the label) - would cover it. `fnc_raiseTooltip` makes the label (or the comparison card, from
  the rows kept on it) again when something live was made after it; `fnc_updateHover` asks after it made a ring on the display and
  `fnc_drawSelection` after its frames. It does nothing while a menu is open or an item is dragged (the name is hidden then), and it
  never uses the focus: the engine draws a focused control over everything, which is why the focus rule of `fnc_onFrame` sends
  it back. The **search field** (`fnc_drawFilter`, `fnc_applyFilter`) dims non-matching tiles; a category chosen at a loot box's side hides them (see "Section bars").
- **The weight card** reads `einv_weight_fnc_getLoad` (ACE's total, the rules' weights and EFAK's kits included), the limits and
  the tier. The bar has no tick marks or zone strip; it fills by load over the Critical limit. The fill, the tier's words and the
  preview take **`fnc_weightColor [unit, load, theme]`**: `text2` in Light, `accent` in Heavy, `loss` in Overloaded and Critical,
  blending into the next tier's colour over the last 6 % of the bar before its limit. The right text is the tier and its effect
  ("Heavy · jogging tires you", `einv_weight_fnc_tierText`); the left the load and where the next tier starts ("12.4 kg · Heavy at
  26.7 kg", `Load_Next`; nothing at Critical); on a narrow column the next limit goes first, then the effect. Lifting something
  from outside the soldier's own gear (`fnc_isOwnStorage`) puts a **preview** of the added weight on the bar
  (`einv_gui_weightBar`, `fnc_previewWeight`, `fnc_clearWeightPreview`) in the colour of the tier it lands in, and the hint says
  "+2.4 kg: you will be Overloaded (46.9 kg)" (`fnc_weightText`) - a forecast, never a refusal.

### Searching, sounds, moving stops looting

- **Searching** (`fnc_isSearched`, `fnc_markHidden`, `fnc_animateSearch`, `fnc_updateStatus`, `fnc_stopStatus`, `fnc_revealTile`, `fnc_learn`): loot
  of the kinds the settings name (bodies, persons, containers, ground; never the player's own gear, an object with
  `einv_noSearch` - see "Leaving an object out" below -, an ACE arsenal box) shows as **diagonally striped tiles** until searched, `einv_gui_searchTime` seconds per cell. An unsearched tile is a
  surface a step above an empty cell with `hatch_ca` stripes over its whole footprint (`fnc_createTile`, `fnc_uiHatch`: pieces of about a cell, so a wide tile keeps
  the stripes' angle; a shaped one run by run; a tile at a round corner of its panel is hatched a third of the corner's radius in from that corner, a square piece
  would stick out over the arc) - no "?", no outline, no ring and no glass on the tile: two controls for a one-cell tile, as the "?" tile had. What a player
  knows is counted per container and class (local), in the arrangement's order, so everyone reveals the same top-left ones; what
  you put in you know. The queue entry is `[container, class, row, col, cells, block]`, revealed one item at a time, the first of the first box that is not
  stopped; a found tile is drawn anew in place (its stripes go, the flash comes), a build only when the section's first find brings Take all. A frame of searching
  costs the same however much is still hidden: a clock, the sound's own clock, and the chip. **The search is told in the box's caption line only**
  ("Section bars: the activity chip", under "Layout"): a ring that goes round, "Searching 0:07" - the time that is left of the box's items, their cells times
  `einv_gui_searchTime`, less what the item being searched has run, written once a second (`fnc_animateStatus`) - and a red cross. The cross stops the search
  of that box (`fnc_stopStatus`: its container is in `GVAR(searchPaused)`, which `fnc_animateSearch` passes over; the window's own state, empty for every window);
  a stopped box says "Stopped 0:07" with a still ring and a button "Search" that takes the container out of the list again. A hidden tile of a page not shown has
  no controls: `fnc_findTile` does not find it, `fnc_revealTile` only takes its hatching from the data. **The search field** (`fnc_drawFilter`,
  `fnc_applyFilter [jump]`) dims the tiles that do not match; it looks at every page of a
  paged box (`fnc_pageCounts` reads all the grid's tiles): typed in or emptied (`jump` true) it turns each paged box to its first page with a match when the page it shows has none
  (`fnc_setPage` with `bySearch`, remembered in `GVAR(pagesMoved)`; those pages go back box by box once nothing filters the box, but not one the player turned since), and draws every bar again - the arrows'
  marks count the matches before and after the page, the bar's text counts the matches on other pages. **The categories at the side of a loot box** work
  through the same function: `GVAR(groupFilters)` (`[[container, group], ...]`, one pair per box that has a category chosen, empty for every window) is read by
  `fnc_applyFilter` per grid (`fnc_boxGroup`) - a tile not of the box's category (`fnc_matchesGroup`) is hidden, one the field does not find (`fnc_matchesFilter`) is dimmed (0.5.7) -, by
  `fnc_pageCounts` (the matches per page, so the arrows' marks and the jump to the first page with a match work for a category as they do for a word) and by the
  folded sections' tab tint. Every place that redid the fading when `GVAR(filter)` is not empty does so when a category is chosen too.
  `fnc_drawPageBar`'s words ("matches on other pages") go by the field **or** the box's category (0.5.7): with only a category chosen the bar says how many matches lie on the
  other pages, as for a word. Whether a box is filtered is per box (the field is every box's, a category the one box's): when a box is filtered no more - the field empty and its
  own category cleared - `fnc_applyFilter [true]` gives it back the page the jump moved it from (`GVAR(pagesMoved)`), also while another box still has a category chosen; the entries
  of boxes that are still filtered stay.
- **Sealed containers of bodies and persons** (issue #6, `fnc_isSealed`): a body's or living person's uniform, vest or backpack
  (`einv_storage_fnc_getOwner` a `CAManBase` that is not the player) that `fnc_isSearched` says must be searched and this player has
  not unsealed (`einv_gui_unsealed` on the container, local, never broadcast) is drawn **sealed** by `fnc_drawSection`: beside its box
  one block of `STORAGE_COLS` x `SEAL_ROWS` 3 cells whatever the container is, on the caption's surface (`lootTab`) with the
  unsearched hatching, a ring, "UNSEARCHED" and a line of what its search does. No compartments, tiles, weight, Take all, Sort,
  category strip, load hint (`infoAreas`), no canvas widening, and `fnc_putAllTarget` leaves it out - nothing tells its size or
  contents. **The state flows through the queue as any box's:** `fnc_drawSection` calls `fnc_markHidden [container, entries, true,
  true]`, which queues the hidden items and after them **the seal**, `[container, "", 0, 0, SEAL_CELLS, SEAL_BLOCK]` (1 cell of search
  time, block 98 so `fnc_build`'s sort puts it last; also for an empty container), with the same "Search starts on click" waiting
  (`searchSeen`/`searchIdle`/`searchPaused`). The caption chip starts, stops and resumes it (`fnc_stopStatus`, the clicked box first);
  with search-on-click a hit box over the block starts or resumes it too (never stops). `fnc_animateSearch` finds the items as ever -
  `fnc_learn`, the "uncover" sound - but `fnc_revealTile` finds no tile and only takes them out of the queue; when the seal's time is up
  it sets `unsealed`, plays the container's "open" and builds the window, which draws the real grid with everything known. While
  sealed `fnc_updateStatus` writes the block's line from the section info's `seal` (`Seal_Click` idle, `Seal_Searching` while it is the
  box being searched - its ring shown and turned by `fnc_animateStatus` -, `Seal_Stopped` / `Seal_StoppedClick`, `Seal_Waiting`) and
  `fnc_animateStatus` leaves the time out of the chip (`Status_Search` with no clock): the time left would tell how much it holds.
  **Cheap redraws:** `fnc_getSignature` gives a sealed loot section `[number, "sealed"]` instead of its cargo, so a sealed container
  never redraws for what changes in it and its unsealing changes the part; `fnc_redrawTiles` answers false for a sealed info (`sealed`
  in `sectionInfo`), so that change builds. Crates, vehicles, the ground, a bag lying about and containers opened from inside one
  keep the hatched tiles.
- **Leaving an object out of the search** (0.5.12). The one mark is the object variable `einv_noSearch` (`QGVARMAIN(noSearch)`, a BOOL, default false), read by `fnc_isSearched` for the container and for the body or person that owns it, so it holds for a crate, a vehicle, a body, a living person and the things they wear; every other question (`fnc_markHidden`, `fnc_learn`, `fnc_openNested`, the cargo chain of compat_ace_cargo) goes through `fnc_isSearched`. It is an override in one direction: it can switch the search off, never force it on where the settings say off. Ways to set it: (a) **Eden**: the attribute `einv_gui_edenNoSearch` (`gui/Cfg3DEN.hpp`, Checkbox "Skip searching", on every object with inventory cargo, in the locks addon's category `EINV_Attributes`, which gui loads after); its expression sets the variable locally on every machine when the mission starts (not in the editor), which needs no broadcast and covers a joiner. (b) **`einv_gui_fnc_setSearchable [object, searchable]`** (public): `false` marks the object, `true` gives it back to the settings; `setVariable` with the broadcast flag, so it works from any machine and for JIP. (c) **Zeus**: the server setting `einv_gui_searchZeus` (CHECKBOX, default on, in the "looting" topic after `searchContainers`) - with it off `fnc_onZeusPlaced` marks every non-person object with `maxLoad > 0` that a curator places. The handler is on the "CuratorObjectPlaced" event of every curator module, put there by `fnc_hookCurators`, which a 5 s per-frame handler in `XEH_postInit` calls on every machine (a game master can be assigned at any time and the event fires where the module is local, which differs by setup); the variable is public and the same from every machine, so a double run is harmless. compat_zen adds the right-click choices "Searching: turn off" and "Searching: turn on" (`fnc_setSearch`, `fnc_canSetSearch`; each is shown while some target would change, targets are `fnc_targets`: crates and vehicles, no persons), which call `fnc_setSearchable` and show the curator feedback line.
- **Sounds** (`fnc_playSound [action, class, container, world, ui]`, public): by family from the config `CfgEinvSounds`
  (`gui/CfgEinvSounds.hpp`; its header explains the layers): `Default`, 17 item families and 4 container families (crate, vehicle,
  body, ground), Arma's own files only; the family is the item's config `einv_sound`, else `fnc_soundFamily`. Actions: `lift`,
  `move`, `drop`, `equip`, `unequip`, `attach`, `detach`, `loadMag...`, `unloadMag`, `rotate`, `open`, `close`, `search`,
  `uncover`, `inspect`, `giveBack`. The looter hears them on the UI channel at the volume of their kind
  (`fnc_soundGain [action]`; there is no master volume since 0.5.5); others within the action's range hear a quieter copy (`einv_gui_soundsWorld`: `fnc_sendNoise` -> the target
  event `einv_gui_noise`, `fnc_onNoise`; never from the Arsenal) which the volumes below do not scale: they are only the looter's ears.
  **The speaker in the header** opens the **sound dropdown** (`fnc_openSoundMenu`; there are no client CBA settings for sound). The kinds
  (`fnc_soundGroup [action]` -> one of `einv_gui_soundGroups`): `moves` (lift, move, drop, equip, unequip, attach, detach, rotate, giveBack and any other
  action), `magazines` (the `loadMag...` actions, `unloadMag`, the reload's own sound in `fnc_playReload` as "reload", the repack's finished sound as "repack"),
  `containers` (open, close), `search` (search, uncover) and `other` (inspect, and "warn": the click of a refused opening in `fnc_onInventoryOpened`, the Arsenal's
  blocked sound in `einv_arsenal_fnc_showBlocked`). State: `einv_gui_soundLevels` (per kind `[volume 0..1, volume to come back to]`; a kind at 0 is off),
  written to the profile as `einv_gui_soundMix` = `[1, levels]` by `fnc_soundSettle` when the dropdown closes (the first number was the master volume; it is written as 1 for the sake of the format, and a saved one is worked into the levels once in `XEH_preInit`) (and by
  `fnc_onUnload`; never per frame) - `einv_gui_soundDirty` says there is something to write. `fnc_soundSet [mode, argument]` is the one place that changes them ("volume"
  `[index, v]`, "toggle" index - off sets the volume to 0 and keeps the old one, on brings it back -, "all": mute everything or, when nothing is audible,
  bring it all back; only the speaker's right click, the dropdown has no button for it) and then updates the open dropdown (`fnc_updateSoundMenu`, in place) and the speaker (`fnc_updateSoundButton`).
  `fnc_soundMuted [action]` is `fnc_soundGain <= 0` (action "" asks about everything: what the speaker shows). `fnc_playSound` and `fnc_playReload` scale their layers
  with `fnc_soundGain`; the three sounds played by the game's `playSound` (the refused opening's click, the blocked arsenal, a repack's finished sound) go through
  `fnc_playClass [CfgSounds class, action]` (public), which reads the class's file, volume and pitch and plays it as a layer at the scaled volume (`playSound`
  itself if the file cannot be found and the kind is not silenced). The dropdown is the context menu's machinery: a layer in `einv_gui_menu`, `einv_gui_menuRect`,
  `einv_gui_menuFor = ["sound", -1]` and `einv_gui_menuState = ["sound"]`, so Escape, a click or right press beside it, `fnc_build` and the
  `fnc_raiseMenu` of `fnc_onFrame`/`fnc_redrawTiles` (which makes it again from the current volumes) treat it as a menu, and `fnc_closeMenu` calls `fnc_soundSettle`
  when it closes it. A click on the speaker while it is open lands on the layer's hit area and closes it. The card (0.5.5) is a small one: a shadow, a one-pixel border and the card inside it, darker than the panels (`0.015` grey, opaque) so it separates, right-aligned to the window's right edge
  (`CONTENT_X + CONTENT_W`, flush with the Close button: Mia, 0.5.7) `UNIT * 0.5` under the header and never above its line; it is `UNIT * 14` wide with one rhythm inside - `UNIT * 0.6` padding left and right,
  `UNIT * 0.45` between the switch, the name, the slider and the percentage, the track ending at the knob's middle at either end, a row's hover film inset by half the padding and round -, its rows are `UNIT * 1` high with a `UNIT * 0.55` font, and everything is neutral - white and grey checkboxes, tracks
  (`[1,1,1,0.12]`) and fills, the accent is not used. Sliders are a track, a fill and a knob with a hit area (`einv_gui_soundRows` is the list of rows for `fnc_updateSoundMenu`); a left press
  starts `fnc_soundSlide ["begin", ...]` (the mouse is read with `getMousePosition` there and at every move - 0.5.7 took it from the events' arguments, which were not in the space of the track's place, and gave only 0 and
  100 %; the volume goes in steps of `SOUND_STEP` 0.05), which adds `MouseMoving`, `MouseHolding` and `MouseButtonUp` to the display for the drag (the way `fnc_dragHandle` does) and plays
  a sample of the kind when the button is let go. The profile variables `einv_gui_muted` (and `einv_gui_searchMuted` before it) are read once, only when no `einv_gui_soundMix`
  is saved: a muted speaker then starts with every kind off.
- **Moving stops looting** (`einv_gui_moveToStop`): a movement key closes the window while it was opened on something or a search runs
  (not keys with Ctrl or Alt; `fnc_onKeyDown`), and `fnc_checkTaken` (every `CHECK_INTERVAL` from `fnc_onFrame`) closes it with the
  reason `"taken"` when the soldier was taken away from what he looted - into a vehicle, handcuffed or surrendering by ACE, dragging or carrying, or
  moved more than `TAKEN_LEASH` 1.5 m from where the window opened (seated, `einv_storage_fnc_inReach` of the vehicle and what he opened).
  There is no looting pose: the soldier keeps whatever stance and animation he has (the looting animation of 0.4.x, `einv_gui_animation`, with its
  `fnc_poseStart`, `fnc_poseCheck`, `fnc_poseEnd`, `fnc_gesture`, `fnc_raiseWeapon` and the rest, was taken out before 0.5.0 was released; a settings box
  that still names `gui_animation` reads clean, `einv_main_retiredSettings`). A magazine into the weapon in the hands (`fnc_playReload`) plays its
  `reloadAction` with `playActionNow` (`fnc_reloadGesture`: player, local, on foot, `currentWeapon`, not while ACE reloads or holds him).

### People, the CBA menu and other mods in the window

- **Living persons.** Every soldier carries one scroll action per client (`fnc_addPersonAction`; agents through the player's
  `fnc_addAgentAction`); `fnc_openPerson` (public) opens the window on the whole person and tells them (`fnc_notifyPerson`).
  `fnc_canOpenPerson [person]` -> `"whole"`, `"backpack"` or `""`; `fnc_canTouchPerson` takes `"items"` or `"worn"`; the server settings
  `einv_gui_personOpen`, `personItems`, `personWorn`, `personNotify`, `searchPersons` decide. The rule on the machine that runs
  each change is the guard `fnc_personGuard` (in `einv_storage_guards`); the looter's `fnc_checkTouch` returns a reason
  ("LookOnly") for the hint. A locked uniform, vest or backpack stays on them; the window closes beyond `PERSON_KEEP` 4 m. Bodies
  open whole from "Inventory" and from the backpack they wear. `einv_locks_fnc_decorate` is called by `fnc_build` right after the
  loot sections are read.
- **CBA item context menu.** Other mods' options of `CBA_fnc_addItemContextMenuOption` appear in the menu of a tile in a real
  container and of the player's own slots (`fnc_cbaTileTarget`, `fnc_cbaSlotTarget`, `einv_gui_cbaSlots`). `fnc_cbaOptions [unit,
  container, item, cbaSlot]` reads them exactly as `cba_ui_fnc_openItemContextMenu` does (the first option of an id wins; shown
  when the slot matches and the show condition agrees, greyed when the enable condition says no); `fnc_cbaRun [condition,
  statement, consume, args]` runs one (`true` reopens the menu where it was, anything else asks `fnc_requestRebuild`). Compat
  addons hide theirs, one guarded line each. A double click never opens the CBA menu.
- **Compat helpers.** `fnc_compatCollect [names, args]` calls every function of a list that exists and joins what they return; the
  window never names another mod's function, it asks `[QEFUNC(compat_tfar,x), QEFUNC(compat_acre,x)]`. `fnc_stepAside [code,
  args]` is for a dialog that does not open over another (TFAR, ACRE2): the window closes, the code runs `STEP_ASIDE_DELAY` 0.2 s
  later, and the window opens again on the same unit and containers when that dialog closes.

- **Opened containers follow their object.** `fnc_build` keeps an `opened` entry only while `everyContainer` of the container it
  was opened from still lists it: put on, taken into a crate or dropped elsewhere it drops out at once, with whatever was opened
  from inside it (a worn one shows in the storage column). Only while one of its class still lies there is it taken for one made
  anew and looked for by its key (`ANSWER_WAIT`); ACE cargo crates (`einv_compat_ace_cargo_openedFrom`) stay with `fnc_pruneOpened`.
- **The storage column takes what is worn there** (`einv_gui_storageRect`, from `fnc_drawColumn`): a uniform, vest or backpack let
  go on it off its grids is `["slot", -1, ..., slot]` - put on by `fnc_doEquip` (the worn one comes off onto its cell), a body's
  exchanged (`fnc_canSwap`); the footprint lies faint over the column. Wearing none of the three, anything else there is `NoFit`.
- **An opened container's box is its tile.** Its slot record carries the container (element 8, `fnc_drawSlot` option `container`);
  `fnc_boxTile` finds that tile in the parent's grid, and the box is pressed, dragged, clicked and hinted as it
  (`fnc_onMouseButton`, `fnc_updateHover`). Both inventory only.

## 5. ACE Arsenal panel (arsenal)

ACE Arsenal is the arsenal; nothing of ACE is patched or replaced. While the uniform, vest or backpack tab of ACE's left bar is
open (and the unit wears it), a panel right beside ACE's list (IDC 15) shows that one container's grid and a staging space, drawn
by the gui addon's window engine attached to ACE's display as a **guest**. The addon requires `ace_arsenal` (it is not skipped
when that is missing: the game should say so) and `A3_Functions_F_Bootcamp`, which makes the entry for `BIS_fnc_arsenal` load
after BI's. The ACE internals it reads are copied under names of ours in `arsenal/script_component.hpp` (display 1127001; IDCs 15
list, 17 sort bar, 102 "+", 701 load bar, 2010 / 2012 / 2014 the left tabs;
`ace_arsenal_currentLeftPanel`, `currentItems`, `mouseButtonState`, `virtualItemsFlat`; the row data `lnbData [row, 0]` and
`lnbValue [row, 2]`). `fnc_compatCheck` looks once at preInit whether they exist (`ACE_TESTED` "3.21.2"; another version gets one
RPT line); not ready, ACE Arsenal opens without the panel. Its known limits are listed in section 9.

### Lifecycle and events

Registered in preInit, so Eden has them too.

| Event | Does |
|---|---|
| `ace_arsenal_displayOpened` | `fnc_onOpened`: state reset, `KeyDown` / `KeyUp` and the list's `LBSelChanged` / `MouseButtonDown` handlers, and `einv_gui_fnc_attach` a frame later (one more if the inventory is still closing), driver `"draw3d"` |
| `ace_arsenal_displayClosed` | `fnc_onClosed`: `einv_gui_fnc_onUnload`, state reset, the BI helper and the staging crate deleted a frame later, `fnc_dropOverflow` (what still lies on no cell is taken out, RPT INFO and ACE's text; a unit not local here keeps `einv_storage_fnc_requestMigrate`, the surplus moves on) and `fnc_reportOverflow` a frame later (not in Eden) |
| `ace_arsenal_cargoChanged` | `fnc_onCargoChanged`: what of an add the engine refused by `maximumLoad` is put in with `einv_storage_fnc_addNew` while there is a free spot; flags the frame-later pass |
| `ace_arsenal_itemsChanged` | `fnc_onItemsChanged`: for the open container's tab `fnc_reconcile` at once, before ACE greys its list |
| `leftPanelFilled`, `rightPanelFilled`, `loadoutImported`, `onLoadoutLoad`, `showToggle` | `fnc_settle` a frame later |

A loadout loaded in ACE Arsenal reaches the unit through `CBA_loadoutSet`, where the storage addon adds what the engine left out of a container for its
`maximumLoad` (`fnc_topUpLoadout`, the storage section "Loadouts"); the panel then shows it at the `onLoadoutLoad` settle. The folded panel is one button
(`fnc_layout`): the panel's colour as its surface, lighter under the mouse, no inner square or frame, and a `SetFocus` handler that hands the focus
to ACE's list so the engine draws no focus frame.

The hook table (`einv_arsenal_fnc_hooks`, section 4) sets `guest`, `header` (none), `layout`
(`fnc_layout`), `footer` (`fnc_footer`: the hint line), `camera` (none: ACE's), `keepOpen` (true: ACE decides when it
closes), `frame`, `mouseDown` / `mouseUp` (`fnc_onMouse`: outside the panel taken, so the engine ignores it), `click`
(`fnc_onClick`: double, Ctrl and Alt clicks swallowed - no equip or quick move past ACE), `wheel`, `dragCheck`, `drop`, `ground`
(-> `fnc_remove`), `fold`, `menu` (Remove, Remove all of this kind) and `hint`. `fnc_onKey` hands the engine only R while dragging
and the drop key (`fnc_isDropKey`) over the panel, never while a field has the cursor. A drop outside the panel never goes to the ground: it takes the
item out.

### The panel

- **Rect** (`fnc_panelRect`): top at ACE's sort bar (IDC 17, else the list's top), bottom at the list's bottom, like ACE's right
  column; width `STORAGE_COLS` cells of `einv_gui_fnc_getCell` plus padding and scroll bar, at most `PANEL_MAX_SHARE` 1/3
  of the screen. `fnc_layout` draws it the way the inventory's columns are drawn: one block of Glass - the theme's `panel` and
  `radius` - laid out in UNITs on one grid, `PANEL_PAD` 0.4 UNIT of room round the content and between the bands (as many pixels wide as high),
  so the picture, the section captions and the grids start on one left edge and the loads end on one right edge. **Title row** at the top: the
  container's picture (`getInfo "picture"`) `TITLE_H` high and square, its name in the theme's bold font at `TITLE_SIZE`
  with its capitals centred in the row's height (`TEXT_MID`), and under the row a hairline in the theme's `line` colour 0.4
  padding below it, as `fnc_drawColumn` draws it. **Sections** in `einv_gui_fnc_drawColumn`
  (id `"storage"`): the open container, then staging; both with `"box"` false, so `einv_gui_fnc_drawSection` draws no picture
  box and the grid starts at the left edge (the inventory keeps its boxes). The caption lines are the inventory's - chevron, tab, load
  right-aligned, the staging space's subtitle in the same 0.46 UNIT; no Take all, Put all in or Sort there (the inventory only). The column
  reaches down to the **hint line**, the block's last band: no box of its own, a hairline over it, `EINV_ArsenalHint` at `HINT_SIZE`,
  a line `HINT_LINE_H` high with `HINT_PAD` above and below - one line, two while staging holds something (the note, in the
  accent colour, from the `hint` hook; the idle text is cut to one line, Ctrl+wheel only where it fits beside). ACE's list is
  registered as the zone `"remove"`.
  The panel's own texts are in **ACE's grid** (`ACE_GRID_H` = `pixelH * pixelGridNoUIScale * 0.25`, 4 px at 1080p at every UI
  size), as ACE's list rows beside them (7 units, 28 px): `TITLE_H` 7.5 (30 px), `TITLE_SIZE` 4.5 (18 px), `HINT_LINE_H` 5.5
  (22 px), `HINT_PAD` 2 (8 px), `HINT_SIZE` 3.75 (15 px, class `EINV_ArsenalHint`, a child of `EINV_FooterHint` in
  `RscArsenal.hpp`). At 1080p that is what the UNITs gave to half a pixel; UNIT (screen height / 40) and ACE's whole-pixel grid
  do not keep one ratio across resolutions, so UNIT-sized texts stood off ACE's on some screens. `PANEL_PAD` (0.4 UNIT), the grid
  cells and the section captions (drawn by `einv_gui_fnc_drawSection`, 0.46 UNIT; the staging subtitle shares their baseline)
  stay on the engine's UNIT.
- **Folds.** A caption's chevron folds its section (the `fold` hook), kept per container class - lowercase, the staging space as
  `"staging"` - in `einv_arsenal_folded` while ACE's window is open: ACE makes a new uniform, vest or backpack for every one
  picked, so folding per object would be lost. `fnc_layout` notes `foldKeys` `[[container, key], ...]` and sets each section's
  `folded` to `key in folded` XOR `container in einv_gui_collapsed`, so the inventory's own list is never touched.
  **A tab switch folds anew** (issue #3): `fnc_layout` keeps the tab the folds were last set for in `GVAR(foldTab)` - ACE's
  tab id (`fnc_selected`, "" for a tab without the panel) or `"kit:" + class` while a kit's sections show -; when it changes,
  `GVAR(folded)` is emptied but for `"staging"`, so the picked container (or the kit's sections) is open, the other worn containers
  folded, the staging space as it was. Order and scroll are untouched. `foldKeys` is emptied before `fnc_kitSections` notes the
  kit sections' keys, so the `fold` hook finds them (a kit section did not fold by hand before).
- **Other worn containers.** `fnc_layout` adds the soldier's other two containers as sections between the open one and the staging space,
  folded to their captions (key `"other_" + class` in `einv_arsenal_folded`; present = unfolded), so items can be dragged between all three;
  the staging space is one shared area in every tab. `fnc_addTo`, `fnc_remove`, `fnc_removeKind` and the drop's watch accept them like the staging
  space (ACE is told only of the open container).
- **Folding the whole panel** (`fnc_toggleCollapse`). Folded, the whole
  panel is a small square button with the inventory's picture (at the right edge of the panel's rect, a click unfolds it); the text below
  that speaks of a title row when folded is out of date. The open panel's fold button is a round button (`EFUNC(gui,uiButton)` in `headerStyle`'s colours, as the inventory's header buttons; hit area = button + 2 px) at the right end of the title row, `TITLE_H` square, chevron down while open and right while folded, its tooltip "Fold the panel to its title bar" / "Unfold the panel"; the container's name ends a gap before it. `GVAR(collapsed)` is the state: set in preInit from `profileNamespace` (`einv_arsenal_collapsed`, written on every toggle, saved by the game with the profile), so it holds through tabs and later openings. `fnc_layout` folded makes only the glass, picture, name and button: no hairline, column, staging crate (made when the panel unfolds), hint line (`hintRect` stays `[]`, so `fnc_footer` and the `hint` hook do nothing) or ACE-list zone, and the panel's rectangle (`panelRect`, `EGVAR(gui,panels)`) is the row with `PANEL_PAD` under it - so `fnc_isOver`, the mouse hooks, the wheel and the focus sink see only that, and no control is left over ACE's own. It is one build when toggled (`buildSoon`, a frame later through the button), never one per frame. The column's scroll is noted in `GVAR(collapsedScroll)` `[container class, pixels]` from the engine's `keepPixels` (the build before the fold still had the column) and put back into `keepPixels` when the same class unfolds. **Unfolding under a drag:** an item dragged from ACE's list (`fnc_listDrag` notes its class in `GVAR(listDragClass)`) over the folded row gets the hint "Hold it over the title bar to unfold the panel" (`fnc_dragCheck`); `fnc_onFrame` counts `UNFOLD_HOVER` 0.6 s on the row (`GVAR(unfoldSince)`), then `fnc_toggleCollapse [0, true, true]` builds at once - which ends the drag, as every build does - and the row (found again by its class) is lifted again with `fnc_listDrag` while the button is still down. A drop on the folded panel does nothing. **Closing:** the question of `fnc_confirmClose` does not depend on the panel, so it works folded; its Keep editing (`fnc_closeConfirm`) unfolds the panel for the session (not in the profile) as the things that do not fit lie in its grid.
- **Staging space** (`fnc_staging`): `Box_NATO_Support_F` by `createVehicleLocal` at the first draw, hidden, no simulation,
  emptied, at the unit's feet (in reach), `einv_noSearch`, **`einv_storage_localOnly`**. Only for a soldier whose moves the
  storage runs on this machine at once (`fnc_isLocalRoot`: the player's own unit, any unit in single player and Eden); objNull for
  any other. Because `localOnly` objects count as local roots, moves between the container (root: the player) and staging (its own
  root) run here with the normal reach, lock and verify checks. Its grid grows (`fnc_growStaging`, from `fnc_layout`'s drawer
  just before its section): `einv_grid = [[STORAGE_COLS, rows]]` with rows = the lowest row in use (plus the heights of overflow
  entries) + `STAGING_FREE_ROWS` 4, at least `STAGING_MIN_ROWS` 10 and the rows that fill the column down to the hint line, at
  most `STAGING_MAX_ROWS` 100 (its own cap, since `MAX_ROWS` 40 also bounds item and compartment sizes in the rules); rows past
  the column scroll; `getBlocks` takes that form exactly. Section id `"staging"`, side `"own"`, a crate icon (`tabIcon`) before
  its caption. `fnc_onClosed` deletes it with its contents. `fnc_onDrop` notes `einv_arsenal_watch` `[container, [[class, count], ...],
  until]` and the frame hook calls `fnc_syncAce` and `fnc_tellAce` once the count changed (`WATCH_TIME` 3 s at most). The staging
  crate is no section of the soldier's (`GVAR(context)` "ownSections"), which the engine's signature reads (`fnc_getSignature`), so a
  move that only rearranged it - a tile moved or turned inside the staging space - was never seen and its tiles stayed where they were
  drawn: the next lift found nothing at the old cell ("Someone else was quicker"). The `signature` hook names the crate
  (`[einv_arsenal_staging]`), its cargo and places go into the "storage" part, and a change there builds the panel.

### Closing with things that do not fit

While ACE's window is open the entries of a uniform, vest or backpack with no cell stay what they are, red tiles shown apart
(`fnc_findOverflow` lists them as `[container, entry]`; `fnc_checkOverflow` only names the containers). When the window closes
they are **taken out**, not left in or moved on, and the player is asked first.

- **Taking the close over** (`fnc_interceptClose`, from `fnc_onOpened`). ACE closes with script handlers of its config: the Close
  button (IDC 1001, `onButtonClick` = `closeDisplay 1`) and the display's `onKeyDown` (`fnc_onKeyDown` of ACE, which ends Escape in
  `closeDisplay 2`). A display cannot be kept open once `closeDisplay` ran, so both are set anew: `ctrlSetEventHandler ["ButtonClick"]`
  on the button (`fnc_onCloseButton`) and `displaySetEventHandler ["KeyDown"]` on the display (`fnc_onAceKey`, looked up with
  `supportInfo` and called through `compile`, so a game without it still loads the file). `fnc_onAceKey` takes Escape - not while
  ACE's loadouts display (IDD 1127002) is open, which closes itself on Escape - and hands every other key to
  `ace_arsenal_fnc_onKeyDown` as `["onKeyDown", _this, "ace_arsenal_display"]`, returning its answer. A missing piece is said once
  in the RPT and the close then goes the old way (below).
- **The question** (`fnc_confirmClose [display, exit code]`). Without overflow, with a unit that is not local here, in Eden or with
  the panel not `ready` it is `closeDisplay` at once. Otherwise a card on ACE's display, built like the red screen's (a controls
  group made with `ctrlCreate` and held in uiNamespace `einv_arsenal_confirm`, so the engine's sweep leaves it alone; a dimming
  and a full-screen `EINV_Hitbox` under the card take the mouse from ACE's controls): "N items do not fit your gear and will be
  removed: <names x count>" (six names at most, then "+K"), **Keep editing** and **Remove and close** (loss colour). While it
  is up `fnc_isOver` says nowhere, `fnc_onKey` does nothing and `fnc_onAceKey` holds every key: Escape is Keep editing
  (`fnc_closeConfirm`), the rest is swallowed. **Moving the card:** its controls lie straight on ACE's display and do not hear
  the mouse themselves, so a left press from `fnc_onConfirmMouse` on no answer and inside the title strip (the live position of
  the film in uiNamespace `einv_arsenal_confirmBar`) starts `["begin", ...] call einv_gui_fnc_dragHandle` with the list in
  `einv_arsenal_confirmMoved` (all the card's controls except the dimming). The helper moves them one by one with the display's
  own `MouseMoving` / `MouseHolding` / `MouseButtonUp`; the answers' hit tests read their live positions, so they follow;
  `fnc_hoverConfirm` lights the film on hover when no drag is running. The red screen (`fnc_onBlockedLoad`) has its card as a group
  inside the full-screen one and a plain `attach` handle over its sign and title.
- **Remove and close** (`fnc_answerConfirm`): `fnc_dropOverflow` - per container the first overflow entry through
  `einv_storage_fnc_removeEntry`, the layout read again after each, `fnc_tellAce` with the class counts before and after, the
  `giveBack` sound once -, an RPT INFO line, then `closeDisplay` with the code the player asked for.
- **A close nothing could ask first** (a script's `closeDisplay`, a handler that could not be replaced): `fnc_onClosed`, a frame
  after `ace_arsenal_displayClosed`, runs `fnc_dropOverflow` for a local unit, says it in the RPT (INFO) and once on the screen
  ("Removed, as they did not fit: ..."), and `fnc_reportOverflow` names what would not come out.

### Add, remove, reconcile

- **Picking another container** (`fnc_keepPlaces`). ACE goes through `setUnitLoadout`, which makes all three containers new objects with first-fit
  places. `GVAR(kept)` holds `[container, class, records]` per slot (re-read every `KEPT_REFRESH` 0.2 s while the object is the same); when a slot
  holds a new object of the same class its records are written back with `einv_storage_fnc_writePlaces` (records that no longer match drop out at
  the next layout). Called from the frame hook, `fnc_snapshot`, `fnc_onItemsChanged` and `fnc_onCargoChanged`, before anything normalizes the new
  containers. The slot whose class changed is laid out fresh (first fit). A loadout set on ACE's unit (`CBA_loadoutSet`) empties `GVAR(kept)` (the old records are stale for the new contents) and sets `GVAR(loadoutFrame)`, `LOADOUT_QUIET_FRAMES` 4 frames in which `fnc_stageOverflow` moves nothing and asks for `fnc_settle` again.
- **Overflow to staging** (`fnc_stageOverflow`, in `fnc_settle` before the snapshot): entries with no cell are moved first to another worn container with a free spot (uniform, vest, backpack order), and only what fits none to the staging
  space (`einv_storage_fnc_moveEntry`, `fnc_growStaging` first), ACE told for the open container; what the staging space cannot take stays red.
  `fnc_findOverflow` also lists everything in the staging space, so the close card names it.

- **ACE's own "+"**: `fnc_snapshot` normalizes the container's places (`einv_storage_fnc_normalize`) and notes its counts by
  class, so after an add every old tile keeps its record and only the new things are laid out first-fit. `fnc_reconcile`: gains
  against the snapshot; overflow entries of a gained class are taken back out (`einv_storage_fnc_removeEntry`, at most the gained
  count), "No room in the vest - move things to free a 1x2 space" appears in ACE's message line and the hint line
  (`fnc_sayNoRoom`), and ACE is told with `ace_arsenal_fnc_fireItemsChangedEvent` (`fnc_tellAce`; an ACE without it gets the
  follow-up in the frame-later pass). Nothing else is ever taken out.
- **List drag.** The list's own `MouseButtonDown` handler (`fnc_onListPress`) notes a left press on its rows - not on the scroll
  bar's 6 %, not on ACE's "-"/"+" (IDC 101/102, shown and not faded) - with where, Shift, the frame and **the row**, worked out
  there: `row = floor((pressY - listY + offset) / rowH)`, `offset = clamp(ctrlScrollValues select 0, 0, 1) * max(0, rows * rowH -
  listH)`, `rowH` the config's `rowHeight`, else its `sizeEx` (ACE leaves `rowHeight` at RscListNBox's 0; both may be expressions,
  evaluated), else `ACE_ROW_SIZE`; a row past the last is -1. The frame hook starts the drag once the mouse moved more than
  `LIST_DRAG_PX` 5 screen pixels **in any direction** with the button held (the list scrolls by wheel and bar, so up/down is a drag
  too; the engine's `DRAG_THRESHOLD` is 6-9 px at 1080p), and does not drop the press in its own frame or the next for a button
  that does not read as held yet. `fnc_listDrag` takes the press's row; only out of range the row the list picked since the press
  (`LBSelChanged`, `einv_arsenal_listSel`). A unique row (`lnbValue [row, 2]` 1) does not drag and flashes "ACE does not allow
  this item here" once; a greyed row drags (the staging space may take it). The row's class is read from `lnbData [row, 0]` into
  a virtual off-screen source grid `"aceList"` whose tile carries `dragEntry` with `count` = the stack (Shift: all); then
  `einv_gui_press` and `einv_gui_fnc_startDrag`. `fnc_dragCheck`: only a
  grid of the panel is a target (else `[]`) - or, with compat_efak loaded, a **kit's tile** there (`fnc_listToKit`: the cell under the
  mouse, the footprint's corner plus `einv_gui_press`'s grab, lies on a tile `einv_compat_efak_fnc_isKit` knows): the target becomes
  `["kitTile", grid, tile, 0, fits, why]` by `einv_compat_efak_fnc_canPackNew [kit, class, count]` - the kit type's Arsenal setting
  (`efak_core_fnc_canPackInto` with the Arsenal, always in Eden), that mod's rules, and the kit's room by `fnc_roomMode`: its
  capacity, or the free cells of its own grid and never the capacity then; green when some fit (the hint says how many), red with
  the reason when none. `fnc_onDrop` packs them with `einv_compat_efak_fnc_packNew` and runs `fnc_settle`. EFAK's own kits tab of
  ACE's window is left as it is. **Kit sections:** `fnc_focusedKit` reads the row picked in ACE's LEFT list (IDC 13); when it is a kit, in any tab, `fnc_layout` shows that kit's grid in place of the containers - `fnc_kitSections [display, holders]`, one section per kit of that type in the worn containers or staging space (`einv_compat_efak_fnc_arsenalSections` -> `fnc_kitSection`, the section a kit window is drawn from too; `foldKey` a string, so `fnc_drawSection` and `fnc_toggleSection` fold by it where there is no container; kept in `GVAR(folded)` as `kitfocus_<class>`, open at first) - plus the staging space; a pick that changes it rebuilds (`LBSelChanged` of the left list). No kit is a section of the container tabs. Its grid is a kit holder like a window's: container to kit and back go through the engine's kit ops, `fnc_listToKit` gives a list drag over it the kit's verdict (`canPackNew`) and `fnc_onDrop` packs it (`packNew`, the cell when free), `fnc_remove` and Ctrl+wheel take out through `einv_compat_efak_fnc_discard` (`takeFromKit` outside a phase, local root, Arsenal setting). ACE's rows are not greyed by the kit's room: its "+" adds to the container. The target's 11th element is the cell under the mouse (the item is held by its middle, so the footprint's corner is no longer the cell
  minus a fixed grab): `fnc_listToKit` takes the cell from it. The drop (`fnc_onDrop`) calls `fnc_addTo [container, class, count, [col, row, block,
  w, h]]`: `normalize`, then `addItemToUniform` / `Vest` / `Backpack` for the open container, `addNew` for staging and for what
  the engine refused, the cell as a new record (`setPlace`); then `syncAce` and `tellAce`.
- **Swapping tiles in the panel.** Dragging a tile onto another of the open container swaps the two as in the inventory (`einv_gui_fnc_swapPlan`,
  a `placeMany` inside one container: counts do not change, so ACE has nothing to hear). Between the container and the staging space the
  swap is an `exchange` through the hub; `fnc_onDrop` is handed the plan (its 15th argument) and notes the counts of both classes
  (`einv_arsenal_watch` `[container, [[class, before], ...], until]`), so the frame hook tells ACE of each (`fnc_syncAce` once, `fnc_tellAce`
  per class) - and likewise for a tile that joins a stack of its own class there.
- **Wheel and remove.** During a list drag the engine's wheel sets the count on the ghost. Else `fnc_onWheel`: plain is the
  column's scroll; **Ctrl** over a tile adds one of its class (`fnc_addTo`, if in `ace_arsenal_virtualItemsFlat`) or takes one out
  (`fnc_remove`). A drop outside the panel, the drop key, the menu or Ctrl+wheel down remove (`fnc_remove`: the record first when the
  whole tile goes, then `removeEntry` with the dragged count; `fnc_removeKind`), with sound `giveBack` and `fnc_tellAce`.
- **Frame-later pass** (`fnc_settle`, once a frame however often asked): `fnc_keepPlaces`, fallback follow-up, `fnc_stageOverflow`, snapshot, `fnc_syncAce` (row counts,
  load bar, `ace_arsenal_currentItems`, `ace_arsenal_fnc_updateRightPanel`), **`fnc_ungrey`** (rows are greyed or lit by whether a stack has room or a spot of the item's shape is free, as an add would find it, one grid look per shape, in turns of UNGREY_BUDGET; also the "+" of the picked row, and the
  whole list a frame after every pick, as ACE greys all rows by weight anew at each pick; unique items and backpacks are left to ACE), **`fnc_pictures`**
  (the rules' `picture=` on ACE's own rows - its left list IDC 13, the right list of the weapon tabs IDC 14 with `lbSetPicture` and the
  container tabs' listnbox IDC 15 with `lnbSetPicture` -, rows by class from `getInfo`'s `pictureOverride` when it is `picture`, done
  `PICTURE_BUDGET` seconds a frame since the lists hold thousands of rows), the engine unit set to `ace_arsenal_center`, build - or after the drag if something is
  held.
- **Mouse and focus.** A press on the panel empties `ace_arsenal_mouseButtonState` (now and a frame later); the frame hook keeps
  it empty while something is held or a list press waits, and ends a drag whose button came up where no display event reached the
  engine. The engine draws the focused control over all, and a row click focuses the list; so the frame hook gives the focus to
  the panel's sink (uiNamespace `einv_arsenal_focusSink`: an `EINV_Hitbox` of no size in the screen's corner, made by
  `fnc_layout`) while the mouse is over the panel with no button held or a drag is on, unless a field (type 2) or the sort bar
  (type 4) has it, and **gives it back to ACE's list (IDC 15) once the mouse has left the panel with nothing held**, so ACE's
  arrow keys work. It is not ACE's 3D area (IDC 0) that gets the focus: it covers the screen, and focused it lay over the panel.

### The vanilla Virtual Arsenal

`BIS_fnc_arsenal` is wrapped (`CfgFunctions.hpp`): "Open" asks `fnc_handleBIOpen`; everything else is BI's own code. The server
setting `einv_arsenal_biArsenal` has three values: **`"ace"`** (default; ACE Arsenal opens with the box's items on a local helper,
`fnc_biItems` -> `fnc_openBI`), **`"block"`** (a red glass screen `EINV_ArsenalBlocked`, IDD 9611, with `einv_arsenal_biMessage`;
`fnc_showBlocked`) and **`"vanilla"`** (BI's untouched; what does not fit the grid is reported afterwards). Always BI's: no
interface, not ready, a mission that sets `einv_arsenal_biPassThrough` true, BI's showcase, Warlords, Eden's editor, a remote,
non-soldier or seated center. In `"ace"` mode also a mission with more `arsenalOpened` / `arsenalPreOpen` handlers than mods had
(`fnc_biCountHandlers`, counted the first frame after postInit), unless it sets `einv_arsenal_biPassThrough` to false; Zeus is
never blocked. `fnc_biSafetyNet` (an `arsenalOpened` handler) closes a vanilla display that opened though nothing here let it, a
frame later with exit code 2, and opens ours or blocks. In the inventory, `fnc_isArsenalBox` (ACE's `virtualItems`, or a BI box)
makes a box never searched and gives it "Open Arsenal" (`fnc_canOpen`, `fnc_open`).

## 6. Setup wizard (setup)

The wizard edits one thing, the text of `einv_items_rules`, through the rules engine's own functions (`parseRules`, `writeRules`,
`compileRules`, `getInfo [class, draft, cache]`), and draws with the inventory's UI kit and theme (`einv_gui_fnc_ui*`,
`einv_gui_fnc_theme`). Nothing reaches the game before Save. Its functions are PREPed in preStart as well as preInit
(`XEH_PREP_entry.hpp`: `fnc_initCbaMenu`, `fnc_openFromGame`), so CBA's menu and the wizard's display find them in `uiNamespace`
over the main menu and in Eden.

### Entry points

| Where | Mode | How |
|---|---|---|
| CBA's Addon Options, a button in the bottom row (between Load and Import) while this mod's Server page (the category of `einv_items_rules`) is open | menu | `fnc_initCbaMenu` (`Extended_DisplayLoad_EventHandlers >> RscDisplayGameOptions`); missing CBA controls mean no button and nothing else breaks |
| ESC > Options > Inventory setup | direct | `CBA_fnc_addPauseMenuOption` with the display `einv_setup_RscWizard` (idd 9620) |
| Eden: Tools menu | direct | `Display3DEN.hpp`, over display 313; saves into the scenario |
| the inventory's cog (`einv_gui_fnc_drawHeader`) | direct | `fnc_openFromGame`; the tooltip says read-only when `fnc_canEdit` says so; the inventory comes back on close (`einv_setup_reopenInventory`), as a person window when it was one |

- `fnc_open [parent = displayNull, mode = "direct", step = 0, class = ""]` (public) -> display; one wizard at a time, an open
  inventory closes first. The wizard edits `einv_items_rules`, has no keybind and no setting of its
  own. `fnc_canOpen []` (public) -> BOOL is the one gate every way in passes: `fnc_openFromGame` (the inventory's cog; asked
  before the inventory closes, so a refusal keeps it open and says nothing), `fnc_open` (a mission's own call), `fnc_initCbaMenu` (the
  button on CBA's Addon Options, asked at every sync) and `fnc_onLoad` (ESC > Options, where the engine makes the display itself:
  closed again through `fnc_defer`, silently). It is `is3DEN || isServer || !isMultiplayer || serverCommandAvailable "#kick"`: the
  editor, the server itself, the host, single player, a logged-in or voted admin. Nobody else sees the wizard: the cog in the
  inventory header (`einv_gui_fnc_drawHeader`) is not drawn, asked at every draw, so a login shows at once (the game has no event for
  it). CBA's pause-menu entries take no condition, so ESC > Options still lists it for everyone; it closes again at once.
  Saving is a question of its own (`fnc_canEdit`); the read-only mode stays in the code for the CBA whitelist case.
  `fnc_canEdit [mode]` (public) -> HashMap `canSave`, `source` (`"server"`, `"mission"`, `""`),
  `override` (may force over the mission, priority 2, multiplayer server only), `locked` (set in a `cba_settings.sqf`), `reason`,
  `priority`, `missionWins`: direct mode saves to the mission in Eden, else to the server - as the server itself (single player
  too), a logged-in admin or CBA's whitelist; everyone else is read-only. Menu mode: the source picked in CBA's menu.
- `fnc_save [overwrite]`: direct mode `CBA_settings_fnc_set` into the source (the mission forced at priority 1, the server at 2
  when the switch says so); menu mode `cba_settings_fnc_import` into CBA's menu as a pending change, and the wizard closes - CBA's
  OK keeps it. Someone else saved meanwhile: replay my edits on top (`fnc_replay`), overwrite, or cancel.
  `einv_items_rulesChanged` while the wizard is open -> `fnc_onRulesChanged` (deferred): no own changes - show the new setup; own
  changes - keep them and show a banner (Reload / keep mine).

### Eden: everything is deferred

Eden runs no postInit, so CBA's frame handlers and `CBA_fnc_execNextFrame` never run there. Every widget therefore hands its code
to `fnc_defer [code, args, delay]` (a button that redraws the wizard deletes itself, which must not happen inside its own click),
and the queue (uiNamespace `einv_setup_deferred`) is emptied by `fnc_runDeferred`, whichever comes first: the display's
`MouseMoving` / `MouseHolding` events (`fnc_onMouse`, every frame while the mouse is over it) or a spawned script that runs it
unscheduled (`isNil`). The queue is taken before it runs, so code that queues more starts a new queue. **Every click of the wizard
goes through `fnc_uiHit` / `fnc_defer`, never through CBA's frame handlers.**

### Popovers and the top layer

Every popover (`fnc_popover`: a dropdown's list, the Same as picker, the import box, `fnc_confirm`'s questions such as closing with
unsaved changes) is made in the **top layer** (`fnc_topLayer`, uiNamespace `einv_setup_layer`): a controls group over the screen,
made anew at the end of every step drawn so it is the display's last control, hidden while empty. The engine draws the focused
control over all others, and the pane holds the focus after a redraw (its sink) or a click - popovers made on the display lay behind
it. A popover therefore takes the focus into the layer (a button of no size on its card) before its content is drawn, its
full-screen hit area closes it on a click beside the card and lets nothing through, and the keys wait while one is open
(`fnc_onKeyDown`, `fnc_onKeyUp`); `fnc_closePopover` hides the layer and gives the focus back to the sink. A popover with an anchor opens below it (above when there is no room), at the anchor's place on the screen as `fnc_screenRect` works it out: the groups around the control add their corner and take off how far each is scrolled (`ctrlScrollValues` times the content's height less the group's; a step that draws a scrolling page says its height in the group's `contentH`, else it is the lowest bottom edge of the group's controls). A step drawn again keeps where its groups were scrolled (`scrollId` on the group): `fnc_showStep` saves them and `fnc_restoreScroll` sets them again until they hold, a page that came out longer or shorter at the same distance from its top. A popover without an anchor sits in the middle of the screen, or - with its seventh argument - centred on a point (`fnc_confirm` centres on the wizard's middle). **`fnc_confirm`** is a card with its question centred (a bold title above it when it has one) and its answers right-aligned along the bottom with one gap, as wide as the answers need; the answer that does nothing is first on the left, Escape and a click beside the card are that answer. Closing with unsaved changes (`fnc_close`) asks "You have unsaved changes.": **Keep editing**, **Close without saving** (style `danger`) and - only when the wizard may save (`!readOnly`) - **Save and close**, which calls `fnc_save` and closes the display once the draft is no longer dirty (a conflict question or a refusal leaves it open).

**Moving a popup window** (`einv_gui_fnc_dragHandle`, gui addon, shared by setup and arsenal). A titled popover is a window: `fnc_popover` makes the title bar (from the card's edge to the cross, down to the content) a drag handle - a transparent `EINV_Hitbox` in the card group, made after the title and before the cross, with a faint film under it that lights on hover (`MouseEnter` / `MouseExit`). A left press on it ("begin") adds `MouseMoving`, `MouseHolding` and `MouseButtonUp` to the display and nothing else runs until then; each move sets the **card group** with `ctrlSetPosition` + `ctrlCommit 0` (a group carries all it holds), the release removes the three handlers. The dimming and the full-screen catcher are siblings of the card in the layer and stay put. The move is the mouse's distance since the press, rounded to whole pixels and clamped so the whole handle stays in the safe zone. The state is uiNamespace `einv_gui_drag` (empty when idle); `["busy"] call einv_gui_fnc_dragHandle` is true while dragging and for 0.3 s after, which the catcher's `ButtonClick` asks so the release that ends a drag never counts as a click beside the card. The popover's eighth argument is a *kind* (`picker`, `export`, `exportClasses`, `exportChoice`, `import`, `importChoice`, `classImport`, `sameAs`; `changes` for the changes list): where a window of that kind was let go is kept in uiNamespace `einv_gui_places` for the session and the next one is put there (brought back inside the screen by the same clamp). Untitled cards make a handle of their own through the same function on the card (`ctrlParentControlsGroup` of the content group): `fnc_confirm` over its words and padding (not the answers; no kind, a question opens in the middle each time), `fnc_openChanges` over its caption strip. Dropdown lists are anchored menus and are not moved.

### State and the draft

`einv_setup_steps = [[id, name key, function], ...]`: `general` (`fnc_drawGeneral`), `items` (`fnc_drawItems`), `containers`
(`fnc_drawContainers`); step functions get `[display, group, theme, args]`. The ids are what others look a page up by - the inventory's
"Settings for <name>" row finds `items` and `containers` there, and `fnc_openFromGame [step, class]` takes the step's place in the list
(0 General, 1 Items, 2 Containers). Group rules (`@group > ...`) have no step of their own: they are text, written and read through Export
and Import. missionNamespace holds the mode, `target` (canEdit's answer), `readOnly`, the draft - two texts, the rules and the server settings:
`origin`, `originSource` (name -> [value, priority] of the source for each of the two settings), `draft` (AST), `draftText` (canonical),
`draftRules` (compiled), `draftCache`, `parseWarnings`, `clean`, and for the settings `originSettings`, `draftSettings` (what the text names,
setting's name -> value), `draftSettingsText`, `cleanSettings`; `sourceEmpty`, `undo`, `redo` (entries `[rules text, settings text]`) -, the
window (`step`, `focus`, `selection`, `theme`) and what steps keep between redraws (`listState`, `treeState`, `editScope`, `cellWork`,
`itemWork`, `cellMode`, `cellBrush`, `sameAs`, `kindEdit`, `exportMode`, ...); controls stay in uiNamespace. **Every edit of the rules ends in
`fnc_commit [ast, redraw = true]`** (an undo step, `fnc_setDraft`, redraw); **every edit of a server setting in `fnc_setSetting [name, value]`**
(nothing for the default; `fnc_commitSettings`, `fnc_setSettingsDraft`); an import and Reset to default change both at once in one
undo step (`fnc_commitSetup`). `fnc_setDraft [text]` parses, writes out again, compiles with a fresh cache and raises the local event
`einv_setup_draftChanged [draftText]`. A change that writes out the same text is no change.

Every change ends in `fnc_showStep`, which draws the step again. A scroll group made anew starts at the top and only knows its height a
frame later, so the lists keep their place by `scrollId`: read before the redraw and put back by `fnc_restoreScroll` a few hundredths
of a second later, until it holds (a few frames show the top meanwhile). The General page is the one exception: drawn again in the same
step, `fnc_showStep` keeps the content group and `fnc_drawGeneral` keeps the page's scroll group in it (the group's variable `page`),
draws the new controls first and deletes the old ones last, so the group is never new, never empty, and the page does not move. A click on
a stepper (`fnc_uiStepper` defers its code, `fnc_setSetting`, `fnc_commitSettings`) or a pick in a dropdown (`fnc_closePopover`, then the
same) takes that path. The Items and Containers editors draw only their own card again (`fnc_drawItemEditor`, `fnc_drawCellEditor`), not
a scrolling page.

**Saving** (`fnc_save`) writes each of the two settings that changed (or that the source lacks, or whose force switch turned) - `einv_items_rules`
and `einv_main_settings` - with `CBA_settings_fnc_set` into the same source and priority; in menu mode it imports both lines into CBA's menu.
`fnc_canEdit` is locked when a `cba_settings.sqf` sets either, `fnc_getActive`, `fnc_targetValue` and `fnc_sourceEmpty` take the setting as an
argument, and a change of either (`einv_items_rulesChanged`, `einv_main_settingsChanged`) while the wizard is open is `fnc_onRulesChanged`'s.

### Steps

- **General** (`fnc_drawGeneral`): one page that scrolls. Its top row has the title and Import (`fnc_openImport`), Export (`fnc_openExport`: a box with
  the own rules, the whole setup written out or the lines for a `cba_settings.sqf` - the rules and, off their defaults, `einv_main_settings` -, read only,
  with Copy where `copyToClipboard` works) and Reset to default (`fnc_resetAll`, after `fnc_confirm`); under it where Save goes,
  or why it may not (in red), and the switch to force it over the mission where `canEdit` allows it. Only when there are any: what the engine left out of
  the text it read. Then:
  - **Containers**: a row for each of `GENERAL_KINDS` (uniform, vest, backpack, vehicle, crate): Auto | Fixed, two steppers (across 1 to `STORAGE_COLS`,
    down 1 to `MAX_ROWS`) greyed while Auto, a reset button while there is a rule, and a few words of what Auto gives. Each is the rule `all kind=K >
    grid=WxH` of the draft (`fnc_kindRule`, `fnc_upsertKinds`); Auto takes `grid` out of it. The engine asks these rules after everything about a class
    (`fnc_resolve`, layer `all`), so a class rule, a table, a mod's `einv_grid` and the preset win over them. The last numbers stepped to are kept per kind
    (`kindEdit`) for when Fixed is switched on again.
  - **Categories** (`fnc_drawCategories`, the card after "How room is worked out"): one row per category there is in the draft (`einv_items_fnc_categories` of `GVAR(draftRules)`, the eight built-in ones first): its picture as the window draws it (`einv_gui_fnc_groupTexture` of the draft), a name field (`fnc_uiField`, applied on Return or when the cursor leaves it: `fnc_renameCategory` - a name of its own category cannot be empty, a built-in one given its shipped name or none is the shipped one), "Built in" or the id, **Picture...** (`fnc_openPicturePicker` with the class `#category`: the picker opens on its extra chip **Category icons**, the slot pictures and symbols of this mod's own `ui` folder, `fnc_iconEntries`, which needs no catalog and is ringed without it; the other chips are the item pictures as before), a reset button (a built-in category back to its shipped name and picture - its statement goes -, one of the setup's own back to the star) and, for the setup's own, a cross that asks (`fnc_confirm`, "danger") and runs `fnc_deleteCategory`. The last row is Add: a field and a button (`fnc_addCategory`; the id is made from the name by `fnc_newCategoryId` - lowercase letters and digits, the rest `_`, `CAT_ID_MAX`, a number on the end where it is taken or reads as a built-in word; Return in the field adds too; refused with a hint without a name and at `MAX_CUSTOM_CATEGORIES`). Every edit is the statement `category=ID > name=... picture=...` of the draft (`fnc_setCategory`, one `fnc_commit`, so undo, Save, Export, Import, the change lists and the server's hash see it as any rules text; Import of a text with `category=` statements joins them, the later statement of an id counting, and Export "full" keeps them). **Delete** (`fnc_deleteCategory`) takes the statement out and the id out of every rule's `cats=` (a rule left with nothing to set goes) and of every `grid=` it accepts (`fnc_cleanGrid` on the parsed grid, written again), and out of the editors' unapplied work (`itemWork` `catsList`, `cellWork` accepts) - in one undo step, so nothing is left that lists a category that is gone. The Items step's Category chips (`fnc_drawCatRow`) and the Containers step's Accepts chips (`fnc_drawCellAttrs`) list the draft's categories by `categoryInfo` `name`, in the order they were defined, and store in the order of `fnc_orderGroups`. The changes list has a row kind `category` (new / changed / removed, "Category bandit: name Bandit loot", `fnc_describeRule` with its fifth argument) which `fnc_countChanges` counts under the General step; `fnc_changeRows` keeps the categories as the General step's own when it measures against the default.
  - **How room is worked out**: the load per cell - the header's `cell=` (`fnc_commit`), 1 to 50, with "1 cell = X kg", its source and a reset - and, in
    words with the numbers of the moment (the cell, `UNIFORM_COLS`, `UNIFORM_ROWS_MIN`/`MAX`, `VEST_POUCHES_MAX`, a vest of load 120, a backpack of 280, a crate
    of 1000): containers, uniforms, vests, backpacks, vehicles and crates, items, stacking, and that a rule of the class beats it all. The sizes of items and
    the stack numbers in the words are those of the default preset - keep them together.
  - **Server settings** by topic (`GVAR(topics)`: looting and searching with the hands' queue times, living persons, containers, weight, hotbar/repacking/locks, vanilla arsenal; a registered setting that
    no topic names goes under Other, one whose addon is not loaded is not shown): two to a line, a text box a line to itself. A control by the registry's type
    (`einv_main_serverSettings`): CHECKBOX `fnc_uiToggle`, SLIDER `fnc_uiStepper` (a step of 1, or 0.5 or 0.05 for a short range with decimals; the value
    rounded to the setting's decimals), LIST `fnc_uiDropdown`, EDITBOX `fnc_uiField` (a text box applied on Return or when it loses the cursor, not per key).
    The label's tooltip is the setting's description, the label is in the accent and a reset button (`fnc_uiReset`) shows while the value is off its default
    (the setting is in `draftSettings`). Settings with `hidden` (`einv_items_massPerCell`, `einv_items_stackSmall`) have none.
  - **What you changed** (`fnc_drawChanges "default"`): the rules that are not the General step's own - `fnc_changeRows "default"` compares the draft with the
    default that keeps the draft's `cell=` and its `all kind=...` rules - so when all uniforms are 10x10 by their kind and one is 5x5, that one is the only
    row.
- The header chip ("Server · forced · 4 changes", `fnc_drawFrame`) is a button: it opens `fnc_openChanges`, the list of what Save would store
  (`fnc_drawChanges "saved"`) over whatever step is open. The footer has Back, Next and Save (Apply in menu mode); a dot on a step pill means changes
  in it (`fnc_countChanges` -> `[count, step ids]`, a rule goes to its step by `fnc_ruleStep`).
- **Items** (`fnc_drawItems`) and **Containers** (`fnc_drawContainers`): a class list on the left (`fnc_drawClassList`, cards by
  `fnc_drawResults`, 30 to a page) and an editor on the right. One class at a time and one rule per class - or, picked in the tree
  view, one rule for a class and everything built on it. The search takes wildcards (`fnc_searchFilter`, `fnc_searchHit`): `*` is
  any run of characters (none too), `?` any one, and the pattern has to fit the class or the name as a whole - `B_Bergen*`,
  `*Carryall*`, `*_F` -, while a plain text still finds itself anywhere; the wildcard becomes a regular expression with every other
  character escaped, and its longest literal run is looked for first, so the expression only meets the few classes that could fit.
  A button beside the search - Tree in the list, List in the tree - switches between the cards and the tree view; the tree opens where the picked class
  stands among its relatives (`fnc_treeTop`, `focus` in `treeState`). "Only classes with own rules" lists, on Items,
  classes whose rules set `footprint` or `stack`; on Containers, `grid` or `like` (`fnc_ownClassRules`' `named`). The Containers
  chips are All, Uniforms, Vests, Backpacks, Cargo and - where Enhanced First Aid Kits brought kit types (`einv_items_fnc_kitTypes`)
  - Kits.
- **Kits** (kind `kit`, section 2) are containers of the Containers step and items of the Items step (family `item`): the type's own
  class is listed, its load the type's capacity (`fnc_classKind`); the instance classes that mod makes of it are in no list and no
  tree. An edit of a kit is always for its tree (`fnc_editScope` -> `[true, instances]`, a note instead of "Only this class"), so the
  rule is `class=efak_IFAK+` and reaches the kits players carry; Import writes it the same way (`fnc_importClasses`), Export gives
  the type's line, which its instances inherit in config. `fnc_kitRoom [info]` -> `"capacity"` / `"cells"` / `""` asks
  `einv_compat_efak_fnc_roomMode` with the draft (else the same test on `einv_items_fnc_setBy`): by capacity, `fnc_answerText` words
  the grid "capacity 35" from "EFAK" (`einv_compat_efak_fnc_capacity`, the mission's setting included), the editor's "Now:" line
  has no compartments part and a note says the cells drawn are only a start - Apply gives the kit them and the capacity no longer
  counts; with a grid of its own, "Now:" is the grid and a note says the capacity no longer counts; Back to the default returns it
  to the capacity. A kit opened for (`einv_setup_focus`) as an instance picks its type.
- **Per field reset** (`fnc_uiReset`, `fnc_resetField`, `fnc_classDefault`): beside the size, stack, weight, name and use of the Items editor and the
  cells of the Containers editor, a small button shows while the value differs from what the draft makes of the class without its own rule for that field
  (`fnc_classDefault [class, fields]`: the rules with those fields taken out of `class=X` and `class=X+`, compiled and asked once per text and class). A click
  removes the field from the class's rule at once (`fnc_upsertRule`, an undo step) and drops what the editor held for it unapplied.
- **`fnc_changeRows [against = "saved" | "default", describe = true]`** is the one diff behind both lists and the header count: rows `[kind, status, label,
  words, picture, before, class, statement, undo]` (kind `rule`, `group`, `category`, `setting`, `preset`, `cell`, `override`) for the preset (only a text can change it now), the cell size, the override switch (saved only), every server
  setting (saved only: kind `setting`, words "before » after" by `fnc_settingText`, the cross sets it back), then every group and rule matched by what it is for
  (a group by name, a rule by its conditions), so a class given another size is one "changed" row. Against `"saved"` the reference is `clean` and
  `cleanSettings`; against `"default"` it is the default with the draft's own `cell=` and `all kind=...` rules, i.e. what the General step sets. A single-class
  rule shows the class's picture and display name plus `fnc_describeRule [.. , valuesOnly = true]`; `all kind=uniform > grid=5x5` is worded "Every uniform:
  compartments 5×5". `undo` is `[code, args]` and ends in `fnc_commit` (or `fnc_setSetting`), so undo/redo keep working; a removed statement goes back after
  the one it followed, since a later rule wins. Reference setups are parsed once per text (`changeRefs`). `fnc_countChanges` counts these rows
  (`describe = false`), so the header chip, the step dots and the list agree.

### The class index

`fnc_buildIndex` / `fnc_indexChunk` read config in pieces of `INDEX_BUDGET` 6 ms (through `fnc_defer`, so it runs in Eden) into
uiNamespace for the whole game session: every public weapon, item, magazine with a picture, pair of goggles, backpack (including
those with a load of 0 - an own grid gives them room), crate and vehicle with a cargo space, one row each (`ROW_*`). What the
rules make of a class is not in it; it is asked (`getInfo` with the draft) only for the rows shown.

### Trees and mass edits (Items and Containers)

`class=X+` already covers X and every class built on it, so editing a family is one rule; the wizard only has to find the family and
write that rule.

- **The data.** `fnc_treeIndex [root]` reads one config root once per game session (uiNamespace `treeIndex`): the parent, name and
  scope of every class of scope 1 or 2 and of each class above it - the hidden bases (`B_Carryall_Base`, `Rifle_Base_F`) several
  variants are built on belong in it though no list shows them -, and the children of every class, sorted. One pass
  (`configClasses` with a scope condition, then `inheritsFrom` up to the first class already known), which is a visible moment for a
  root of a large mod pack (not measured in the game); it runs when a tree is first asked for, not in the pieces the class index is
  read in.
  `fnc_classTree [class]` is a class and everything built on it in tree order (`order`: lowercase class and depth) with the same as a
  set (`set`) - what a rule `class=X+` covers - and the class's `parent`; `fnc_treeRows [class, step]` is the list a step shows of it:
  scope 1 or 2, not named `..._Base`, and of a kind the step lists (`fnc_classKind`, which the class index uses too: on Containers a
  uniform, vest, backpack, crate, vehicle or kit that holds something, a backpack always; on Items everything but the cargo; a kit's
  instance classes on neither), each row
  `[class lowercase, class, name, depth, how many listed classes are built on it]`. A class that is not listed leaves its listed
  children one level up; the first row, the class the tree starts at, is always there. The rule `class=X+` covers the unlisted classes
  below X as well (a scope 0 variant, a kind the step does not list); the counts are of the listed ones. Both are kept in uiNamespace
  (`treeCache`, `treeRowsCache`).
- **The view.** `treeState` holds, per step, `on`, `root` (a lowercase class, "" for the one picked) and `page`. With the view on,
  `fnc_drawResults` hands its box to `fnc_drawTree`: the tree's start and how many classes are built on it, "Up one level"
  (starts the tree at the parent - how a family is found whose members share a hidden base nobody can pick; stops at a parent with
  more than `TREE_UP_MAX` 2000 classes under it) and "Start at picked", then the rows of the page indented by `TREE_INDENT` (at most
  `TREE_INDENT_MAX` levels): picture, name, class and "N below", and what the draft makes of the class with where from
  (`fnc_answerLine`, the one line the cards use too). The arrow at the end of a row starts the tree at that class. The list's search
  and "only classes with own rules" filter the rows; switching the view on starts the tree at the class picked.
- **What an edit is for** (`editScope`, per step): `class` for the class alone, `tree` for it and everything built on it. A card of the
  list picks "class", a row of the tree picks "tree", and so do opening the step for a class and a click on a line of the change lists.
  `fnc_editScope [step, class]` answers `[tree, how many listed classes are built on it]` and is a tree only when there are any. The
  editors say so in a line (class, the number and the rule, `class=X+`) with a chip "Only this class"; Apply, Back to the default and
  Export then work on the tree - one `class=X+` rule through `fnc_upsertRule [.., tree = true]`, a class with a rule of its own further
  down keeps it. "Same as another class" is for one class and is not offered then. Working copies are per class, tree or not.
- **Which rule covers a class.** `fnc_answerText` reads the source tag of the field (`own:<i>`, i the rule's index in the draft): a
  rule `class=X+` of a class above this one says "inherited from X", a rule for the class itself "your rule", a preset "preset", as
  before. `fnc_ownClassRules` returns a third map, `tree` - the values of the rules written for exactly `class=X+` -, which the
  editors use to offer Back to the default for a tree.

### Export and import at the editors

Both editors have Export and Import in the corner (`fnc_editorTools`).

- **Export** (the button opens `fnc_openExportChoice`, a box under it with two buttons; `fnc_exportClasses [step, class, tree, format]`)
  - **Config entry (for a mod)**, `"config"`: asks `einv_items_fnc_configEntry [class, false, draftRules]` for the config
    lines of the class - of every listed class of the tree, one line each, for a tree edit -, so they come from the draft and a design
    can be exported before Save, and only the keys that differ from what the class gets without the rules text. Where `configEntry`
    is missing the wizard writes the lines itself from the draft, every key that has an answer.
  - **Layout only (to share)**, `"layout"`: the same keys for the class alone (a layout has no tree), read back with
    `parseConfigEntry` and `fnc_configValues` (config key -> rule field) and written as a rule without conditions
    (`einv_items_fnc_writeRules`) after the marker `LAYOUT_MARKER`: `einv-layout: grid=1x3+5x7+1x3 weight=1.2 picture=/a3/...`.
    No class name, so it works across mods.
  They go to the clipboard where `copyToClipboard` works (`isServer || !isMultiplayer`, as at the General page's Export); a client gets a box with the text
  to select and copy.
- **Import** (`fnc_openClassImport`, a paste box under the button, which knows the selected class and whether the edit is for its tree;
  Apply runs `fnc_applyClassImport`, which calls `fnc_importClasses [text, selected, tree, choice]` and words the result line). What
  is read, in this order: a **layout** (`LAYOUT_MARKER`; its values, no class), **config lines** (`einv_items_fnc_parseConfigEntry`; each class
  with its keys, `size` -> `footprint`, `stack`, `grid`, `weight`, `name`, `icon`, `picture`, by `fnc_configValues`), **rules of single
  classes** (every rule is exactly `class=X` or `class=X+`, no groups, no `einv` header, no setting around them: a class each, as config
  lines), and else any **rules**, as the General page's Import reads them (`fnc_importText`), whose statements join the own ones without repeating
  one that is already there. A text of the first three never creates a rule for a class this game does not have (`getFacts "root"` is
  ""), and where the values go depends on the selected class:
  - a layout always goes to the selected class (the selected tree for a tree edit);
  - a text naming one class the game lacks (another mod's, not loaded): its values go to the selected class instead and the line says
    so (`"selected"`); naming several it lacks: nothing is applied (`"skipped"`);
  - a text naming the selected class alone: applied to it; naming other classes the game has: the answer is `"ask"` and
    `fnc_openImportChoice` asks - **Apply to the selected class** (only when the text names one class, and then the highlighted one) or
    **Apply to the classes named in the text** (the highlighted one for several; classes the game lacks are left out and counted) -, and
    `fnc_applyClassImport` runs the import again with the choice (`"selected"` / `"named"`);
  - what cannot mean anything to the selected class is left out: no `grid` for what is no container, no `stack` for what never shares a
    tile, no `like`; if nothing is left the line says so (`"notFit"`).
  All of a kind go through one `fnc_upsertRules` and so one undo step. Nothing is saved: Save decides.

### The picture of an item and of a box (Items, Containers)

- **The Picture row** (`fnc_drawPictureRow`, under Name in the Items step and under the preview of the cells in the Containers step):
  the label, a read-only field with the whole texture path as text - the working copy's, else config's own in the muted ink -,
  **Pick...** and **Reset** (enabled while a picture is set). The field is `fnc_uiEdit` with `selectable` (`EINV_EditReadOnly`,
  `canModify = 0`, enabled): a click puts the cursor in, Ctrl+A / Ctrl+C copy it, and Ctrl+C or Return in it gives the focus back to the sink
  (`fnc_onLoad`) so the wizard's keys (display `KeyDown` returns early while an edit has the focus) work again; it opens nothing. The working copy holds `pictureText` (Items: in the item's canvas under `GVAR(itemWork)`; Containers:
  `GVAR(boxWork)`, per lowercase class, with `iconPercent`, apart from the cells' `GVAR(cellWork)`); the row hands every choice to
  the editor's code, which stores it and draws the editor again. Everything that shows the item by the working copy uses the
  picture at once: the tile preview (`fnc_drawPreview` passes `"picture"` in the tile's entry), the canvas, the box preview.
- **Apply** writes `picture=PATH` when it differs from now; Reset then Apply takes the class's own `picture` away - or, where the item's
  own config sets `einv_picture` that would win again, writes config's own picture path (`getFacts "picture"`, read by
  `fnc_parsePicture`) to win over it. The Containers step's Apply writes the cells (when changed) and `icon=` / `picture=` in one
  `fnc_upsertRule`, and is enabled for a picture change alone; Discard and Back to the default (`grid`, `like`, `icon`, `picture`) clear
  both working copies.
- **The picker** (`fnc_openPicturePicker [current, code, arguments, inUse, class]` - the class `#category` for a category's picture, see the General step's Categories card -> `fnc_popover` in the middle of the wizard;
  `fnc_drawPicturePicker`; state `GVAR(picker)`): a search field, chips under it (`chip`: "Item icons" `items`, "Uniforms & gear" `gear`,
  "Vehicles & boxes" `vehicles`, "All"; the part `"chips"` draws them alone), a page of `PICKER_COLS` x `PICKER_ROWS` (6 x 4) thumbnails each with the
  first owner's name under it (`+N` for the others that share the picture; the tooltip lists the classes and the path), the range and the
  page arrows, a field for any texture path with a thumbnail and a line that says whether the game has the file, and Cancel /
  **Use picture**. A click picks (a ring), a second click on the same one within 0.6 s or Use picture takes it; of the list and the
  path field the one used last is the one Use picture takes. The path field is read by `fnc_parsePicture` with `encoded = false` and
  must name a file that `fileExists` finds (with or without the leading backslash) - a missing file is never given to a control, the
  engine would pop up a message. `fnc_pickPicture [path]` closes the popover and calls the editor's code with `[path, arguments]`.
  It opens on the chip of the edited class's kind (`fnc_pictureCategory` of its index row's kind; "All" for a class the index does not
  list) and on the picture in use - the one set, else config's, passed by `fnc_drawPictureRow` - as `picked`: once the catalog is read
  (`reveal`), its entry is found by the whole path (`byPath` by `fnc_pictureKey`: lowercase, slashes unified, leading slash dropped),
  ringed and its page turned to - only that file, never another picture of a class that owns it too. A crate or vehicle with no picture
  set is drawn by its `editorPreview`, so that is the one in use (config's picture is only the Picture row's text); where the chip does not hold it the chip turns to All; a path the catalog does
  not have is the path field's. A click on a chip or typing in the search before the catalog is read ends `reveal`.
- **The catalog** (`fnc_pictureCatalog`, `fnc_pictureChunk`; uiNamespace `einv_setup_pictures`): the picker's pictures are the distinct
  `picture` values of the class index's rows (`ROW_PICTURE`, already looked at by `safePicture`), one entry each - `[path, lowercase
  path, search text, first owner's name, its class, how many own it (a class once, though its list and editor picture be one file), up to
  `PICKER_OWNERS` 8 classes in lowercase, their names, categories, its `fnc_pictureKey`, the class that owned it last]`,
  sorted by the first owner's name, plus `byPath` for the change lists' "picture from <class>"; a ninth member lists the categories of the owners
  (`items`, `gear`, `vehicles`: `fnc_pictureCategory` of each owner's kind - uniform, vest, headgear and backpack are gear; crate and
  vehicle are vehicles, whose `editorPreview` is catalogued as well as their `picture`; all else, weapons, magazines, attachments,
  kits, goggles, are items), which the chips filter by. Built lazily the first time the picker opens, in
  pieces of `INDEX_BUDGET` seconds on the wizard's queue (like the index itself and waiting for it; a run that was dropped when the
  window closed is taken up again), and kept for the session. The search is `fnc_searchFilter`'s: a plain text anywhere in the path,
  classes and names, a wildcard on the path, a class or a name as a whole; it is worked out once per text, so turning a page does not
  look through the catalog again.
- **The box** (`fnc_drawBoxPreview` -> `einv_gui_fnc_uiBoxPicture`): in the Containers step the box of the class drawn as the window draws
  it (a crate or vehicle with its editor picture unless a picture is set, a uniform, vest or backpack with its config picture or the
  set one), by the working zoom and shift. The change lists word a rule's picture "picture from <class>" where the catalog knows the owner
  (`fnc_describeRule`), else "picture <path>".

### The paint model (Containers) and the item editor (Items)

- **The canvas** `fnc_uiCanvas`: `cols`, `rows` and per place (index `row * cols + col`) either `cells` (bool, Items) or `paint`
  (0 none, 1 to `PAINT_COUNT` 8, Containers, option `palette`). A panel and a hit box per place; a click recolours that one panel,
  rebuilds the outline lines of that place and its four neighbours (at most 20 controls) and calls `onChange [canvas, arguments]`.
  Painting starts on `MouseButtonDown` (deferred); `MouseEnter` with `inputMouse 0` down continues the stroke with the value the
  press decided (uiNamespace `einv_setup_canvasStroke`), so a drag paints a run; any `MouseButtonUp` ends it. Where no press
  arrives, the click alone paints.
- **Colours -> components -> letters.** The brush `einv_setup_cellBrush` (0 none, 1 to 8: `PAINT_COLORS` red, blue, green, yellow,
  orange, purple, cyan, pink; theme-independent): a click paints, a click with the same colour clears. **Compartments**
  (`fnc_canvasBlocks`) are the 4-neighbour components of one colour, in reading order of their first cell, each `[w, h, holes,
  pos]` (holes: box places not its own; `pos` only when there are two or more): two red columns and a blue middle are three
  compartments; an unpainted place is no cell. Apply writes them as one canvas, a letter per component in that order
  (`einv_items_fnc_formatGrid`; one component alone falls back to `WxH` or a mask). The drawing reads like the preview: the theme
  `panel` behind, each place the preview's empty `cell`, painted ones under a `PAINT_TINT` 0.35 tint, each compartment framed in
  its colour.
- **Loading** (`fnc_canvasFromBlocks [blocks, min, max, cols, painted]`): blocks are placed as `einv_gui_fnc_flowCompartments`
  places them. Painted, each block takes a colour greedily in block order from `index mod 8` on, skipping every colour of a block
  it touches, so neighbours never share one. A block whose own holes split it (`x-x`) reads back as two. Rows go up to
  `CANVAS_ROWS_LOADED` 80 when loaded, `MAX_ROWS` when drawn on; the item board is `SHAPE_MAX` wide. An untouched class is never
  rewritten: Apply is enabled only when the blocks differ from the loaded ones.
- **Item editor** (`fnc_drawItemEditor`): width and height steppers (1 to 8), the stack (1 to 999; not for weapons, uniforms,
  vests, backpacks), the weight in kg and the name (two text fields; empty is config's own, and config's weight is the
  placeholder), the **Picture row** (see below), an 8x8 canvas where a click makes a place one of the item's cells, the tile preview, and a warning while the
  cells are not one piece (Apply off). The button row (this editor and the Containers one, `fnc_drawCellEditor`): Discard and Back to the default (the Containers one also "Same as another class") from the left, Apply at the right end - the width of the footer's Save (`fnc_footerButtonW`, the formula of `fnc_drawFrame`'s Back, Next and Save), ending at the editor's right edge so it lies above Save; a button on the left that would reach under it shows its icon alone. Beside the preview, the **zoom block** (`fnc_drawIconBlock`, "Zoom and place", shared with the Containers step): a zoom stepper (25 to 400 %, shown as
  "Zoom 140 %") with chips for 50, 100, 150 and 200 %, two shift steppers, "Across" and "Down" (-100 to 100 % of the tile), and
  Reset (back to 100 % and nothing shifted; enabled while it is not). The working copy holds them as `iconPercent`
  (`[zoom, across, down]` in whole per cent; `ICON_PERCENT_PLAIN` is `[100, 0, 0]`). Each stepper (`fnc_uiStepper`; range
  `[min, max, step, step with Shift]`, here 1 and 10 - the Shift state is taken from `MouseButtonDown`, as `ButtonClick` has none) has a
  text box beside it (`fnc_uiNumber`: `fnc_uiEdit` on a film, read on Return or `KillFocus`, cut to the range, put back when it is no
  number; one `apply` code shared by both, run once - a `done` flag stops the redraw that follows from reading it a second time)
  that calls the same code as the stepper with `[value, arguments]`. A blur that leaves for another control redraws the editor, so
  that control's own click may be lost once, and the preview is `fnc_drawPreview` drawing the
  tile with **`einv_gui_fnc_createTile`** itself - on a piece of grid, the cells under the tile made way for it, name, count and
  full magazine as in a container, at the inventory's cell (`einv_gui_fnc_getCell`) where it fits and as big as fits where not, the
  entry carrying the working `"icon"` - so the picture is seen as Apply will write it. Apply writes `class=X > size=WxH` or
  `size=xx/x-`, `stack=N`, `weight=KG`, `name=...`, `picture=PATH`, `use=LIST` and `icon=ZOOM@ACROSS:DOWN` (as `[scale, across, down]`, 1.4 and 0.1 for 140 % and
  10 %), each only when it differs from now; a field emptied takes its own value away. Reset then Apply takes the class's own `icon`
  away when nothing below draws the picture otherwise, else writes the plain picture (`icon=1`) to win over the item's `einv_icon`.
  "Back to the default" removes `icon` with the rest; the tree view's edits write `class=X+ > icon=...` like the other fields;
  Export writes `einv_icon = "1.4@0.1,-0.05";` (`fnc_configEntry`) and Import reads it (`fnc_configValues` maps `einv_icon` to
  `icon`); The change lists word it ("picture at 140 %, moved 10 % across and -5 % down", `fnc_describeRule`). The weight is read by `fnc_weightValue` (a dot or a comma,
  rounded to the gram, at most `EDIT_WEIGHT_MAX` 1000; -1 for nothing typed, -2 for text that is no weight, which Apply refuses and
  says), the name cut to `EDIT_NAME_MAX` 100 (the rules' `name=` encoding is `writeRules`' business). Typing goes into the working
  copy (`weightText`, `nameText`) without drawing the editor again - the field would lose the cursor -, Return draws it again, and
  Apply reads the working copy.
- **Use from** (`fnc_drawUseRow`, the Items step, under the Picture row): a chip each for Uniform, Vest and Backpack, on for the
  containers the class is whitelisted for (`use=`, `einv_use`; `info "use"`), and a muted line under them of what the settings
  "Use items from ..." (`einv_storage_useUniform`, `useVest`, `useBackpack`) limit now - "Limited now: Backpack: only
  whitelisted." or, when all three are on Everything, a note naming the settings. The chips are always clickable: the rule belongs to
  the item and travels with the rules text and the config export, whatever this mission's settings are; with a container on
  Everything its chip changes nothing in the game, and with one on Nothing a whitelisted item is not usable there either. The
  click goes into the working copy (`useList`, in the order uniform, vest, backpack), the editor is drawn again and Apply
  writes `use=` only when it differs from now - an emptied list as `use=none`, which takes back what a broader rule whitelisted
  (Back to the default removes the class's own `use` with the rest). The tree view's edits write `class=X+ > use=...` like the other
  fields, so `kind=grenade` is one tree edit away. Export writes `einv_use = "backpack,vest";` (`fnc_configEntry`), Import maps
  `einv_use` to `use` (`fnc_configValues`), The change lists word it ("usable from the Vest, Backpack", `fnc_describeRule`).
- **Category** (`fnc_drawCatRow`, the Items step, under Use from): a chip for each of the eight categories (`ITEM_GROUPS`), on for the
  ones the class is in now (`info "groups"`: `cats=` / `einv_cat`, else the built-in one), wrapping onto a second line where they do
  not fit; at least one stays on. A click goes into the working copy (`catsList`, in the order of `ITEM_GROUPS`), the editor is drawn
  again, and a reset button appears while the list differs from the built-in one (`fnc_classDefault`). Apply writes `cats=` when it
  differs from now, and takes the class's own `cats` away when the list is the built-in one again; the tree view writes
  `class=X+ > cats=...`. Export writes `einv_cat = "medical,misc";` (`fnc_configEntry`), Import maps `einv_cat` to `cats`
  (`fnc_configValues`), the change lists word it ("category: Medical, Misc", `fnc_describeRule`).
- **Blocks mode** (`fnc_drawCellBlocks`): the switch "Paint | Blocks" (`einv_setup_cellMode`, 0/1, kept for the session). One
  small drawing per compartment (a click toggles a hole), width and height steppers for the picked one, Add and Remove; working
  copy `{blocks, picked}`; Apply writes the blocks joined by `+` (flow layout). A class drawn as a canvas gets a note that Blocks
  loses the positions. Switching converts the working copy: Paint -> Blocks takes the components in reading order without `pos`;
  Blocks -> Paint lays them out and colours them as loading does.
- **Accepts and single slots in the Blocks way** (`fnc_drawCellAttrs`, `fnc_cellBlock`): under the tools row, two rows for the picked
  compartment - "Accepts" with a chip for All and one for each category (a click on All takes the lock away, one on a category adds it
  or takes it out, the last one out is All again) and "Single slot" with the chip "One item, any size". The working copy keeps a
  compartment as `[cols, rows, holes]` while it takes anything and is no slot, `[cols, rows, holes, [], accepts, single]` once it
  does (`fnc_cellBlock` is the one form, so copies compare equal and go to the preview and to `formatGrid` as they are); Apply writes
  `grid=...:ammo+...`. Each compartment shows what it takes under its cells. The preview and the inventory draw a locked empty
  compartment with its category's picture.
- **Accepts and single slots in the Paint way** (the same `fnc_drawCellAttrs`, `fnc_canvasBlocks`, `fnc_canvasMatch`,
  `fnc_canvasPick`): each compartment the painter produces has the same two rows. Above them a row picks the compartment: a stepper
  "Compartment 2 / 5" through the compartments in reading order and the chip "Select on canvas" (`einv_setup_cellBrush` -1: a click on
  the drawing picks the compartment it hits and paints nothing, no stroke). The picked one is framed in white and a pixel thicker on
  the drawing (`fnc_uiCanvas` options `picked` and `onPick`; `canvasPickSet` on the group changes the frame without drawing the
  canvas again). The canvas (`fnc_canvasFromBlocks` painted) carries `attrs`, `[[places, accepts, single], ...]` for the
  compartments that have any, the places being the indices of the compartment's cells at the time. `fnc_canvasBlocks` hands each
  entry to the compartment that now has most of those places (`fnc_canvasMatch`: first on a tie, a compartment taken only once, a next
  best for the second of two that grew together) - so a split compartment keeps its attributes on the larger part, a merge takes
  the first's and a compartment painted away loses them - and returns the blocks as `parseGrid` gives them, `[cols, rows, holes, pos,
  accepts, single]` (`[cols, rows, holes, [], accepts, single]` where it drops the pos of compartments that lie as the flow would put
  them; a plain one `[cols, rows, holes, []]`). Asked to sync (second argument) it also writes `attrs` with the places as they are now,
  `parts` (per compartment its places, ascending) and `label` (per place its compartment) into the canvas; the editor syncs each time
  it is drawn and on every paint change, so the next change maps from the compartments as they were. The picked compartment is kept the
  same way, as its places (`GVAR(cellPick)`, lowercase class -> places; `fnc_canvasPick` finds the compartment that has most of them,
  the first when none is left), so it stays picked while compartments before it appear or go. A paint change that leaves the number of
  compartments, the picked one and what it accepts as they were only updates the frame, the total and the preview; any other redraws the
  editor (the stepper's range and the chips). A chip click writes `attrs` of the working copy (made on the first change) and redraws.
  Apply writes the canvas letters with them, `grid=aab/aab:a=ammo:b=grenade|one`, or - where the compartments lie as the flow would put
  them - `2x2:ammo+1x2:grenade|one`, exactly the text `parseGrid` reads. Switching Paint and Blocks carries attributes and the picked
  compartment over (blocks as `fnc_cellBlock`, canvas through `canvasFromBlocks` and `canvasBlocks`), "Copy cells of X" keeps X's
  attributes in either way, deleting a category takes it out of `attrs` as well as of the blocks, and the "Back to the default" button
  also appears for a change of attributes alone. The preview draws the first category's picture, large and faint, in the middle of a
  compartment that accepts only some (a single slot a little stronger), as the inventory does for an empty one (`fnc_drawPreview`), and
  the change lists word them after the compartments, "(takes only: Ammo; Grenade · one item)" (`fnc_describeRule`).
- **Same as another class** (`fnc_drawSameAs`): a popover on the button (`fnc_popover`): a search over the index's containers
  minus itself, 8 to a page. A pick offers **Follow X** (writes `like=X` and removes the own `grid`, which would win over it) and
  **Copy cells of X** (X's `fnc_classBlocks` into a working copy in the current mode, `unlink` set when the class has `like=`, so
  Apply also removes it). A linked class shows X's cells read-only with a chip "Same as X · Unlink"; a copied working copy is
  editable even while `like=` stands.
- **Working copies**: `einv_setup_cellWork` (lowercase class -> a painted canvas, or `blocks` and `picked`; optional `unlink`),
  `einv_setup_itemWork`; the first change makes the copy, Discard drops it, "Back to the default" removes `grid` and `like`. Apply
  checks no cell, `MAX_CELLS`, `MAX_BLOCKS` and a drawing taller than `MAX_ROWS`, and writes through `fnc_upsertRule`. A grid laid
  out by load or by a pattern is shown as the compartments it gives; editing it writes those cells instead.
- **Preview** (`fnc_drawPreview`): the window's own `flowCompartments` with the blocks Apply would write, so painted
  compartments sit where they were painted with the window's seams between them, each on its panel as the window draws it, every
  cell the same size and gap (the cell and the pads whole pixels; the cell a little smaller where a canvas's seams would make it
  wider than the card), and blocks flow; an item's tile on a
  piece of grid. One routine for Paint and Blocks: an untouched class previews its own `classBlocks` (places included) in both
  ways, an edited one what Apply would write. `fnc_canvasBlocks` drops the `pos` of painted compartments that lie exactly where
  `fnc_canvasFromBlocks` (places only, 6th argument) would flow them, so they read, preview and are written as the Blocks way's
  `6x4+...` blocks; only a layout the flow cannot make stays a canvas.

## 7. Other addons

### hotbar (`einv_hotbar`)

The keys 4 to 0 use what lies on them, and every item on the bar really does something: a bandage bandages the part that bleeds
most, a tourniquet goes on the worst bleeding limb, a grenade goes into the hand, a magazine reloads the weapon in the hands, a
kit opens. The addon needs only CBA, `ace_common` and our own addons; ACE medical, advanced throwing, field rations, EFAK and
`compat_efak` are called behind `isNil` guards. The gui calls the hotbar only through `isNil`-guarded `EFUNC(hotbar,x)` and only
in the inventory: the row under the gear (`fnc_drawStrip`), `fnc_hintParts`, the drag trio (`fnc_canBindFrom`, `fnc_bind`; target
`["hotbar", slot, 0, 0, fits, reason]`), `fnc_menuChoices` / `fnc_stripMenu`, `fnc_onWindowKey`, `fnc_footerHint`. A hotbar slot
is an ordinary slot record of `fnc_drawSlot` with the slot's number at element 7 (-1 for every other slot), so nothing that drags,
equips or shows targets for real slots touches it.

- **Slots.** `SLOT_COUNT` 7 on 4 5 6 7 8 9 0 (DIK 5 to 11); CBA keybinds `einv_hotbar_slot1` to `slot7` and `einv_hotbar_show`. A
  slot is bound to a **class**: any carried item of that class is used and the bar shows how many there are; a class sits in at
  most one slot. Kept per player in the profile (`einv_hotbar_slots`), so a respawn keeps the bar.
- **What an item does** (`fnc_useOf [class] -> [kind, data]`, public, cached): `"kit"`, `"throw"` (anything the `Throw` weapon
  takes), `"consume"` (ACE field rations), `"medical"` (an item one of ACE's treatments lists), `"reload"` (a magazine that
  `storage fnc_partFor` puts on a carried weapon), `""` (refused). Binding is refused for what is not carried (`fnc_canBindFrom`) and for what lies in a container the settings "Use items from ..." close to it (`einv_storage_fnc_useState`: "Cannot be used from the backpack"); counts, the magazine, the kit and the grenade only see what `einv_storage_fnc_useCarried` leaves (section 3, Use from containers).
- **Medical** (`fnc_treatmentIndex`, `fnc_pickTreatment`, `fnc_whyNot`, `fnc_useMedical`): the index is read from
  `ace_medical_treatment_actions` (ACE's and other mods', ACM's among them); the role (bandage, tourniquet, splint, any) picks the
  part: bandage - the largest sum of wound amount times bleeding rate; tourniquet - the worst bleeding limb without one; splint -
  a leg before an arm; any - a free arm, then a leg, the torso, the head. Every candidate must pass
  `ace_medical_treatment_fnc_canTreat`; the first that does is started with `ace_medical_treatment_fnc_treatment` (ACE's progress
  bar and settings); a second press goes to the next part, with none `fnc_whyNot` names the reason.
- **Throwing, magazines, food** (`fnc_useThrowable`, `fnc_useMagazine`, `fnc_useConsumable`, `fnc_useKit`): with ACE advanced
  throwing the key takes the throwable into the hand and left click throws; a magazine reloads the weapon in the hands with the
  fullest magazine of the class not loaded; food and drink call `ace_field_rations_fnc_consumeItem`; a kit opens the window on the
  own gear with the kit inside, else `efak_core_fnc_openKit`.
- **Keys** (`fnc_onKey`, a frame later `fnc_use`): left to Arma and ACE when the slot is empty, while a command menu is open, in
  Zeus or a feature camera, and - `einv_hotbar_leaderKeys` - while the player leads AI; a second press within `USE_LOCK` 0.4 s is
  ignored. CBA keybinds do not run in a dialog, so the window asks `fnc_onWindowKey` itself: over a tile or an own slot a slot's
  key binds the item, over a hotbar slot it swaps the two, the drop key (`fnc_isDropKey`) empties it. A filled slot of the
  window's row can also be dragged: onto another slot it swaps, anywhere else it is removed (gui `fnc_startStripDrag`). `fnc_checkKeys` names, once per profile, every other
  keybind on the same keys. `fnc_bind [index, class, from, checked]`, `fnc_unbind`, `fnc_use` are public.
- **The bar on the screen** (`RscTitles >> einv_hotbar_RscHud`, `CfgUIGrids` entry `einv_hotbar_grid`, movable in Arma's layout
  editor): seven boxes (key, picture, count, a thin bar) and a message line, run by `fnc_hudPing` / `fnc_hudFrame` /
  `fnc_hudDraw`; `fnc_hudWanted` hides it in dialogs, Zeus, when unconscious, in the map; then `einv_hotbar_hudMode` decides.
  An item whose rules draw its picture larger, smaller or moved (`icon=`; `fnc_slotInfo` has its `"icon"`) shows it in the slot's
  twin of the picture, inside an `EINV_HotbarClip` group of the picture's place that cuts it (made with the box by `fnc_hudCreate`,
  hidden until a slot needs it; the plain picture is hidden meanwhile, and the offsets are a share of the whole box).
  Nothing goes over the network.

### weight (`einv_weight`)

The engine weighs every item by its config whatever `weight=` says. This addon makes the rules' overrides count where players feel
them, and adds the tiers.

- **Virtual load.** `fnc_getExtraLoad [unit]` is, for everything the unit carries (worn, weapons with attachments and loaded
  magazines, the contents of uniform, vest and backpack, nested containers), `getInfo "mass" - getInfo "configMass"` times the
  count. `fnc_updateVirtualLoad` hands ACE only the difference to what it applied before (`einv_weight_appliedLoad` on the unit,
  public) through `ace_movement_fnc_addLoadToUnitContainer` on the unit itself, never on a container, which could be dropped with
  our share on it. `fnc_queueVirtualLoad` runs it and `fnc_updateTier` once a frame, queued on the player's unit changing, CBA's
  loadout event, `einv_items_rulesChanged` and every `NESTED_CHECK_INTERVAL` 3 s; a check every `TIER_CHECK_INTERVAL` 1 s compares
  `[load, limits key, effects switch]`. Nothing runs in Eden, but `getLimits`, `getLoad`, `getTier` answer there.
- **Tiers.** `fnc_getLoad [unit]` (public) is ACE's total. `fnc_getLimits [unit]` (public) gives `heavy`, `overloaded`, `critical`
  in config mass and `heavyKg`, ..., `fromAce`, `aceFatigue`, `key`, cached under a key made of every input. Overloaded
  (`einv_weight_overloadedAt`, 45 kg) and Critical (`criticalAt`, 60 kg, at least 1 kg above Overloaded) are settings; Heavy
  (`heavyAt`, 0 = follow ACE) is where ACE Advanced Fatigue's own jog (12 km/h, weapon lowered, `JOG_SPEED`) costs more than the
  body keeps up aerobically (`fnc_heavyFromAce [performance, load factor]`; 26.7 kg at ACE's defaults). With ACE's fatigue off,
  Heavy is 60 % of Overloaded; never later than Overloaded. `fnc_getTier [unit, load = -1]` (public) answers `TIER_LIGHT` to
  `TIER_CRITICAL`; `fnc_tierText [tier, limits]` (public) the words and the effect ("jogging tires you", "no sprinting, tiring
  faster", "walking only"; "" where it does not apply).
- **Effects** (`fnc_updateTier`, `fnc_applyEffects`, the player's machine only): from Overloaded ACE's status effect
  `blockSprint`; from Critical `forceWalk` (reason `einv_weight`, through `ace_common_fnc_statusEffect_set`); and an ACE Advanced
  Fatigue duty factor (`addDutyFactor`, reading `einv_weight_duty` on the unit) climbing from 1 at Overloaded to
  `OVERLOAD_DUTY_MAX` 1.5 at Critical. `einv_weight_effects` off keeps the bar and takes the effects off. No `setAnimSpeedCoef`:
  ACE resets it every second. A tier change raises the local CBA event `einv_weight_tierChanged [unit, tier, old tier]` and, with
  the inventory closed and `einv_weight_notify` on, an ACE message (`fnc_notifyTier`). Nothing is ever refused because of a tier.
- **Off switch** (`einv_weight_enabled`, global, default on, first in the Weight category). Off: `fnc_getLimits` still works out
  the marks (the bar needs an end) but sets `enabled` false in the map and in its `key`; `fnc_getTier` then answers `TIER_LIGHT`
  for every load, `fnc_tierText` `["", ""]`, `fnc_notifyTier` says nothing, and `fnc_updateTier` sets duty 1 and, as the tier fell
  to Light, takes `blockSprint` / `forceWalk` off through `fnc_applyEffects` (which also reads the switch). The duty factor
  registered with ACE answers 1 at once while off. The flip is seen by the 1 s tier check (the limits key changed) and redraws an
  open window (its signature holds the key). The weight card and its hint (`einv_gui_fnc_drawEquipmentCards`, `fnc_infoHint`) read
  `enabled` too: only the kilograms, no next tier, no tiers above. What stays: the load (`fnc_getLoad`), the virtual load of the
  rules' `weight=` overrides handed to ACE, and ACE's own fatigue, untouched.

### magazines (`einv_magazines`)

Repacking, needing `ace_magazinerepack`; setting `einv_magazines_repack`. A partly filled magazine dropped on a partly filled one
of the same class (target `["repack", gridIndex, tileIndex, 0, fits, reason]`, footprint in the accent colour), or "Repack all
<name>" in the menu of an own magazine, runs ACE's schedule (`ace_magazinerepack_fnc_simulateRepackEvents`, ACE's time settings),
sounds, kneel and gesture; the progress shows in the window (a film on the tiles, a bar moving with every round, live rounds
text), not in ACE's progress bar, which closes dialogs. Rounds go from the emptier into the fuller; each result stays in its cell;
an emptied magazine is gone. Both magazines must lie under the same root (`fnc_domain` via `einv_storage_fnc_rootOf`): the
player's own gear or one crate, vehicle, pile or body; a living person's gear, kits, virtual grids and loaded magazines never take
part. A mouse press or Escape stops it (`einv_gui_swallowUp`). **One commit** at the end (done, stopped, closed): `fnc_commit`
sends one phase `[root, [["repack", [parts]]]]` through `einv_storage_fnc_request`, parts `[container, class, rounds before,
rounds after, cell]`; the op `repack` (`einv_storage_fnc_opRepack`) checks at the authority that each was partly filled before,
none over full after, whole rounds, the same sum, and that every magazine is still there with those rounds ("Gone" otherwise,
nothing changed); the record of a magazine that lay alone comes back at the same cell with the key of its new rounds
(`class|m<rounds>`). ACE's CBA menu row "Repack Magazines" is hidden while repacking is on (`fnc_hideCbaOption`).

### locks (`einv_locks`)

A crate or vehicle can be locked to one side, one group or the admins. **The record** `einv_locks_lock = [mode, who]` on the
object, public: `["side", west]`, `["group", <GROUP>]` or `["group", "Alpha 1-1"]` (a callsign), `["admins", ""]`; nil when not
locked. Written only by `fnc_setLock [object, mode, who]` (public; `""` opens it again; people are refused), which sends a
client's request as the server event `einv_locks_set`; the server writes the record, the public list `einv_locks_objects` and
raises the CBA event `einv_locks_changed [object]`. `fnc_getLock` and `fnc_describe` (public) read and say it. `fnc_isAllowed
[unit, lock]` passes members (the side of the unit's group, the group, the callsign), logged-in admins (`fnc_isAdmin`) and Zeus
while `einv_locks_zeusOpens` is on. **The engine lock** per client (`fnc_refresh`, `fnc_refreshAll`, re-evaluated on every change
and every `LOCK_RECHECK` 1 s): each client runs `lockInventory true` on its own machine on every locked object its player may not
open, undoing only the lock it set (a mission's own is never lifted). **The question** every gate asks: `fnc_canReach [unit,
container, root] -> [ok, reason, tip]` (public): the container's own lock, the lock of the object it is attached to or lies in up
to `MAX_DEPTH` 3 containers deep (`fnc_lockHolder`), or the root's; then a mission's `lockInventory`; then the **providers**
(`fnc_addProvider [code]`, public: `[unit, container] -> refusal text or ""`; they read only what is the same everywhere). **The
guard** `fnc_guard [op, args, requester, root]` is in `einv_storage_guards`, runs on the machine that runs the op, whoever sent
it, and answers `"Locked"`; settlement skips it. **Eden** (`Cfg3DEN.hpp`): "Inventory locked to" and "Group callsign" on crates
and vehicles, applied at mission start (`fnc_applyEden`). **In the window** `fnc_decorate [unit, sections, opened]` turns a
section the unit may not reach into a `locked` one; the other gates are the engine lock, `fnc_onInventoryOpened`,
`fnc_sendMoves`, `fnc_quickMove` and the guard.

### compat_efak (Enhanced First Aid Kits and Enhanced Utility Pouches)

A kit opens as a **floating window** inside the window (section 4), its contents tiles; dragging packs and unpacks. Kit contents
are EFAK's global table keyed by the instance class, so a kit opens wherever the window shows its tile. A kit is a holder of the
storage, `"kit:" + lowercase class` (`einv_storage_holderTypes "kit"`), whose root is the root of the container it lies in
(`fnc_holderRoot`, `fnc_holderVerify`); its ops `kitTake`, `kitPut`, `kitPlace`, `kitMove`, `kitRemoveIfEmpty` run at that root's
authority, so every write of one kit happens on one machine (EFAK sends the whole kit with every write and the last write wins). A
kit grid is non-virtual with `container` objNull plus `kit` and `layoutKey`; every move path outside the compat exits on objNull.
Open kits are `einv_compat_efak_opened`; where each lies is found anew at every build (`fnc_getSections`: in the cargo of every
container the window shows, else in another open kit, up to `KIT_MAX_DEPTH` 4); found nowhere it closes. `fnc_drop [source,
target, entry, count, cell, slotSource]` is the dispatcher (checks `fnc_canDrop`, `fnc_mayReach`, `einv_gui_fnc_checkTouch`, then
one `sendMoves` move). Prototypes (`efak_core_needsConversion`) are refused until EFAK made them. Another living player's kits are
shown but neither opened nor moved (`fnc_isPlayerGear`, `fnc_checkTile`). No `efak_*` function is called outside this addon;
`fnc_isKit` is public.

**A kit's room** (`fnc_roomMode [kit, compiled, cache]` -> `"capacity"` / `"cells"`, public): a kit is a container of the rules
(kind `kit`, section 2) whose grid counts only where someone set it - a rule of the rules text or the older table, or the class's
config key (`einv_items_fnc_setBy` `"rule"` / `"config"` on the `grid` field). Then **cells**: the grid is all its room, Enhanced
First Aid Kits' capacity counts nowhere in this mod. Else - the preset's or the built-in answer - **capacity**, as before: that mod's
masses against its capacity, and an open grid that grows. Everything that decides what goes into a kit asks it:

- `fnc_kitBlocks [kit]` -> the compartments of its grid (`einv_storage_fnc_blocksFor` with kind `kit`, its `maxLoad` the type's
  capacity, so `grid=auto` and `grid=120%` are by capacity), `[]` by capacity; kept per class until the rules change
  (`einv_compat_efak_blocksCache` `[revision, map]`). It is the holder type's `"blocks"`, so the storage lays the kit out in those
  compartments (`fnc_getLayout`, `fnc_hasSpace`, `fnc_findEntry`) and the window draws them in its kit window.
- `fnc_canPack [kit, class, count, rounds]`: that mod's rules and defaults as before, then the room - capacity, or
  `fnc_hasCells [kit, class, count, rounds]` (the kit laid out with them added, piles of their kind filled first, magazines by their
  rounds; `"NoRoom"`). `fnc_canDrop`, `fnc_putIntoKit` (the payload's rounds), `fnc_opKitMove` (the tile's rounds) and
  `fnc_canPackNew` pass the rounds.
- `fnc_cellFree [kit, view, cell, holes, skip]`: a cell inside the compartment it names (bounds, the compartment's holes) and free -
  for `fnc_putIntoKit` and `fnc_opKitPlace`, which keep the compartment of the cell (was always 0).
- `fnc_fillState [kit]` -> `[text, over]`: "12 / 35 mass" (over: past the capacity) or "8 / 12 cells" (over: tiles with no cell -
  a grid given to a full kit; they show apart and are never lost), for `fnc_getSections` (`load`, `loadOver`), `fnc_hintParts` and
  `fnc_inspectRows`. `fnc_getMass` still reports what the kit weighs.
- `fnc_capacity [kit]` (public) -> that mod's capacity (its CBA setting over config), the registry's where its functions are not
  there, -1 for no kit - the setup wizard's "capacity 35 (EFAK)".

**ACE Arsenal** (section 5): `fnc_canPackNew [kit, class, count]` -> `[how many it takes, why not all]` (`fnc_notReady`, the
kit type's Arsenal setting `efak_core_fnc_canPackInto [kit, true]`, `fnc_canPack`; as many as fit by halving) and `fnc_packNew
[kit, class, count, cell, root]` -> `[added, why, landed]`: only for a root whose phases run here (`einv_storage_fnc_isLocalRoot`)
with the kit under it (`fnc_holderVerify`), so the one writer of the kit is this machine - written where it is called, outside any
phase, as `einv_storage_fnc_addNew` does (`einv_storage_fnc_makePayload`, `fnc_putIntoKit`, `fnc_requestRebuild`).
`fnc_arsenalSections` notes where each kit it returns lies in `GVAR(arsenalHolders)` (lowercase class -> `[container, ""]`, made anew
at every call; the panel calls it with `[]` outside kit mode, `fnc_onWindowOpen` empties it). No kit window is open in ACE's window,
so `GVAR(holders)` stays empty there (`fnc_getSections`), and the engine's moves between a kit's grid and the staging space or a
container (`fnc_drop` -> `fnc_locate`, `fnc_canDrop`, `einv_storage_fnc_rootOf` -> `fnc_holderRoot`) found the kit nowhere and
were refused with "Failed" in either room mode (issue #4); `fnc_locate` and `fnc_canDrop` fall back to it, and `fnc_signature`
counts those kits' places as an open kit's. Enhanced First
Aid Kits' own kit window and its kits tab in ACE's window still count the capacity: a kit with a grid of its own may hold more than
its capacity there.

### compat_ace_cargo, compat_tfar, compat_acre, compat_zen, compat_ace_vehiclelock, compat_ace_interaction, compat_aime

- **compat_ace_cargo.** `fnc_getSections [lootSections]` adds, right under every container section with things loaded
  (`ace_cargo_loaded`), a section `id "cargo"` with `vehicle`, `parent`, `items` and `drawer` (the name of `fnc_drawSection`),
  which draws a card per thing (picture, ACE's name, size and damage, Open or Close and Unload) with no grid. `fnc_rowState
  [holder, item, unit]` decides what a button may do (not for a locked vehicle or a crate locked to the player, a size ACE cannot
  unload, in the air, beyond ACE's reach, another unloading). `fnc_toggleOpen` puts a crate into the window's `opened` list as
  `[class, crate, vehicle]` (`fnc_pruneOpened` drops it once it left the cargo). Unloading (`fnc_startUnload`, `fnc_unloadFrame`,
  `fnc_stopUnload`, `fnc_finishUnload`) does not use ACE's progress bar, which closes dialogs: the button becomes a bar over ACE's
  time, kept up by a per-frame handler applying ACE's own condition, and at the end `ace_cargo_fnc_unloadItem` runs.
- **compat_tfar / compat_acre.** The same function names in both, asked through `einv_gui_fnc_compatCollect`: `fnc_tooltip [class,
  holder]`, `fnc_hintParts`, `fnc_inspectRows`, `fnc_menuChoices [class, holder, own, inSlot]` ("Open radio", "Use as active
  radio"), `fnc_open`, `fnc_makeActive`. Everything is read-only from the mods' data (TFAR's raw `TFAR_RadioSettingsNamespace`,
  since `getSwSettings` writes defaults; ACRE2's through `acre_sys_data_fnc_dataEvent`). "Open radio" steps aside
  (`einv_gui_fnc_stepAside`) and calls the mod's own dialog function, for the player's own radios only; "Use as active radio" is
  the mod's call followed by `einv_gui_fnc_requestRebuild`. compat_tfar adds `"radio_settings"` to `einv_storage_carryVariables`.
  compat_acre fixes the dummy radio ACRE2 keeps in the radio slot (`fnc_isFixedSlot [unit, slot]`): it cannot be lifted, taken off
  or dropped, accepts nothing (`slotAccepts`), its menu has Inspect only, and `fnc_guard` in `einv_storage_guards` answers
  `"Failed"` to `takeOff` and `putOn` there.
- **compat_zen.** The right-click menu "Inventory lock" on crates and vehicles and the module "Lock inventory" (`fnc_module`,
  `fnc_apply`, `fnc_groupDialog`, `fnc_groups`, `fnc_targets`); the lock goes through `einv_locks_fnc_setLock`. It also adds "Searching: turn off" / "Searching: turn on" to the same menu (`fnc_setSearch`, `fnc_canSetSearch`): the mark `einv_noSearch` through `einv_gui_fnc_setSearchable` (section 4, "Leaving an object out of the search").
- **compat_ace_vehiclelock.** ACE's vehicle lock as a provider of `einv_locks` (`fnc_check`):
  `ace_vehiclelock_LockVehicleInventory` on, the player on foot, a Car, Tank or Helicopter, `locked` 2 or 3, and no key by
  `ace_vehiclelock_fnc_hasKeyForVehicle`. ACE blocks only the vanilla display 602, which this window never opens - without the
  provider ACE's lock would be bypassed.
- **compat_aime.** ACE Interaction Menu Expansion (AIME, Workshop 1376867375, author upsilon). Its CfgPatches `UPSL_aime_change_ammo`
  and `UPSL_aime_inventory` are required, so the addon is skipped without them. AIME adds these actions that touch the inventory (read
  from its pbos); what is done with each:
  - *Self action "Change Ammo Type"* (`UPSL_aime_change_ammo_ammo_class`, CAManBase, `ACE_SelfActions`). Its children are built by a
    `CfgFunctions` function, final and unchangeable, that lists `magazines _player` (every container, the backpack too) and loads with
    `addWeaponItem [weapon, [mag, 0]]` + `reload` (the engine picks any magazine of the class) - a bypass of the use limits.
    **Replaced**: postInit waits until AIME has put its action into `ace_interact_menu_inheritedActionsMan`, takes it out
    (`removeActionFromClass` with inheritance: out of every class built so far and kept out of every later one) and adds one of the
    same name, label, icon and place (`fnc_ammoCondition`, `fnc_ammoMenus`, `fnc_ammoLoad`). AIME's setting "Enable ammo switch
    menu" is still read. The list is the magazines `einv_storage_fnc_useCarried` leaves that the muzzle takes and that are not
    loaded, grouped by class (the class in the weapon is left out, as AIME leaves it out); with only closed containers' magazines
    left, one entry says where to take one out of. A click loads the fullest usable magazine of the class (ties: uniform, vest,
    backpack) with `einv_storage_fnc_loadMagazine`. AIME's `Reloaded` handler (it gives the old magazine back with `addMagazine`)
    never has a flag to act on, since its own loader no longer runs.
  - *Self action "Change Ammo Type" of a vehicle gunner* (`..._vehicle_ammo_class`, LandVehicle): the vehicle's turret magazines, not
    the unit's inventory. Left alone.
  - *"Inventory" on a vehicle* (`UPSL_aime_inventory_open_action`; Car, Tank, Helicopter, Plane, Ship_F), *"Open backpack"* on a
    living person (`..._backpack_action_3d` and `..._backpack_action`), *"Inventory" on a body* (`..._open_action` on CAManBase),
    *"Open"* on a pile's backpack (`..._holder_open_action`): all end in the engine's `action ["Gear" | "OpenBag", ...]`, which
    section 4 ("Opening") answers with this window and its checks (locks, `einv_noAccess`, `fnc_personInReach`, the search), so they
    cannot bypass anything. What the config patch changes is when they show: the vehicle entry only where
    `einv_gui_fnc_canOpenVehicle` holds (`fnc_vehicleCondition`) and not at all beside `compat_ace_interaction`'s own "Inventory"; the
    living person's backpack entries only where `fnc_canOpenPerson` and `fnc_personInReach` hold (`fnc_personCondition`). The body's
    entry is as it was (bodies are open to everyone).
  - *Ground pile action* (`UPSL_aime_inventory_holder_action`, WeaponHolder and WeaponHolderSimulated): one click picks up the only
    item lying there (`TakeWeapon`, `addMagazine` + `clearMagazineCargoGlobal`, `PutBag` / `AddBag`) with no search. Its statement is
    patched to `fnc_holderRun`: while `einv_gui_searchTime` is above 0, `einv_gui_searchGround` is on and the pile has no
    `einv_noSearch`, the click opens the window on the pile (`action ["Gear", pile]`); otherwise AIME's own pick-up runs.
  - *Static weapon assemble / disassemble* (`..._assemble_action`, `..._disassemble_action`, the `WeaponAssembled` handler that clears
    a base backpack) work on the engine's backpack of a static weapon, which has no cargo: left alone. AIME's UAV terminal, group,
    vehicle seat and vehicle control actions do not touch the inventory.
- **compat_ace_interaction.** Needs `ace_interact_menu` (skipped without it). In postInit, on machines with a screen: ACE
  interaction "Inventory" with the inventory icon, under `ACE_MainActions` of `CAManBase` (type 0, with inheritance, so agents and
  respawned units too). Condition `fnc_canOpen [target, player]`: not the player, `einv_gui_fnc_canOpenPerson` not "" (the
  "Living persons" settings: whole or only the backpack) and `einv_gui_fnc_personInReach [player, target, true]` (both on foot,
  `PERSON_KEEP`, ACE's `canInteractWith` with `isNotSwimming`). Statement: `einv_gui_fnc_openPerson [target]` a frame later
  (`CBA_fnc_execNextFrame`), exactly as the action menu's "Inventory" (`einv_gui_fnc_addPersonAction`), which stays.

## 8. Settings

Every CBA setting of the mod (`initSettings.inc.sqf` of each addon) is in one of two categories of CBA's Addon Options:
`CBA_SETTINGS_EINV_CLIENT` "Arma Inventory Overhaul - Client" for what each player sets for himself (scope 0) and `CBA_SETTINGS_EINV_SERVER`
"Arma Inventory Overhaul - Server" for the settings box, the rules and the older tables (scope 1). The keybinds stay under `CBA_SETTINGS_EINV`
"Arma Inventory Overhaul" (CBA's Controls, `CBA_fnc_getKeybind` asks for it). A setting's name does not carry its category, so a `cba_settings.sqf` and
saved values are the same under either; `fnc_initCbaMenu` takes its page from the category of `einv_items_rules` (the Server page). Scope **client** is
`0` (each player's own value), **global** is `1` (the same for everyone; the server or mission decides). Descriptions in the
stringtables are wrapped as BRIEFING asks.

**Server settings** - the ones of scope 1 - are no rows of CBA's menu. Each addon registers its own with
`einv_main_fnc_addSetting [name, type, [label, description], valueInfo, script = {}, hidden = false]` (the arguments of `CBA_fnc_addSetting`
less the category and the scope, in `initSettings.inc.sqf`): `einv_main_serverSettings` (name -> definition: `type`, `label`, `tip`, `default`, `min`,
`max`, `decimals`, `values`, `labels`, `script`, `hidden`, `key`), `einv_main_serverKeys` (key -> name), `einv_main_serverOrder`. The variable exists at
once, set to what the box below holds for it by then (CBA has read the box before any addon registers), else the default - as CBA
sets a row's variable at once and runs its script only later. Their values are the text of **one CBA EDITBOX, `einv_main_settings`** (scope 1, default "", title "Server settings - set in
the setup wizard, do not edit", sanitized by `einv_main_fnc_sanitizeSettings`): `einv1, gui_searchTime=0.6, weight_enabled=0` - the header, then
`key=value` for each setting that is off its default, in registration order, the key the name without `einv_`. A switch is `1` or `0` (also `on`, `off`,
`true`, `false`), a slider a number cut to its range and rounded to its decimals, a list the value of one of its choices, a text box free text with
`%` and four hex digits for every character that is not a letter, a digit, `-` or `.` (`fnc_encodeText`, `fnc_decodeText`). `fnc_parseSettings [text]` ->
`[values, warnings]` (public; a typo is left out with a warning, never the rest), `fnc_writeSettings [values]` -> the canonical text ("" for none; public),
`fnc_parseValue [entry, text]`. **`fnc_applySettings`** is the box's change script, run by CBA on every machine when the settings are first read and
whenever the text changes: it sets every registered variable (the default where the text says nothing), then runs each changed setting's script
with the value (every one the first time, as CBA does) and raises CBA's `CBA_SettingChanged [name, value]` (which the hotbar listens to) and the local
event `einv_main_settingsChanged [text]` (an open wizard takes it in). Before CBA's settings are ready (`cba_settings_ready`; never in Eden)
it only sets the variables - no script, no `CBA_SettingChanged`, and the first call once they are ready still runs every script: `XEH_preInit`
calls it on CBA's `cba_settings_refreshSetting` for the box then, so a save in Eden reaches the variables too. The variables, their names, their kinds
of value and their scripts are those of the rows they replace, so no reader changed. What the text says, and the old names below, is read by
`fnc_readSettings [text, names = []]`. While the box is empty and a mission has values for the old names - lines of its own `cba_settings.sqf`
(CBA's `cba_settings_missionConfig`), else saved in Eden (the mission attribute `cba_settings_hash`) - those values are taken as if the text said them;
the server's profile and file are not read. A scope-2 box (a setting nobody may override) would be a second EDITBOX; no setting needs one.

The setup wizard's General page draws a control for each registered setting that is not `hidden` (section 6). What stays in CBA's menu: the rules
(`einv_items_rules`) with the three older tables, the box above, and every setting of scope 0.

| `einv_items_rules` | EDITBOX | global | `einv1 base=default` | the setup (section 2); runs `fnc_loadRules` |
| `einv_items_massPerCell` | SLIDER 2 to 20 | global (hidden) | 5 | fallback mass per cell, when a text has no `cell=` - the General page sets `cell=` |
| `einv_items_stackSmall` | SLIDER 1 to 50 | global (hidden) | 10 | `@item_small`'s stack, only when moved off 10 - by hand in `einv_main_settings` |
| `einv_main_settings` | EDITBOX | global | "" | the server settings as one text (above); runs `einv_main_fnc_applySettings` |
| `einv_items_sizeTable`, `einv_items_stackTable` | EDITBOX | global | "" | older tables, `class:WxH` / `class:N`; win over the text |
| `einv_storage_migrate` | CHECKBOX | global | on | move a unit's surplus (overflow) on to its next container with room (section 3, Surplus) |
| `einv_storage_containerTable` | EDITBOX | global | "" | `class:N` or `class:WxH+WxH`; wins over the text |
| `einv_storage_nearbyRange` | SLIDER 1 to 5 | global | 3 | m, how far crates and piles count as nearby |
| `einv_storage_useUniform`, `useVest`, `useBackpack` | LIST | global | `all` | "Use items from the uniform / vest / backpack": `all` Everything, `list` Only whitelisted (items with `use=` for it), `none` Nothing, `strict` Strict (hidden) - Only whitelisted, and the blocked items are kept out of the cargo in the unit's hidden holder; what the padlocks, the hotbar, the window's use rows and the reload key honour (section 3, Use from containers and Strict mode) |
| `einv_gui_cellScale` | SLIDER 0.8 to 1.3 | client | 1.1 | tile scale: the cell size, capped where the columns no longer fit; next opening |
| `einv_gui_pageRows` | SLIDER 0 to 40 | client | 10 | rows per page of a tall compartment of what is looted (section 4, "Tall compartments"); 0 or 40 no pages, at least 4 |
| `einv_gui_compareTooltip` | CHECKBOX | client | on | the comparison card for vests, uniforms, helmets, backpacks |
| `einv_gui_tileNames` | CHECKBOX | client | off | the item's short name in the top corner of every tile (`fnc_createTile`, a name that does not fit set a fifth smaller before it is cut; the setup wizard's preview always has it); the name at the mouse stays; ACE Arsenal's panel follows |
| `einv_gui_cameraDefault` | LIST | client | `soldier` | the camera as the window opens: `soldier` (third person), `off` (first person) |
| `einv_gui_lootSide` | LIST | client | `left` | where the loot column opens: `left` of the storage column, which never moves (default), or `right`, at the right edge with the storage column moving in (`fnc_layoutGlass`); read at every build |
| `einv_gui_showNearby` | CHECKBOX | client | on | nearby piles and crates as boxes in the loot column |
| `einv_gui_magazineFillBar` | CHECKBOX | client | on | the bar on magazines that are not full |
| `einv_gui_magazineText` | CHECKBOX | client | on | the rounds ("17/30") on magazine tiles; off leaves the bar alone |
| `einv_gui_soundsWorld` | CHECKBOX | global | on | players nearby hear someone loot |
| `einv_gui_moveToStop` | CHECKBOX | client | on | a movement key closes the window while looting |
| `einv_gui_searchTime` | SLIDER 0 to 3 | global | 0.4 | seconds per cell searched; 0 shows everything |
| `einv_gui_handDrop` | SLIDER 0 to 3 | global | 0.3 | seconds the hands are busy dropping one item (hands' queue, section 4); 0 drops at once |
| `einv_gui_handMove` | SLIDER 0 to 3 | global | 0.4 | seconds to move one item to a different container or holder (the quick move, Take all, Put all in; never a drag); 0 at once |
| `einv_gui_handEquip` | SLIDER 0 to 5 | global | 1 | seconds to put one item on or take it off (a drag never waits); 0 at once |
| `einv_gui_waitMove` | CHECKBOX | global | on | the quick move, Take all, Put all in and the menu's moves take the hands' time; off: at once |
| `einv_gui_waitDrop` | CHECKBOX | global | on | the drop key and Drop in the menu take the hands' time; off: at once |
| `einv_gui_waitWorn` | CHECKBOX | global | off | putting on and taking off a uniform, vest, backpack or headgear takes the hands' time; off: at once |
| `einv_gui_waitEquip` | CHECKBOX | global | off | equipping anything else (goggles, night vision, a map, weapon parts) takes the hands' time; off: at once |
| `einv_gui_searchBodies`, `searchPersons`, `searchContainers` | CHECKBOX | global | on | what has to be searched |
| `einv_gui_searchZeus` | CHECKBOX | global | on | crates and vehicles a game master places are searched; off marks them `einv_noSearch` (needs `searchContainers`) |
| `einv_gui_searchGround` | CHECKBOX | global | off | loose items on the ground too |
| `einv_gui_personNotify` | CHECKBOX | global | on | the person whose gear is opened is told |
| `einv_gui_personOpen` | LIST | global | Everyone | Everyone, Unconscious and captives, Only the unconscious |
| `einv_gui_personItems` | LIST | global | Everyone | who may take items from and put into a living person's gear: Everyone, Unconscious and captives, Nobody - look only |
| `einv_gui_personWorn` | LIST | global | Unconscious and captives | who may take off what a living person wears: Everyone, Unconscious and captives, Nobody |
| `einv_gui_debugTiming` | CHECKBOX | client | off | "Log window timings (debug)": build and redraw times and the display's controls, the script cost of idle, hovering and dragging frames, and each drag's lift and frames, to the RPT (read as the window opens) |
| `einv_arsenal_biArsenal` | LIST | global | `ace` | the vanilla Virtual Arsenal: `ace` (ACE Arsenal with the box's items), `block`, `vanilla` |
| `einv_arsenal_biMessage` | EDITBOX | global | "" | the line on the "not allowed" screen |
| `einv_hotbar_enabled` | CHECKBOX | global | on | the hotbar row, bar and keys |
| `einv_hotbar_leaderKeys` | CHECKBOX | client | on | leave the keys to Arma while leading AI |
| `einv_hotbar_hudMode` | LIST | client | While in use | Never, While in use, Always |
| `einv_hotbar_hudTime` | SLIDER 1 to 15 | client | 4 | seconds the bar stays after a key |
| `einv_magazines_repack` | CHECKBOX | global | on | the window's own repack |
| `einv_weight_enabled` | CHECKBOX | global | on | the tiers at all; off: plain kilograms, no effects, no duty factor, no messages (ACE's fatigue alone) |
| `einv_weight_heavyAt` | SLIDER 0 to 100 | global | 0 | kg; 0 follows ACE's fatigue |
| `einv_weight_overloadedAt` | SLIDER 10 to 100 | global | 45 | kg |
| `einv_weight_criticalAt` | SLIDER 10 to 150 | global | 60 | kg, at least 1 above Overloaded |
| `einv_weight_effects` | CHECKBOX | global | on | no sprinting from Overloaded, walking only at Critical |
| `einv_weight_notify` | CHECKBOX | client | on | a message when the tier changes with the inventory closed |
| `einv_locks_zeusOpens` | CHECKBOX | global | on | Zeus may open locked containers |

CBA keybinds: `einv_hotbar_slot1` to `slot7` (4 to 0), `einv_hotbar_show`, `einv_gui_quickMove` (F, the quick move in the inventory window), `einv_gui_drop` (G, the drop in the inventory window). Kept in the player's
profile: `einv_gui_soundMix` (the sound dropdown's volumes; the speaker's `einv_gui_muted`, `einv_gui_searchMuted` before it, are read once), `einv_hotbar_slots` (`einv_gui_cameraOn` no longer since 0.5.0: `einv_gui_cameraDefault`).

**What missions and other mods may set** (all optional): on an object `einv_grid` (a grid text, public), `einv_noSearch`,
`einv_nearby = false`, `einv_noAccess` (a person); in a mission `einv_arsenal_biPassThrough`; in an item's config `einv_size`,
`einv_stack`, `einv_grid`, `einv_weight`, `einv_name`, `einv_icon`, `einv_picture`, `einv_use` (section 2, "Config keys of an item"; the older `einv_gridSize[]`,
`einv_stackSize`, `einv_grids[]` and `einv_slots` still work), `einv_sound = "family"`; a preset as a class of
`CfgEinvRulesets`; a sound family or action in `CfgEinvSounds`; a lock through `einv_locks_fnc_setLock` or `addProvider`; an op,
guard or carried variable in the storage's tables (section 3).

## 9. Known limits and untested

### Known limits

- **Categories are per class, not per instance.** `cats=` and `einv_cat` put a class in categories; a compartment's `accepts` is by
  category. An ACE item that two mods put in different categories is one item to the rules. A magazine of a grenade launcher is a
  grenade only when its kind is (one round, light) or its ammo simulates a mine or a bomb - a heavy rocket is ammo. A category of the
  setup's own is a word of the rules text, shared by the server's text alone: a mod's `einv_cat` or `einv_grid` may name one, and it counts only
  where the setup defines it (`category=...`); until then it is ignored where it is used and the text's compile warns once. The strip shows at most
  `MAX_CUSTOM_CATEGORIES` + 8 categories, 7 at a time once there are more than 8 (click "more"); there is no scroll or wheel on it.
- **A single slot holds one tile, not one item.** A stack in a slot is one tile with its count (`stack=` over 1 puts several grenades in a
  slot); give grenades `stack=1` (the default preset does) for one grenade per loop.
- **Use from containers is not a lock the engine knows.** The settings "Use items from the uniform / vest / backpack" are honoured by
  everything this mod draws or runs (the window, the hotbar), by the keyboard's reload key, by a reload from the action menu or a
  gamepad (taken back after the fact, only for a magazine whose container is known), and by the throw key when only closed grenades
  are left (section 3), not by the game: ACE's own medical, rations and self-interaction menus and every mod that reads the unit's
  items itself (they see the backpack's bandages as real items), what ACE's advanced throwing selects, a grenade of a class that
  also lies in an open container (the game may take the closed copy), a vehicle's guns, and scripts take from any container. A
  reload that was undone shows its animation and the magazine's return. Untested in the game.
  **Strict (hidden)** is the full enforcement: the blocked items are kept out of the unit's containers altogether, in a hidden holder
  (section 3, Strict mode), so nothing outside this mod reaches them. Its own limits: a loadout read outside an arsenal
  (`getUnitLoadout`, `CBA_fnc_getLoadout`, a mission's respawn loadout) does not contain them; a mod that adds into the container sees
  its item for a moment before the op hides it; a Zeus editing a remote player through an arsenal on the Zeus's machine does not see
  them; radios and kits in the holder are unknown to their mods while hidden; whitelisted items stay physical and reachable. The
  setting's text says it can break mods and scripts that expect the items in the container. Untested in the game.
- **Transactions and multiplayer.** A client's connection dropping inside one send batch can lose a payload it took, or settle a
  put again (the hub names it in the RPT). Changes outside this machinery - ACE medical treatment, EFAK's own pouch, the engine's
  scroll-menu actions, scripts - are not serialised with ours; a script error in our own code exactly between an engine change and
  its journal line returns that payload once more. A machine that holds a phase and hangs holds it until it answers or leaves (the
  hub re-sends every 10 s, the window stops showing it as pending after 15 s; nothing is re-added on a timeout). The player's
  own arrangement reaches others up to 2 s after their moves; moves in the last 2 s before a player quits (not dies) with the
  window closed are never broadcast. A client whose rules differ from
  the server's draws other sizes and asks for normalises (at most every 30 s): fix the settings. Nested containers rely on the
  same `netId` on every machine. Settlement skips guards by design: an item can go back into a container that was locked meanwhile -
  it came from there.
- **Surplus.** Nothing raises an event for a script's `addItem`: a unit's cargo is found changed through CBA's polled `loadout`
  event (the player), the engine's `Take` / `Put` / `InventoryClosed`, a loadout set, and a window showing the overflow - an AI
  whose gear a script filled and nobody looks at keeps its surplus until one of those happens. Up to 0.3 s plus a tick pass
  before the surplus moves. A stack that would only fit by joining a partly filled pile of the same class (no free cell) is not
  moved: the plan needs a free cell per tile. Mid-move changes by other players in the same network moment can make a planned
  cell taken; the op then takes the first fit or leaves the tile where it is.
- **Kits.** Another living player's kits do not open or move. EFAK itself writes kits on whichever machine acts (its medical use,
  its own window, ACE actions on a kit outside the actor's gear); such a write in the same network moment as a write of this
  window can lose one of the two. EFAK's `syncAll` replaces the whole table on a joining machine even once synced; the window
  waits for the server's welcome, but EFAK's own writes in the first seconds are not covered (the fix belongs in EFAK). Kits in
  crates or on the ground that nobody has carried cannot be opened (EFAK has no public conversion). CBA statements that look for
  display 602, and mods that hook `RscDisplayInventory`, never see the window; CBA's item renames are not applied.
- **Locks.** The engine's "Rearm" scroll action on an ammo crate may not respect `lockInventory` (the code does what is safe
  either way and does not hide the action: that would take over `inGameUISetEventHandler`, which ACE owns). A raw `setVariable
  ["einv_locks_lock", ...]` works in the guard and the window but sets no engine lock and is not in the list for joining players:
  always use `fnc_setLock`. An admin moving things in a *driven* vehicle locked to admins is refused: the guard runs at the
  driver's machine, which cannot tell about another client's login.
- **Weight.** Heavy is where *jogging* stops being free in ACE's model at ACE's jog speed; running uphill, raised weapons, wounds,
  heat and carrying a body tire sooner than the mark says - it is steady on purpose. The body forecast covers grid targets and
  empty slots; a swap (a vest onto a worn vest) shows none. The comparison's Armor is the item's own ACE armor at its main zone.
- **ACE Arsenal panel.** Picking another uniform, vest or backpack in ACE's left list goes through `setUnitLoadout`: the
  containers are new objects and their arrangement starts first-fit (the staging space keeps its items). ACE Arsenal Extended's
  option panel stands where this panel does. Rows ACE leaves lit but the grid cannot take are not greyed (the add is taken back
  with the message). The undo is after the fact: other mods see ACE's add and then the removal; adds from the list or the wheel
  raise `itemsChanged` but not ACE's `cargoChanged`. The panel's bottom reaches into the top of ACE's message line, so a long
  message can be partly under it. A press below the last row of ACE's list starts no drag. A mission that registers BI arsenal
  handlers before the first frame after postInit counts as mods': it sets `einv_arsenal_biPassThrough`.
- **The window.** Controls made on the display later than a kit window draw over it where the window has been moved onto the
  equipment cards (a hovered slot's ring, the green glow of slots taking a dragged item, a footprint under a window's edge).
  Dropping the first item on the ground with nothing looted brings the loot column in, but the storage column keeps its scroll. A
  kit window covers the soldier in the middle while it is open. Repacking never touches loaded magazines, mixed classes or more
  than one magazine of a tile; GreenMag is not detected. Radios open only when the player carries them and the window comes back
  fresh; "Use as active radio" is local, not a transaction. ACE cargo: no airdrop from the window.
- **Hotbar, sounds, rules.** ACE picks which single item a treatment uses; ACE binds 6, 7 and 0 and Arma's command menus use 1 to
  0, so a bound slot shares its key until one of the two is moved (the notice says which); a slot holds a class, so two magazines
  of one class differ only by rounds (the fullest goes in). The sounds were chosen by measurement, not by ear. Named shapes are
  not read; an item is at most 8x8; nine mutually touching blocks would have to share one of the wizard's eight colours.

### Never run in the game

Built and checked in code only (`hemtt check`, reading), as far as this repository records:

- **All of 0.4.0 but the first version of the ACE Arsenal panel** (which the owner ran, from screenshots): cells as the only room
  and everything removed with the weight limit; the panel's look, staging space, list drag, wheel and focus rule; the backpack
  as the fourth gear slot; shaped grids, `like=`, shaped items with rotation, positional compartments (a canvas), width 10, the
  presets `default` revision 2, `realism` and `weight` revision 2; the wizard (Start, Items, Containers with paint, Blocks and
  Same as, Review, and later the wildcard search, the tree view with its `class=X+` edits, the weight and name fields and Export /
  Import at the editors); the window details (the menu's right-click fall-through, the weight card without ticks, count pills, the
  n/stack badge); the backpack drop with its safety nets; `hasSpace` with partial stacks.
- **Features older than that but newer than the 0.2.3 test**: the sound families, "moving stops looting", the
  magazine fill bar and the repack, the weight tiers with their effects and the comparison card, the window's lock gates, ACE
  cargo, TFAR and ACRE2 radios, the vanilla Virtual Arsenal handling.
- **Three gate tests that were never run**: whether variables on nested objects reach other machines (G1; both ways are kept), the
  jog speed in ACE's fatigue model that Heavy is derived from (G2; `JOG_SPEED` is ACE's number), whether the engine's "Rearm"
  respects `lockInventory` (G4). Also unconfirmed: that the topmost group takes the mouse wheel (so nothing under a kit window
  scrolls) and that a group's fade carries its controls (the kit windows' fade-in).
- **Separate stacks** (0.5.0): the counts in the places' records and their reconciliation with the cargo, `put` with `separate` and
  `merge into`, the op `split`, the merge drop, the plan filling partial stacks, and the Arsenal's lowering of a tile's count were
  written and read through, not run. To try: 5 of 10 of a class on a cell, drop 1 on another cell of the same container (two
  tiles), in another container (two tiles), onto the stack of five (merge); Shift+click; Quick move of the single into a
  container that holds a partial stack; Take all; close and reopen; another player or a script adding the same class
  (reconciled, nothing lost); a save from before the counts.
- **Searching left out for one object** (0.5.12): the Eden attribute "Skip searching", the "CuratorObjectPlaced" hook (on which machines it fires), the compat_zen choices and `fnc_setSearchable` were written and read through, not run. To try: place a crate in Eden with the box ticked and loot it (no stripes); in Zeus place a crate with *Search Zeus-placed crates and vehicles* off (no stripes), right-click it, *Searching: turn on* (stripes again for a player who opens it fresh), then *Searching: turn off*; call `[_crate, false] call einv_gui_fnc_setSearchable;` from the debug console and join as a second player.
- **Categories of the setup's own and the locked compartments' faint pictures** (0.5.0): the `category=` statements and their registry, the Categories card of the General step (add, rename, picture, delete with its clean-up), the picker's Category icons chip, the strip with more than eight categories (the "more" field), the watermark on the free cells (also on a paged box and in a kit; the corner badge was taken out in 0.5.12), and the footer hint on a locked compartment were written and read through, not run. To try: a vest with a 2x2 `:medical` compartment holding a pulse oximeter (the cells carry the faint picture, no badge in the corner, hovering says "Only medical items here"); add a category, give it a picture, put an item in it (Items step) and a compartment (Containers step, Blocks), loot a crate holding it (the strip lists it; add 9 and click "more"); delete the category (the chips, the item and the compartment lose it, one undo brings it back); export and import the setup on a client.
- **Multiplayer on a dedicated server**: the hub, the handshake and the nested copies are designed for it; `HISTORY.md` records no
  dedicated-server run.
