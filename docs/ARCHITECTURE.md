# Enhanced Inventory - architecture (phase 2: real data, two looks)

This is the contract every file of phase 2 is written against. Function names, arguments and HashMap
keys here are binding: several people (and agents) write different files at the same time and only
meet through these interfaces. If something here turns out wrong, fix it here first.

The sections marked "Phase A" (the rules engine in items, setup, weight) are the newest and win over
the dated sections at the end wherever they disagree; the plan behind them is `docs/design/design_synthesis.md`
with the corrections in `docs/design/design_critic.md`.

Read `docs/BRIEFING.md` for the goal and the conventions. The short version of the conventions:

- HEMTT 1.11.2, CBA macros (GVAR, QGVAR, FUNC, QFUNC, EFUNC, LLSTRING, CSTRING, ECSTRING, ARR_N,
  PREP via XEH_PREP.hpp). Prefix `einv`, addons `main` + one addon per feature, named by what it does.
- Everything in the repo is English, stringtables only `<English>`.
- Function header like the existing files (Author: Miss Heda, description, Arguments, Return Value,
  Example, Public). Comments explain WHY, in plain sentences, like the existing files and Enhanced
  First Aid Kits (`C:\Users\Heda\GitHub Repos\Enhanced-First-Aid-Kits`, the design reference).
- CBA setting descriptions: `\n` about every 40 characters, paragraphs `\n\n`, no scope line.
  Settings ordered by topic, then numbers > switches > lists > text boxes.
- Never commit, never start Arma.

## What the user decided (2026-10-06)

- The layout follows the shooters she showed: **dedicated slots** for weapons (with their attachments
  and magazines), secondary, launcher, helmet, uniform, vest, ... and **free grid storage** where every
  item takes its own number of cells (Tarkov-like) for uniform, vest and backpack contents.
- Storage: uniform, vest and backpack **stacked under each other** in one scrollable column, each with
  a header (picture, name, weight).
- Loot (ground, crate, vehicle, body) gets **its own column, only while looting**.
- The middle: **switchable** - a live camera on the player's own soldier, or nothing.
- **Two looks, switchable in the game** with a Style button in the header: **Tarkov** and
  **Glass** (Enhanced First Aid Kits' look). Reforger and Wardogs looks were tried and dropped (2026-10-07).
- No quick-use bar / hotkeys yet. No moving items yet - phase 2 is read-only.
  *(The hotbar came with 0.2.1, see the Hotbar section at the end.)*

## Addons

| Addon | Does | Requires |
|---|---|---|
| `main` | version, macros, shared defines (`script_macros.hpp`: CATEGORY_*, STORAGE_COLS, MASS_TO_KG, MAX_ROWS, MAX_BLOCKS, MAX_CELLS) | cba_main, ace_common |
| `items` | what an item is: name, picture, category, kind, mass, grid size, stack size - and the rules engine that decides sizes, stacks, container grids, weights and names (`einv_items_rules`) | einv_main |
| `storage` | what a container holds and where it lies on its grid; what a unit wears | einv_items |
| `gui` | the window: styles, layouts, slots, grids, tiles, camera, taking over from vanilla | einv_storage, einv_locks, einv_weight |
| `arsenal` | the Enhanced Arsenal: ACE Arsenal's boxes, loadouts and events in the inventory's window; the vanilla Virtual Arsenal by setting; for players who keep ACE's own window, ACE's loadouts kept inside the grids - see "Enhanced Arsenal" at the end | cba_main, ace_common, ace_arsenal, A3_Functions_F_Bootcamp, einv_main, einv_items, einv_storage, einv_gui, einv_setup |
| `setup` | the setup wizard and its entry points (CBA's Addon Options button, ESC > Options, Eden's Tools menu, keybind, the inventory's cog) | einv_gui, einv_items, einv_storage |
| `weight` | `weight=` overrides of the rules into ACE's virtual load (`ace_movement_vLoad`), so ACE's weight and fatigue count them; the weight tiers Light / Heavy / Overloaded / Critical tied to ACE's fatigue - see "Weight tiers, full by weight, gear comparison" at the end | cba_main, ace_common, ace_movement, einv_main, einv_items |
| `compat_efak` | kits of Enhanced First Aid Kits and pouches of Enhanced Utility Pouches in floating windows of their own inside the inventory; packing and unpacking by drag and drop (`skipWhenMissingDependencies`) - see "Enhanced First Aid Kits and Enhanced Utility Pouches" at the end | cba_main, einv_main, einv_storage, einv_gui, efak_core, efak_gui |
| `locks` | who may open a crate's or vehicle's inventory: one side, one group or the admins; set from Eden, Zeus or a script; the engine's own inventory locked per client; checked again on the machine that runs every op (`einv_storage_guards`) - see "Locks" at the end | cba_main, einv_main, einv_storage |
| `compat_ace_vehiclelock` | ACE's vehicle lock as one more lock of ours (`skipWhenMissingDependencies`) | cba_main, ace_vehiclelock, einv_main, einv_locks |
| `compat_zen` | Zeus Enhanced: right-click menu "Inventory lock" and the module "Lock inventory" (`skipWhenMissingDependencies`) | cba_main, zen_context_menu, zen_custom_modules, zen_dialog, einv_main, einv_locks |
| `compat_ace_cargo` | ACE cargo in the loot column: what is loaded in a vehicle or crate as a "CARGO" section with a card per thing, Open / Close for a crate and Unload with ACE's time (`skipWhenMissingDependencies`) - see "Locks, ACE cargo and radios" at the end | cba_main, ace_cargo, einv_main, einv_gui, einv_locks |
| `compat_tfar` | Task Force Arrowhead Radio: channel and frequency at the mouse, in the hint and on the inspect card, "Open radio" and "Use as active radio" in the right-click menu, a long-range backpack's frequencies kept through moves (`skipWhenMissingDependencies`) | cba_main, tfar_core, einv_main, einv_storage, einv_gui |
| `compat_acre` | ACRE2: the same for its radios, ACRE2's own "Open" of the CBA item menu left out, and the dummy radio ACRE2 keeps in the radio slot fixed (`skipWhenMissingDependencies`) | cba_main, acre_main, acre_api, acre_sys_core, acre_sys_data, acre_sys_radio, acre_sys_gui, einv_main, einv_storage, einv_gui |
| `hotbar` | items on the keys 4 to 0, used with ACE's own treatments, throwing, rations and the engine's reload; the HUD bar and the window's hotbar row - see "Hotbar" at the end | cba_main, ace_common, A3_Ui_F, einv_main, einv_items, einv_storage, einv_gui |

## items

### `einv_items_fnc_getInfo` (Public: Yes)

`[class, compiled (opt), cache (opt)] call einv_items_fnc_getInfo` -> HashMap. Without `compiled`:
the rules in effect, cached per lowercase class in `einv_items_info` (missionNamespace, emptied on
every rules change). With `compiled` (a wizard's draft) and a `cache`: kept there; with `compiled` and
no cache: not kept. Callers must not modify it. The config part comes from `einv_items_fnc_getFacts`
(cached for good in uiNamespace `einv_items_facts`), the rest from the rules (`einv_items_fnc_resolve`),
see "Rules engine" below.

| Key | Type | |
|---|---|---|
| `class` | STRING | configName (config case); for unknown classes the input |
| `name`, `short` | STRING | the rules' `name=`, else displayName; displayNameShort or else displayName |
| `description` | STRING | descriptionShort (may contain `<br/>`), "" if none |
| `picture` | STRING | config `picture`, "" if none |
| `category` | NUMBER | CATEGORY_* |
| `kind` | STRING | see below |
| `mass` | NUMBER | effective mass in config units (tenths of a pound): the rules' `weight=` (kg / MASS_TO_KG), else config mass |
| `size` | ARRAY | `[w, h]` in grid cells, upright, `w <= STORAGE_COLS`, `h <= MAX_ROWS` |
| `stack` | NUMBER | how many may share one tile, >= 1 |
| `capacity` | NUMBER | magazine rounds (`count`), 0 for everything else |
| `maxLoad` | NUMBER | uniform/vest: maximumLoad of its containerClass; backpack, crate, vehicle: maximumLoad; else 0 |
| `cells` | NUMBER | `w * h` |
| `shape` | STRING | the size as the rules write it, `"2x3"` |
| `grid` | ARRAY | containers: the grid spec (`einv_items_fnc_parseGrid`), `[]` for anything else |
| `src` | HashMap | field -> where it came from (`einv_items_fnc_resolve`) |
| `configMass` | NUMBER | config mass, whatever the rules say |
| `configDisplayName`, `configShort` | STRING | config's names, whatever the rules say |
| `weightOverride` | NUMBER | the rules' weight in kg, -1 when none |
| `nameOverride` | STRING | the rules' name, "" when none |
| `lc`, `root`, `rounds`, `lineage`, `addon`, `mod` | | from `fnc_getFacts`: lowercase class, config root, a CfgMagazines `count` (grenades too), lowercase classes from itself up, the CfgPatches class that brought it in, what its own config says about its grid |

Phase A has no `forms`, `turns` or `canon` (shapes come later, see "Rules engine").

Kinds: `rifle`, `handgun`, `launcher` (CfgWeapons `type` 1/2/4), `binocular` (type 4096),
`muzzle`, `optic`, `rail`, `bipod` (ItemInfo type 101/201/301/302), `headgear` (605), `nvg` (616),
`vest` (701), `uniform` (801), `map`, `gps`, `radio`, `compass`, `watch` (by `simulation`
ItemMap/ItemGPS/ItemRadio/ItemCompass/ItemWatch; ItemInfo type 621 UAV terminals are `gps`),
`item` (other CfgWeapons, CBA's and ACE's misc items among them), `magazine`, `grenade` (CfgMagazines
with count 1 and mass <= 15), `backpack` (CfgVehicles with isBackpack 1), `goggles` (CfgGlasses),
`vehicle` (CfgVehicles of AllVehicles), `crate` (any other CfgVehicles class), `unknown`.

Category: MEDICAL if `ACE_isMedicalItem` == 1 or ItemInfo type 401/619; WEAPON for
rifle/handgun/launcher; AMMO for magazine/grenade; GEAR for uniform/vest/headgear/goggles/nvg/
binocular/backpack; MISC otherwise.

Mass: weapons `WeaponSlotsInfo >> mass`, other CfgWeapons `ItemInfo >> mass`, CfgMagazines/
CfgVehicles/CfgGlasses `mass`.

### Rules engine (Phase A, 2026-10-09) - replaces `fnc_getSize` and the old items settings

Size, stack, container grid, weight and name of every item come from one text of rules, the CBA
setting `einv_items_rules`, built on a preset (`CfgEinvRulesets`). `fnc_getSize`, its size-by-kind list,
`einv_items_sizeCorrections` and `fnc_findInTable` are gone: the list lives on, with the same sizes
and stacks, as the `default` preset (`items/CfgEinvRulesets.hpp`), so nothing changes for anyone until
they write a rule. Shaped items (L forms, masks, turns) come in a later phase.

#### The text (`fnc_parseRules`, `fnc_writeRules`)

Statements part at commas; a line break counts as a comma. The writer always joins with `", "`, in
the order header, groups, rules, a rule's values in the order size, stack, grid, weight, name - read and
written again, a text stays the same, so two setups that mean the same compare as texts.

| Statement | Example | |
|---|---|---|
| header | `einv1 base=default cell=5` | only as the first statement. `base=` a preset id or `none`; `cell=` config mass per grid cell, 1 to 50, two decimals. No header reads as `einv1 base=default`; a newer `einvN` warns and reads what it can |
| group | `@rifle_mags: kind=magazine mass<=20` | id of `a-z 0-9 _`. The same id twice in one layer means either. An own group replaces the preset's group of that name, and `@itself` inside it means the preset's definition (`@mag_rifle: @mag_rifle` + `@mag_rifle: class=X+` adds X). A definition that does not hold up (unknown group, a loop, more than MAX_GROUP_DEPTH 4 deep) is left out and the one below counts again |
| rule | `kind=grenade > stack=3` | conditions, then what it sets; the `>` only reads better. No condition means every item. A later rule beats an earlier one, field by field |

Conditions - all must hold, `|` means either, `!` in front means not, at most 64 choices:

| Condition | |
|---|---|
| `kind=rifle\|handgun` | the kinds of `fnc_getFacts` (see "Kinds" above) |
| `cat=medical` | `misc`, `gear`, `weapon`, `ammo`, `medical` |
| `class=X`, `class=X+`, `class~abc` | that class; X and every class inheriting from it (any mod's, a mission's mod's); a part of the class name, 3 letters at least. Class case is kept in the text, matched lowercase |
| `addon=x`, `addon~abc` | the CfgPatches class that brought it in |
| `well=X` | a magazine of that magazine well |
| `for=X` | a magazine weapon X loads |
| `mass<=20`, `rounds>=50`, `load>160` | config mass, a CfgMagazines count, a container's maximumLoad; `= < <= > >=` |
| `@group`, `@a\|@b` | a member of that group |

Values:

| Value | |
|---|---|
| `size=2x3` (alias `shape=`) | the footprint, at most STORAGE_COLS across and MAX_ROWS down (cut down with a warning). `size=mass`: as many cells as it weighs (the rules' weight if set) / cell - rifles and launchers two rows high, everything else near square. Anything else made of letters, digits, `/` and `@` is a shape: reserved, warned "shapes come in a later version", that value dropped, the rest of the rule kept |
| `stack=10` | 1 to 999 |
| `grid=...` | containers only (`fnc_parseGrid`): `auto` (maximumLoad / cell, laid out by the kind's pattern), `24` cells, `120%` (10 to 500 % of auto), a pattern `rig` or `rig:16` (`pockets`, `pockets_mixed`, `rig`, `mixed`, `plate`, `long`, `single`, `wide`), or `6x4+2x3` compartments exactly; limits STORAGE_COLS, MAX_ROWS, MAX_BLOCKS, MAX_CELLS |
| `weight=1.25` | the item's weight in kg instead of config's: digits and one dot, rounded to the gram, at most 1000 |
| `name=Field_kit` | the name it shows, at most 100 characters, encoded: in `name=`, `_` means a space and `%5F` an underscore; letters, digits, `-` and `.` stand as they are, every other character is `%XX` per UTF-8 byte (`Field kit (3)` -> `Field_kit_%283%29`). `fnc_encodeName` writes it, `fnc_decodeName` reads it (a `%` without two hex digits stays as it is). The writer emits `%5F` for an underscore - unlike decision 2's wording, which kept `_` - because otherwise a name with an underscore would come back with a space |

What may stand in a statement: letters, digits, space, tab and `_ + . / % : | @ ! < > = ~ -`. Never a
`;`, a quote, `#` or a backslash: CBA's export, import and every `cba_settings.sqf` split lines at `;`,
and the preprocessor reads the others. The EDITBOXes (rules and the three tables) are registered with
CBA 3.19's sanitizer `einv_items_fnc_sanitizeText`, which turns `;` and line breaks into commas and drops
quotes, `#` and backslashes as they are typed.

Left out, each with a warning that names it (RPT on load, the wizard's Review): a statement with any
other character, an unknown key, a condition after a value, a header that is not first, a statement
that sets nothing, statements past 500; a text over 16384 characters reads as the default (over 8192
only warns). One typo never costs the rest of the text.

#### Parts and compiled form

```
AST (fnc_parseRules)  HashMap
  "version" NUMBER, "base" "default" | "none" | preset id (lowercase), "cell" NUMBER (-1 = not set),
  "groups" [[id, conds], ...] (text order), "rules" [[conds, values], ...] (text order),
  "warnings" [STRING, ...]
  cond   = [negated BOOL, key STRING, op STRING, values ARRAY of STRING]
           group reference: key "@", op "=", values the ids; class=X+ keeps the "+" on the value
  values = HashMap, any of "footprint" ("WxH" or "mass"), "stack" NUMBER, "grid" STRING (as
           fnc_formatGrid writes it), "weight" NUMBER (kg), "name" STRING (decoded)

Compiled (fnc_compileRules)  HashMap - plain data, no code (it is kept in missionNamespace)
  "text"        own text as the writer has it      "ast"        the own text's AST
  "base"        the preset built on, "none"         "chain"      preset ids read, base first
  "cell"        config mass per grid cell           "warnings"   [STRING, ...]
  "groups"      group key -> [alternatives], each a list of compiled conditions; the key in effect
                is the group's name, replaced definitions are "name#layer"
  "groupKeys"   name -> key in effect               "groupSource" name -> "own" | "preset:<id>"
  "groupOrder"  names as they first appear, the presets' first
  "own"         [[conds, values, tag, text, kinds], ...] - the text's rules, then the tables';
                tag "own:<i>" or "legacy:<setting>:<i>"; kinds -1 for any, else the kinds it can match
  "preset"      the same for the preset chain, tag "preset:<id>:<i>" (and "legacy:einv_items_stackSmall:0")
  "byKind"      kind -> [own indices, preset indices (both highest first), own fields, preset fields]
  "hash"        hashValue of cell, chain, every layer's text and the tables' rules - STRING
  compiled cond   = [negated, key, op, data, cost] (fnc_compileCond: sets, numbers, class lineage sets,
                    magazine sets of a well or weapon - cheapest first)
  compiled values = "footprint" [w, h, []] or "mass", "stack", "grid" spec (fnc_parseGrid), "weight", "name"
```

#### Which answer wins (`fnc_resolve`), per field - first answer wins

Each field (footprint, stack, grid, weight, name) goes to the first layer that has an answer:

1. **forced** - rifles, handguns, launchers, binoculars, uniforms, vests and backpacks always stack 1.
2. **the older tables** - `einv_items_sizeTable`, `einv_items_stackTable`, `einv_storage_containerTable`,
   compiled as `class=X+` rules appended LAST to the own layer, each table sorted shallow-first (fewest
   parents first), so the nearest class listed wins and every table beats the text, as before rules
   existed.
3. **the own text** - `einv_items_rules`, a later rule before an earlier one.
4. **the item's mod config** - `einv_gridSize[]`, `einv_stackSize`, `einv_grids[]` then `einv_slots`.
5. **the preset chain** - `base=` and its own bases, up to MAX_CHAIN 4 deep, a derived preset's rules
   before its base's, a later rule before an earlier one. `einv_items_stackSmall`, when moved off its
   default 10, is this layer's last word on `@item_small`: it beats the preset's own stacks, not a rule
   or a mod.
6. **builtin** - 1x1, stack 1, `grid=auto`, config weight, config name.

Afterwards: `size=mass` becomes cells, the footprint is clamped to STORAGE_COLS x MAX_ROWS, stacks to
whole numbers >= 1, and non-containers get no grid. `fnc_explain [class, compiled]` lists every layer
that has a say, highest first, with what it sets and wins (the wizard's "Why?").

For a container **object** (`einv_storage_fnc_getBlocks`), its own **`einv_grid`** beats all of these
for its compartments: a STRING grid spec as in `grid=` (`"6x4+2x3"`, `"rig:16"`, `"auto"`, ...), set by
a mission with the public flag on a crate, a vehicle, or a unit's uniform, vest or backpack container -
`_crate setVariable ["einv_grid", "6x4+2x3", true]`. One that cannot be read is named in the RPT once
(cache `einv_storage_objectGrids`, text -> spec) and the rules count instead. Then the rules for the
object's class, then `auto`. `einv_storage_fnc_blocksFor [class, kind, maxLoad, spec, cell]` lays it
out.

Mass per grid cell: the header's `cell=`, else the nearest preset in the chain with a `cell` > 0, else
the slider `einv_items_massPerCell` (default 5); clamped 1 to 50.

#### Functions (items)

| Function | Public | |
|---|---|---|
| `fnc_getFacts [class]` | Yes | config facts, cached for good in uiNamespace `einv_items_facts` |
| `fnc_getInfo [class, compiled, cache]` | Yes | see above |
| `fnc_parseRules [text]` | Yes | -> AST |
| `fnc_writeRules [ast, header = true]` | Yes | -> canonical text |
| `fnc_compileRules [text, legacy = true]` | Yes | -> compiled; `legacy` reads the tables and stackSmall too |
| `fnc_currentRules []` | Yes | the rules in effect, compiled again first when `fnc_rulesInputs` changed |
| `fnc_explain [class, compiled]` | Yes | every layer's say, highest first |
| `fnc_encodeName [name]`, `fnc_decodeName [text]` | Yes | `name=` encoding |
| `fnc_parseGrid [text]` -> `[spec, messages]`, `fnc_formatGrid [spec]` | No | grid specs |
| `fnc_compileCond [cond, groupKeys]` -> `[error, cond]`, `fnc_matches [facts, conds, compiled, memo]` | No | conditions |
| `fnc_resolve [facts, compiled]` | No | -> `footprint`, `stack`, `grid`, `weight` (kg, -1), `name` ("" none), `src` |
| `fnc_rulesInputs []` | No | `[rules text, size table, stack table, container table, stackSmall, massPerCell]` |
| `fnc_loadRules [text]` | No | compiles when the inputs changed; a text stands in for the setting (testing, `einv_items_rulesOverride`), `""` ends that |
| `fnc_checkServerRules [published]` | No | warns once when the server reads the same settings differently |
| `fnc_parseTable [text, type, warnings]` | No | the older tables -> lowercase class -> value |
| `fnc_sanitizeText` | No | the EDITBOXes' CBA sanitizer |

`src` tags: `own:<i>`, `legacy:<setting>:<i>`, `mod:<config key>`, `preset:<id>:<i>`, `builtin`, `forced`.

#### Variables and events

- missionNamespace: `einv_items_ruleset` (compiled, nil until the first compile), `einv_items_rulesInputs`
  (what it was compiled from), `einv_items_rulesInputsKey` (`hashValue` of those), `einv_items_rulesRevision`
  (NUMBER, from 0, +1 per compile), `einv_items_info` (lowercase class -> getInfo, emptied on every
  compile), `einv_items_rulesOverride` (test text, nil), `einv_items_hashWarned`, `einv_items_versionWarned`.
- `einv_items_rulesHash` - public, set by the server (not in Eden): an ARRAY `[inputsKey, hash, version]`,
  so a client only compares a hash it compiled from the same settings (they arrive in either order). The
  server also sends it to the clients already connected as the CBA event `einv_items_rulesPublished
  [published]`; a client joining later finds the variable set when it reads its own rules.
- uiNamespace (not in save games): `einv_items_facts` (lowercase class -> facts), `einv_items_presetCache`
  (preset id -> AST).
- Local CBA event **`einv_items_rulesChanged [revision]`**, raised by `fnc_loadRules` on every machine after
  a compile. Listeners: gui (an open inventory is built again, after a held tile is let go:
  `einv_gui_rulesRebuild`), setup (an open wizard takes the new setup in, `fnc_onRulesChanged`), weight
  (the player's virtual load is worked out again).
- Eden: CBA runs no setting scripts there, so `fnc_getInfo` calls `fnc_currentRules` while
  `einv_items_ruleset` is nil or `cba_settings_ready` is not set, and that compiles the current
  `einv_items_rules` text whenever `fnc_rulesInputs` differs from what it compiled.
- MAX_ROWS (40), MAX_BLOCKS (24) and MAX_CELLS (STORAGE_COLS x MAX_ROWS) live in `main/script_macros.hpp`.

#### Settings (items: Grids; storage: Containers)

All global (1). Each one that feeds the rules runs `fnc_loadRules` when it changes.

| Setting | Type | |
|---|---|---|
| `einv_items_massPerCell` | SLIDER `[2, 20, 5, 0]` | fallback mass per cell when neither the header nor the preset sets one |
| `einv_items_stackSmall` | SLIDER `[1, 50, 10, 0]` | `@item_small`'s stack, only when moved off 10 |
| `einv_items_rules` | EDITBOX, default `einv1 base=default` | the setup |
| `einv_items_sizeTable` | EDITBOX | `class:WxH, ...` - older table, wins over the text |
| `einv_items_stackTable` | EDITBOX | `class:N, ...` - older table, wins over the text |
| `einv_storage_containerTable` | EDITBOX | `class:N` or `class:WxH+WxH` - older table, wins over the text |

#### Where the build knowingly differs from the design's contract (design_synthesis 5.1/5.2)

- `einv_items_rulesHash` is the ARRAY above, not a STRING.
- `einv_items_massPerCell` is still a setting (the fallback), not a plain variable.
- `fnc_getInfo` has no `forms`, `turns` or `canon` in Phase A (no shapes yet); it has `configMass`,
  `configDisplayName`, `configShort`, `weightOverride` and `nameOverride` in addition.
- `fnc_resolve` also returns `weight` and `name`; `fnc_writeRules` and `fnc_compileRules` take a second
  argument; `fnc_loadRules` returns whether it compiled.

## storage

All functions Public: No unless noted. Entries and sections are HashMaps.

### `einv_storage_fnc_getContents` `[container]` -> ARRAY of entries

Reads a container object (uniformContainer/vestContainer/backpackContainer of a unit, a crate, a
vehicle, a weapon holder). One entry per tile:

| Key | |
|---|---|
| `class` | STRING |
| `count` | NUMBER, >= 1 (a stack splits into several entries at the item's `stack` size) |
| `ammo` | NUMBER, rounds in a magazine, 0 otherwise |
| `capacity` | NUMBER, from getInfo |
| `attachments` | ARRAY, for weapons the `weaponsItemsCargo` entry, `[]` otherwise |
| `container` | OBJECT, a uniform/vest/backpack lying in this container: its own container object from `everyContainer` (matched by class, in order), objNull otherwise |

Sources: `weaponsItemsCargo` (each weapon on its own), `getBackpackCargo` (each backpack on its own),
`magazinesAmmoCargo` (each magazine on its own; stackable ones - stack > 1, the grenades - grouped by
class and split at `stack`), `getItemCargo` (grouped by class, split at `stack`). Order: weapons,
backpacks, magazines, items. A null container gives `[]`.

### `einv_storage_fnc_getMaxLoad` `[container]` -> NUMBER

`getNumber (configOf _container >> "maximumLoad")`; `-1` (no limit) for weapon holders
(`einv_storage_fnc_isGroundHolder`) and null.

### `einv_storage_fnc_isGroundHolder` `[object]` -> BOOL

isKindOf `GroundWeaponHolder`, `WeaponHolder` or `WeaponHolderSimulated`.

### `einv_storage_fnc_getMass` `[entries]` -> NUMBER (config mass)

Sum of `mass * count`; a weapon adds its attachments and loaded magazines. Used for the "x.x / y.y kg"
of a section header. Since Phase A `mass` is getInfo's effective mass, so `weight=` rules count here.

### `einv_storage_fnc_getLayout` `[container, entries]` -> HashMap

*Superseded (0.2.0): see "Synced arrangement and transactions" at the end.* Places are public, written
by each holder's authority, keyed by `fnc_entryKey`; kits keep theirs in
`einv_storage_places_kit_<class>`, `einv_storage_layouts` is gone.

Where each entry lies on a grid STORAGE_COLS wide. Every entry gets `col`, `row`, `w`, `h`,
`overflow` (BOOL) set on it (the entry HashMaps are changed in place). Result keys: `entries` (all of
them, placed), `rows` (rows used, 0 when empty).

- The layout is kept on the container: `_container getVariable [QGVAR(layout), []]`, an array of
  `[lowercase class, col, row, w, h]`, set WITHOUT the public flag (local to this machine for now).
  For `objNull` (virtual sections) nothing is stored.
- Reconcile: entries of a class take that class's stored records in order, as long as the record's
  size still matches and its cells are free. Everything left is placed first-fit - largest area
  first, then by category, then by class - scanning rows top to bottom, columns left to right; the
  grid grows downward as needed. Nothing is ever dropped. An entry wider than the grid gets
  `overflow` true and lies on its own row at the end.
- Stores the result back. Items never rotate in phase 2 (`ctrlSetAngle` distorted pictures in the
  phase 1 test; turning comes with dragging in phase 3).
- **A grid with no object of its own** (2026-10-09, `compat_efak`): argument 0 may be a STRING key
  instead of a container - `"kit:" + lowercase kit class` for an open kit. A key has no compartments
  (laid out like the ground: STORAGE_COLS wide, rows used + 1, at least 3) and keeps its records in
  `einv_storage_layouts` (HashMap key -> records, local, set in storage `XEH_preInit`) instead of on an
  object. `fnc_setPlace` takes the same key (it checks the type before `isNull`, which fails on a
  STRING); `""` and objNull are ignored by both.

### `einv_storage_fnc_getGridRows` `[maxLoad, rowsUsed]` -> NUMBER

Rows to draw: maxLoad `-1` (ground) -> `max(rowsUsed + 1, 3)`; else `cells = ceil(maxLoad /
einv_items_massPerCell)`, `full = ceil(cells / STORAGE_COLS)`; `full <= 14` -> `max(full, rowsUsed)`,
else (big crates, vehicles) `max(rowsUsed + 2, 6)`.

### `einv_storage_fnc_getEquipment` `[unit]` -> HashMap (Public: Yes)

What a unit wears, from `getUnitLoadout` (weapon arrays are `[class, muzzle, rail, optic,
[magazine, ammo] or [], [second magazine, ammo] or [], bipod]`, `[]` when empty):
`primary`, `launcher`, `handgun`, `binocular` (ARRAY each), `uniform`, `vest`, `backpack`,
`headgear`, `goggles`, `map`, `gps`, `radio`, `compass`, `watch`, `nvg` (STRING each, "" when empty).

### `einv_storage_fnc_getSections` `[unit]` -> ARRAY of sections

The unit's own storage, in order uniform, vest, backpack (only those it has):

| Key | |
|---|---|
| `id` | "uniform" / "vest" / "backpack" / "container" / "ground" / "worn" |
| `title` | STRING, the container item's displayName (or the crate's / "Ground" / the body's name) |
| `class` | STRING, the uniform/vest/backpack class whose picture the header shows ("" for crates) |
| `container` | OBJECT (objNull for a virtual section) |
| `maxLoad` | NUMBER (`-1` = no limit) |
| `entries` | only for virtual sections: the entries to show |

### `einv_storage_fnc_getLootSections` `[container, secondary]` -> ARRAY of sections

- A body (CAManBase, not alive): a virtual `worn` section (one entry per worn thing: weapons with
  their attachments, headgear, goggles, nvg, binocular, uniform, vest, backpack, assigned items),
  then its uniform, vest and backpack sections (`getSections`).
- A weapon holder: `ground`, titled with `localize "STR_einv_storage_Ground"`.
- A crate or vehicle: `container`, titled with its displayName.
- `secondary`, when not null and not the same object, adds its sections the same way.
- Sections of ground holders with no entries are left out.
- *(0.2.1)* Two more parameters: the uniforms, vests and backpacks opened from inside a container
  (`[class, object, container it lies in]`) and `nearby`, the objects `fnc_getNearby` found (those listed
  already are left out). Every section of a container carries `holder`, `root` (`fnc_rootOf`), `parent`,
  `nearby`, `folded` (the crates found lying around start folded) and `side` ("loot"). With more than one
  pile the piles are titled "Ground - <short name of the largest item>" (area, category, class). The list
  goes through `fnc_orderSections`: a section with a `parent` lies right below its parent's, after the
  parent's earlier children; one whose parent is not in the column (opened from the player's own storage)
  comes after what was looted and before the nearby boxes.

## gui

Everything on the window except the dim layer is created at run time - the style decides the
layout, and switching the style rebuilds the window.

### State (XEH_preInit)

`GVAR(unit)`, `GVAR(container)`, `GVAR(secondary)`, `GVAR(openedAt)`, `GVAR(bypassUntil)`,
`GVAR(frameDriver)` (`[driver, id]`, see "Window engine for other displays"), `GVAR(nextCheck)`, `GVAR(created)` (top-level runtime controls, deleted on
rebuild), `GVAR(grids)`, `GVAR(slots)` (hover areas of slots: `[[x, y, w, h] absolute, class,
caption, anchor, weapon]` - anchor is `{rel, parent}` for a slot inside a group, else an empty HashMap;
weapon the slot's weapon array or `[]`; both optional), `GVAR(hover)`, `GVAR(lastMouse)`,
`GVAR(hint)` (the hint control), `GVAR(hoverFrame)` (the accent frame around a hovered slot that is
not inside a column's group - made last by `fnc_build`), `GVAR(camera)`, `GVAR(cameraLight)`, `GVAR(signature)` (contents signature, see onFrame), `GVAR(styles)`.

Kit windows (2026-10-10, see "Kit windows" at the end): `GVAR(windowOrder)` (keys, bottom first - the
z-order), `GVAR(windowPos)` (key -> `[x, y]`), `GVAR(windowAnchor)` (key -> the tile's rect, used by the
first draw), `GVAR(windowFresh)` (keys to fade in at their next draw), `GVAR(windowScroll)` (key -> the
body's scroll in screen height), `GVAR(windowMove)` (`[key, dx, dy]` while a title is held), `GVAR(middle)`
(the free middle of the last build, `[]` for none); uiNamespace `QGVAR(windows)` (the records, bottom
first), `QGVAR(windowTrash)` (window groups to delete next frame), `QGVAR(scrollRestore)` (`[group,
pixels, frame]` to put back once the frame has passed - columns and window bodies). All reset in
`fnc_open`; `GVAR(collapsed)` holds containers only.

`GVAR(styles)`: `[[id, name stringtable key, theme function name, layout function name], ...]` in
this order:

| id | theme | layout |
|---|---|---|
| `tarkov` | `einv_gui_fnc_themeTarkov` | `einv_gui_fnc_layoutTarkov` |
| `glass` | `einv_gui_fnc_themeGlass` | `einv_gui_fnc_layoutGlass` |

The chosen style id and the camera switch live in `profileNamespace` (`einv_gui_style`, default
"tarkov"; `einv_gui_cameraOn`, default true), saved with `saveProfileNamespace` when changed.

### Screen geometry (gui/defines.hpp)

- `UNIT` = `safezoneH / 40` - one row, ~27 px at 1080p, whatever the UI size.
- `SQUARE(H)`, `UNSQUARE(W)`, `SNAP_X/Y/W/H` as in phase 1. Everything see-through meets on whole
  pixels.
- Header bar: `HEAD_Y = safezoneY + UNIT * 0.6`, `HEAD_H = UNIT * 1.6`.
- Content: from `CONTENT_Y = safezoneY + UNIT * 3` to `CONTENT_B = safezoneY + safezoneH - UNIT * 2.6`.
- Footer: `FOOT_Y = safezoneY + safezoneH - UNIT * 2`, `FOOT_H = UNIT * 1.4`.
- Side margin `MARGIN_X = SQUARE(UNIT * 1.2)`.
- Cell: `einv_gui_fnc_getCell` -> `[cellW, cellH]`, a whole number of pixels, the same across and
  down: `round(((UNIT * 1.45) min UNSQUARE(safezoneW / 46)) / pixelH)` pixels. Every grid of every
  style uses it, so a tile is the same size everywhere.

### Themes

`einv_gui_fnc_themeBase` returns a HashMap with every key; each look's theme function copies it and
overrides (`private _theme = call FUNC(themeBase); _theme merge [createHashMapFromArray [...], true];`).

| Key | |
|---|---|
| `id`, `name` | style id, display name (localized) |
| `font`, `fontBold` | fonts (`PuristaMedium`, `PuristaSemibold` in the shipped look, as in vanilla Arma and ACE; `RobotoCondensed`, `RobotoCondensedBold`, `PuristaLight`, `PuristaBold` also work) |
| `upper` | BOOL, captions in capitals (`einv_gui_fnc_caption`) |
| `radius` | NUMBER, panel corner radius as a height (0 = square corners) |
| `dim`, `dimCamera` | the screen's dim colour without / with the camera |
| `panel` | column background; `[]` for none |
| `inspectBg`, `tooltipBg` | the inspect card and the kit windows; the comparison card and the mouse tooltip |
| `panelBorder` | `[]` or colour (1 px frame) |
| `card` | section header / card background |
| `slot`, `slotEmpty` | slot background filled / empty |
| `slotBorder` | `[]` or colour |
| `slotCaption` | "none" / "above" / "tab" / "inside" - where a slot's caption goes |
| `slotCaptionBg` | colour behind a "tab" caption |
| `slotIcon` | colour of the silhouette in an empty slot |
| `slotAccent` | colour of the accent (square looks: bar on the left of the primary weapon) |
| `hatch` | BOOL, empty slots and hidden tiles show diagonal hatching (Tarkov) |
| `cell` | empty grid cell colour |
| `tileBg` | ARRAY of 5 colours, by CATEGORY_* |
| `tileBorder` | `[]` or colour |
| `tileName` | BOOL, short name in the top right corner |
| `tileCount` | "text" / "pill" / "badge" - how count and ammo show |
| `tileCountBg`, `tileCountColor` | for pill/badge |
| `tileAmmoBar` | BOOL, a thin bar along the bottom of a magazine |
| `text`, `text2`, `muted`, `accent`, `accentSoft`, `line`, `gain`, `loss`, `info` | colours |
| `barTrack`, `barFill` | weight bars |
| `button`, `buttonHover`, `buttonText` | header buttons |
| `keyBg`, `keyText`, `keyRound` | key hints in the footer (`keyRound`: BOOL, a round badge instead of a key cap) |
| `cameraDefault` | unused for now, keep true |

### UI kit (all Public: No)

All take a `parent`: `controlNull` for the display (absolute coordinates) or a controls group
(coordinates relative to it). Everything snaps to pixels (relative snapping inside groups, like
Enhanced First Aid Kits' `fnc_createPanel`). Top-level controls are registered in `GVAR(created)`.

- `fnc_uiCreate [display, class, parent, rect]` -> CONTROL
- `fnc_uiPanel [display, parent, rect, colour, radius, border]` -> ARRAY of controls. radius 0: one
  rectangle; else the seven pieces (3 rects + 4 corner textures). `border` `[]` or a colour (an
  `EINV_Frame` over it, square panels only).
- `fnc_uiLabel [display, parent, rect, text, size, colour, font, align]` -> CONTROL, align 0 left /
  1 right / 2 centre (classes `EINV_Label`, `EINV_LabelRight`, `EINV_LabelCenter`).
- `fnc_uiIcon [display, parent, rect, texture, colour]` -> CONTROL (keeps aspect)
- `fnc_uiPicture` - the same with the item's own colours.
- `fnc_uiFrame [display, parent, rect, colour]` -> CONTROL (ST_FRAME)
- `fnc_uiBar [display, parent, rect, fraction, track, fill, radius]` -> ARRAY
- `fnc_uiButton [display, parent, rect, id, text, icon, theme, code]` -> ARRAY; hover lights it up
  (`button` -> `buttonHover`); left click runs `code` with `[1, id]`, right click with `[-1, id]` (one
  code for several buttons: each kit window's cross).
- `fnc_uiKeyHint [display, parent, [x, y], key, text, theme]` -> NUMBER (width taken)
- `fnc_uiHatch [display, parent, rect, colour]` - Tarkov's hatching
- `fnc_caption [text, theme]` -> STRING (capitals when the theme says so)
- `fnc_fitText` (exists) - leave ~12 % slack: in the phase 1 test, names fitted to the full width
  were still cut on the left.

### Grids and tiles

- `fnc_createGrid [display, parent, [relX, relY], rows, theme, section id]` -> grid HashMap: `parent`,
  `rel`, `cols` (STORAGE_COLS), `rows`, `cellW`, `cellH`, `cells`, `tiles`, `section`. Cells are one
  control each with a 1 px gap, created directly in `parent` (no group per grid - a nested group
  would eat the mouse wheel of the scrolling column).
- `fnc_createTile [display, grid, entry, theme]` - picture (upright, fitted), name/count/ammo per
  theme, hides the cells under it, adds the entry (with `controls`, `background`, `color`) to the
  grid's `tiles`. An entry with `hidden` true shows "?" (phase 5).
- `fnc_gridOrigin [grid]` -> `[x, y]` on the screen: the parent group's position + `rel` - the
  parent's scroll offset (`ctrlScrollValues` times `contentH - visible height`; the column stores
  `contentH` on its group with `setVariable`). Through `fnc_scrollPixels`, so a group made this frame
  counts with the scroll it gets back on the next (`QGVAR(scrollRestore)`), capped at what its content
  allows - a press that raises a scrolled kit window is worked out on the new body as it will stand.
- `fnc_screenToCell`, `fnc_tileAt` as in phase 1, through `fnc_gridOrigin`.
- `fnc_slotRect [slot]` -> `[x, y, w, h]` of a registered slot on the screen now, through its anchor
  and `fnc_gridOrigin`, clipped to its group, `[]` when scrolled out of view. The rect a slot
  registers is from before the column's scroll is restored, so hover (`fnc_updateHover`) and drag
  (`fnc_updateDrag`) both go through this.

### Building blocks the layouts share

- `fnc_drawSlot [display, parent, rect, class, options, theme]` -> ARRAY. A dedicated slot: background
  (`slot` / `slotEmpty`, hatch when the theme says so and it is empty), border, caption per
  `slotCaption`, the item's picture or the silhouette `options get "icon"` in `slotIcon`. Options
  (HashMap): `caption` (STRING), `icon` (texture for the empty slot), `ammo` (`[ammo, capacity]` or
  `[]`), `number` (STRING, e.g. "1"), `name` (BOOL, show the item name at the bottom left),
  `accent` (BOOL), `weapon` (the weapon array, so the hint names this weapon's attachments - a
  body's slots). Registers a hover area in `GVAR(slots)`.
- `fnc_drawColumn [display, rect, sections, theme, title, icon, drawer, id]` -> the scroll group. Panel
  in the theme's `panel` colour, optional title row, a scroll group, each section drawn with
  `[display, group, y, width, section, theme] call drawer` which returns the height it used; stores
  `contentH` on the group, and the column's `id` (`QGVAR(column)`: "storage", "loot") - `fnc_build`
  keeps each column's scroll by it, `fnc_startDrag` tells the columns from other groups by it.
- `fnc_drawSection` - the default drawer (Glass): header row (picture of `class`, title,
  "x.x / y.y kg", weight bar under it), then the grid with its tiles - laid out by
  `fnc_flowCompartments [layout]` -> `[places, height]` and drawn by `fnc_drawCompartments [display,
  parent, [left, top], section, layout, places, theme, window = ""]`, which a kit window shares. Folding
  and the close cross go by the section's container only.
- `fnc_drawHeader [display, theme]` - top bar: title; Style button (shows the style's name, cycles
  forward on left click, back on right click); camera switch (icon, accent while on); Vanilla; Close.
- `fnc_drawFooter [display, theme]` - key hints on the left (`ESC` Close, `I` Close), the hint in the
  middle (`GVAR(hint)`), the version on the right.

### Layout functions

`[display, theme, context] call einv_gui_fnc_layoutX` draws everything between header and footer and
returns the rectangle `[x, y, w, h]` (screen) where the soldier should stand when the camera is on, or
`[]` when the layout has no free middle. Context (HashMap): `unit`, `container`, `secondary`,
`equipment` (getEquipment), `ownSections` (getSections), `lootSections` (getLootSections), `looting`
(BOOL: a crate/vehicle/body, or a ground holder with something in it), `cameraOn` (BOOL).

### Build, camera, refresh

- `fnc_open` (exists, reworked) stores unit/containers, then `fnc_build`.
- `fnc_build [display]`: takes the kit windows away (`fnc_clearWindows`), reads each column's scroll by
  its id, deletes `GVAR(created)`, clears grids/slots/hover, reads the style, sets the dim colour,
  `drawHeader`, the layout, `drawFooter`, then the camera: on when `cameraOn`, the layout returned a
  rectangle and the unit is on foot - else off; last the kit windows (`fnc_drawWindows`, which ends with
  the tooltip, the inspect card, the filter and the hover - `fnc_drawTopLayer`).
- `fnc_cameraStart [unit, rect]` / `fnc_cameraStop`: a local `camera` in front of the unit (facing
  it, ~2.5 m, chest height), turned so the soldier stands in the middle of `rect`; `cameraEffect
  ["internal", "back"]`, `showCinemaBorder false`; pulled closer if a wall is in between
  (`lineIntersectsSurfaces`); at night a weak local `#lightpoint` on the soldier. Stop terminates and
  deletes both. Stopped on every close (onUnload), on every rebuild before starting again.
- `fnc_cycleStyle [step]`, `fnc_toggleCamera` - change, save to the profile, rebuild.
- `fnc_onFrame` (exists): hover (tiles through the grids, slots through `GVAR(slots)`); every
  CHECK_INTERVAL the close checks; every second a contents signature (`str` of `getUnitLoadout` of
  the unit and of a looted body, the cargo of other loot containers, and the cargo of every uniform,
  vest and backpack lying inside any of them, recursively via `everyContainer`) - when it changed,
  rebuild.

### Who writes what in phase 2

- items addon, storage addon - one each.
- gui core: defines, Rsc*, preInit/postInit/settings, open/build/close/keys/frame/hover, UI kit,
  grids/tiles, drawSlot/drawColumn/drawSection/drawHeader/drawFooter, camera, themeBase, style
  switching.
- Glass: `fnc_themeGlass`, `fnc_layoutGlass`,
  `fnc_drawEquipmentCards`.
- Tarkov: `fnc_themeTarkov`, `fnc_layoutTarkov`, `fnc_drawEquipmentDoll`, `fnc_drawSectionTarkov`.
- Textures: `tools/generate_ui_textures.py` and `addons/gui/ui/`.

### CBA item context menu (2026-10-09)

Other mods' options of CBA's item context menu (`CBA_fnc_addItemContextMenuOption` - ACE repack, field
rations, dog tags, IR light, CBA's accessory switching, ...) appear in the window's right-click menu.
CBA is a hard requirement, so this lives in gui; it is the one change everybody gets, with or without
Enhanced First Aid Kits.

- **Where:** a tile in a real container (`fnc_cbaTileTarget [grid]` -> `[cbaSlot, container]`: the
  player's uniform/vest/backpack -> `UNIFORM_CONTAINER` / `VEST_CONTAINER` / `BACKPACK_CONTAINER` with
  that container; a ground holder -> `GROUND`; anything else -> `CARGO` with the body a uniform, vest or
  backpack belongs to (`einv_storage_fnc_getOwner`), else the crate/vehicle/nested container) and the
  player's own slots (`fnc_cbaSlotTarget [owner, slotId]` -> `[GVAR(cbaSlots) get slotId, unit]`; a
  body's slots, a virtual grid and a kit's grid get none). `GVAR(cbaSlots)` maps the slot ids to CBA's
  names (`primary` -> `RIFLE`, `primary_mag2` -> `RIFLE_MAGAZINE_GL`, `nvg` -> `HMD`, ...).
- **Which** (`fnc_cbaOptions [unit, container, item, cbaSlot]` -> choices): read exactly as
  `cba_ui_fnc_openItemContextMenu` reads them - the item's class and every class it inherits from
  (`CBA_fnc_getItemConfig`, `inheritsFrom`, by `configName`), `cba_ui_ItemContextMenuUniqueOptions` by
  the raw class, `"##" + subtype`, `"#" + type` (`BIS_fnc_itemType`), `"#All"`; the first option of an id
  wins. Shown when the slot is in its slots (or `"ALL"`) and its show condition agrees; greyed out when
  its enable condition says no, and always when it consumes from `GROUND`/`CARGO`. Arguments exactly
  CBA's: `[unit, container, item, slot, params, id]`; conditions read with `param [0, false]` so `nil`
  counts as no. Sorted by source, then name; the first row carries a separator, and so does the window's
  Sort after them. `unit` is `call CBA_fnc_currentUnit`.
- **Left out:** whatever `einv_compat_efak_fnc_hideCbaOption [item, name]` says (isNil-guarded) -
  Enhanced First Aid Kits' own "Open" (`STR_efak_core_Action_OpenKit` on a kit class).
- **Running** (`fnc_cbaRun [condition, statement, consume, args]` -> keepOpen): the condition again,
  `CBA_fnc_consumeItem [unit, item, slot, container]` first when it consumes (on failure an RPT error and
  a statement of `{true}`), the statement isolated from the function's variables as CBA does
  (`[nil] apply {...}`). `true` reopens the menu where it was (`GVAR(menuAt)`) next frame; anything else
  asks for a rebuild (`fnc_requestRebuild`, Public: Yes - `nextCheck` and `nextSignature` to 0, so the
  next frame compares the signature; never while a tile is held).
- **Menu rows** (`fnc_openMenu [display, choices, at=[]]`): a choice may carry a 4th element, a HashMap:
  `icon` (texts of every row move over for it), `color`, `tooltip`, `enabled` false (muted; the click is
  swallowed and the menu stays), `separator` (a line above). `fnc_contextMenu [display, at=[]]` opens
  at `at` (else the mouse) and keeps it in `GVAR(menuAt)`.
- **Double click never opens the CBA menu** (Mia: double click = open a container or kit, else quick
  move; on the ground it puts on what can be worn since 0.2.4). The vanilla inventory's double click is
  not copied.
- **Covered** (`fnc_isCovered [display]`: a display whose `displayParent` is the window, or Enhanced First
  Aid Kits' `efak_gui_display` / `efak_gui_contentsDisplay` - its keybinds can open them over the window):
  `fnc_onFrame` keeps still meanwhile - no focus fix, no hover, tooltip, drag or search animation, no
  rebuild; the close checks keep running. Becoming covered ends a drag (it goes back) and a press and
  closes the menu; uncovered, `fnc_requestRebuild`. `GVAR(covered)`. A statement that closes the dialog
  (ACE's progress bar) closes the window as it closes the vanilla inventory.

## setup (Phase A, 2026-10-09)

The setup wizard. It edits one thing, the text of `einv_items_rules`, through the rules engine's own
functions (`einv_items_fnc_parseRules`, `writeRules`, `compileRules`, `getInfo [class, draft, cache]`);
it draws with the inventory's UI kit and theme (`einv_gui_fnc_ui*`, `einv_gui_fnc_theme`). Functions are
PREPed in preStart as well as preInit, so CBA's menu and the wizard's display find them in uiNamespace
over the main menu and in Eden.

### Entry points (entry files: `initEntryPoints.inc.sqf`, `Display3DEN.hpp`, `XEH_PREP_entry.hpp`, `fnc_initCbaMenu`, `fnc_openFromGame`)

| Where | Mode | How |
|---|---|---|
| CBA's Addon Options, button in the bottom row while this mod's page is open | menu | `fnc_initCbaMenu` (Extended_DisplayLoad_EventHandlers >> RscDisplayGameOptions); missing CBA controls -> no button, nothing else breaks |
| ESC > Options > Inventory setup | direct | `CBA_fnc_addPauseMenuOption` with `einv_setup_RscWizard` |
| Eden: Tools menu | direct | `Display3DEN.hpp`, over display 313; saves into the scenario |
| keybind `einv_setup_openWizard` (unbound) | direct | `fnc_openFromGame [step, class]` |
| the inventory's cog (`einv_gui_fnc_drawHeader`) | direct | `fnc_openFromGame`; the tooltip says read-only when `fnc_canEdit` says so; the inventory comes back on close (`einv_setup_reopenInventory`) |

### Functions others call

- `fnc_open [parent = displayNull, mode = "direct", step = 0, class = ""]` (Public) -> display. Parent null:
  display 46, or 313 in Eden. One wizard at a time; an open inventory closes first. The arguments reach
  `fnc_onLoad` through uiNamespace `einv_setup_openArgs`. Display `einv_setup_RscWizard`, idd 9620.
- `fnc_canEdit [mode]` (Public) -> HashMap `canSave`, `source` (`"server"` / `"mission"` / `""`), `override`
  (may force over the mission, priority 2 - multiplayer server only), `locked` (set in a
  cba_settings.sqf), `reason`, `priority`, `missionWins`. Direct mode: the mission in Eden, else the
  server - as the server (single player too), a logged-in admin or CBA's whitelist; everyone else
  read-only. Menu mode: the source picked in CBA's menu (its Client tab read-only).
- `fnc_save [overwrite = false]`: direct mode `CBA_settings_fnc_set` into the source (the mission forced at
  priority 1, the server at 2 when the switch says so); menu mode `cba_settings_fnc_import` into the
  menu as a pending change, and the wizard closes - CBA's OK keeps it. Someone else saved meanwhile
  (`einv_setup_originSource` differs): replay my edits on top (`fnc_replay`), overwrite, or cancel.

### Steps

`einv_setup_steps` = `[[id, name key, function name], ...]`: `start` (`fnc_drawStart`), `groups`, `items`,
`containers`, `review` (`fnc_drawReview`). A step whose function does not exist is a disabled tab,
"coming in the next version" - in Phase A steps 2 to 4; they join later by bringing their functions.
Step functions get `[display, group, theme, args]`.

### State

- missionNamespace: `einv_setup_mode` ("menu" / "direct"), `target` (canEdit's HashMap), `readOnly`,
  `override`, `cleanOverride`; the draft - `origin` (text in use when opened), `originSource`
  (`[value, priority]` of the source then), `draft` (AST), `draftText` (canonical), `draftRules`
  (compiled), `draftCache` (getInfo answers under it), `parseWarnings`, `clean` (last saved or loaded),
  `sourceEmpty`, `undo`, `redo`; the window - `step`, `focus`, `selection`, `stepKey`, `theme`; what steps
  keep between redraws - `keepOwn`, `exportMode`, `rawText`, `rawShown`, `presetPick`, `importText`,
  `banner`, `hint`; `reopenInventory`.
- uiNamespace (controls never go into missionNamespace): `einv_setup_display`, `openArgs`, `deferred`,
  `popover`, `frame`, `content`, `editAreas`, `root`, `sink`, `hintCtrl`, `textArea`, `importEdit`,
  `presetEdit`, `rawState`.
- Every edit goes through `fnc_commit [ast, redraw = true]` (undo step, `fnc_setDraft`, redraw).
  `fnc_setDraft [text]` raises the local CBA event **`einv_setup_draftChanged [draftText]`**. Nothing
  reaches the game before Save.
- `einv_items_rulesChanged` while the wizard is open -> `fnc_onRulesChanged` (deferred): no own changes -
  show the new setup; own changes - keep them and show a banner (Reload / keep mine). Not in menu mode.

### Deferral (`fnc_defer [code, args, delay]`, `fnc_runDeferred`)

A widget's code runs a moment later, never inside its own click (a redraw deletes the button). Not
through CBA: per-frame handlers and `CBA_fnc_execNextFrame` start in postInit, which Eden never reaches.
The queue lives in uiNamespace `einv_setup_deferred` and is emptied by whichever comes first: the
display's MouseMoving / MouseHolding events (`fnc_onMouse`, every frame while the mouse is over it) or a
spawned script that runs `fnc_runDeferred` unscheduled (`isNil`). The queue is taken before it runs, so
code that queues more starts a new queue.

## weight (Phase A, 2026-10-09)

The engine weighs every item by its config whatever `weight=` says. This addon makes the overrides count
where players feel them: ACE's weight and fatigue, through ACE movement's virtual load.

- `fnc_getExtraLoad [unit]` -> config mass: for everything the unit carries (worn, weapons with their
  attachments and loaded magazines, the contents of uniform, vest and backpack, nested containers
  included), `getInfo "mass" - getInfo "configMass"`, times the count. Below zero when the rules make
  things lighter.
- `fnc_updateVirtualLoad [unit]` - only where the unit is local: hands ACE only the difference to what it
  applied before (`einv_weight_appliedLoad` on the unit, public, so it travels with the unit) through
  `ace_movement_fnc_addLoadToUnitContainer` on the unit itself - never on a container, which could be
  dropped with our share on it. ACE's total load and load coefficient never go below zero (EFAK's share
  and anyone else's counted).
- `fnc_queueVirtualLoad` - one update per frame (`einv_weight_queued`). Queued on: the player's unit
  changing, CBA's loadout event, `einv_items_rulesChanged`, and every 3 s while a container lies inside
  the player's own storage. Postinit only - nothing in Eden.
- The inventory weighs by the same numbers: section headers, the inspect card and the hover use
  `getInfo "mass"` (through `einv_storage_fnc_getMass`); the Weight card (`einv_gui_fnc_drawEquipmentCards`)
  shows `loadAbs` plus `ace_movement_vLoad` of the unit and its uniform, vest and backpack - ACE's own
  total, EFAK's kits included - and `einv_gui_fnc_getSignature` holds that sum, so the card is drawn
  again when it changes.

## Phase 3a: moving items (2026-10-08)

- storage: `fnc_moveEntry [from, to, entry, count, cell]` (Public) -> "" / "TooHeavy" / "Failed". There is
  no "remove one item" command, so `fnc_removeEntry` writes the cargo anew without it (`fnc_snapshot`,
  `fnc_restore` - nested uniforms/vests/backpacks keep their contents) and returns a payload that
  `fnc_addPayload` puts into the target. `fnc_hasRoom` checks mass against maximumLoad (the cargo
  commands add anything). `fnc_setPlace` keeps the stored layout in step (the n-th record of a class
  belongs to the n-th entry of that class). `fnc_getGroundHolder` finds or makes the pile at the feet.
- gui: grids carry `container` and `virtual`. Mouse buttons come from the display and every scroll
  group (`fnc_onMouseButton`, deduplicated per frame); press -> drag after DRAG_THRESHOLD
  (`fnc_startDrag`, `fnc_updateDrag` with a green/red footprint, `fnc_endDrag`), Ctrl+click
  `fnc_quickMove`, Delete `fnc_dropToGround`; all through `fnc_applyMove`, which rebuilds.
- Phase 3b-7 (same day):
  - Equipment: slot ids `primary`, `primary_optic`, ... (`fnc_getSlot`), `fnc_slotAccepts` (kind, CBA
    compatible items, `compatibleMagazines` per muzzle), `fnc_slotFor`, `fnc_putOn` / `fnc_takeOff`
    (run where the unit is local; weapons through `fnc_addWeapon`, which undoes addWeapon's own magazine
    and preset attachments), `fnc_equip` / `fnc_unequip`. gui: slots register `slot` + `unit`
    (record index 5, 6); drag tile -> own slot equips, drag slot -> grid unequips, Ctrl+click slot,
    Alt+click tile; a body's worn tiles in Glass stand for its slots.
  - Searching: `fnc_isSearched` (settings searchTime/searchBodies/searchContainers/searchGround,
    `einv_noSearch` on an object), `fnc_markHidden` counts known items per container and class
    (local `einv_gui_known`), `fnc_onFrame` reveals the queue one item at a time, `fnc_learn` on moves.
  - Multiplayer: moves touching a shared container (`fnc_isShared`) go to the server as CBA events
    (storage XEH_postInit: move, take, put, unequipRemote); answers by token (`fnc_onServerAnswer`).
    Layouts stay on the client. *(superseded, see 0.2.0)*
  - Polish: Vanilla button and keybind removed (fnc_openVanilla stays as the fallback when the dialog
    cannot be created; the replaceVanilla setting stays as the off switch), Shift+drag moves half a
    stack, EFAK kits show their player-given name and open on double click. *Superseded: kits open
    inside the window now - see "Enhanced First Aid Kits and Enhanced Utility Pouches" at the end.*
- Not yet: turning items, a context menu, a search field, quick slots. *(Quick slots: the hotbar, 0.2.1.)*

## Feedback round (2026-10-08) - supersedes the parts above it contradicts

- **One look.** Tarkov's layout (`fnc_layout`, `fnc_drawEquipmentDoll`, `fnc_drawSection`) in Enhanced
  First Aid Kits' glass (`fnc_theme`). The Style button, `fnc_cycleStyle`, the Glass and Wardogs
  layouts and the separate Tarkov theme are gone; `GVAR(styles)` keeps a single entry.
- **Compartments.** `einv_storage_fnc_getBlocks` gives a container its compartments (pockets, pouches,
  main compartment and side pockets, one block for crates, `[]` for the ground), patterned per class;
  `einv_grids[] = {{cols, rows}, ...}` overrides it (since Phase A the mod layer of the rules, below the
  tables and the rules text, and below an object's `einv_grid` - see "Rules engine"). `fnc_getLayout` places entries into compartments
  (records `[class, col, row, w, h, block]`, cells `[col, row, block]`), never grows a container, and
  lists what fits nowhere as overflow (drawn red, no drop target). `fnc_hasSpace` dry-runs a layout for
  moves without a cell. `fnc_getGridRows` is gone.
- **Drop outside** every panel (`GVAR(panels)`) puts the item on the ground.
- **Duplication guard.** `fnc_restore` only re-adds a kind of cargo after clearing really emptied it;
  `fnc_removeEntry` checks the class count before and after and hands nothing on (RPT error) when it
  does not match.
- **Weapon pictures** show their attachments as Arma does: each WeaponSlotsInfo slot with an attachment lays its own `iconPicture` at `iconPosition` / `iconScale` / `iconPinpoint` over the weapon picture (`fnc_drawAttachments`) - e.g. the Spectrum Device's per-antenna pictures.
- **Context menu** on right click (`fnc_contextMenu`, `fnc_openMenu`, `fnc_closeMenu`): attach to a
  weapon, equip, move to a container, drop, open a kit (2026-10-09 in the loot column, since 2026-10-10
  in a window of its own - see the last sections); on slots take off, drop, detach parts.
- Empty slots use Arma's own gear silhouettes (`GEAR_ICON`), measured texts get `TEXT_SLACK` (1.3),
  scroll positions come back a frame after a rebuild.

## Glass back, removal by negative counts (2026-10-08) - supersedes the parts above it contradicts

- **Glass layout again.** `fnc_layoutGlass` (equipment cards | camera | storage | loot) with
  `fnc_theme`; weapon cards show every attachment slot beside the weapon (`fnc_drawEquipmentCards`)
  and the attachments on its picture (`fnc_drawAttachments`). Tarkov's `fnc_layout` is gone; its
  section drawer `fnc_drawSection` draws the storage and loot columns.
- **Taking things out of cargo** uses negative counts, as ACE does: `addItemCargoGlobal`,
  `addMagazineAmmoCargo` (that magazine, by its rounds), `addWeaponCargoGlobal`,
  `addBackpackCargoGlobal` with -n (`fnc_removeEntry`, `fnc_clearCargo`). Only what really left - read
  off the cargo before and after - is handed on. `fnc_restore` only fills a container `fnc_clearCargo`
  emptied. `fnc_normalizeWeapon` pads 6-entry weapon arrays to the 7-entry shape.
- **No copies from slots either.** `fnc_takeOff` hands nothing on while the slot still holds the item;
  `fnc_putOn` hands back an old item only when it left; `fnc_equip` (and `fnc_onServerAnswer` in MP)
  puts an item back where it came from when it did not go on; `fnc_addWeapon` returns an autoloaded
  magazine to the inventory only once it is out of the weapon.
- **Magazine onto a weapon.** A magazine or attachment dragged onto a weapon card goes on the part
  that takes it (`einv_storage_fnc_partFor`, the 7th element of `GVAR(dragTarget)` is the part slot):
  dropped on the rifle, a magazine is loaded. The context menu says "Load into" for magazines.

## Rotation, wheel count, round hover (2026-10-08) - supersedes the parts above it contradicts

- **Uniform and vest containers are no ground.** Their class derives from `ContainerSupply: WeaponHolder`,
  so `fnc_isGroundHolder` took them for piles: no pockets, no limit, no Drop from them, and after a move
  into one `fnc_afterAction` made it the loot column's "Ground" - the "copied" ground. It now excludes
  `ContainerSupply`.
- **Backpacks** are one compartment for now, as near square as `STORAGE_COLS` allows (`fnc_getBlocks`).
- **Rotation.** R while dragging (`fnc_rotateDrag`) swaps `GVAR(dragSize)`; the cell handed on is
  `[col, row, block, w, h]` and `fnc_setPlace` keeps that size. `fnc_getLayout` accepts a record either
  way round, sets `"rotated"`, and turns what fits nowhere upright. Turned pictures:
  `fnc_uiPictureTurned` (`ctrlSetAngle` works in the screen's non-square units, so the control is made
  in the pre-turn shape; `EINV_PictureStretch`, proportions from `getTextureInfo`).
- **Stack count while dragging**, as in EFAK: whole stack, Shift half; mouse wheel +/-1
  (`fnc_onMouseZ`, display and columns, one per frame), middle button all. `GVAR(dragCount)`, a counter
  at the ghost (`fnc_makeGhost`), columns held still meanwhile and scrolled at their edges
  (`fnc_updateDrag`, `dragScroll`). The hint shows the drag keys.
- **Hover outline** follows round corners: `fnc_uiRing` (edges + `ring_*_ca`, `RING_SHARE`), made per
  hovered slot (`hoverRing`); the square `hoverFrame`s are gone. Icon-only buttons centre their icon.

## Tarkov feel: uncover, inspect, search field (2026-10-08) - supersedes the parts above it contradicts

- **Uncover animation.** The search queue entry is `[container, class, row, col, cells, block]`,
  sorted by container, compartment, row, col. `fnc_showSearch` (end of every build) puts a ring
  (`search_ring_01..32_ca`, `SEARCH_RING`) and a circling magnifier on the head's tile (found via
  `fnc_findTile`), hiding its "?" (`"mark"`). `fnc_animateSearch` runs every frame from `fnc_onFrame`
  (not while a press is held; paused time is added back): fills the ring, moves the glass, rustles,
  and on completion learns, draws that one tile anew in place (`fnc_revealTile`, since 0.2.4 - a build
  only when the section's first find brings Take all) and calls `fnc_revealFx` (fade-in + accent flash,
  `fnc_flashTile`).
- **Sounds** (`fnc_playSound`, setting `einv_gui_sounds`): `playSoundUI` with vanilla
  `a3\sounds_f\characters\stances\adjust_short1-5.wss` on lift, put and while searching.
- **Feedback.** Where a dragged item lands flashes (`fnc_flashTile`); slots that take a dragged item
  glow green (`fnc_showTargets`, `dragGlow`); a name tooltip follows the mouse (`tooltip`, placed by
  `fnc_updateHover`, moved by `fnc_onFrame`); the hint shows weight.
- **Context menu**: Inspect (`fnc_inspect`, a card kept as a menu), Sort (layout record cleared), Open /
  Close for a uniform, vest or backpack lying in a container (`fnc_openNested`, `GVAR(opened)` =
  `[class, object, parent]`, shown as extra loot sections, searched as its parent). Double click opens.
- **Search field** in the header (`fnc_drawFilter`, `EINV_Edit`, `GVAR(filter)`): `fnc_applyFilter`
  fades non-matching tiles. Focus survives rebuilds (`GVAR(filterFocus)`); otherwise focus goes to an
  invisible sink button so keys never type into it by accident.

## Milsim definitions, ACE Arsenal, contrast (2026-10-08) - supersedes the parts above it contradicts

- **CBA misc items are items, not bipods.** `CBA_MiscItem_ItemInfo` has `type = 302` (the bipod type) and
  every ACE item inherits it; `fnc_getInfo` now makes CBA_MiscItem children kind "item" - ACE bandages
  stack again. Uniforms, vests, backpacks and weapons always stack 1.
- *Superseded by "Rules engine" in the items section (Phase A): the two precedence lists below are
  history. The tables are now `class=X+` rules appended last to the own layer (`fnc_compileRules`),
  `einv_items_sizeCorrections` and `fnc_findInTable` are gone, the old built-in sizes are the `default`
  preset, and a container object's `einv_grid` beats every rule. What follows "A uniform/vest opened
  inside a container" still holds.*
- **Item sizes and stacks** (items addon), first answer wins:
  size: setting `einv_items_sizeTable` "class:WxH, ..." > config `einv_gridSize[]` >
  `einv_items_sizeCorrections` (built-in, formerly the HashMap called sizeTable) > rules;
  stack: setting `einv_items_stackTable` "class:N, ..." > config `einv_stackSize` > rules (grenade 5,
  1x1 item = setting `einv_items_stackSmall`, default 10). A table class also covers every class that
  inherits from it (`fnc_findInTable`, `fnc_parseTable`). Changing a setting clears `einv_items_info`.
- **Container volume** (storage addon): setting `einv_storage_containerTable` "class:N" (cells, shaped
  by the kind's rules) or "class:WxH+WxH" (exact compartments) > config `einv_grids[]` > config
  `einv_slots` > maximumLoad / massPerCell. Capped at 8 wide, 40 rows, 320 cells (`MAX_ROWS`).
  A uniform/vest opened inside a container is tagged `einv_storage_itemClass` (fnc_openNested) so it
  gets its own pockets. Setting `einv_storage_gridOnly`: only the grid limits containers (volume over
  mass) - hasRoom always true, moveEntry/unequip ask the grid themselves; the load caption no longer
  turns red then.
- **ACE Arsenal** (new addon `arsenal`, `skipWhenMissingDependencies`): an add that does not fit the
  container's grid is taken back out (`ace_arsenal_cargoChanged` -> `fnc_onCargoChanged`, snapshot via
  `fnc_rememberCargo`, Remove all button hooked); loadouts that overflow a grid are reported on load,
  import, swap and close (`fnc_checkOverflow`, `fnc_reportOverflow`); arsenal boxes
  (`ace_arsenal_virtualItems`) are never searched; context menu "Open Arsenal" (`fnc_canOpen`, `fnc_open`).
  *Since 0.3.0 these helpers only serve players who chose ACE's own window; ACE Arsenal boxes open in the
  Enhanced Arsenal - see "Enhanced Arsenal" at the end.*
- **Contrast**: theme films and texts stronger (panel 0.85, card 0.055, slot 0.08, slotEmpty 0.055,
  slotIcon 0.5, cell 0.065, line 0.09, text2/muted brighter); header controls and the footer sit on
  their own strips of glass so they read over any world.

## Enhanced First Aid Kits and Enhanced Utility Pouches (compat_efak, 2026-10-09) - supersedes the parts above it contradicts

Mia: kits (EFAK) and pouches (EUP) work directly in the inventory, "like the other containers at the
side". A kit opens **inside the window as a section of the loot column**, like a uniform, vest or
backpack opened from inside a container; its contents are tiles; dragging packs and unpacks. *Since
2026-10-10 a kit opens in a floating window of its own instead - see "Kit windows" at the end.*

### Decisions

- **A window of the inventory, not EFAK's dialog.** Kit contents are EFAK's global table keyed by the
  instance class (`efak_core_contents`), tied to no place, display or dialog - so a kit opens wherever the
  window shows its tile: own gear, crate, vehicle, ground, a body's containers, a container opened inside a
  crate (beyond EFAK's own pouch) and inside another kit's window (only with `efak_core_allowNesting`).
  It opens as a floating glass window over the columns (gui `fnc_drawWindow`, since 2026-10-10), never as
  part of the loot column.
- **Own list.** Open kits are `einv_compat_efak_opened` (classes), not `einv_gui_opened` (which needs an
  object). Where each lies is found anew at every build (`fnc_getSections`): in the item cargo of every
  container the window shows, else in the contents of another open kit (up to `KIT_MAX_DEPTH` levels).
  Found nowhere -> closed (left the window's reach, turned back into a prototype by `CBA_fnc_setLoadout`,
  removed when empty). So a kit stays open while it is moved within sight.
- **A kit grid** is non-virtual, container objNull, plus `kit` (class) and `layoutKey`. Identity of a grid
  is `[container, kit]` - two kit grids both have objNull. Every move path outside the compat exits on
  objNull, so a path without a kit branch fails safe.
- **Tiles by the window's rules**: one entry per pile, split by getInfo `stack`, magazines by rounds
  (full ones together, opened ones by fill from `efak_core_fnc_getCharges`, a one-round magazine carries
  its round) - the same keys as `einv_storage_fnc_getContents`. The grid is the ground's open grid (no
  compartments): EFAK's only limit is its capacity, shown on the caption.
- **Layouts kept** under `"kit:" + lowercase class` in `einv_storage_layouts` (see storage, getLayout).
- **All or nothing** for the count of a drag (whole, Shift half, wheel, middle click) - as everywhere.
  Refusals turn the footprint red with EFAK's own words (`einv_gui_fnc_flashHint` now shows any text
  that is not one of its keys as it is; `""` shows nothing).
- **Leave first, write what arrived.** The cargo side changes first through the storage functions,
  counted before and after; then the kit is written once (`fnc_changeKit` -> `efak_core_fnc_setContents`,
  opened magazines' rounds noted and struck off as EFAK's internal `adjustCharges` does). Never
  `efak_core_fnc_packItem` / `unpackItem` (own source and destination, case-sensitive, no crates, ACE
  hints, would pack a kit into itself).
- **One writer per kit** (2026-10-09, Mia's hard rule: in MP nobody may ever see something different
  from another player, nothing may be duplicated or vanish). EFAK's `setContents` sends the whole kit
  and the last write wins, so every kit has exactly one writer (`fnc_isOwn`): a kit in the player's own
  uniform, vest or backpack - or worn, or packed in such a kit, any depth - is written by that player's
  machine (where EFAK writes it too: medical use, its kit window); every other kit (crate, vehicle,
  ground, body, a uniform/vest/backpack lying somewhere, a kit packed in one of those) only on the
  server, as a delta checked against the server's contents inside one unscheduled CBA handler, so the
  server serialises them. Before writing, the server checks the kit still lies where the client found
  it and that this container is no uniform, vest or backpack a living player wears (`fnc_liesIn` on the
  top container from `fnc_locate`, `fnc_isPlayerGear`: players, and units remote-controlled through Zeus
  by BIS's `bis_fnc_moduleRemoteControl_owner` mark - awake or unconscious; a dead player's body is the
  server's). So a kit picked up into somebody's gear in the meantime - also by vanilla Take, which keeps
  a backpack's object - is refused, never written by two machines. Clients never reach into another
  living player's worn gear either (`fnc_mayReach`, below). Not in SP (`isMultiplayer` false):
  everything here. *(Superseded, see 0.2.0: kits change through the storage's transactions at their
  root's authority; only EFAK's own sync is waited for.)*
- **Ready first** (`fnc_notReady`, asked before every move and shown as the kit window's notice): EFAK's
  table has to have arrived (`efak_core_contentsSynced`), and in MP the server has to have answered
  `hello` with this version of the events (`SERVER_EVENTS`, `fnc_greetServer`). The client says `hello`
  once, right after EFAK's first `syncAll`: EFAK asks again every 5 s until the first copy arrives, and
  the server answers in order, so `welcome` comes after every late copy of the table that could set an
  own kit back on this machine alone. A server without these events (einv missing there, another
  version) never answers or answers another number: after `SERVER_ANSWER_TIMEOUT` (10 s) the window
  says so (`ServerVersion`) and no kit changes - nothing leaves the player's gear for a server that
  would not take it. *(Superseded, see 0.2.0: kits change through the storage's transactions at their
  root's authority; only EFAK's own sync is waited for.)*
- **Locality of containers** as the window's moves: the player's own uniform, vest, backpack here; any
  other container on the server. A move whose two sides have one machine runs there in one go; a move
  whose sides have different machines runs in two steps - the side the player's machine writes first,
  then the server's (or the server's first, answering with exactly what left, then the client's). Whatever
  has left its place but cannot go where it was meant to by then is put away, never lost (`fnc_putAway`:
  own gear with room, else the container the kit lies in or the ground; the server counts it in).
  *(Superseded, see 0.2.0: kits change through the storage's transactions at their root's authority;
  only EFAK's own sync is waited for.)*
- **Never searched**: an open kit shows everything; the kit's own tile is searched like any item.
- **Prototypes** (`efak_core_needsConversion`) are refused: an AI body's -> `efak_core_fnc_requestUnitKits`
  (also at every build while a body is looted) and "being made ready"; the player's own -> the same text;
  in a crate or on the ground -> EFAK's `STR_efak_gui_Error_NotOpenedYet`.
- **Double click** on a kit tile opens or closes it (only while EFAK's client setting
  `efak_core_doubleClickOpen` is on), else as before (open a nested container, else quick move). Never the
  CBA menu.
- **Ctrl+click** (0.2.1: the double click and "Move over"; Ctrl+click selects) from own gear: loot containers first, then open kits (the topmost window first, since
  2026-10-10), the ground only when
  neither is shown. From a kit: own gear, EFAK's "take into" choice first (`efak_core_fnc_getKitContainer`).
  From loot: own gear (kits are no target).
- **Unpack everything** puts what fits into own gear and leaves the rest in the kit (hint) - never on the
  ground. From a kit the server writes one tile per request, the next asked only once the last is in
  (`fnc_unpackNext`), so each finds the room the last one left.
- **Names** (`fnc_getName`, through `einv_gui_fnc_itemName` wherever a name shows: tile, tooltip, hint,
  inspect title, search filter, section title and box, context menu): label -> mission type name -> the
  window's own (rule `name=`, config); short: label -> type name -> rule `name=` -> EFAK registry short
  name ("IFAK").
- **Weights** (`fnc_getMass`): hint and inspect show the real kit weight = getInfo `mass` +
  `efak_core_fnc_getWeightOffset` + both parts of `efak_core_fnc_getKitLoad`. Section loads, `hasRoom` and
  the weight card stay (the card counts ACE's vLoad, EFAK's included). The kit window's title shows
  EFAK's capacity measure, `"12 / 60 mass"` (rounded, EFAK's `STR_efak_gui_MassUnit`).
- **No `efak_*` function in gui.** Every EFAK call lives in `compat_efak`; gui calls `EFUNC(compat_efak,x)`
  only behind `!isNil QEFUNC(compat_efak,x)`. `gui fnc_openKit` (closed the window, opened EFAK's dialog)
  and `STR_einv_gui_Menu_Open` are gone. Without EFAK/EUP everything works as before; the CBA bridge (gui,
  "CBA item context menu") is the one change for everybody.

### The kit section (`fnc_getSections` -> HashMap) - what a kit window is drawn from

`id` "kit", `title` (the window's title), `class` (kit class: the title's picture), `container` objNull,
`maxLoad` -1, `entries` (`fnc_getEntries`, `[]` while `efak_core_contentsSynced` is false), `virtual`
false, `kit`, `key` and `layoutKey` (`"kit:" + lowercase class` - the window's key), `load`
(`"used / capacity mass"`), `loadOver`, `notice` (`""`, or `fnc_notReady`'s reason - "Loading the kit's
contents..." before EFAK's sync and the server's `welcome` reached this machine, the server-version text
when it never will: drawn as a line instead of the grid, so nothing can be dropped there). `closable` is
gone (2026-10-10).

Called by `einv_gui_fnc_drawWindows` (at every build and whenever a kit opens or closes), no longer by
`fnc_build`. `einv_gui_fnc_drawSection` no longer reads `key`, `closable`, `load` / `loadOver` or
`notice`: folding and the close cross go by a section's container only (`einv_gui_collapsed` holds
containers, `fnc_toggleSection` and `fnc_closeNested` take objects). `entries`, `virtual`, `kit` and
`layoutKey` stay generic keys of any section's grid (`fnc_drawCompartments`); a window's grids also get
`window` (its key).

### State (`compat_efak` XEH_preInit)

`GVAR(opened)` (kit classes, opening order; emptied by `fnc_onWindowOpen`, called from
`einv_gui_fnc_open`), `GVAR(holders)` (lowercase class -> `[container, parent kit]`, set whenever the
kit windows are drawn), `GVAR(kitStart)` (lowercase class -> `[contents, charges]` the first time the
window touched the kit - EFAK's packing-off rule, `fnc_repackable`), `GVAR(stamp)` (in the window's
signature). *(0.2.0: `GVAR(pending)`, `GVAR(nextToken)`, `GVAR(serverEvents)` and `GVAR(greeted)` are
gone with the server events - see "Synced arrangement and transactions" at the end.)*

### Opening, keeping, closing

- `fnc_toggle [gridIndex, tileIndex, doubleClick]` -> handled (double click in
  `einv_gui_fnc_onMouseButton`; Open / Close in the menu via `fnc_menuChoices`). A refused open says why
  and is still "handled" - a double click never quick-moves a kit by surprise.
- `fnc_open [class, container, parent, anchor = []]` -> `fnc_canOpen [class, container]` (prototype;
  `fnc_mayReach`: never another living player's worn uniform, vest or backpack (`fnc_isPlayerGear`), else
  EFAK's rule for others' kits - `efak_core_interactWithOthers` and, while awake, `interactWithAwake`),
  pushes the class, notes its holder, `fnc_snapshot`, the lift sound, then
  `["kit:" + lowercase class, anchor] call einv_gui_fnc_openWindow` - no build. `fnc_toggle` passes the
  tile's rect (`einv_gui_fnc_tileRect [grid, tile]`) as the anchor. Open already: brought to the top.
- `einv_gui_fnc_drawWindows` calls `[ownSections, lootSections] call EFUNC(compat_efak,getSections)` with
  the last build's context and draws one window per section; the loot column never sees kits.
- Closing: `fnc_toggle` and the window's cross / Escape go through `einv_gui_fnc_closeWindow [key]`, which
  calls `fnc_close [key]` and draws the windows again (no build); a kit found nowhere is pruned whenever
  the windows are drawn; all are emptied when the window opens again.

### Moves (`fnc_drop [source, target, entry, count, cell, slotSource]`, the dispatcher)

*Superseded (0.2.0): see "Synced arrangement and transactions" at the end.* `fnc_drop`, `fnc_equip`
and `fnc_unpackAll` only check and hand moves to `einv_gui_fnc_sendMoves`; the table below is how it
was.

`source` and `target` are `[container, kit]` (a kit's tile as target: `[the tile's grid container, tile class]`).

"Own kit" = written here (`fnc_isOwn`), "server kit" = any other; "own container" = the player's
uniform, vest, backpack, "shared container" = any other (`einv_gui_fnc_isShared`). The Runs column names
the server events (`einv_compat_efak_*`, below).

| From -> to | Function | Runs |
|---|---|---|
| within one kit | `einv_storage_fnc_setPlace` on the kit key (whole tile, onto a cell) | here |
| own slot -> own kit (section or tile) | `fnc_packSlot` (`einv_storage_fnc_takeOff`, then write) | here |
| own slot -> server kit | `fnc_packSlot` with the kit's top container: off here, then `fnc_sendToKit` | here, then `give` |
| own kit -> own kit | `fnc_moveBetween` (two writes, rounds kept; the target turns it away -> back) | here |
| server kit -> server kit | `fnc_moveBetween` (layout false, holder sent along) | `between` |
| own kit -> server kit | `fnc_takeFromKit` here, `fnc_removeIfEmpty`, `fnc_sendToKit` | here, then `give` |
| server kit -> own kit | `take`, then `fnc_putIntoKit` here when the answer comes (still own? else own gear / ground) | `take`, then here |
| own container -> own kit | `fnc_pack` (`einv_storage_fnc_removeEntry`, then write what left; a uniform, vest or backpack that left with contents - the engine picks which of a class leaves - goes back, `EmptyFirst`) | here |
| own container -> server kit | `fnc_pack` with the kit's top container: out here (an empty magazine, or a uniform, vest or backpack with contents, back), then `fnc_sendToKit` | here, then `give` |
| shared container -> server kit | `fnc_pack` (layout false) | `pack` |
| shared container -> own kit | `fetch` (`removeEntry`), then `fnc_putIntoKit` here; turned away -> back into the container (`put`) | `fetch`, then here |
| own kit -> own container | `fnc_unpack` (`fnc_takeRounds` -> `efak_core_fnc_pickCharges`, `fnc_payloadFor`, `einv_storage_fnc_addPayload`, `fnc_countHeld` before and after, write only what arrived) | here |
| own kit -> shared container (drag; Delete / Drop to `einv_storage_fnc_getGroundHolder`) | `fnc_takeFromKit` here, `fnc_removeIfEmpty`, then `put` (counted in, the rest onto the ground) | here, then `put` |
| server kit -> shared container | `fnc_unpack`, then `fnc_removeIfEmpty` in the same handler | `unpack` |
| server kit -> own container (drag; Ctrl+click via `fnc_takeOut`) | `take` (`fnc_takeFromKit`, `fnc_removeIfEmpty`), the answer `fnc_putAway`s it into the container dropped on, else own gear with room, else the ground | `take`, then here |
| own kit -> own slot (drag, Alt+click, Equip / Attach / Load) | `fnc_equip` via `einv_gui_fnc_doEquip [slot, from, entry, kit]`: out of the kit, `einv_storage_fnc_putOn`, the old item `fnc_stow`ed (into the kit if it takes it and it is empty, else own gear, else the ground); not on -> back into the kit | here |
| server kit -> own slot | `fnc_equip`: `take`, the answer puts it on; not on -> own gear / ground; the old item `fnc_stow`ed into own gear / ground (never into a server kit) | `take`, then here |
| Unpack everything, own kit | `fnc_unpackAll` (each tile into the first own container with room) | here |
| Unpack everything, server kit | `fnc_unpackAll` -> `fnc_unpackNext`: one `take` per tile, the next once the last is in | `take`, then here |

Before anything is sent the record of what leaves goes (as before), the new record only on success
(`fnc_onServerAnswer`); a refusal flashes the hint. A server kit found nowhere (`fnc_locate` -> objNull)
is refused before anything leaves ("Failed"), and so is one whose top container the player may not reach
any more (`fnc_mayReach` again at every move, in `fnc_drop`, `fnc_equip`, `fnc_unpackAll`: "NotYours").
Nothing moves while `fnc_notReady` gives a reason (the hint shows it).

- `fnc_canDrop [source, kit, entry, count, slotSource, holder]` -> `[fits, reason]`, in this order: from
  that kit itself (yes); `mayReach` of the kit's holder; a body's slot (`OwnGearOnly`); a uniform, vest or
  backpack with contents (`EmptyFirst`); `fnc_notReady` (`Loading` / `ServerVersion`); packing switched off
  (`efak_core_fnc_canPackInto`) and more than came out this session (`STR_efak_core_Error_PackingDisabled`);
  `fnc_canPack`. `fnc_canPack [kit, class, n]`: not synced, prototype, `fnc_contains` (the kit itself or
  a kit it is packed in: `NotIntoItself`), `efak_core_fnc_canPackItem [kit, class, 1, true]` (its reason,
  else `STR_efak_gui_Row_NotAllowed`), `efak_core_fnc_getPackLimit` and `countItem`
  (`Error_DefaultsReached`), room `floor ((free + 0.0001) / efak_core_fnc_getItemMass) < n`
  (`Error_NotEnoughSpace`) - EFAK's config masses, never einv's `weight=`.
- `fnc_removeIfEmpty [kit, holder]` - EFAK's "remove when empty" (`efak_core_kit_<id>_removeWhenEmpty`):
  out of the parent kit's contents (a write of the parent), or out of exactly the container it lies in
  with `einv_storage_fnc_removeEntry`, then `efak_core_fnc_freeInstance`. On the kit's writer: here for
  an own kit; a server kit is removed by the server in the handler that emptied it (a client that still
  calls it for one sends `einv_compat_efak_removeKit`, and the server looks again). Not EFAK's
  `removeKit`, which only knows the holder's top-level cargo.
- gui hooks: `fnc_updateDrag` (a kit's tile under the mouse is a target of its own, dragTarget
  `["kitTile", grid, tile, 0, fits, why]`; on a kit grid a taken cell sets the new 8th element `place`
  false instead of refusing - the kit's layout finds a cell; kit targets ask `canDrop`, cached in
  `dragRoom`), `fnc_endDrag` (kit branches before the slot-source branch and before containers are
  compared), `fnc_onMouseButton` (a kit grid's tile may be pressed), `fnc_quickMove`, `fnc_dropToGround`,
  `fnc_quickEquip`, `fnc_doEquip`, `fnc_contextMenu` (a tile in a kit: Inspect, Equip..., Drop, Open /
  Close and Unpack everything for a kit packed in it, Sort <kit>; no CBA rows, no Arsenal), `fnc_findTile`
  (7th element: kit).

### Server events and answers (`compat_efak` XEH_postInit)

*Superseded (0.2.0): see "Synced arrangement and transactions" at the end.* The events,
`fnc_askServer`, `fnc_onServerAnswer`, `fnc_greetServer`, `fnc_sendToKit`, `fnc_putAway` and the other
functions named here are deleted; the compat's XEH_postInit listens on nothing of the network any more.

All `einv_compat_efak_*`, all on the server; each ends with `client, token` (added by `fnc_askServer`)
and answers `einv_compat_efak_done [token, result, extra]` -> `fnc_onServerAnswer` (client). `where` is
the kit's top container (`fnc_locate`), checked with `fnc_liesIn` before every write; `holder` is
`[container, parent kit]` for `fnc_removeIfEmpty`.

- `hello [client]` - answered `welcome [SERVER_EVENTS]` (not `done`): this server handles these events, in
  this version (`fnc_greetServer`, `fnc_notReady`). Raise `SERVER_EVENTS` whenever an event or its
  arguments change.
- `pack [from, entryArray, count, kit, where]` - shared container -> server kit (`fnc_pack`, layout false).
- `unpack [kit, holder, where, entryArray, count, to]` - server kit -> shared container (`fnc_unpack`,
  then `fnc_removeIfEmpty`).
- `between [fromKit, fromHolder, fromWhere, toKit, toWhere, entryArray, count]` - server kit -> server kit
  (`fnc_moveBetween`, layout false).
- `take [kit, holder, where, class, count, ammo]` - out of a server kit for the client
  (`fnc_takeFromKit`, then `fnc_removeIfEmpty`); extra = the payload, `[]` when nothing left.
- `give [kit, where, payload, unit]` - into a server kit what already left the client's own side
  (`fnc_putIntoKit`); refused -> `fnc_putAway` into `where` (not when a living player wears it by now),
  else the ground at the unit's feet; extra = where it went.
- `fetch [from, entryArray, count]` - out of a shared container for an own kit (`removeEntry`); extra =
  the payload.
- `put [to, payload, unit]` - into a shared container what left an own kit, or found no place
  (`fnc_putAway` with `[to]`: counted in, the rest onto the ground); extra = where it went; token -1 =
  no answer (the fallbacks of `fnc_putAway` on a client).
- `removeKit [kit, holder]` - `fnc_removeIfEmpty` on the server, only while `fnc_liesIn` holds for the
  holder's container (a kit packed in another kit is left: an empty kit left behind loses nothing).

The answer: `pack` / `unpack` / `between` set the target's layout record on success; `give` refused shows
where it went plus the kit's reason; `put` sets the record when it went into `to`; `take` puts the payload
into the container dropped on / own gear (`container`), into an own kit (`kit`, still own? else own gear),
on a slot (`slot`, unit noted in the request) or continues Unpack everything (`all`); `fetch` writes the
own kit, refused -> back into the container. A kit is written on the client only while `fnc_isOwn` still
says so when the answer comes. An answer of its own: `einv_gui_fnc_onServerAnswer` takes containers on
both sides.

### Refresh

`efak_core_contentsChanged` (when that kit is open), `efak_core_labelChanged`, `efak_core_syncAll`,
`CBA_SettingChanged` for `efak_core_kit_*` and `efak_core_allowNesting` -> `fnc_requestRebuild` (stamp + 1,
`einv_gui_fnc_requestRebuild`). Handlers only set variables: EFAK raises `contentsChanged` inside our own
`setContents` (and on a host inside `freeInstance`); a move of the window builds right after its write.
`efak_core_syncAll` also sends the one `hello` (`fnc_greetServer`); `einv_compat_efak_welcome` notes the
server's version and rebuilds.

### EFAK functions used

Public: `isKit`, `getContents`, `getCharges`, `pickCharges`, `setContents`, `getMagazineSize`,
`canPackItem`, `canPackInto`, `getPackLimit`, `countItem`, `getCapacity`, `getUsedCapacity`,
`getItemMass`, `getKitSetting`, `getKitLabel`, `getTypeName`, `getKitShortName`, `getItemName`,
`formatCharges`. EFAK-internal (Public: No, framework revision 2), each isNil-guarded with a plain
fallback: `getKitLoad`, `getWeightOffset`, `requestUnitKits`, `getKitContainer`,
`freeInstance`. Variables read with defaults: `efak_core_contentsSynced`, `efak_core_needsConversion`,
`efak_core_doubleClickOpen`, `efak_core_interactWithOthers`, `efak_core_interactWithAwake`. Strings
reused: `STR_efak_core_Action_UnpackAll`, `STR_efak_core_Action_OpenKit` (to hide EFAK's CBA "Open"),
`STR_efak_core_Error_PackingDisabled`, `_DefaultsReached`, `_NotEnoughSpace`,
`STR_efak_gui_Error_NotOpenedYet`, `STR_efak_gui_Row_NotAllowed`, `STR_efak_gui_MassUnit`.

Enhanced Utility Pouches ships the same framework (`efak_core`, `efak_gui`, byte-identical to EFAK 1.1.2),
so one addon covers both: its pouches are ordinary EFAK kits (ammo pouches keep opened magazines as
charges; the CBRN bag holds a uniform, glasses and a backpack - only empty ones go in).

### Known limits

- **Guarantee** (one writer per kit, ready first, above): whatever this window does, two players never
  take from or add to the same old contents - the second finds the item gone or the kit full, nothing is
  duplicated, nothing vanishes (what left its place and cannot go where it was meant to lands in own
  gear, the kit's container or on the ground; a uniform, vest or backpack that left with contents goes
  back), and every machine ends with the same contents. It rests on Arma delivering one machine's CBA
  events to another in the order they were sent (the `hello` barrier).
- **The one edge left - a kit changing hands, inside one round trip:** a kit, or the container it lies
  in, that has just gone into or out of a player's worn gear can be written once by both his machine and
  the server while the one has seen the change and the other not yet. Into his gear through the window
  this cannot happen (the server moves it, so it stops writing the kit before his machine starts); it
  can when it goes in by other means - vanilla Take, which keeps a backpack's object, or a script - and
  when it goes out by any means, the window's server move included (the server moves it and writes it
  from then on, while his machine - his window, EFAK's medical use - still counts it as his until the
  change reaches it).
- **Another living player's kits do not open in the window** - in his worn uniform, vest or backpack,
  awake or unconscious, also with EFAK's `interactWithOthers` / `interactWithAwake`: his machine writes
  them, and he may wake up and pack into one any moment. A kit opened before is refused at the next move
  ("NotYours"). A dead player's body is the server's again. Zeus remote control is recognised by BIS's
  `bis_fnc_moduleRemoteControl_owner` mark only. A kit in a container lying in his gear - a vest or
  pouch in his backpack - is not his machine's: `fnc_isOwn` counts only what lies directly in his
  uniform, vest and backpack, on his machine too, so the server writes it, and it opens and changes like
  a kit on a body, by the settings for his gear (`einv_gui_fnc_checkTouch`). One writer holds.
- **The server must run the same Enhanced Inventory** (`SERVER_EVENTS`): otherwise no kit changes in
  the window (`ServerVersion`, after 10 s without an answer).
- **What it cannot cover - writes that do not go through this window:** EFAK itself writes kits on
  whichever machine acts - its medical use of a kit on the ground or of a patient's kit (on the medic's
  machine), its own kit window and ACE actions on a kit that is not in the actor's gear. Such a write in
  the same network moment as a server write of this window to the same kit can still lose one of the
  two changes, and the machine that made the other change may show its own until the kit's next write.
- **EFAK-side, on a joining machine:** EFAK's `syncAll` handler replaces the whole table even once
  `contentsSynced` is true, and EFAK asks again every 5 s until the first copy arrives - a slow server
  can answer twice, the second copy after a write made in between, setting that kit back on the joining
  machine alone. The window waits for `welcome`, which comes after every such copy, so its own writes
  never fall in that gap; EFAK's own writes there (its medical use, its kit window in the first seconds)
  are not covered. The fix belongs in EFAK: ignore `syncAll` once `contentsSynced` is true (or answer
  only the latest `requestSync`).
- A player who leaves the game between the server taking something out of a kit for him (`take`,
  `fetch`) and its answer reaching him: what was on its way to him is gone with him, as with the window's
  own server moves (`einv_storage_take`).
- Kits in crates or on the ground that nobody has carried cannot be opened (EFAK has no public conversion).
- CBA statements that look for display 602, and mods that hook RscDisplayInventory, never see the window.
  CBA's item renames (`CBA_fnc_renameInventoryItem`) are not applied.
- Kit contents count toward no crate's load and no `hasRoom` (the engine does not count them either).
- On a dedicated server the reasons a server-side pack or unpack gives come in the server's language.

## Living persons (2026-10-09) - supersedes the parts above it contradicts

- **Entry.** The engine's "Open <backpack>" (CfgActions OpenBag, only from behind, only the backpack) is
  off the action menu with `show = 0` (gui/CfgActions.hpp); scripts still run it. Every CAManBase carries
  one scroll action per client (`fnc_addPersonAction`: XEH init, all units at postInit, and
  `einv_gui_addPersonAction` after a respawn - the mark `einv_gui_personAction` = [unit, id] names its
  unit, since a respawned unit takes the variables along but not the action). It reads like the engine's
  own: "Inventory" with the gear icon from CfgActions Gear, or "Open <backpack>" from OpenBag when only
  the backpack may be opened. It has no shortcut, and it shows mid-screen only when OpenBag does (ACE:
  no). `fnc_personActionCondition` requires: alive, on foot, ACE canInteractWith, PERSON_REACH from the
  eyes, and for the unconscious beyond ACE medical's own "Inventory" (radius 2, `ACE_INVENTORY_REACH`) -
  within it ACE's stands alone. Agents carry no actions: the player's own soldier carries one more
  (`fnc_addAgentAction`, from the CBA "unit" player event, mark `einv_gui_agentAction`) whose condition
  (`fnc_agentActionCondition`) takes an agent under `cursorObject` within PERSON_REACH and asks the same
  condition; the text cache `einv_gui_personActionText` is [action id, key]. `fnc_openPerson` (public)
  opens the window and tells the person (`fnc_notifyPerson`: ACE's zipper event for a real backpack and
  a line of text for a player, server switch `einv_gui_personNotify`) - with the window switched off,
  only the text, once the vanilla inventory is open. `fnc_onInventoryOpened` turns a living wearer's
  backpack (ACE's backpack interaction) into the whole person, and blocks ACE dragging clones,
  `einv_noAccess` and persons out of reach (`fnc_personInReach`, hint "OutOfReach"). Bodies keep their
  entries; one opened by the backpack it wears (ACE's "Open <backpack>" on the dead, a script) opens
  whole as well, with nothing asked (Mia, 2026-10-10 - see "Living persons and kits together").
- **Who and what.** `fnc_canOpenPerson` returns "whole" / "backpack" / "". `fnc_canTouchPerson` takes
  "items" or "worn" plus the top container. On the looter side, `fnc_checkTouch` returns a reason
  ("LookOnly", "Failed" when out of reach), through `fnc_personOf` -> [person, top container]: the
  window's own `GVAR(person)` when the container is one they wear, else `einv_storage_fnc_getOwner`,
  which ignores a stale owner mark (a container its marked unit no longer wears) and asks objectParent.
  Settings (server): `einv_gui_personOpen`, `personItems` and `personWorn` (Everyone / unconscious and
  captives (`fnc_isHelpless`) / none), plus `personNotify` and `searchPersons`. Gated in startDrag,
  updateDrag, contextMenu, quickMove, movePerson, doEquip and doUnequip (hint "LookOnly"), and again on
  the person's machine, which also keeps a locked uniform, vest or backpack on them.
- **Window.** As for a body: the doll, then pockets, rig and backpack, with ACE's name. A living
  person's containers locked with lockInventory are left out. `GVAR(person)` and `GVAR(personMode)` are
  set in fnc_open. fnc_onFrame closes the window beyond PERSON_KEEP, in a vehicle, when the person is
  claimed by someone else or gone, or when they may no longer be opened; a person who dies stays open.
  The signature leaves out a living person's loaded rounds.
- **Every change where it is local.** *(Superseded, see 0.2.0: the relay below is replaced by the storage's
  transactions and `fnc_personGuard`.)* `fnc_isShared` resolves nested containers to the top one. Own ->
  shared is removed here and put in where the target lives (`fnc_deliverPayload`: here when local, else
  `einv_storage_put`, which now falls back to the ground). A living person's containers and slots change
  on the person's machine:
  - `fnc_askPerson` -> server `einv_gui_personForward` -> targetEvent `einv_gui_personRequest` ->
    `fnc_onPersonRequest`. The kinds are take, takeOff, put, move and unequip. It checks reach,
    permission, and that the container is theirs.
  - The answer goes `einv_gui_personReply` (server) -> `einv_gui_personAnswer` -> `fnc_onPersonAnswer`,
    matched by token in `GVAR(pending)`. Straight back when the request came from the same machine
    (`clientOwner`); a player who disconnected meanwhile gets nothing, and the payload lands at the
    person's feet.
  - Payloads come back to the looter and go on through `fnc_deliverPayload`. A put that is turned down
    goes back where it came from, else to the ground. Ground -> person is a server `take` (now with a
    count) followed by a person put (pending "relay").
- **Known gaps.** A request is lost when the person's client disconnects the moment it arrives. Older
  than this feature: the server still removes from piles a client created, and still refills nested
  containers in containers it does not own; storage `unequip` lets a uniform go into a vest lying inside
  it.

## Living persons and kits together (2026-10-10) - supersedes the parts above it contradicts

The person access and compat_efak were built side by side on 0.1.15 and merged into 0.1.16. Where they
meet:

- **Bodies by the backpack** (Mia): `fnc_onInventoryOpened` turns a dead wearer's backpack, as the engine
  names it for ACE's "Open <backpack>" or a script, into the whole body plus what the engine named
  beside it - like a living person, but with nothing asked (bodies are open to everyone) and nobody
  told. A body named itself stays as the engine named it.
- **Hints.** `fnc_flashHint` knows TooHeavy, NoRoom, NowhereToGo, NoFit, LookOnly and Failed; any other
  text shows as it is (EFAK's and the compat's reasons), `""` shows nothing.
- **Closing while covered.** The person checks of `fnc_onFrame` are part of its close test, which also
  runs while another window (EFAK's, a CBA option's dialog) lies over this one: a person who walks off
  meanwhile closes the window.
- **Context menu.** On a living person's item the player may only look at: no Equip / Drop, and no CBA
  rows either - other mods' choices would change it. A tile in an open kit is judged by the gear the kit
  lies in (`einv_compat_efak_fnc_checkTouch`). `fnc_doEquip` asks the kit first, then the person, then
  the shared container.
- **Ctrl+click** (0.2.1: the double click and "Move over") from own gear: loot containers the player may put into (`fnc_checkTouch`), then open
  kits, the ground only when neither is shown; when every container shown was refused and no kit takes
  it, the hint gives the person's reason.
- **Drag footprint** (`fnc_updateDrag`): a kit grid asks `einv_compat_efak_fnc_canDrop`; any other grid
  of another container asks `fnc_checkTouch`, then the room. `fnc_startDrag` lifts nothing out of a kit
  in a person's gear the player may not change.
- **A kit in a living person's gear** is part of their gear: packing into it and taking out of it -
  drag, Ctrl+click, Unpack everything (not offered then), Equip - follow "Take and put items" and their
  reach (`einv_compat_efak_fnc_checkTouch` on the kit's top container, asked in `fnc_canDrop`, `fnc_drop`,
  `fnc_equip`, `fnc_unpackAll`, `fnc_menuChoices`; `fnc_drop` and `fnc_equip` ask it before the
  `fnc_isOwn` split, so a kit written here - every kit in single player - is held to it as well, also on
  Alt+click). Looking into it stays allowed, as opening a uniform
  in their backpack does. Unpack everything out of a server kit asks again before each tile
  (`fnc_unpackNext`: `fnc_mayReach`, then `einv_gui_fnc_checkTouch` on the kit's top container): the chain
  runs on after the window closed, so a person who woke up, a setting that changed or a player who
  walked off stops it, the rest stays in the kit and the hint gives the reason.
- **Another living player's kits** (compat's rule, kept; Mia, 2026-10-10: shown, but neither opened nor
  moved): their tiles show in the person window. Opening one and packing into it are refused with "The
  kits of others are off limits here" (`fnc_mayReach`, now asked before the prototype check in
  `fnc_canOpen`, so a prototype there says the same), and so is moving the kit itself
  (`einv_compat_efak_fnc_checkTile [class, container]`: a kit directly in the uniform, vest or backpack a
  living player other than this one wears, `fnc_isPlayerGear`). Asked in `fnc_startDrag` (nothing is
  lifted), `fnc_movePerson` (drag, Ctrl+click, a double click that falls back to Ctrl+click, Delete,
  Drop), `fnc_contextMenu` (no Equip / Drop and no CBA rows for it) and `fnc_doEquip`. Taking off the
  uniform, vest or backpack it lies in stays a move of worn gear, by "Take off worn gear". A kit in a
  container lying in his gear is the server's and moves like his other items (compat Known limits).
- **A living person's container as one side of a kit move** *(superseded, see 0.2.0)* changes on the
  person's machine, never through the compat's server events:
  - container -> kit: `einv_gui_fnc_askPerson` "take", pending `["personThen", function, args]` (a new kind
    of `fnc_onPersonAnswer`: another addon's next step) -> `einv_compat_efak_fnc_fromPerson`: into an own
    kit here (`fnc_putIntoKit`; turned away -> back to the person, turned down there -> the ground), into
    a server kit through `give` (`fnc_sendToKit`). The args carry where `fnc_drop` found the kit
    (`[container, kit]`): a closed kit's tile is in no list `fnc_locate` reads, so it is located with that
    holder, and looked up anew only when that finds nothing. Before `give`, what the server kit would turn
    away goes back to the person instead - a weapon, a uniform, vest or backpack that left with contents
    (`EmptyFirst`), an empty magazine (`EmptyMagazine`) - as `fnc_pack` does for own gear: turned away
    there it would go where the kit lies or onto the ground.
  - own kit -> container: `fnc_takeFromKit` here, `fnc_removeIfEmpty`, then askPerson "put" (pending
    `personPut`, back = the ground).
  - server kit -> container: the server's `take`, whose answer (`["container", to, cell]`) goes on with
    askPerson "put" for a person's container.
  - The compat's server handlers change no living soldier's gear that another machine changes
    (`einv_compat_efak_fnc_wornElsewhere [container]`: worn by a living unit or agent not local to the
    server, or lying in such gear up to four levels deep, found with `everyContainer` - the server cannot
    use the window's list of opened containers). `fnc_removeIfEmpty` leaves an emptied kit there (as one
    packed in a kit the server cannot place: an empty kit left behind loses nothing, a kit freed while
    another player takes it out on the person's machine would share its contents with the next), and
    `give`'s refusal goes onto the ground at the asking player's feet instead of into that container. AI
    local to the server and the host's own soldier are the server's to change, as before. This covers the
    player's own containers lying in his backpack too, which his machine now changes itself
    (`fnc_isShared` resolves nesting).
- **Kits made real** (`efak_core_fnc_requestUnitKits` in `einv_compat_efak_fnc_getSections`): for bodies as
  before, for a living soldier the window opens only while EFAK's rule lets players use his kits.
- **The one edge left (compat), narrowed.** `fnc_applyMove` now takes the player's own gear out on his
  machine before it goes into a shared container (person access, "Every change where it is local"), and
  another player's window takes it out of his gear on his machine too. So a kit, or the uniform, vest or
  backpack it lies in, that leaves a player's gear through the window is no longer his machine's to
  write before the server or the other player starts writing it. The edge stays for other means
  (vanilla, scripts) and for a kit going into his gear by them.
- **Person requests always pass the server in multiplayer** *(superseded, see 0.2.0)* (`fnc_askPerson`), also
  for a person local to the player's own machine (AI in his group), and so does the answer once the person's
  gear changed (`fnc_onPersonRequest` answers straight only when nothing changed, in single player and on the
  server itself). Taken straight on his machine, a server kit in his AI's gear became his to write
  (`fnc_isOwn`) at once, while the server - not yet seeing the change - still wrote it for another player.
  Through the server, the server sees the change before it passes the answer on: a write it made before
  reaches him before the kit is his, and a request it handles later finds the kit gone (`fnc_liesIn`). This
  supersedes "Straight back when the request came from the same machine" above. It costs AI in the player's
  group one round trip to the server per move.

## Kit windows (2026-10-10) - supersedes the parts above it contradicts

Mia after testing 0.1.16: opening an IFAK "pops" - the drop / ground column pops up, the other one pops
away. Root cause: open kits were sections of the loot column (`fnc_build` appended them to
`lootSections`), so they decided whether that column existed (`looting`), what it was titled and how tall
it was; and the columns' scroll was restored by list position and only when the number of groups
matched. Decision (Mia offered "like the inspect thing" or "like the other containers at the side"): kits
and pouches open as **floating glass windows**, like Tarkov's container windows and our inspect card.

- **Kits leave the loot column.** `fnc_build` no longer appends them: `lootSections` and `looting` are
  real loot only. Opening, closing, raising or moving a kit window draws only the windows
  (`fnc_drawWindows`, `fnc_raiseWindow`) - no section appears, goes or moves, no column scrolls, the camera
  keeps its aim.
- **Column scroll by id.** `fnc_drawColumn` tags its group with an id (`QGVAR(column)`: "storage",
  "loot"); `fnc_build` reads each column's scroll in screen height from the top (`fnc_scrollPixels
  [group]`, which counts a scroll still waiting to be put back as the group's own) and puts it back on the
  next frame by id (`QGVAR(scrollRestore)` `[group, pixels, frame]`, processed first thing in
  `fnc_onFrame`) as `(pixels / new range) min 1`. Window groups and the inspect card no longer count, so
  the loot column coming in for real loot does not reset the storage column either. Window bodies keep
  their scroll the same way (`GVAR(windowScroll)`).
- **The window** (`fnc_drawWindow [display, section, theme, fresh]` -> record): one `EINV_Group` of a
  fixed size whose content fits it exactly - the inspect card's glass (`inspectBg`, theme radius) with the
  context menu's edge, a title row (the kit's picture, its name, `"12 / 60 mass"` right-aligned in `loss`
  when over, a close cross - `fnc_uiButton` with the key as id), a hairline, and a body
  (`EINV_ScrollGroup`, reaching into the right padding) holding the kit's grid
  (`fnc_drawCompartments`, grids tagged `window` = key) or the notice. At most the content band high: a
  kit taller than the screen scrolls in its body. Records in uiNamespace `QGVAR(windows)`: `key`, `group`,
  `body`, `rect`, `title` and `close` (rects in the window), `section`, `grids` (indices).
- **Placement** (`fnc_placeWindow [[w, h], anchor]`): next to the kit's tile (`fnc_tileRect`), never over
  it; candidates in the free middle (`GVAR(middle)`, right-aligned - always, also for a window wider than
  the middle, as on 16:9 and 16:10 while looting, which then reaches into the equipment column instead of
  a storage or loot column - then a window's width further left while it starts inside the middle),
  then left of, right of, below, above the tile, each clamped into the content band; the least overlap
  with `GVAR(panels)` and the open windows wins, ties by distance to the tile. Kept while the inventory is
  open (`GVAR(windowPos)`), clamped at every draw and move between header and footer; forgotten when the
  window closes and when the inventory opens.
- **Moving**: a left press on the title strip (not the cross) sets `GVAR(windowMove)`; `fnc_onFrame`
  follows the mouse, snapped to pixels, looked up by key every frame; released or covered, it ends. No
  grip button: a focused control would draw over everything.
- **Opening** (`fnc_openWindow [key, anchor]`): on top of `GVAR(windowOrder)`, anchored, marked fresh -
  fades in over `WINDOW_FADE` (0.15 s) with a `LAND_FLASH` accent flash on its title. No scale effect:
  resizing a group clips instead of scaling; the flash leaves the cross out, which stays the topmost
  thing there for its clicks. **Closing** (`fnc_closeWindow [key]` -> was open): cross (not while
  something is dragged - its right click works with the left button held), Escape on the topmost (after
  the menu and the inspect card; not while Escape is to empty the search field, nor while something is
  dragged), double click / Close on the tile; `einv_compat_efak_fnc_close`, lift sound,
  windows drawn again - kits found only through it close too.
- **Z-order**: creation order is the only one the engine has. The floating layer is made after
  everything else of a build: windows bottom first, then the name tooltip and the inspect card
  (`fnc_drawTopLayer`, which also applies the filter and the hover); the context menu, footprint, ghost
  and counter come later still. **Raise** (`fnc_raiseWindow [key]`, any press on a lower window but on
  its cross or its body's scroll bar - the engine's bar would be taken away under the mouse): that
  window alone is made again, last, from its record's section; its new grids take the old ones' places in
  `GVAR(grids)`, so press, hover and the remembered first click stay valid, and the press is worked out
  on the new body as scrolled as the old one (`fnc_gridOrigin` counts the pending restore). A window that
  goes is hidden at once and put in `QGVAR(windowTrash)` (`fnc_clearWindows` for all of them,
  `fnc_raiseWindow` for one);
  `fnc_onFrame` deletes it on the next frame, never inside its own event (`fnc_build`'s sweep of
  unregistered controls takes it along when a build comes first). Window grids always come after the
  columns' in `GVAR(grids)`: `fnc_clearWindows` drops them and forgets a press or hover on one,
  `fnc_drawWindows` a remembered first click on one.
- **Hit testing** (`fnc_topAt [point]` -> "inspect", a window key or ""): menu > inspect card > windows
  (top first) > columns. `fnc_updateHover` (grids whose `window` matches, slots only on ""),
  `fnc_updateDrag` (targets, slots, the ground only on "" and outside every panel - over a window's title
  or edge it goes back; edge scrolling per layer, bodies included), `fnc_onMouseButton` (raise, move,
  cross), `fnc_contextMenu` (free cells), `fnc_startDrag` (`dragScroll` = columns by id plus every window
  body, each with its layer), `fnc_quickMove` (Ctrl+click from own gear: kits topmost window first).
  The wheel over a window goes to the window (assumed in the game: the topmost group takes it).
- **compat_efak**: `fnc_open` takes an anchor and calls `einv_gui_fnc_openWindow`; `fnc_toggle` opens with
  the tile's rect and closes through `einv_gui_fnc_closeWindow`; `fnc_getSections` is called by
  `einv_gui_fnc_drawWindows` and has no `closable` any more. Moves, the one-writer rule, the server events
  and the refresh handlers are unchanged: a window's grid carries the keys a kit section's grid carried
  (`container` objNull, `virtual` false, `kit`, `layoutKey`) plus `window`.
- **Accepted limits**: controls made on the display later than the windows draw over them where a window
  has been moved onto the equipment cards (a hovered slot's ring, the green glow of slots taking a dragged
  item, a footprint under a window's edge). Dropping the first item on the ground with nothing looted still
  brings the loot column in - real loot - but the storage column keeps its scroll. A window covers the
  soldier in the middle while it is open, as in Tarkov.
- **To confirm in the game**: the topmost group takes the wheel (nothing under a window scrolls), and a
  group's fade carries its controls (the fade-in).

## Synced arrangement and transactions (0.2.0) - supersedes the parts above it contradicts

The core backbone (backlog `core_design.md` sections 1-6, wave W1 of the build plan): one arrangement for
everyone, every change as a transaction run where its container is local, the server as the hub between
machines. Selection, group moves, Take all and everything nearby build on it and came with 0.2.1 (the
Window and Nearby bullets below).

- **Authority.** Every container is changed only where its root is local: the unit for a unit's uniform,
  vest or backpack (and what lies in them), else the object itself (crate, vehicle, pile, body); kits by the
  root of their container. `einv_storage_fnc_rootOf`, `fnc_verifyChain`, `fnc_isLocalRoot` (multiplayer:
  only the player's own unit runs without the hub).
- **Places.** `einv_storage_places = [revision, records]`, public, on the container (kits:
  `einv_storage_places_kit_<class>`, dropped when the kit instance is freed), written only by the authority
  (`fnc_writePlaces`; the player's own containers broadcast at most every 2 s, `fnc_flushPlaces` - also on
  closing the window and on death), canonical, the latest write re-asserted after locality changes, stale
  viewer copies re-written on request. Records `[key, col, row, w, h, block]`, keys by `fnc_entryKey`
  (`class|w<hash>` a weapon by what is on it, `class|m<rounds>` a magazine, `class|c<uid>` a uniform, vest
  or backpack lying in a container, else the lowercase class; `fnc_payloadKey` gives the key a payload will
  have once it lands). `fnc_getLayout` is pure: exact keys, then same kind (`fnc_layoutKey`, ACE's
  `ace_arsenal_uniqueBase`), then first fit; `"drift"` makes the window ask the authority to `normalize`.
  While a phase runs, reads and `fnc_setPlace` go through its buffer (`GVAR(buffer)`), written once at the
  end. `fnc_dumpPlaces [holder]` (public) writes revision, records, nested tags and the drawn view to the
  RPT.
- **Nested containers.** A uniform, vest or backpack lying in a container carries a tag `[uid, itemClass,
  parent]` (`fnc_tagNested`, ids from `fnc_newUid`: `<machine id>-<n>`) and travels with its places in
  payloads (the snapshot's sixth element `[records, tag]`, `fnc_snapshot` / `fnc_restore`; since 0.3.3 a seventh,
  the carried variables `[[name, value], ...]` - see "Locks, ACE cargo and radios" at the end); same-class
  siblings never swap (`fnc_removeSameClass`: all of the class out, the wanted one by uid, the others back,
  verified). The gate test whether variables on nested objects reach other machines (G1) was never run, so
  both ways are kept: tags and places stay on the nested object, and in multiplayer a copy goes onto the
  outermost container, `einv_storage_nested = [[netId, uid, itemClass, places], ...]`. Readers take the
  object's own tag first, else the copy's; for places the higher revision of the two (the object's own on a
  tie, the copy only when its uid matches). The authority brings objects up to their copies in
  `fnc_verifyChain` (once per frame per outermost container). This needs nested containers to keep their
  `netId` across machines.
- **Transactions.** `einv_storage_fnc_request [phases, callback, args, silent, requester]` (public); a phase
  is `[root, ops]`, ops on one root (`GVAR(ops)`: place, placeMany, sort, normalize, move (within one root),
  take, put, putGround, takeOff, putOn; compat's kitTake, kitPut, kitPlace, kitMove, kitRemoveIfEmpty); an
  op's input may be a ref `["#ref", phase, op, n]` to what an earlier op produced. Each op answers
  `[status, produced, extra]`. Guards (`GVAR(guards)`, `[op, args, requester, root] -> "" or reason`), reach
  (`fnc_inReach`) and the holder check (`fnc_verifyChain`) run before every op where it runs. Phases run
  whole, journaled (`GVAR(journal)` by `"id|phase|attempt"`, `fnc_journalNote`, `fnc_phaseFinalize` the
  next frame - through `fnc_nextFrame`, which works in Eden too), within a per-frame op budget (`fnc_tick`,
  `PHASE_FRAME_OPS`). The server hub (`fnc_hubStart`, `fnc_hubNext`, `fnc_hubRoute`, `fnc_hubPhaseDone`,
  `fnc_hubTick`, `fnc_hubDisconnect`) routes each phase to its root's owner, never to two owners of one
  root at once, re-sends unanswered phases every 10 s, holds payloads in escrow while they travel to a
  client, settles every unconsumed payload back to its origin, into the requester's vehicle or onto the
  ground (`fnc_settle`, steps 1-3, no reach and no guards), and re-routes a leaving player's phases
  (`PlayerDisconnected`, and `allUsers` as a safety net). A settlement step the requester cannot run itself
  goes to the hub as a silent transaction whose first phase counts as run and carries the payloads, so the
  hub's books - refs only - cover them. Single player runs the same code in one frame. The answer's summary
  is `[per phase per op [status, extra], [went back, into the vehicle, onto the ground], pile or objNull]`.
  `fnc_moveEntry`, `fnc_equip` and `fnc_unequip` (public) are wrappers for missions that build these
  phases and return `""` (done here), `"Requested"` or a reason.
- **Handshake.** A client greets the server (`einv_storage_hello [machine id, version]`, again every 5 s
  until answered, `fnc_greetServer`); the server answers `einv_storage_welcome [version]`.
  `einv_storage_fnc_hubReady` is true in single player, on the server and on a client after a welcome with
  the same version; before that the window refuses moves that need the hub ("Waiting for the server - try
  again in a moment"): a server without these events would drop what the client already took out. The
  kits' own greeting is gone; `einv_compat_efak_fnc_notReady` only waits for EFAK's own sync.
- **Window.** No prediction: `fnc_sendMoves` turns every move into phases (at most `BATCH_MAX` moves per
  transaction, the next chunk when the answer came); moved tiles stay faded and cannot be lifted, their
  target cells outlined (`GVAR(inFlight)`, `fnc_drawPending`) until the answer and the new places arrived
  (`GVAR(answers)`, finished in `fnc_onFrame` by `fnc_afterAction`, at the latest `ANSWER_WAIT` seconds
  after the answer; given up after `PENDING_TIMEOUT` with a hint). While its own moves are under way the
  window does not rebuild for a change of contents. Drift is noted per grid (`GVAR(drift)`, from
  `fnc_drawCompartments`, whose grids carry `holder` and `root`) and reported after `DRIFT_WAIT`
  (`fnc_requestNormalize`, a silent `normalize [holder, revision, hashValue records]`). A uniform, vest or
  backpack opened from inside a container is found again by its key when the engine made it anew. A
  dragged container over itself or anything lying in it shows red ("It cannot go into itself",
  `einv_storage_fnc_liesIn`). The signature holds the places revision of every holder shown. Ground drops
  go to a non-empty server-local pile within 2 m that the player can see, or a fresh one on the surface
  under the feet (`fnc_groundPos`, `fnc_getGroundHolder` on the server); seated, into the vehicle; nothing
  under the feet - swimming, falling - is refused. In multiplayer shared containers never open in the
  vanilla inventory (`fnc_onInventoryOpened`; the first time, the window says why).
  *Since 0.2.1:*
  - **Selection** (inventory only - `fnc_isInventoryMode`, no hook table attached): a click selects a tile,
    Ctrl+click toggles it, Shift+click takes the range from the anchor in reading order, a frame dragged
    out from an empty cell (`fnc_startBand`, `fnc_updateBand`, `fnc_endBand`; the column scrolls at its
    edge) takes what it touches, Ctrl+A the section under the mouse (`fnc_selectSection`), Escape lets go
    after the menu, the inspect card and the kit windows. One side at a time ("own" or "loot"). Tiles
    searched, not under way, on a column's grid - never a kit window's - can be selected. The selection
    is view state: refs `[holder, key, compartment, col, row]` (`GVAR(selection)`), found again on every
    build and redraw by `fnc_selectionTiles`, which drops what is gone; `fnc_drawSelection` shows a
    two-pixel accent frame and a faint fill in each tile's own group. A click on a tile of a selection of
    several does nothing, so a double click can move them (`fnc_quickMoveGroup`: own -> the loot column's
    containers in order, else the ground at the feet; loot -> uniform, vest, backpack; Delete and the
    menu's "Drop" put the selection on the ground). Quick move is the double click now (it was
    Ctrl+click), and the menu has a "Move over" row on every tile for what a double click would open.
  - **Group drag** (`GVAR(dragGroup)`, the same drag trio): whole stacks, no turning, no wheel. Over a grid
    `fnc_groupMode` decides, cached per cell in `GVAR(dragRoom)`: *keep* (one compartment, every tile's
    cell free or lifted, room by mass in another holder; a footprint per tile, the pictures at their
    offsets), *pack* (`einv_storage_fnc_plan` into the hovered container, its compartment first; an outline
    green, amber or red, "4 / 6" on the counter), *kit* (`einv_compat_efak_fnc_canDrop` for each tile) or
    *none* (into itself, a person's container the player may not put into, a slot: "Several items cannot go
    into one slot"). `endDrag` sends keep and pack through `fnc_sendPlan`: the tiles that stay in their
    holder are one `placeMany` move (`fnc_sendMoves` kind "placeMany": one op, so two tiles never wait for
    each other's cells), the others one move each with the planned cell, the hint "Moved 4 of 6 - no room
    for the rest" when the plan left some behind.
  - **Take all / Put all in**: a button on the caption line of every loot section that holds something
    searched ("Take all" into uniform, vest and backpack), of the unit's own sections and the containers
    opened from them ("Put all in" into the first container of the loot column that takes things,
    `fnc_putAllTarget`; never the ground), and on a kit's window title ("Take all" through
    `einv_compat_efak_fnc_unpackAll`). `fnc_takeAll` and `fnc_putAll` work from the container's contents,
    not from what is drawn, so a folded section works too; what is not searched stays ("3 not searched
    yet"). The button is drawn disabled while a move out of its section is under way, and its click runs
    a frame later (`fnc_later`). `fnc_uiButton` has the disabled state and a text size for it.
  - **Redraw**: the signature is `[own, list, loot]` (`fnc_getSignature`). `own` or `list` (the sections
    shown, what lies around, bodies' dolls, kits) changed: `fnc_build`. Only some `loot` parts (cargo and
    places revision of a section) changed: `fnc_redrawTiles` draws those sections' tiles again
    (`fnc_drawTiles`, split out of `fnc_drawCompartments`) and updates the load text; it answers false
    before touching anything when the compartments (as `fnc_viewBlocks` shows them, since 0.2.4), the
    overflow tiles, the button or the folded-rows line changed, or a pile emptied, and `fnc_onFrame`
    builds then. The search's glass and ring are made anew with the queue (`fnc_showSearch` deletes the
    last ones), so the section being searched redraws in place as well (0.2.4). Nothing is
    rebuilt while a frame is held.
  - **Hotbar hooks**: the drag trio, the context menu, `fnc_onKeyDown` and the footer call
    `einv_hotbar_fnc_*` only behind `isNil` guards and in the inventory (see the hotbar section).
- **Living persons on transactions.** The relay (`fnc_askPerson`, `fnc_movePerson`, `fnc_onPersonRequest`,
  `fnc_onPersonAnswer`, `fnc_deliverPayload`) and `fnc_onServerAnswer` are deleted. A living person's rules
  are the guard `einv_gui_fnc_personGuard` (`fnc_canTouchPerson` "worn" for takeOff and putOn, "items" for
  every other op - rearranging and sorting included - with the top container a holder or kit lies in;
  `fnc_personInReach`; a locked uniform, vest or backpack does not come off), run on the person's machine.
  The looter's own checks (`fnc_checkTouch`) stay for the hint. `fnc_isShared` is
  `!isLocalRoot(rootOf(holder))`.
- **Kits on transactions.** compat_efak registers the holder type `"kit"` (`einv_storage_holderTypes`:
  `entries`; `root` - `fnc_holderRoot [holder, hint]`, the hint handed on by `einv_storage_fnc_rootOf`;
  `verify` - `fnc_holderVerify`, read off the real cargo under the root; and its op names) and the ops
  kitTake, kitPut, kitPlace, kitMove and kitRemoveIfEmpty, each checking first that its kit lies under the
  phase's root. `fnc_drop`, `fnc_equip` and `fnc_unpackAll` check and hand moves to
  `einv_gui_fnc_sendMoves`, which builds a kit's phases from the type's op names. An emptied kit is removed
  inside the op and its places dropped (`fnc_removeIfEmpty`, `einv_storage_fnc_dropPlaces`). Equipping out
  of a kit: the old item goes into the kit when `fnc_canPack` allows it, else into the player's first own
  container with room (`fnc_equip` decides, `fnc_sendMoves` follows), else where settlement puts it. The
  server events, `fnc_isOwn`, `fnc_askServer`, `fnc_onServerAnswer`, `fnc_greetServer`, `fnc_sendToKit`,
  `fnc_putAway`, `fnc_pack`, `fnc_unpack`, `fnc_unpackNext`, `fnc_moveBetween`, `fnc_packSlot`, `fnc_stow`,
  `fnc_countHeld`, `fnc_fromPerson`, `fnc_wornElsewhere` and the compat's own `fnc_liesIn` are deleted;
  `fnc_isPlayerGear` stays for the rule that another living player's kits are shown but neither opened nor
  moved. "Unpack everything" no longer re-sorts the kit.
- **Nearby** (0.2.1). `einv_storage_fnc_getNearby [unit, range, max]` (public): every ground pile that holds
  something and every crate (`ReammoBox_F`, empty ones too) within `einv_storage_nearbyRange` (1-5 m,
  default 3, measured flat from the feet), on the same floor and in sight (`fnc_isNear`), nearest first, at
  most `NEARBY_MAX` (10); not vehicles, bodies, living persons, hidden, carried, loaded or locked objects,
  nor `einv_nearby = false` (public) on the object; nothing while seated. `fnc_readNearby` fills
  `GVAR(nearby)` when the window opens, at each contents check and before the window is built for a
  move's answer, only with `einv_gui_showNearby` on and in the inventory. The boxes are sections of the
  loot column after what was opened; the crates among them start folded (a click on the caption opens
  them; `GVAR(collapsed)` keeps the player's change from that start), their Take all works folded, the
  loot column is titled "Nearby" when nothing was opened and the search field tints the tab of a folded
  section with a match. A nested container opened from a nearby pile sits right below it. Dropping to the
  ground is unchanged: the server uses a non-empty server-local pile within 2 m that the player can see.
- **Local by design**: search progress and view state only.
- **Known limits.**
  - A client's connection dropping inside one send batch can lose a payload it took, or settle a put again
    (the hub names it in the RPT). Changes outside this machinery - ACE medical treatment, EFAK's own
    pouch, the engine's scroll-menu actions, ACE Arsenal, scripts - are not serialised with ours. A script
    error in our own code exactly between an engine change and its journal line returns that payload once
    more.
  - A machine that holds a phase and hangs (does not disconnect) holds it until it answers or leaves - the
    hub re-sends every 10 s, the requester's window gives up showing it as pending after 15 s; nothing is
    re-added on a timeout.
  - The vanilla inventory in multiplayer opens only on own gear; a player who wants vanilla for crates must
    use single player.
  - The player's own arrangement reaches others up to 2 s after the player's own moves; moves made in the
    last 2 s before a player quits (not dies) are never broadcast.
  - Places of a holder nobody looked at are only written at the first look (one small write).
  - A client whose rules differ from the server's (already warned by `einv_items_rulesHash`) draws other
    sizes and asks for normalises; the authority re-writes at most every 30 s; fix the settings.
  - Nested containers rely on the same `netId` on every machine.
  - Built and checked in code only: nothing of 0.2.0 or 0.2.1 has run in the game yet.

## Hotbar (2026-10-10) - supersedes the parts above it contradicts

The keys 4 to 0 use what lies on them, Tarkov-style, and **every item on the bar really does something**:
a bandage bandages the part that bleeds most, a tourniquet goes on the worst bleeding limb, a grenade goes
into the hand, a magazine reloads the weapon in the hands, a kit opens. Built in 0.2.1 as the new feature
addon `hotbar` (prefix `einv_hotbar`), designed in `hotbar_design.md` (H1-H16); nothing of it has run in the
game yet.

- **Layout of the addon.** Always loaded, needs only CBA, `ace_common` and our own addons. Everything else -
  ACE medical, advanced throwing, field rations, weaponselect, Enhanced First Aid Kits, `compat_efak` - is
  called behind `isNil` guards, never required. gui calls the hotbar only through `isNil`-guarded
  `EFUNC(hotbar,x)` and only in the inventory (`fnc_isInventoryMode`): `fnc_drawEquipmentCards` (the row
  "HOTBAR" under the gear: `fnc_drawStrip`), `fnc_updateHover` (`fnc_hintParts`), the drag trio
  (`fnc_canBindFrom`, `fnc_bind`; drag target `["hotbar", slot, 0, 0, fits, reason]`), `fnc_contextMenu`
  (`fnc_menuChoices`, `fnc_stripMenu`), `fnc_onKeyDown` (`fnc_onWindowKey`) and `fnc_drawFooter`
  (`fnc_footerHint`). A hotbar slot is an ordinary slot record of `fnc_drawSlot` (new options `count`,
  `faded` and `hotbar`) with the slot's number at element 7 (`>= 0`; -1 for every other slot) and no slot
  id and no unit, so nothing that drags, equips or shows targets for real slots touches it.
- **Slots.** Seven, on 4 5 6 7 8 9 0 (DIK 5-11), CBA keybinds `einv_hotbar_slot1` ... `slot7`, each
  changeable in Configure Addons. A slot is bound to a **class**, not to one item: any carried item of that
  class is used and the bar shows how many there are. A class sits in at most one slot. Kept per player in
  the profile (`einv_hotbar_slots`, saved at every change), so the next mission and a respawn with another
  loadout keep the bar; what is not carried shows as 0, faded.
- **What an item does** (`fnc_useOf [class] -> [kind, data]`, cached per lowercase class), the first that
  applies: `"kit"` (Enhanced First Aid Kits / Utility Pouches, `efak_core_fnc_isKit`; data: the prototype),
  `"throw"` (anything the `Throw` weapon takes on any muzzle), `"consume"` (ACE field rations: a value in
  `acex_field_rations_thirstQuenched` / `hungerSatiated`; data: the chain class -> replacement item -> ...,
  at most four, so a bottle that became half a bottle is still the same key), `"medical"` (an item that
  one of ACE's treatments lists), `"reload"` (a magazine; bindable only when `storage fnc_partFor` puts it
  on a carried weapon), `""` (everything else: refused with "Has no use from the hotbar"). Binding is
  refused too for what is not carried (`fnc_canBindFrom`: the own uniform, vest and backpack, a carried
  kit, the own equipment slots - not a container inside the backpack, not a virtual grid, not the window
  of another unit) and for food and drink while field rations are off.
- **Medical** (`fnc_treatmentIndex`, `fnc_pickTreatment`, `fnc_whyNot`, `fnc_useMedical`). The index is
  read from `ace_medical_treatment_actions` - ACE's actions and those other mods add, Advanced Combat
  Medical's among them: an action counts when `items[]` is not empty, self-treatment is not a plain 0 and
  its condition is not `"false"` (ACM switches ACE's blood, plasma and saline bags off that way, so they
  cannot be bound). The role comes from `callbackSuccess` (bandage, tourniquet), "splint" in the name or
  callback, else "any". The part is picked by role: **bandage** - the part with the largest sum of wound
  amount times bleeding rate in `ace_medical_openWounds` (a part a tourniquet holds shut last);
  **tourniquet** - the worst bleeding arm or leg without one; **splint** - a leg before an arm; **any**
  (morphine, painkillers, epinephrine, IV, ACM's drugs) - a free arm, then a leg, the torso, the head, a
  limb with a tourniquet last. Every candidate must pass ACE's `ace_medical_treatment_fnc_canTreat`
  (allowed part, items at hand - also in a carried kit with EFAK -, medic level, holster rule, the
  treatment's own condition); the first that does is started with `ace_medical_treatment_fnc_treatment` -
  ACE's (or ACM's override's) progress bar, animation, item use and settings, nothing rebuilt. A second
  press goes to the next part. When none passes, `fnc_whyNot` names the reason, in this order: nothing
  bleeding / no limb for a tourniquet, not on oneself, needs medical training, holster or lower the
  weapon, nothing to splint, else "cannot use this on yourself now".
- **Throwing** (`fnc_useThrowable`). With ACE advanced throwing on, the key takes that throwable into the
  hand (`selectThrowable` + `ace_advanced_throwing_fnc_prepare`) and left click throws; another
  throwable's key swaps it while it is not primed (`setAmmo` of the active muzzle back, `selectThrowable`;
  ACE's draw handler changes the model), a primed one is refused, ACE's two seconds between throws are
  respected. With it off, the first press selects the throwable and a second press within 1.5 s throws it
  (`forceWeaponFire`). A throwable in the hand is put away (`exitThrowMode`) before medical, food or a
  reload.
- **Magazines** (`fnc_useMagazine`) reload the weapon in the hands with the fullest magazine of the class
  that is not loaded, `action ["LoadMagazine", unit, unit, creator, id, weapon, muzzle]` (the engine's
  reload with its animation); a round for the grenade launcher goes into the launcher's muzzle; one that
  does not fit the weapon in the hands is refused. **Food and drink** call
  `ace_field_rations_fnc_consumeItem`. **Kits** open the window on the own gear with the kit as a window
  inside it (`einv_gui_fnc_open`, then `einv_compat_efak_fnc_open`) when the replacement is on and
  `compat_efak` is loaded, else `efak_core_fnc_openKit`.
- **Keys** (`fnc_onKey`, a frame later `fnc_use`). The key is left to Arma and ACE (the handler reports
  false) when the slot is empty, while a command menu is open (`commandingMenu`, so 0-0-1 for the radio
  works), in Zeus or a feature camera, and - setting `einv_hotbar_leaderKeys`, on by default - while the
  player leads AI. Otherwise it is taken (true: Arma's command menu does not open on it; another mod's
  keybind on the same key still runs, CBA runs every handler of a key). Dead, unconscious or not local:
  taken, nothing done. ACE's progress bar up: "Busy". A second press within 0.4 s is ignored. The use
  runs a frame later, so ACE's own grenade keys (6, 7 and 0 by default) have selected their grenade by
  then and the slot's wins, and ACE's progress bar (which closes and opens a dialog) is not started inside
  a key handler. CBA keybinds do not run in a dialog, so the window asks `fnc_onWindowKey` itself: over a
  tile or an own equipment slot a slot's key binds the item, over a hotbar slot it swaps the two, Delete
  over a hotbar slot empties it.
- **Shared keys** (`fnc_checkKeys`, once, five seconds after the settings are in). Names every other CBA
  keybind (`cba_keybinding_actions`) with the same key and modifiers, and Arma's command menus (1 to 0, no
  modifier), in a chat line - once per profile: `einv_hotbar_keysNoticed` holds what the last notice said,
  a different list says it again. The hotbar changes nobody else's keys.
- **Binding** (`fnc_bind [index, class, from = [], checked = false] -> BOOL`, public, with `fnc_unbind`,
  `fnc_useOf` and `fnc_use`). Drag a tile or a slot onto a hotbar slot - nothing moves, the tile flies
  back -, point at an item and press a slot's key, or right click "Put on the hotbar (5)" / "Take off the
  hotbar (5)"; a hotbar slot's right click has "Clear hotbar 5". `checked` skips the carried check when the
  drag has asked `fnc_canBindFrom` already. With the replacement off, the same two rows are in CBA's item
  context menu (not shown while our window is open, which shows the options of the same menu itself).
- **The bar on the screen** (`RscTitles >> einv_hotbar_RscHud`, `cutRsc` on the layer `einv_hotbar_hud`).
  Bottom centre, movable in Arma's layout editor (`CfgUIGrids` entry `einv_hotbar_grid`; the position is
  read from `IGUI_einv_hotbar_grid_X` / `_Y`), in the player's interface colours (`IGUI_BCG_RGB_*`,
  `IGUI_TEXT_RGB_*`, `IGUI_WARNING_RGB_*`, `IGUI_ERROR_RGB_*`). Seven boxes (key, picture, count, a thin
  bar) and a line for messages. `fnc_hudPing` starts a per-frame handler (`fnc_hudFrame`) that makes the
  display on demand (`fnc_hudCreate`), fades it in and out, reads the counts and keys every 0.25 s and
  paints again (`fnc_hudDraw`) when they changed, and each frame mirrors ACE's progress bar on the slot in
  use, counts down a throwable's two seconds, lights the box of the slot in use or of the bound grenade in
  the hand, lights a refused press red for 0.6 s and shows the line for 2.5 s. `fnc_hudWanted`: hidden in
  dialogs (ACE's progress bar excepted), in Zeus and feature cameras, when unconscious or dead, with the
  HUD off and in the map; then the setting `einv_hotbar_hudMode` decides - never, while in use (4 s after a
  key, while an item is used, while a bound grenade is in the hand) or always. With "never" a refusal is
  ACE's hint. The controls live in uiNamespace (`einv_hotbar_hud`, `einv_hotbar_hudCtrls`), never in the
  mission namespace.
- **Settings** (topic "Hotbar"): `einv_hotbar_hudTime` (each player, 1-15 s, default 4),
  `einv_hotbar_enabled` (everyone, on), `einv_hotbar_leaderKeys` (each player, on), `einv_hotbar_hudMode`
  (each player, a list). Off, the row, the bar and the keys are gone and 4 to 0 do what they did before.
- **Multiplayer.** Nothing goes over the network from the hotbar: it runs on the player's own, local unit
  through ACE and engine commands that are global in effect, writes no layout (an item ACE or the engine
  took out of the uniform, vest or backpack drops out of the stored layout at the next reconcile, a
  magazine the reload put back is placed first-fit, like any change made outside the window) and touches no
  container the server serialises. A dedicated server or headless client leaves postInit at
  `hasInterface`.
- **Known limits.** ACE picks which single item a treatment uses (carried before kit, uniform before vest
  before backpack, a vehicle's cargo first in a seat). ACE binds 6, 7 and 0 and Arma's command menus use 1
  to 0: a bound slot shares its key until one of the two is moved (the notice says which). A slot holds a
  class: two magazines of one class are told apart only by their rounds (the fullest goes in). The reload
  needs the magazine's id and creator from `magazinesAmmoFull` (entries 5 and 6); a game that does not give
  them refuses the reload and writes a warning to the RPT. The bar counts what is carried; it does not tell
  in advance whether a treatment will be possible - a refused press says why. Remote-controlled units
  (Zeus) use the bar only when the unit is local to the controlling machine.


## Window engine for other displays (0.2.2) - supersedes the parts above it contradicts

The window of the gui addon is no longer tied to the inventory's dialog. Any display that carries the dim layer
(`IDC_DIM` 9601) and the first control (`IDC_FIRST` 9602) becomes **the window** through `einv_gui_fnc_attach`, and
what makes it different from the inventory goes through a **table of hooks**. The Enhanced Arsenal (addon
`arsenal`, display `EINV_ArsenalDisplay`, IDD 9610) is the first user; the editors of Zeus and Eden are meant to
be the next. Designed in `arsenal_design.md` 2.4; the Arsenal itself is built in 0.3.0 - in 0.2.2 its addon is the
skeleton (every function a stub with its final header) and its hand-over from ACE's display says no, so ACE's own
window opens as it always did and the vanilla Virtual Arsenal opens vanilla.

**The rule that keeps the inventory safe: with an empty hook table every function of the gui addon behaves exactly
as before.** `einv_gui_fnc_isInventoryMode` is true then, and every inventory-only feature asks it (nearby boxes,
selecting, the band, group drags, Take all / Put all in, the hotbar). A hook may only be asked through
`einv_gui_fnc_hook`, never read out of the table directly.

- **Attaching.** `fnc_attach [display, unit, container, secondary, hooks = createHashMap, driver = "pfh"] -> BOOL`
  does everything `fnc_open` did once the dialog existed: it refuses (false) when another display is the window
  already - there is one session at a time, the display is `uiNamespace einv_gui_display` -, sets the unit and the
  containers the window looks into, `GVAR(hooks)`, starts every piece of window state afresh (search, filter,
  inspect card, kit windows, moves under way, answers, drift, selection, band, drag group), adds the display's
  MouseButtonDown / MouseButtonUp / MouseZChanged handlers, reads what lies around (inventory mode only), builds
  once and starts the frame. `fnc_open` is now: make the dialog, note the living person looked into, attach with no
  hooks, show the hint of the opening. `fnc_onUnload` stops the frame, empties the hooks and the zones - the next
  window is the inventory again.
- **Frame drivers.** `fnc_startFrame [driver]` / `fnc_stopFrame []`, kept as `GVAR(frameDriver) = [driver, id]`
  (replaces `framePFH`). `"pfh"` is a CBA per-frame handler, the inventory's. `"draw3d"` is a Draw3D mission event
  handler: CBA's per-frame handlers and `CBA_fnc_execNextFrame` never run in the Eden editor, Draw3D does. Either
  calls `fnc_onFrame` with no arguments; its "display gone" exit and `fnc_onUnload` end whichever runs.
- **Deferral.** `einv_gui_fnc_later [code, args]` (already there since 0.2.1, `einv_storage_fnc_nextFrame`) is what
  everything that must run after the current event uses - `fnc_openMenu` now too, whose rows did call CBA directly.
  Scroll positions put back after a build need no change: `fnc_build` records them and `fnc_onFrame` restores them a
  frame later, which works under either driver.
- **`fnc_hook [name, args = [], default = nil] -> ANY`.** The hook is absent: the default. It is not code (a flag):
  its value. It is code: `args call it`, and its answer unless that is nil, then the default.
- **`fnc_showHint [text, colourKey = "text2"]`.** The footer's hint in one of the theme's colours; `fnc_flashHint`
  stays the loss-coloured reason. The next hover replaces either.
- **Kept control.** A top-level control with `IDC_KEEP` (9603) and everything in it survives the build's sweep. A
  window that keeps a large control set across builds (the Arsenal's catalog column) puts it there. The build adds
  the mouse handlers to a controls group only once (the group's `einv_gui_hooked`), so a kept group does not collect
  them, and `dragScroll` of a hook window holds every scrolling group of the display, not only the columns this
  build made.

### The hook table

All hooks are optional. "Asked in" names the function; the argument lists are the contract.

| Hook | Arguments | Answer | Asked in |
|---|---|---|---|
| `theme` | `[theme]` | nothing - edits the theme | `fnc_build`, after the theme is made |
| `context` | `[context]` | nothing - edits what the window shows (`ownSections`, `storageSections`, `cameraOn`, ...) | `fnc_build` |
| `layout` | `[display, theme, context]` | where the soldier stands, `[x, y, w, h]` or `[]` - replaces the look's layout | `fnc_build` |
| `header` | `[display, theme]` | nothing - replaces `fnc_drawHeader` | `fnc_build` |
| `camera` | `[rect]` | nothing - with it the gui's own camera is never started or stopped | `fnc_build`, last of the camera part |
| `afterBuild` | `[display]` | nothing | `fnc_build`, the very last line |
| `footerKeys` | `[]` | `[[key, text], ...]` - replaces the footer's key hints | `fnc_drawFooter` |
| `keepOpen` | `[]` | BOOL - replaces the inventory's must-close rules (they read `ACE_player`, wrong in Eden and Zeus) | `fnc_onFrame` |
| `frame` | `[display, mouse, now]` | nothing - every frame, also while dragging, not while another window covers this one | `fnc_onFrame` |
| `focusAll` | a flag | true: every control with the focus but a field goes back to the sink, while no mouse button is held | `fnc_onFrame` |
| `wheel` | `[scroll, mouse]` | BOOL - only while nothing is dragged, once per turn | `fnc_onMouseZ` |
| `mouseDown` | `[button, mouse, shift, ctrl, alt]` | BOOL, true = taken - after the inspect card and menu checks, before the right click | `fnc_onMouseButton` |
| `mouseUp` | `[button, mouse]` | BOOL, true = taken | `fnc_onMouseButton` |
| `click` | `[kind "single"/"double", target, shift, ctrl, alt]` | BOOL, true = handled - a click that did not become a drag, before the inventory's own handling | `fnc_onMouseButton` |
| `key` | `[display, key, shift, ctrl, alt]` | BOOL, true = handled - after the hotbar and selection keys, before Delete and the Gear key | `fnc_onKeyDown` |
| `submit` | `[edit]` | nothing - Return in any field, the cursor is back at the sink | `fnc_onKeyDown` |
| `dragCheck` | `[dragTarget, entry, sourceGrid, slotSource]` | the target as it is to stand (another kind, fits or reason), `[]` for none, nil to leave it - last of everything | `fnc_updateDrag` |
| `drop` | `[kind, sourceIndex, tileIndex, slotSource, entry, count, targetIndex, col, row, w, h, targetSlot, place]` | BOOL, true = handled - after the `!fits` exit | `fnc_endDrag` |
| `ground` | `[source, count]` | BOOL, true = handled - `source` is `[unit, slot]` or `[grid index, tile index]`, count -1 for all | `fnc_quickUnequip`, `fnc_dropToGround`, `fnc_quickMove`, right before each falls back to the ground |
| `menu` | `[display]` | choices - replace the default, `[]` = no menu, nil = the default | `fnc_contextMenu`, first |
| `filter` | `[]` | nothing - after the tiles were faded for the search | `fnc_applyFilter` |
| `tileBadge` | `[class]` | a texture or `""` - a mark `SQUARE(UNIT * 0.42)` in the top left corner | `fnc_createTile`, `fnc_drawSlot` (filled slots) |
| `hint` | `[kind "tile"/"slot"/"none", class, tile or slot record]` | parts `[[text, colourKey], ...]` written after the gui's own; for "none" the whole idle hint | `fnc_updateHover` |
| `inspectRows` | `[class, count, ammo, attachments]` | rows `[label, text]` or `[label, fraction 0..1, text]` (a small bar) before the Mod row | `fnc_drawInspect` |

- **The click target** (`click`, kept with the press as element 8 of `GVAR(press)` while a window listens): a
  HashMap with `type` (`"tile"`, `"slot"`, `"cell"`, `"none"`), `grid`, `tile` (-1 unless a tile), `cell` `[col, row]`,
  `slot` (an index into the slots, only for `"slot"`) and `source` (the grid's `"source"`, or `""`). A window that
  listens also gets presses on empty slots, on free cells of non-virtual grids and on nothing (tile -1; nothing is
  lifted from them - `fnc_startDrag` ignores them) and counts a Shift double click as a double click.
- **Typing.** Any focused edit keeps its keys, not only the search field: Escape empties the search field (and, empty,
  closes as ever) or leaves another field, Return leaves the field and calls `submit`. A click beside any focused edit
  gives the focus to the sink. `fnc_drawFilter` takes a fourth argument, the placeholder text.
- **Where the hooks sit.** `fnc_onKeyDown`: Escape closes the menu, then the inspect card, then the topmost kit window
  - R while dragging - a focused field keeps its keys (`submit`) - the hotbar's and the selection's keys (inventory
  only) - the `key` hook - Delete and the Gear key. `fnc_onMouseButton`: the inspect card's and the menu's checks -
  `mouseDown` / `mouseUp` - kit windows - the right click - the press; on release without a drag the `click` hook
  comes before the double click, Ctrl, Alt and selection handling. `fnc_onFrame`: display gone - covered - the focus
  rule - the moving of the inspect card and kit windows - the press that becomes a drag - the `frame` hook - the
  drag, the band, the hover.

### Source grids and zones

- **Source grid.** A grid HashMap with `"source"` (a STRING, e.g. `"catalog"`) is a place things come from and never a
  target: it is `virtual` (so `fnc_updateDrag` never targets it), has no container, is never faded by the search and
  never searched. A tile may carry `"dragEntry"` (the entry that is dragged - class, `w`, `h`, `count` = how many may
  go at once, `ammo`, `capacity`, `attachments`, `controls` = the controls that fade and come back), `"dragStart"`
  (the first count, 1; Shift takes the whole stack), `"grab"` (`[col, row]` within the true size, where the item is
  held) and `"size"` (`[w, h]` for the hint). A press on such a tile is a press like one on a container's tile, and
  the drag is **always ended by the `drop` hook**: whatever it answers, `fnc_endDrag` then only cleans up and never
  runs a move of its own - there is no container behind the tile to move from. The kit-tile branch of
  `fnc_updateDrag` is skipped for it (a kit tile under it is a taken cell); the room check against another
  container's grid is the existing "another container" one.
- **Zones.** `uiNamespace einv_gui_zones` = `[[rect, id], ...]`, emptied by every build and filled by whoever draws the
  area. Over a zone (and no slot or grid) `fnc_updateDrag` sets the target `["zone", index, 0, 0, true, ""]` and the
  footprint covers the zone's rectangle at half `DRAG_FOOTPRINT_ALPHA`. A zone is only ever acted on through the
  `drop` hook; gui itself does nothing for one. The `dragCheck` hook may turn the ground into a zone or into nothing.
- **Drag target kinds** gain `"zone"`: `["zone", zoneIndex, 0, 0, true, ""]`.

### Layout, sections, sounds

- **`fnc_layoutGlass`** reads optional context keys: `rightColumn` BOOL (reserve the loot column's place though nothing
  is looted, without drawing it), `rightKeep` NUMBER (UNITs) and `rightGrow` NUMBER (a fraction of a column) - the
  reserved column grows by what the middle would have beyond `SQUARE(UNIT * rightKeep)`, at most `rightGrow` of a
  column (the Arsenal: 18 and 0.75, so a 21:9 screen gets a catalog of about 830 px and leaves the soldier 527 px,
  16:9 stays at one column) -, and writes the reserved rectangle back as `rightRect` (not into `GVAR(panels)`: its
  owner pushes it). The storage column draws `storageSections` when present, else `ownSections`.
- **Placeholder sections** (a uniform, vest or backpack the unit has not) may carry `"owner"` (the unit): their box is
  then that unit's slot of the section's id, so a click or a drop on it puts one on.
- **`fnc_updateHover`** shows `tile "size"` where present instead of the tile's own cells. **`fnc_playSound`** knows
  `"giveBack"`: the same rustle, pitch 0.82, volume 0.5. **`fnc_startDrag`** from a source grid lifts `dragEntry`, one
  at a time (`dragStart`), and does not look for living persons' rules.
- **Textures.** The gui addon's `ui/` gained 16 stroke icons: `icon_arsenal_ca`, `icon_loadouts_ca`, `icon_star_ca`,
  `icon_star_outline_ca`, `icon_unique_ca`, `icon_eye_ca`, `icon_eye_off_ca`, `icon_vision_ca`, `icon_import_ca`,
  `icon_export_ca`, `icon_share_ca`, `icon_giveback_ca`, `icon_blocked_ca` for the Arsenal and `icon_lock_ca`,
  `icon_lock_open_ca`, `icon_unload_ca` for the locks - drawn by `tools/generate_ui_textures.py` like the others.

### Storage side

`storage` gained what the Arsenal needs to make things rather than move them, all on the player's own, local
containers: `fnc_makePayload [class, count = 1, rounds = -1]` (the payload shapes of `fnc_removeEntry`: a magazine full,
a weapon bare, a backpack with an empty snapshot, anything else an item), `fnc_addNew [container, class, count = 1, cell
= []] -> "" / "TooHeavy" / "NoRoom" / "Failed"` (room by weight, a free spot on the grid when no cell is given - always,
also without the grid-only setting -, counted before and after, the place written with `fnc_setPlace` outside any
phase) and `fnc_countClass [container, class]`.

CBA's loadouts carry the arrangement: `fnc_onLoadoutGet` (event `CBA_loadoutGet`) writes
`einv_layout = [1, [uniformRecords, vestRecords, backpackRecords]]` into the extended info - the records of
`fnc_readPlaces` with the key cut down to `fnc_layoutKey` of its class - and `fnc_onLoadoutSet` (`CBA_loadoutSet`)
writes them back with `fnc_writePlaces` where the unit is local, else sends them to its machine
(`einv_storage_loadoutPlaces`, `fnc_onLoadoutPlaces`). A record the new items do not match drops out at the next
layout; a loadout without the key leaves everything to the first fit. Both handlers are registered in preInit on
every machine.

## Locks (0.2.2) - supersedes the parts above it contradicts

A crate or a vehicle can be locked to one side, one group or the admins, and ACE's vehicle lock is respected.
Built in 0.2.2 as the backbone (addons `locks`, `compat_ace_vehiclelock`, `compat_zen`): the record, the engine
lock per client, the guard on every op, Eden, Zeus and the ACE vehicle lock. The window's own gates (a locked
section instead of the box, the hint on a refused move, the gate in `fnc_onInventoryOpened`) came with
0.3.3: `einv_locks_fnc_decorate` is called by `einv_gui_fnc_build`.

- **The lock record.** `einv_locks_lock = [mode, who]` on the object, public: `["side", west]`,
  `["group", <GROUP>]`, `["group", "Alpha 1-1"]` (a callsign, matched by name), `["admins", ""]`; nil when not
  locked. Written only by `einv_locks_fnc_setLock [object, mode = "", who = ""] -> BOOL` (public; `""` opens it
  again). Only crates, vehicles and other non-unit objects: people are refused with an error in the RPT (their
  gear has `einv_noAccess` and the window's settings for persons). `fnc_getLock [object] -> [mode, who]`
  (public, `["", ""]` for none) reads it, `fnc_describe [lock] -> STRING` says it ("BLUFOR only", "group Alpha 1-1
  only", "a disbanded group only", "admins only").
- **One writer.** `fnc_setLock` called anywhere sends a client's request as the server event `einv_locks_set`;
  the server writes the public record, rewrites the list `einv_locks_objects` (missionNamespace, public, written
  only by the server - never assigned in a preInit, because a joining client may already hold the server's
  value) and raises the CBA global event `einv_locks_changed [object]` after the list went out (same sender,
  in order). An object that is deleted leaves the list (`Deleted` handler on the server). Joining players
  receive the record and the list with the mission's variables and call `fnc_refreshAll` in postInit. The
  server event takes the same trust as any CBA event: a script on a client can ask for a lock to change.
- **Who passes** (`fnc_isAllowed [unit, lock] -> [allowed, how]`): members (the side of the unit's *group* -
  ACE's handcuffed captives are civilians to the engine -, the unit's group, or the callsign of its group),
  logged-in admins always (`fnc_isAdmin`: on the player's own machine the hosting player or whoever has
  `serverCommandAvailable "#shutdown"`, which a voted admin lacks; on the server about someone else
  `admin owner == 2`; a client cannot tell about another client), and Zeus while `einv_locks_zeusOpens` is on
  (a curator logic assigned to the unit, or to the unit that remote controls it). Single player has no admin:
  locks work as for any player, which is how a mission maker tests them.
- **The engine lock, per client** (`fnc_refresh [object]`, `fnc_refreshAll`). `lockInventory` is global in
  argument but local in effect, so each client runs `lockInventory true` *on its own machine* on every locked
  object its player may not open and `false` again when the player may - only ever undoing the lock this machine
  set (`einv_locks_engineMine` on the object, local); a lock the mission set (`lockedInventory` already true)
  is never lifted and never taken over. Re-evaluated on every `einv_locks_changed` and every `LOCK_RECHECK` (1 s;
  side, group, admin login, Zeus and respawn have no event). The inventory key, the scroll action and any
  script or mod that asks the engine to open the object stop at it. `einv_locks_allowedHere` (local on the
  object) remembers the last answer; a change counts `einv_locks_stamp` up (part of the window's signature later)
  and closes the vanilla inventory (display 602, window switched off) of a player within `VANILLA_CLOSE_DISTANCE`.
  `getNearby` already leaves out `lockedInventory` objects, so a crate locked to the player never appears as a
  nearby box.
- **What is asked** (`fnc_canReach [unit, container, root = objNull] -> [ok, reason, tip]`, public) - the one
  question every gate asks. The lock that counts is the container's own, the locked object it is attached to (ACE
  cargo hangs a crate under its vehicle) or lies in up to `MAX_DEPTH` containers deep (`fnc_lockHolder`: a
  backpack in a locked crate), or - when the caller knows it - that of `root`, the top of the chain a backpack
  was opened from. Then a lock the mission set with `lockInventory` on this machine (asked only for `ACE_player`
  and never for a person: "Locked by the mission"), then the providers. The tip ("Locked: BLUFOR only - you may
  open it" / "...as an admin" / "...as Zeus") is for the window's open padlock.
- **Providers** (`fnc_addProvider [code]`, public): other mods' locks, `[unit, container] -> refusal text or ""`,
  asked about the container at the top of the chain on every machine; they must read only what is the same
  everywhere, because the guard asks them where the op runs. `compat_ace_vehiclelock` adds ACE's rule
  (`fnc_check`): `ace_vehiclelock_LockVehicleInventory` on, the player on foot, a Car, Tank or Helicopter,
  `locked` 2 or 3, and no key by `ace_vehiclelock_fnc_hasKeyForVehicle` (master key, side key, custom keys).
  ACE blocks only the vanilla display 602, which this window never opens - without the provider ACE's lock
  would be bypassed. "Locked - you have no key for it".
- **The guard** (`fnc_guard [op, args, requester, root] -> "" or "Locked"`, pushed onto `einv_storage_guards`
  in preInit as a wrapper, next to `einv_gui_fnc_personGuard`). Runs on the machine that runs the op - the
  root's authority - for every op, whoever sent it and whatever the window showed: a lock set a moment ago, a
  script, a client without this window. It asks `fnc_canReach` for the holders the op names (`move`: both;
  `place`, `placeMany`, `sort`, `normalize`, `take`, `put`: the first) and for the phase's root, each with its own
  root (`einv_storage_fnc_rootOf`; two crates of one move share an authority, not a root) - so also a backpack
  opened inside a locked crate or an ACE-locked vehicle, and a kit (a STRING holder is left to the root; compat's
  ops count through it). `takeOff`, `putOn` and `putGround` name no holder; a root that is a unit (own gear,
  bodies) is never locked. Settlement phases skip guards (the system puts things back) and so does a request
  with no requester (a mission script). A refused op answers `"Locked"`, and what it would have consumed is
  settled by the transaction machinery - back where it came from, else the ground - so nothing is lost or
  doubled. Every input is global (the record, group and side, `admin owner` on the server, curator, ACE's lock
  and keys), which is what makes a lock the same on every machine.
- **Eden** (`locks/Cfg3DEN.hpp`, category "Enhanced Inventory", on crates and vehicles with cargo, not on
  units): "Inventory locked to" (Everyone, BLUFOR, OPFOR, Independent, Civilian, One group, Admins only) and
  "Group callsign". The expressions run in the mission, not in the editor (`!is3DEN`), keep the values on the
  object (`einv_locks_edenMode`, `einv_locks_edenGroup`) and queue it (`einv_locks_edenQueue`, created by
  whichever of the expression and the preInit runs first); `fnc_applyEden` (server postInit, before the
  hosting player's handlers exist - `fnc_refreshAll` covers that) makes the locks once every object has its
  own. A callsign found among the groups becomes that GROUP (the lock follows renames); one not found is matched
  by name from then on, with a warning in the RPT; "One group" without a callsign locks to the admins (fail
  closed), with a warning. A callsign two groups share belongs to the first group found.
- **Zeus** (`compat_zen`): the right-click menu "Inventory lock" on crates and vehicles (Not locked, one choice
  per side, Admins only, One group... - a ZEN dialog listing the groups with a living member, sorted by side
  and callsign) and the module "Lock inventory" (two combos preselected from the current lock). The target is
  the entity under the mouse if it is lockable, else the selected lockable objects (`fnc_targets`: not a person,
  `maxLoad > 0`); the lock goes through `fnc_setLock`, i.e. to the server, and the game master gets Zeus's own
  feedback line. Vanilla Zeus has no module of ours.
- **In the window** (`fnc_decorate [unit, sections, opened = []] -> sections`, called from `fnc_build` right
  after the loot sections are read): a `container` or `ground` section whose container the unit may not reach
  (also a backpack opened from inside a locked crate, found through the `opened` list's parent chain) loses
  `container`, `holder`, `root` and `entries` and gets `locked`, `notice` (why) and `lockedObject`;
  `fnc_drawSection` draws it as a caption with a padlock where the chevron would be (the notice as the
  padlock's tooltip) and one muted line "Locked: BLUFOR only" - no box, no grid, no tiles, so nothing can be
  seen, lifted, dropped onto, sorted, searched, selected or taken from there, and it has no Take all button.
  A container opened from inside one that is locked now loses its section, and `GVAR(opened)` lets go of it.
  A lock the unit passes adds `lockTip`: an open padlock before the load text, its tooltip "Locked: BLUFOR only
  - you may open it" (as an admin, as Zeus). A locked section counts as looting, so the loot column shows it.
  Nearby boxes never show a crate locked to the player (`getNearby` leaves out `lockedInventory`, which the
  engine lock sets), the crates the player passes are listed and carry the open padlock.
- **Settings** (topic "Locks"): `einv_locks_zeusOpens` (everyone, on).
- **Gates** (what stops what):

  | Gate | Where | Check |
  |---|---|---|
  | Engine lock | every client, `fnc_refresh` | `lockInventory true` on objects the player may not open |
  | `fnc_onInventoryOpened` | client | `fnc_canReach` for the container and the second container, before the `replaceVanilla` exit: ACE's click; window switched off: the vanilla inventory on own gear (`fnc_openVanilla [unit, objNull]`); window on: it opens and shows the locked section |
  | `fnc_openVanilla` | client | a container locked to the player is left out - the vanilla inventory opens on own gear |
  | Window build | client, `fnc_decorate` | locked sections |
  | `fnc_sendMoves` | client, before the phases are built | a move whose `from` or `to` is an object holder that `fnc_canReach` refuses (with the move's `fromRoot` / `toRoot`, own gear, people, the ground and kits are left out of the question) is left out, the hint "Locked" unless something else is the first reason; none left: nothing is sent. Catches a lock set a moment ago, before the next build |
  | `fnc_quickMove` | client | from own gear, when no loot container is left as a target but a section of the loot column is locked, the ground is no fallback: the hint "Locked" |
  | `fnc_flashHint` | client | `"Locked"` -> `STR_einv_locks_Hint_Locked` |
  | Every transaction op | the machine that runs it | `fnc_guard` in `einv_storage_guards` |
- The signature gains the lock stamp (`einv_locks_stamp`, counted up on every change seen on this machine) and
  the `locked` state of the two containers the window was opened on (ACE lockpicking or a key changing
  `locked` while the window is open), both in its `list` part.
- **Known limits.**
  - The engine's own "Rearm" scroll action on an ammo crate may not respect `lockInventory`. The gate test G4
    that would tell was never run, so the code does what is safe either way - the engine lock is set, the
    guard covers our own paths - and does not try to hide the action (that would take over
    `inGameUISetEventHandler`, which ACE and others own). Test point: look at a locked `Box_NATO_Ammo_F` and
    check the scroll menu; note the result here.
  - A raw `setVariable ["einv_locks_lock", ...]` works in the guard and the window but sets no engine lock and
    is not in the list for joining players: always use `einv_locks_fnc_setLock`.
  - An admin moving things in a *driven* vehicle locked to admins is refused: the guard runs at the driver's
    machine, which cannot tell whether another client logged in. Crates, piles and empty vehicles are
    server-local, where it works.
  - Settlement puts skip guards by design: an item can go back into a container that was locked meanwhile -
    it came from there.
  - ACE vehicle lock's own handler waits for a vanilla display 602 our window never opens; should the player
    later open the vanilla inventory in the same session, ACE closes it once and reopens it on own gear.
  - Built and checked in code only: nothing of the locks has run in the game yet.

## In-game findings of 0.2.3 (0.2.4) - supersedes the parts above it contradicts

Mia tested 0.2.3 in the game. What changed for each finding:

- **Searching flickered** (a vehicle's hold being uncovered). Every item found built the whole window:
  every control made anew, the columns at the top for a frame until their scroll came back a frame later,
  the camera started again - once per item, for a hold full of loot dozens of times. Now
  `fnc_animateSearch` hands the found item to **`fnc_revealTile [display, item]`**: its tile is drawn anew
  in place (same index in its grid's tiles, so press and hover stay valid), the item leaves the queue and
  `fnc_showSearch` puts the glass on the next one. `fnc_showSearch` keeps all three of its controls in the
  6th element of `QGVAR(searchFx)` and deletes the last ones first. Only the first find of a section
  whose Take all / Put all in button is still missing builds the window (that line is the section's).
  `fnc_redrawTiles` no longer refuses the section being searched. Hidden tiles get a faint outline
  (`line` alpha x 1.8) in looks without tile borders, so "?" tiles of different sizes read as tiles, not
  as "?"s strewn over a field.
- **A dropped backpack vanished.** A backpack lying in a pile is an object of its own with a shape, at
  the pile's position; `einv_storage_fnc_isNear`'s line of sight from the eyes hit it and called the pile
  out of sight, so with the nearby boxes on (the default) the pile never showed - and the server never
  reused it for the next drop. `fnc_isNear` now ignores hits on what lies in the object (`everyContainer`)
  and on its own parts (up to 8 hits looked at). As a safety net `fnc_afterAction` reads what lies around
  first and makes a pile the answer names the looked-into container (`_fnc_adopt`) whenever it is not
  among the nearby boxes - also with them on: what was dropped always shows.
- **A body's doll has a backpack slot.** `fnc_drawEquipmentDoll`: EARPIECE | HEADWEAR | FACE COVER,
  UNIFORM | BODY ARMOR | BACKPACK, ON SLING | HOLSTER, ON BACK | BINOCULAR, and five small slots EYEWEAR |
  MAP | GPS | COMPASS | WATCH. The backpack slot is a slot like the others (record with `slot` and the
  body as `unit`): take off, drag, exchange.
- **The ground: double click puts on, Ctrl+click opens** (Mia's rule, inventory only, on a pile's grid,
  `fnc_onMouseButton`): a double click on a searched tile that `einv_storage_fnc_slotFor` gives a whole
  slot (no `_` in its id: uniform, vest, backpack, headgear, goggles, NVG, binocular, a weapon, the
  assigned items) puts it on (`fnc_quickEquip`; the old item goes onto the pile where the new one lay);
  magazines and attachments, kits and the rest keep the double click as before. Ctrl+click on a uniform,
  vest or backpack lying there opens it (`fnc_openNested`); anything else is selected as everywhere. The
  hint names both on such a tile ("Double click: put on", "Ctrl+click: open", in the accent colour); the
  footer's keys stay the general ones. Crates, vehicles, bodies and own gear are unchanged (Ctrl+click
  selects, double click opens or moves over).
- **Equip by dropping anywhere on the equipment column.** `fnc_layoutGlass` keeps the column's rect in
  `GVAR(equipmentRect)` (reset in `fnc_build`, `[]` for a window that draws its own layout). In
  `fnc_updateDrag`, a single tile over that column - not over a slot that takes it - targets the slot
  `slotFor` names: `["slot", record index or -1, 0, 0, fits, reason, slot id, true, unit]`, the footprint
  on that slot's card where the column shows one, else faintly over the whole column (the backpack's box
  is in the storage column, and only while one is worn); a slot that does not take it is no longer the
  target there. `fnc_endDrag` sends it through `fnc_doEquip` as before. Inventory only; a group never.
- **Exchanging worn gear with bodies (and persons).** A worn item dragged off a slot - the player's own or
  a body's - onto the same slot of the other (a doll slot, a section's uniform / vest / backpack box), or a
  body's anywhere over the player's equipment column, is exchanged: **`fnc_canSwap [[unit, slot], toUnit,
  toSlot]`** -> `""` or a reason (same slot id, one in `SWAP_SLOTS` - headgear, goggles, NVG, uniform,
  vest, backpack, map, GPS, radio, compass, watch, never a weapon; the player is one of the two; each
  takes the other's item, `slotAccepts`; `fnc_checkTouch "worn"` on both), and **`fnc_doSwap`** sends the
  new move kind **`"swap"`** of `fnc_sendMoves` (`unit`, `slot`, `toUnit`, `toSlot`): `takeOff` at the
  first unit's root, `putOn` at the other's (which takes off and hands back what was there), and - only
  when something was there - `putOn` of that at the first unit's root. Three phases, every change at its
  root's machine, contents and places travel in the payloads. An item that does not go on came off a
  slot: settlement puts it into the requester's vehicle or onto the ground - never lost, never doubled.
  `fnc_showTargets` takes the slot source as a third argument and lights up the slots a worn item may be
  exchanged with; the drag target names the unit as its 9th element.
- **Big crates and vehicles: far less scrolling, nothing hidden.** The grid stays STORAGE_COLS wide (the
  arrangement is synced and laid out the same on every machine, so a wider view grid would mean other
  places for everybody). Instead **`fnc_viewBlocks [layout, holder]`** -> `[blocks, hidden rows, foldable,
  hidden cells]` shows a tall compartment down to its last row in use (and the rows moves under way go
  to) plus `COLLAPSE_SPARE_ROWS` (2), at least `COLLAPSE_MIN_ROWS` (4), and only folds when that hides
  `COLLAPSE_HIDE_MIN` (4) rows or more. `fnc_drawSection` draws with those blocks (a shallow copy of the
  layout, view only) and adds one line under the grid, "+32 empty rows (256 cells)", that opens them, and,
  opened, "Fold the empty rows away" (`fnc_toggleRows [holder]`, kept in `GVAR(expanded)` for the mission,
  like `GVAR(collapsed)`). The caption's load still counts the whole container; Take all, quick moves and
  group packing place by the whole compartments and the column grows with what lands. The section info
  notes `foldable`; `fnc_redrawTiles` builds instead when the view's rows or the line would change. Kit
  windows and the unit's own storage column (where the player arranges what he carries) are not folded.
- Not done here: TFAR "open radio" (a later wave).

## Enhanced Arsenal (0.3.0, polish 0.3.1) - supersedes the parts above it contradicts

Removed in 0.4.0 - see 'ACE Arsenal panel'.

ACE Arsenal's boxes open in the inventory's own window: the soldier's slots and grids on the left and in the
middle, a catalog where the loot column would be, and everything that enters the soldier obeys the grid. Designed
in `arsenal_design.md` (the decisions below are its D1-D17), built on the window engine of the section before
("Window engine for other displays", the gui contract: `fnc_attach`, the frame drivers, `fnc_later`, the hook
table, source grids, zones, `IDC_KEEP`), with the storage functions listed there under "Storage side".

### Decisions

| # | Decision |
|---|---|
| D1 | The Arsenal is a display of its own, `EINV_ArsenalDisplay` (IDD 9610), made the window by `einv_gui_fnc_attach` with the hook table of `fnc_hooks` and the `"draw3d"` frame driver. gui never names the arsenal; with no hooks the inventory is unchanged. |
| D2 | Layout `| equipment | 3D soldier | storage | catalog |`: the catalog takes the loot column's place (`rightColumn`, `rightGrow` 0.75, `rightKeep` 18). |
| D3 | The catalog is a pool of uniform cards in a scrolling group, rebound on scroll (`fnc_bindCatalog`); a card is a tile of a source grid, so hover, hint, inspect and drag are gui's; the ghost has the item's true grid size. |
| D4 | Six groups (Weapons, Parts, Ammo, Gear, Items, Identity) and chips for their categories; ACE's custom right-panel buttons become chips under Items. A plain click on a slot browses the catalog for it and makes it the target. |
| D5 | One search field, the header's: it filters the catalog over every category and fades the soldier's tiles. |
| D6 | Supply is always ACE's format (`ace_arsenal_virtualItems`). Unique items (carried, not offered) have no tab: they carry a mark, and destroying one needs a second click within 3 s (`einv_arsenal_confirmUnique`). |
| D7 | Everything that enters obeys sizes, stacks, compartments, `hasRoom` and free cells. Loadouts and container swaps are trimmed: what has no cell goes back to the arsenal; unique items are never removed and stay as red overflow. |
| D8 | Loadouts are ACE's, unchanged in storage and format; the arrangement travels inside the extended info as `einv_layout` (storage's `CBA_loadoutGet` / `CBA_loadoutSet` handlers). |
| D9 | ACE's window is replaced by a hand-over: only `ace_arsenal_display >> onLoad` is patched (`CfgAceArsenal.hpp`); in Enhanced mode the display is disarmed at run time and ours opens a frame later on the same parent. Eden has its own menu entry and is never handed over. |
| D10 | Client setting `einv_arsenal_window` (Enhanced / ACE). A header button reopens the same box in ACE's window; if ours cannot open, ACE's does. |
| D11 | Our window raises ACE's lifecycle, gear and loadout events with ACE's parameters, and never the events that hand out ACE's controls (`leftPanelFilled`, `rightPanelFilled`, `rightPanel*`, `displayStats`, `displayActions`, `*ChangePage`, `loadoutsDisplay*`, `loadoutsTabChanged`, `loadoutsListFilled`). ACE's session globals are set while open and nil'd at close as ACE does; `currentLeftPanel` / `currentRightPanel` stay nil. |
| D12 | EFAK kits are catalog items like any other (chip "Kits"); an opened kit is the inventory's kit window. A card dropped on an open kit's window or on a kit's tile (open or not) is packed into it when the kit's arsenal setting is "everything" and the kit would take the item by hand; giving back out of a kit needs "remove" or more; "nothing" kits are read-only ("This kit cannot be changed in the arsenal"). |
| D13 | BI's Virtual Arsenal: server setting `einv_arsenal_biArsenal` - "enhanced" (default, ours with the same items), "block" (the red glass screen), "vanilla". A wrapper of `BIS_fnc_arsenal` takes only "Open", plus a safety net on `arsenalOpened`. Eden, BI's showcase, Warlords and the Garage keep the vanilla one; Zeus is never blocked. |
| D14 | Eden-safe: the frame is a Draw3D handler, deferrals go through `einv_gui_fnc_later` / `einv_storage_fnc_nextFrame`. |
| D15 | The catalog column is kept across builds (top-level group `IDC_KEEP`); a build only re-registers its grid, zones and panel and rebinds counts. |
| D16 | Drag out = give back. Nothing of a session ever goes to the ground: gui's `ground` hook is the arsenal's give-back and always answers "handled" (also while a unique item waits for its second click). |
| D17 | MVP first (0.3.0), polish after it (0.3.1): ACE stats, sorts and actions, packing kits from the catalog, vision modes, the held weapon, mod icons, left-drag pan. Eden layouts follow with the Eden editor (W7). |

### Lifecycle

- **`fnc_openWindow [box, center, full = false, classes = nil, parent = displayNull, source = "ace"] -> BOOL`**:
  ACE's guards (center local, a man, on foot outside Eden, no `ace_arsenal_camera`, ours not open); an inventory window
  open is closed and the opening runs once more a frame later (`GVAR(reopening)`). Items: full -> a copy of
  `uiNamespace ace_arsenal_configItems`; `classes` (BI) -> classified by ACE's `addVirtualItems` on a local helper;
  else a copy of the box's list. Parent: given, else 312, else 46, in Eden 313. The arguments go to the display through
  `uiNamespace einv_arsenal_openArgs`.
- **`fnc_onLoad`** in ACE's order: `fnc_sessionStart` (ACE's globals, the lists in ACE's order: copy -> flatten ->
  `virtualItemsFlatAll` -> unique list; shared namespace, default list, saved loadouts, face, voice, insignia,
  favorites) -> **`ace_arsenal_displayOpened [display]`** -> `[true] call fnc_readSupply` (what the handlers left:
  `GVAR(availableLc)`, `GVAR(catalogItems)` - ACE Arsenal Extended's full copy when it is loaded) -> Eden: the clone
  (`fnc_edenStart`) -> HUD, view -> `fnc_cameraStart` (also `ace_arsenal_camera`) -> `einv_gui_fnc_attach` -> open,
  `einv_arsenal_opened [display, center, box]`. Attach failing closes the display and opens ACE's window.
- **`fnc_onUnload`**: **`ace_arsenal_displayClosed []`** with everything still set -> Eden: `fnc_edenEnd` (code 1 =
  Apply: the clone's loadout on every selected unit, `save3DENInventory`) -> `fnc_cameraStop` -> Zeus: remote control
  released (not when the [ACE Arsenal] button closed it) -> the player's view and the curator camera back -> face and
  voice broadcast with ACE's events and JIP ids -> gui's `fnc_onUnload` -> `fnc_sessionEnd` (favorites to the
  profile, ACE's globals nil'd, HUD back) -> closed; a BI session raises BI's `arsenalClosed [displayNull, false]`;
  `einv_arsenal_closed [center, box]`.
- **While open**: `fnc_keepOpen` (center alive; a BI box gone closes); `ace_arsenal_refresh` of our box re-reads the
  list (`fnc_onBoxRefresh`), `ace_arsenal_boxRemoved` closes; shared and default loadout events mark the loadouts view
  dirty; `einv_items_rulesChanged` drops the catalog's rows. `fnc_afterBuild` after every build: ACE's current and
  unique lists, carried counts, `weaponItemChanged` for parts that changed on an unchanged weapon, the target rings,
  the landing flash, ACEAX textures when the uniform or backpack changed; while hidden it hides every panel and
  empties grids, slots, zones and panels (`fnc_layout` shows the kept column again once they come back).
- **Keys** (`fnc_onKey`): Escape closes (Eden: Cancel; in ACE's showcase mission Arsenal.VR `fnc_leaveVR` asks
  "Leave the Arsenal?" first - [Exit to the menu] saves `ace_arsenal_missionLastLoadout` like ACE does, closes the
  window and ends the mission; [Stay], Escape again or a click beside the card stays), the game's night vision key
  (and the header's view button) cycles normal / night vision / thermal (`fnc_cycleVision`: `camUseNVG`,
  `setCamUseTI`; `fnc_cameraStop` puts the view back), Backspace hides / shows the panels (`fnc_toggleHidden`,
  `ace_arsenal_showToggle`), Ctrl+F search, Ctrl+C class under the mouse else export (Shift: the default list),
  Ctrl+V import (Shift in Eden: a list of defaults), Delete gives back, Left / Right one less / one more (Shift: five),
  the Gear key is swallowed.
- **Camera** (`fnc_cameraStart`, `fnc_cameraFrame`, `fnc_cameraRect`): no helper object - an orbit by vector maths
  round `GVAR(cameraPosition) [distance, dirH, dirV, target]`, the soldier centred in the layout's free middle,
  the distance clamped so he fits it; right drag turns, the wheel zooms, a double click in the middle resets. The
  left button moves the target point (`GVAR(cameraPan)`, `fnc_cameraFrame`) inside the soldier's bounding box with
  ACE's own sums and `ace_arsenal_camInverted`; the vision mode is `GVAR(visionMode)`.
- **The soldier on show** (`fnc_showItem [slot | "voice" | "insignia" | "keep" | ""]`): a weapon or binocular just
  put on is held in ACE's poses (`playActionNow` "PrimaryWeapon", "SecondaryWeapon", "HandGunOn", "Binoculars",
  `selectWeapon`; `switchAction` when simulation is off, as in Eden), a new insignia is saluted, a new voice says a
  line (`directSay`). The pose lives in `ace_arsenal_currentAction` / `selectedWeaponType`; `fnc_afterBuild` asks
  for "keep" after every build (the weapon is held again, or lowered when it is gone). Not for a unit that is not
  the player's (ACE does not either, `ace_arsenal_centerNotPlayer`).

### Entry points and ACE's window

| Entry | Path |
|---|---|
| ACE box action, Eden's ACE Arsenal attribute, ACE's and ZEN's Zeus arsenal, scripts calling `ace_arsenal_fnc_openBox`, Arsenal.VR | `openBox` makes `ace_arsenal_display` -> patched onLoad -> `fnc_handOver` -> ours on the same parent a frame later |
| The inventory's "Open Arsenal" | Enhanced and ready: `fnc_openWindow` directly; else ACE's `openBox`; a BI-only box: `BIS_fnc_arsenal "Open"` |
| Eden: unit > Arsenal > **Enhanced Arsenal** | `fnc_open3DEN` -> `fnc_openWindow` (ACE's and BI's entries untouched) |
| BI's Virtual Arsenal | the `BIS_fnc_arsenal` wrapper (below) |

- **The patch** (`CfgAceArsenal.hpp`): `onLoad` asks `einv_arsenal_fnc_handOver` first, else runs ACE's own string
  word for word. ACE Arsenal Extended patches `onUnload` - left alone, so load order never matters.
- **`fnc_handOver [display] -> BOOL`**: no in Eden, for a one-shot `GVAR(forceAce)` (a `diag_frameNo` stamp honoured
  for 3 frames), with the setting on "ace", when not ready, or for a remote center outside Zeus. Yes: the display is
  disarmed (`displaySetEventHandler` empties Unload, KeyUp, mouse buttons, KeyDown swallows; the mouse area's handlers
  emptied; every control hidden), `ace_arsenal_camera = objNull` guards `openBox`; a frame later the display closes,
  ACE's focus flags are nil'd and ours opens - for Zeus after waiting up to 2 s for the unit to become local; failing
  that, ACE's window after all.
- **Fallbacks**: `GVAR(ready)` (`fnc_compatCheck`, preInit: ACE's functions and data present; one RPT line when ACE is
  not the tested 3.21.2) false -> ACE's window every time. The header's [ACE Arsenal] (`fnc_openAce`) reopens the box in
  ACE's window (Eden: applies first, then ACE's `open3DEN`); hidden for BI boxes that are not full.
- **From ACE's window to ours**: `fnc_aceButton` adds a small `[Enhanced Arsenal]` button at the top right of ACE's
  display (`ace_arsenal_displayOpened`, registered in preInit so the Eden editor has it too; only for ACE's own
  display, only when ours is ready). Pressed: box, unit and "ignore the box's list" are written down, ACE's window
  closes (Eden: with Apply, and the entity ACE's copy stood for is the unit), and `fnc_openWindow` opens ours
  directly - never through `openBox`, which would show the bare game for a few frames. A Zeus's remote controlled
  unit stays his (`ace_arsenal_moduleUsed` is taken down for ACE's close and put back for ours). If ours cannot
  open, ACE's opens again.
- **ACRE**: `fnc_acreDisplay` (called in `fnc_onLoad`) registers our IDD with `acre_api_fnc_addNotificationDisplay`,
  once, so ACRE's notifications show over the window as over ACE's.

### Supply, grid rules, giving back

- Source of truth: `GVAR(catalogItems)` (what the catalog lists) and `ace_arsenal_virtualItemsFlat` /
  `GVAR(availableLc)` (what is offered). `fnc_isUnique [class or entry]`: neither the class, its layout key (radio and
  kit instances), its base weapon nor its non-preset backpack is offered; an entry is unique when anything leaving
  with it is.
- Creating: `einv_storage_fnc_addNew` into containers (`fnc_addItem`, `fnc_quickAdd` - by kind into vest, uniform or
  backpack, the target container first, `hasRoom` and `hasSpace` always), `einv_storage_fnc_putOn` into slots
  (`fnc_equipItem`). Swaps: `fnc_swapWeapon` (parts the new weapon takes stay, a full first magazine, spare magazines of
  only the old weapon go back), `fnc_swapContainer` (the new container gets the old one's snapshot - contents and
  places -, then `fnc_trimToFit`). An old unique item goes into storage (`fnc_storeAway`) or needs the second click.
- Giving back (`fnc_giveBack [source, count = -1, quiet = false]`, source `[grid, tile]`, `[unit, slot]` or
  `[container, entry]`): record removed, `einv_storage_fnc_removeEntry` / `fnc_takeOff`, payload discarded,
  `fnc_freeKits` frees EFAK kit ids of everything that left (unless the center still carries that kit). Out of an
  open kit window the item comes out of the kit (`einv_compat_efak_fnc_onGivenBack`, below) when the kit's arsenal
  setting allows taking out; otherwise "This kit cannot be changed in the arsenal". `fnc_trimToFit [unit]`: overflow
  first, then by weight unless grid-only; unique stays.
- ACE events: `ace_arsenal_cargoChanged` once per item added to or given back from the uniform, vest or backpack
  (`fnc_aceCargoEvent`, with `updateActionsOnCargoChange` off meanwhile); `weaponItemChanged` from the build's diff,
  quiet after swaps and loads.
- Sounds name the item: `["move", class]` for adds, `["equip", class]` for equips and swaps, `["giveBack", class]`
  for give back (`einv_gui_fnc_playSound [action, class, container, world, ui]`, section "Feel" below; the
  Arsenal is never heard by others).

### Kits in the Arsenal (compat_efak)

Used only by the arsenal addon, every call guarded with `isNil`:

- `fnc_arsenalEditing [kit] -> 0 / 1 / 2` - nothing / take out only / everything: the setting of Enhanced First Aid
  Kits for the kit's type (`efak_core_fnc_getArsenalEditing`; everything in Eden), 0 for a class that is no kit.
- `fnc_packNew [kit, class, count, cell = [], root = objNull] -> [added, why, landed]` - packs new items straight
  into a kit: needs 2 from `fnc_arsenalEditing`, asks `fnc_canPack` (that mod's item rules, default contents limit,
  room - for as many as fit, found by halving), checks the kit lies under `root`, then `fnc_putIntoKit` with
  `einv_storage_fnc_makePayload`, which ends in that mod's `setContents`; the tile's record is written at the cell
  asked for when free, else where the kit's layout puts it. `why` is "" / `"ReadOnly"` / `"Gone"` / `"Failed"` / a
  text or word for `einv_gui_fnc_flashHint`.
- `fnc_onGivenBack [kit, tile, count = -1, root = objNull] -> [status, payload, kitRemoved]` - needs 1 or more from
  `fnc_arsenalEditing`, then `fnc_takeFromKit` and `fnc_removeIfEmpty`; status "" / `"ReadOnly"` / `"Gone"` /
  `"Failed"`.
- **One writer.** Both write where they are called, outside any phase, and only for a `root` that is local (else
  "Failed"): the kit lies in the center's own gear, whose transactions (`einv_storage_fnc_isLocalRoot`) run on this
  machine as well - like `einv_storage_fnc_addNew`. Both call `fnc_requestRebuild`, so the kit windows redraw.

### Catalog

- Rows (`fnc_catalogRow`, cached in `GVAR(rows)`): `[class, search, name, short, picture, w, h, tileCategory, kind,
  stack, capacity, mass, modName, category, key]` (`ROW_*`), read in the background about 2 ms a frame
  (`fnc_catalogFrame`, the shown category first). Identity rows (faces by the soldier's face type, voices, insignia)
  are cards too; not in Eden and not while ACE's identity tabs are off.
- The list (`fnc_catalogList`): search over every category (every word, any order; a magazine class also finds the
  weapons taking it), favorites (and what the soldier carries), Fits for parts and magazines, sort by name, weight,
  size, mod or one of ACE's sorts for the category (either direction), debounced 0.15 s.
- The view (`fnc_drawColumn`, `fnc_drawCatalogBar`, `fnc_drawCatalog`, `fnc_bindCatalog`): the column is made once per
  display and rect; `fnc_layout` registers the source grid and the "giveBack" zone only in the Items view, the
  "soldier" zone always. The wheel steps one card row (`fnc_catalogWheel`), the scroll bar is native.
- **ACE's sorts** (`fnc_aceSorts`, modes `["list", category]`, `["label", id, category]`, `["value", id, class]`):
  the sort menu lists what ACE has for the category's tab (accuracy, rate of fire, magnification, protection, mods'
  `ace_arsenal_fnc_addSort` ...), minus the ones the catalog has itself (alphabetical, mod, weight) and minus a
  container's (amount). A sort is `"ace|"` + ACE's name for it on that tab (`ACE_accuracyL00`); its value for a
  class is `[config, class, 0] call statement` made a string like ACE does (`CBA_fnc_formatNumber [value, 8, 2]`),
  kept in `uiNamespace einv_arsenal_sortCache` by sort and class. In a search over every category, or in a
  category without that sort, the list goes by name and the chip says "Name".
- **Mod icons**: with `ace_arsenal_enableModIcons` on 1 (the mod's logo) or 2 (the DLC's), a card carries a small
  logo at the foot of its picture (an eighth control per card, `fnc_drawCatalog`; found with
  `ace_common_fnc_getAddon` / `getDLC` and kept per class in `uiNamespace einv_arsenal_modLogos`,
  `fnc_bindCatalog`).

### Interactions

| Where | Gesture | Result |
|---|---|---|
| card | drag onto own cell / slot / weapon card / the soldier | created there / put on / loaded or attached / like Alt+click |
| card | drag onto an open kit's grid or a kit's tile | packed into the kit (`einv_compat_efak_fnc_packNew`): only for a kit whose arsenal setting is "everything", what the kit's mod would let in by hand (item rules, default contents limit, room), as many as fit ("Only 3 of 5 fit"); otherwise the footprint is red and says why |
| own tile (in a kit window) | drag onto the catalog, Ctrl+click, Delete, menu "Give back" | out of the kit, for kits that allow taking out |
| card | Alt+click / Ctrl+click / Shift+Ctrl+click | equip / add 1 / add `einv_arsenal_quickAddAmount` |
| card | double click / Shift+double click | use (equip, attach, load into the target magazine slot, add; identity: apply) / favorite |
| card, own tile | Right / Left arrow | one more / one less of that class (Shift: five) |
| own slot | plain click | browse the catalog for it, the slot becomes the target (again: cleared) |
| own free cells | plain click | that container becomes the target of quick adds |
| own tile or slot | drag onto the catalog or outside every panel | given back (the column tints in the loss colour) |
| own tile or slot | Ctrl+click, Delete | given back (a weapon with its parts, a container with its contents) |
| own tile | double click | a kit opens, a uniform, vest or backpack opens as a section, else equip |
| anything | right click | menus (`fnc_menu`): inspect, equip / attach / load rows, add (to each container), favorite, copy class; give back, give back all, fill, open, sort; browse, take off, detach; add here, sort, empty |
| inspect card | open on a card or tile | "In this arsenal: Yes / No" and ACE's stat rows for the item's tab (`fnc_inspectRows`: ACE's condition, bar and text statements, at most eight; weight, load and round count are the card's own) |
| own slot | right click | besides the usual rows, the actions ACE's window has under that slot's tab (`fnc_aceActions`: the gunbag's, other mods' `ace_arsenal_fnc_addAction`): a button runs ACE's statement and rebuilds the window, a text says itself in the hint |
| free middle | left drag | moves the point the camera looks at (ACE's `camInverted` honoured) |

### Loadouts

Tabs Mine (profile `ace_arsenal_saved_loadouts`), Default (`ace_arsenal_defaultLoadoutsList`, while
`ace_arsenal_allowDefaultLoadouts`), Public (ACE's shared namespace, multiplayer). Every row is checked with ACE's
`verifyLoadout` + `recoverInvalidContainers`, 10 a frame, cached per tab, name, data and supply. Load (unique items
lost -> second click; `CBA_fnc_setLoadout` with full magazines, trim, identity), Save (name required, a shared name
refused, overwrite confirmed, `replaceUniqueItemsLoadout`; on Default with rights `addDefaultLoadout`), Rename, Delete,
Share / Stop sharing, Make default, Copy to mine, Import (clipboard parsed with `parseSimpleArray`, never compiled;
ACE's extension in multiplayer), Export. Events: `onLoadoutLoad(Extended)`, `onLoadoutSave(Extended)`,
`onLoadoutDelete`, `loadoutImported`, `loadoutExported`, `loadoutShared` / `loadoutUnshared` (remote).

### Events

Raised: `ace_arsenal_displayOpened [display]`, `displayClosed []`, `cargoChanged`, `weaponItemChanged`, the loadout
events above, `showToggle [display, shown]`; own `einv_arsenal_opened [display, center, box]` and
`einv_arsenal_closed [center, box]`. Never raised: the panel, stats, actions and loadouts-list events of D11.
Listened to: `ace_arsenal_refresh`, `boxRemoved`, `addDefaultLoadout`, `removeDefaultLoadout`, `renameDefaultLoadout`,
`loadoutShared`, `loadoutUnshared`. The handlers that serve ACE's own window (`arsenal/XEH_postInit.sqf`) exit while
ours is open. `ace_arsenal_displayOpened` of ACE's own display also makes the `[Enhanced Arsenal]` button
(`fnc_aceButton`, registered in `arsenal/XEH_preInit.sqf`).

### The vanilla Virtual Arsenal

- **Wrapper** (`CfgFunctions.hpp` -> `functions/fnc_biArsenal.inc.sqf`): "Open" asks `fnc_handleBIOpen`; everything
  else is BI's own code untouched. `fnc_checkBIOverride` logs when another mod won the entry; then only the safety net
  (`fnc_biSafetyNet`, an `arsenalOpened` handler that closes BI's display a frame later and opens ours or blocks)
  works.
- **`fnc_handleBIOpen`**: "vanilla" -> BI's. Always BI's: no interface, not ready, `einv_arsenal_biPassThrough` true,
  BI's showcase, Warlords; in "enhanced" also a mission with more `arsenalOpened` / `arsenalPreOpen` handlers than mods
  had (`fnc_biCountHandlers`, the first frame after postInit) unless `einv_arsenal_biPassThrough` is false. A remote or
  seated center -> BI's (with its own error). Zeus open -> ours whatever the mode. "block" -> `fnc_showBlocked`.
  "enhanced" -> `fnc_biItems` (the box's and the mission's virtual cargo, `%ALL` -> ACE's categories, linked items and
  the soldier's own gear, less `arsenalRestrictedItems`, limited to tabs the mission edited in BI's catalog) ->
  `fnc_openWindow [.., "bi"]`.
- **The block screen** `EINV_ArsenalBlocked` (IDD 9611): red glass, a card with the title, the server's
  `einv_arsenal_biMessage`, where the setting is, [Understood]; Escape and Return close it.
- **Leave it alone**: `arsenalPreOpen` notes the center, `arsenalClosed` reports what does not fit the grid
  (`fnc_reportOverflow`).
- BI boxes in the inventory: `fnc_isBIBox` makes them arsenal boxes (never searched, "Open Arsenal"),
  `fnc_canOpenBI` checks BI's own action rules and the box's `bis_fnc_arsenal_condition`.

### Known limits

- ACE internals the window calls (`updateVirtualItemsFlat`, `updateUniqueItemsList`, `updateCurrentItemsList`,
  `verifyLoadout`, `recoverInvalidContainers`, `canEditDefaultLoadout`, `configItems`): missing -> ACE's window, one
  RPT line.
- The hand-over relies on `displaySetEventHandler` / `ctrlSetEventHandler` replacing the config's handlers; the Zeus
  locality wait (2 s) is a guess - both to be checked in the game, on a dedicated server for Zeus.
- Mods that add controls to ACE's display (EFAK's kits tab, ACEAX's option panel) or rename rows in ACE's lists (dog
  tags, ACRE) do not show in ours; their players switch to ACE's window. stx_common's F1 may log a script error.
- ACEAX in Eden: Apply from our window does not rewrite the unit's ACEAX texture attribute.
- Missions that register BI arsenal handlers before the first frame after postInit count as mods'; such a mission
  sets `einv_arsenal_biPassThrough = true`.
- Moves between the soldier's own containers are gui's transactions; should one fail and settle, settlement may still
  use the ground (as compat_efak's race fallback, which runs on the server and not through the `ground` hook).
- Layouts made in Eden are lost at mission start; on 4:3 the
  soldier stands behind the panels until Backspace; `ace_arsenal_fnc_message` calls aimed at ACE's window do not show.
- The first time an ACE sort is used in a category, its value is worked out for every class of the category (ACE
  does the same when it sorts); it is kept after that.
- A card dropped on a closed kit's tile shows its footprint at the card's cell, not on the tile.
- Arsenal.VR is told apart by its `onPauseScript` (`ace_arsenal_fnc_onPause`; its description.ext writes it as an
  array, `fnc_leaveVR` takes either) alone.
- Built and checked in code only: nothing of the Arsenal has run in the game yet.

## Feel: sounds and the looting pose (0.3.1) - supersedes the parts above it contradicts

- **Sounds by family.** `einv_gui_fnc_playSound [action, class, container, world, ui]` (Public) plays the sound of
  an action for an item's family (`fnc_soundFamily`: config `einv_sound`, ACRE/TFAR radios, medical items, EFAK
  kits, then the kind) or, without a class, a container's (`fnc_containerFamily`: body, ground, vehicle, crate, or
  a nested uniform/vest/backpack by its item). The table is the config `CfgEinvSounds` (gui, `CfgEinvSounds.hpp`):
  18 item families and 4 container families, each action up to 4 variants of up to 3 layers
  `{file, volume, pitch low, pitch high, offset, length, delay}`, `use` aliases (`fnc_soundDef`), surface tokens
  (`@crawl`, `@crawl2`, `@grenade` -> `Surfaces` by `fnc_groundSurface`) and vehicle doors (`@getIn`, `@getOut`);
  `fnc_resolveLayers` turns a chosen variant into what is played. Arma's own base-game files only, by path (105
  files, all checked against the PBO listings), volumes levelled to 0.1.15's rustle by measured loudness. A mod or
  mission adds a family or replaces an action in `CfgEinvSounds`, and an item picks its family with `einv_sound`.
- **Actions:** lift, move, drop, equip, unequip, attach, detach, loadMag (Handgun, Launcher, Ugl), unloadMag,
  rotate, open, close, search, uncover, inspect, giveBack. The old kinds keep working (`"put"` is `"move"`; the
  Arsenal's `["giveBack"]` with no class). The looter hears them on the UI channel through the effects bus
  (`playSoundUI`, `isEffect`), so the game's effects volume, ACE's earplugs and blast deafness apply, times
  `einv_gui_soundVolume`, and only with `einv_gui_sounds` on. A pick-up (`fnc_startDrag`) and a turn
  (`fnc_rotateDrag`) sound at once; **every change sounds when its answer is finished**: `fnc_sendMoves` stores how
  its first three moves sound (`fnc_feelFor`) as the fourth element of the in-flight record, and `fnc_afterAction`
  plays the first that really moved (`fnc_feelAnswer`, one sound per answer, none for a refusal). A magazine into
  the weapon in the hands plays that weapon's own `reloadMagazineSound` and `reloadAction` gesture
  (`fnc_playReload`, `fnc_reloadSound`, `fnc_soundFile`); into any other weapon a short generic click per weapon
  type. The hotbar's rebuild after a bind is silent; the context menu's Sort sounds a search when it is sent.
  Kits: `einv_compat_efak_fnc_open` plays `["open", class]` and `fnc_close` `["close", class]` (family `medic`).
- **Others hear it** (`einv_gui_soundsWorld`, a server setting): `fnc_sendNoise` sends the resolved layers (at most
  three) as the CBA target event `einv_gui_noise` to the players within the action's range plus 5 m, at most every
  0.2 s (search ticks every second) and never from the Arsenal; `fnc_onNoise` (registered in postInit, interface
  only) plays them with a local `playSound3D` at the looter's hands. Nobody near: no network at all.
  `einv_gui_noiseSelf = true` in the debug console lets the looter hear the copy others get (single player test).
- **Looting pose** (`einv_gui_animation`: Off / While looting / Always): Arma's own inventory states
  `Ainv<Perc|Pknl|Ppne>MstpS<ras|non>W<rfl|pst|lnr|non>Dnon` (`fnc_poseState`), played with `playMoveNow` on the
  local player's own unit - the engine carries them to every machine and to joining players; no `switchMove`, no
  custom animation. `fnc_open` notes what the window was opened on (`GVAR(openedOn)`: the first of the container and
  the second that is somebody else's loot - not the unit, not its own uniform/vest/backpack, not the empty pile the
  engine makes at the feet for its ground panel), the stance, vehicle and place (`openStance`, `openParent`,
  `openPos`), then `fnc_poseStart` (guarded by `fnc_canPose`: a living, awake, local unit on foot in a plain state;
  never ACE handcuffed, surrendering, escorting, dragging or carrying; not swimming, deployed, in a vehicle or
  with the binocular in the hands). The soldier kneels at bodies and unconscious or prone persons, at a pile he
  aims at or that holds something not searched yet, and at crates lower than 0.6 m (`fnc_isLowTarget`).
  `fnc_poseCheck` (every check interval, after the window's own "stay open" checks) closes the window when the
  soldier was taken away (vehicle, ACE captive/drag/carry, more than 1.5 m moved; `GVAR(closeReason)` "taken":
  no close sound, no end move), starts the pose late when a search began later, re-aims the live camera once the
  pose is reached, brings the pose back after a weapon change (3 times at most) and forgets it when another
  animation takes over (ACE's unconscious state, a mod's move). `fnc_onUnload` plays the close sound and calls
  `fnc_poseEnd`: back to the opening stance (`fnc_restState`, lowered first), **only while the soldier is still in
  an `Ainv` state** and never after "taken" or with an ACE captive, drag or carry flag set (ACE's animation may
  not have started in that frame), so nothing ACE or anyone else started is ever fought. Gestures (`fnc_gesture`): the reload
  and the suppressor mount/dismount only (upper body), never prone or while ACE's own reload runs. ACE's magazine
  repack lands in an `Ainv` state too: `fnc_poseCheck` takes it as the pose and `fnc_poseEnd` returns the soldier
  to his opening stance.
- **Moving stops looting** (`einv_gui_moveToStop`, each player): a movement key (keyboard, from `actionKeys` of
  MoveForward, MoveBack, TurnLeft, TurnRight, MoveLeft, MoveRight, MoveFastForward, MoveSlowForward, EvasiveLeft,
  EvasiveRight) closes the window while the window was opened on something or a search runs (`fnc_onKeyDown`,
  `closeReason` "move"); keys held as the window opened count after their release (`GVAR(moveHeld)`, a KeyUp
  handler `fnc_open` adds), nothing counts in the first 0.5 s, **keys pressed with Ctrl or Alt never** (Ctrl+A
  selects the section and A is MoveLeft; such a key counts as held until it is let go, so its repeats after Ctrl
  came up first close nothing either), and nothing in the search field. The held key walks the soldier out of
  the pose; only a tap that moved nothing stands him up after 0.6 s.
- `GVAR(openedOn)` - not the layout's `looting` (nearby boxes switch that on) - decides "while looting", the
  open/close sounds and the kneel. The Arsenal never sets it: no pose, no open sound, no noise for others.
- While magazines are repacked (section below) `fnc_poseCheck` is not called: ACE's `goKneeling` and `Gear`
  gesture are not answered with a re-entry; the repack's own per-frame check (`canInteractWith`) stops it when the
  soldier is taken, and the pose is looked after again the moment it ends.
- **Known limits.** The sounds were chosen by measurement, not by ear - expect a few swaps (each is one line in
  `CfgEinvSounds`). Controller movement bindings do not stop looting. A mod's weapon without a findable
  `reloadMagazineSound` file gets the generic click. Built and checked in code only: nothing of it has run in the
  game yet.

## Magazines: repack and fill bar (0.3.1) - supersedes the parts above it contradicts

- **Fill bar** only on magazines that are not full (`fnc_createTile`, `fnc_drawSlot`), switchable per player:
  `einv_gui_magazineFillBar` (topic Magazines). Full ones show their rounds only; a one-round magazine has no bar.
  Tiles keep `bar`, `barRect`, `amount` and `amountShort` for a repack in progress.
- **Repack** (new addon `magazines`, prefix `einv_magazines`, needs `ace_magazinerepack` and
  `skipWhenMissingDependencies`; setting `einv_magazines_repack`, the same for everyone): a partly filled magazine
  dropped on a partly filled one of the same class (drag target `["repack", gridIndex, tileIndex, 0, fits, reason]`,
  footprint in the accent colour on that tile), or "Repack all <name>" in the menu of an own magazine (also of a
  weapon's magazine slot). ACE's schedule (`ace_magazinerepack_fnc_simulateRepackEvents`, ACE's time settings),
  sounds, kneel and gesture, and ACE's per-frame conditions (`canInteractWith` with `isNotInside`, `isNotSwimming`,
  `isNotSitting`); the progress shows in the window (a film on the tiles, a bar that moves with every round, live
  rounds text, the search ring on the magazine being filled, a counting hint), not in ACE's progress bar, which
  closes dialogs. Rounds go from the emptier magazine into the fuller one; each result stays in its cell; an
  emptied magazine is gone. Only available in the inventory (`fnc_isInventoryMode`): the Arsenal and later editor
  windows never repack.
- **Hands busy** while it runs: a mouse press stops it and does nothing else, its release is swallowed
  (`GVAR(swallowUp)`); Escape stops it and the window stays; Delete waits; hover, drag and searching pause
  (`fnc_onFrame`, `fnc_onMouseButton`, `fnc_onKeyDown`). `fnc_build` ends with `einv_magazines_fnc_drawJob`
  (before the `afterBuild` hook), `fnc_onUnload` starts with `einv_magazines_fnc_stop "Closed"`, a window over ours
  stops it ("Interrupted").
- **One commit** at the end (done, stopped, interrupted, closed): `einv_magazines_fnc_commit` sends one phase
  `[root, [["repack", [parts]]]]` through `einv_storage_fnc_request`, parts `[container, class, rounds before,
  rounds after, cell]`; the callback `einv_magazines_fnc_onCommitted` waits for the places the op wrote (as the
  window does for its moves) and shows the result (`fnc_finish`). The op `repack` (`einv_storage_fnc_opRepack`,
  registered in `einv_storage_ops`, its holders walked by `fnc_execute`) checks at the authority that it is one
  kind of magazine ACE allows, each partly filled before, none over full after, whole rounds and the same sum;
  that every magazine is still there with those rounds ("Gone" otherwise, nothing changed); takes them out by
  their rounds (read off the cargo before and after, everything put back and "Failed" on a mismatch) and puts the
  new ones in, in order; the record of a magazine that lay alone on its tile leaves with it and comes back at the
  same cell with the key of its new rounds (`class|m<rounds>`), a pile keeps its record and the new magazine lies
  where the layout finds room. No server event of its own: the hub, journal, guards (the locks' among them) and
  reach apply as to every op.
- **Both magazines must lie under the same root** (`einv_storage_fnc_rootOf`, from the grid's `root`:
  `einv_magazines_fnc_domain`): the player's own gear (any depth), or one crate, vehicle, pile or body, nested
  containers included. Otherwise the drop is red with "Take it into your own gear first, then repack". A living
  person's gear, kits (EFAK/EUP), virtual and overflow grids, the Arsenal's catalog and loaded magazines never take
  part.
- ACE's CBA menu row "Repack Magazines" is hidden while repacking is on (`einv_magazines_fnc_hideCbaOption`, asked
  by `einv_gui_fnc_cbaOptions`); with the setting off it shows and behaves as in the vanilla inventory.
- **Concurrency.** Nothing in the cargo changes while the repack runs; the op at the end checks every magazine
  against the cargo as it is then (rounds per container, as a multiset). Another player taking one of them, a
  magazine moved meanwhile or a window closed mid-repack therefore end in "Gone" (nothing changed) or in the
  counts reached so far - never in a round more or less. Two repacks of the same crate are serialised by its
  authority like every other phase. A tile of the job that is gone from the window after a rebuild stops the
  repack ("Interrupted", `fnc_drawJob`).
- **Known limits.** Loaded magazines never take part (drag the magazine out first); same class only, as ACE; one
  magazine of each tile (the drag count is ignored); a pile's repacked magazine lies where the layout finds room;
  ACE's self-interaction repack still works as ACE's; GreenMag is not detected (switch the setting off on such
  servers).

## Weight tiers, full by weight, gear comparison (0.3.3) - supersedes the parts above it contradicts

Backlog `weight_design.md`, wave W6. Nothing of it has run in the game yet. It replaces the weight card's
"Light / Medium / Heavy / Overloaded" by 1 at Arma's limit (the `weight` section above and the Weight card in
the gui text), the plain red load text of a section, and the name at the mouse for vests, uniforms, helmets
and backpacks.

- **Tiers** (`weight` addon, which now also needs `ace_common`). `einv_weight_fnc_getLoad [unit]` is ACE's total:
  `loadAbs` plus `ace_movement_vLoad` of the unit and of its uniform, vest and backpack (the weight overrides
  of the rules and the Enhanced First Aid Kits load included). `fnc_getLimits [unit]` gives Heavy, Overloaded
  and Critical in config mass and kilograms (`heavy`, `overloaded`, `critical`, `heavyKg`, ..., `fromAce`,
  `aceFatigue`, `key`), cached in `GVAR(limitsCache)` under a key made of every input, so a changed setting,
  ACE setting or performance factor makes a new entry and nothing has to be told. Overloaded
  (`einv_weight_overloadedAt`, 45 kg) and Critical (`einv_weight_criticalAt`, 60 kg, at least 1 kg above
  Overloaded) are settings; Heavy (`einv_weight_heavyAt`, 0 = follow ACE) is where ACE Advanced Fatigue's own
  jog (12 km/h, weapon lowered, `JOG_SPEED`) costs more than the body keeps up aerobically
  (`fnc_heavyFromAce [performance, load factor]`: ACE's running formula, bisected, then ACE's own
  `(kg - 3.5) x loadFactor` turned back; 26.7 kg at ACE's defaults). The jog-speed gate test G2 was never run,
  `JOG_SPEED` is ACE's number. ACE's fatigue off, or no ACE value: Heavy is 60 % of Overloaded; it is never
  later than Overloaded. `fnc_getTier [unit, load = -1]` answers `TIER_LIGHT` / `TIER_HEAVY` /
  `TIER_OVERLOADED` / `TIER_CRITICAL` (`main/script_macros.hpp`; also `KG_TO_MASS`, `NEAR_FULL`);
  `fnc_tierText [tier, limits]` the words (`Tier_*`, `Effect_*`). Nothing is ever refused because of a tier.
- **What the red tiers do** (`fnc_updateTier`, the player's machine only). From Overloaded: ACE's status effect
  `blockSprint`; from Critical: `forceWalk` (reason `einv_weight`, through `ace_common_fnc_statusEffect_set`,
  which ACE syncs); and an ACE Advanced Fatigue duty factor registered in postInit
  (`ace_advanced_fatigue_fnc_addDutyFactor`, code reading `einv_weight_duty` on the unit) that climbs from 1
  at Overloaded to `OVERLOAD_DUTY_MAX` (1.5) at Critical. `einv_weight_effects` off keeps the bar and takes the
  effects off. No `setAnimSpeedCoef`: ACE's fatigue resets it every second. A change of tier raises the local
  CBA event `einv_weight_tierChanged [unit, tier, old tier]` and, with the inventory closed and
  `einv_weight_notify` on, an ACE message with the weight icon (`fnc_notifyTier`). The unit's old tier,
  duty and effects are cleared when the player's unit changes (the CBA `unit` event). ACE refreshes its total
  load only on loadout events: when it differs from ours by more than 1, `ace_movement_fnc_handleVirtualMass`
  is asked to count again.
- **When it is worked out.** `fnc_queueVirtualLoad` runs `fnc_updateVirtualLoad` and then `fnc_updateTier` on the
  next frame (unit change, loadout event, rules change, the 3 s nested check), and a per-frame handler every
  `TIER_CHECK_INTERVAL` (1 s) compares `[load, limits key, effects switch]` with the last look - catching kit
  loads, other mods' virtual load, settings and a looter filling a searched person's backpack. Nothing runs in
  Eden (no postInit); `getLimits`, `getLoad`, `getTier` still answer there, which is what the Arsenal's weight card
  draws from.
- **Container weight** (`storage`). `fnc_roomByWeight [container, entry, count = -1]` is the one rule:
  `fits`, `reason` (`""`, `"TooHeavy"`, `"NoBackpack"`, `"Failed"`), `need`, `free` (-1 for no limit),
  `perItem`, `maxCount` (how many of the stack fit), `maxLoad`, `held`. `fnc_hasRoom` keeps its yes or no.
  `fnc_opMove`, `fnc_opPut`, `fnc_moveEntry` and `fnc_unequip` answer `"NoBackpack"` where that is the reason
  (a backpack into a backpack, which used to read as too heavy). `fnc_getLoadState [container, mass = -1]`:
  `state` `none` (no limit: the ground, or Limit by room only), `ok`, `near` (from `NEAR_FULL` 85 %), `full`
  (less than `FULL_FREE_MASS` or `FULL_SHARE` of the load left while it holds something, or a load of 0) and
  `over`, with `mass`, `maxLoad`, `free`, `fraction`. `fnc_plan` sends a stack that is too heavy for a target as
  a whole, from another holder, in part - as many as the weight allows - and `fnc_sendPlan` passes the count on
  (the fifth element of an assigned entry; -1 for all): Take all and a group quick move move what fits and say
  "Moved 3 of 10 - the rest is too heavy for ...". `GVAR(carryVariables)` (the list of variables on a container
  object that travel with it) is declared in storage's preInit for the locks work.
- **Full by weight, in the window** (`gui`). A section with a container and a limit in play draws, besides the
  load text (text2, warning when `near`, loss when `full` / `over`): a weight icon left of it from `near`, a
  chip (Full / Over) left of that from `full`, a two-pixel load bar instead of the caption's hairline (`line`
  track, fill in the state's colour, `LOAD_BAR_H`), and reddish free cells (`cellFull`) while it is full or over.
  A container with no limit keeps the hairline. Every such section is a record in uiNamespace `einv_gui_loadBars`
  (container, parent, bar rect, label and its rect, text, colour, the icon and chip controls, mass, state, the grid
  indices, the colour the cells have, fill, preview, tinted cells); emptied by every build.
  `fnc_redrawTiles` draws a section's tiles and updates its text and bar in place only while its state is the one
  it was drawn in and not full / over; otherwise the window is built. **Lifting** something
  (`fnc_startDrag`, before the ghost) calls `fnc_markWeight [display, entry, count, create]`: every container
  but the source asks `roomByWeight`; its bar gets a preview of what the item adds (`text`, or `loss` when it
  does not fit, `PREVIEW_ALPHA`); one that cannot carry it turns its free cells `cellBlocked` and its load text
  reads "Too heavy - 0.1 kg left" with the icon and chip hidden. The wheel (`fnc_onMouseZ`) and the middle button
  repeat it for the new count (recolour only); `fnc_clearWeightMarks` undoes it, first thing in `fnc_endDrag`.
  Not for a group (`fnc_groupMode` shows those) and not for what comes out of a kit's grid.
- **The weight card** (`fnc_drawEquipmentCards`). Value "34.5 kg", then "/ 45.0 kg" (the red mark) in muted, the
  tier word in the tier's colour (Light text2, Heavy `warn`, Overloaded and Critical `loss`); a bar from 0 to
  Critical with ticks where Heavy (yellow) and Overloaded (red) start - none at 0 or the end - and a two-pixel
  strip under it in `zoneWarn` / `zoneLoss` from those marks on (the square look keeps its ten segments, in the
  tier's colour). The Light fill is the `text` colour. uiNamespace `einv_gui_weightBar` holds the bar for the
  drag: from outside the soldier's own gear (`fnc_isOwnStorage`: the holder's root, `einv_storage_fnc_rootOf`, is
  the window's unit; a source grid; another unit's slot) a preview of the added weight lies on the bar in the colour
  of the tier it lands in. `fnc_getSignature` holds the limits' key in its own part.
- **Hints** (`fnc_infoHint [kind, args]`, `fnc_dragHint [parts]`, `fnc_weightText [kind, ...]`). uiNamespace
  `einv_gui_infoAreas` ([rect, "", "", anchor, kind, args]) are the hover areas of the weight card ("weight") and
  of every section's caption line ("load"); `fnc_updateHover` also finds a free cell of a grid (`["cell", grid]`)
  and says how full a container is when it is near, full or over. Over a target while dragging, the hint is
  the key help (`GVAR(dragKeys)`, written at lift) unless the target has something to say: "Too heavy for Tactical
  Rig: 0.1 kg left, this weighs 0.5 kg", "Only 3 of 10 fit by weight into Backpack - the wheel takes fewer" (the
  counter at the ghost turns red meanwhile), "A backpack does not go into a backpack", or - into the soldier's own
  gear from outside it, or onto an empty own slot - "+2.4 kg: you will be Overloaded (46.9 kg)" in warn / loss.
  `fnc_dragHint` writes only when the parts changed. The room answer and its hint are cached per target and count
  in `GVAR(dragRoom)`. A refusal says the numbers too: `fnc_endDrag` and `fnc_applyMove` pass
  `["TooHeavy", [container, entry, count]]` to `fnc_flashHint`, and `fnc_afterAction` does the same for a
  refused move of a transaction, from the in-flight record's fifth element (`details`, `[[to, entryArray,
  count], ...]`, one per move in the order of the moves, written by `fnc_sendMoves`). `fnc_quickUnequip` tells
  "Nowhere to go" from "Too heavy for your containers: 0.4 kg left at most" when a body's or person's slot cannot
  go anywhere. `GVAR(pendingHint)` is a hint a quick move leaves for after its answer: `fnc_build` writes it once,
  `fnc_afterAction` clears it on any refusal.
- **Comparison card** (`fnc_compareRows [unit, class]`, `fnc_drawCompare [display, rows]`). Over a vest, uniform,
  helmet or backpack - a tile, or a slot of a body, a person, the ground or the Arsenal's catalog, but not a slot
  of the soldier's own gear and not a hotbar slot - the name at the mouse becomes a small card (setting
  `einv_gui_compareTooltip`, each player, on): the name, "vs. <worn item>" (or "vs. nothing worn", "the same as
  yours"), and rows - Armor (zone) for vests and helmets (and uniforms when the chest values differ), Covers
  (zones with armor: kept in text, gained in green, the worn item's lost ones as "-zone" in red), Space (cells,
  from `einv_storage_fnc_blocksFor` against the worn container's `getBlocks`), Holds (kg, left out with Limit by room only) and Weight
  (heavier is red) - each with the difference. Armor is ACE's own number: `einv_items_fnc_getArmor [class,
  hitpoint]` calls `ace_medical_engine_fnc_getItemArmor` when it exists, else the same formula copied;
  `einv_items_fnc_getProtection [class]` gives `zones`, `order`, `mainZone`, `main` (the chest, or the head for
  headgear), cached for good in uiNamespace `einv_items_protection`. The card is one `EINV_Group` made on every
  change of what the mouse is on, sized to its content plus two pixels (a group scrolls once its content is
  taller), kept as uiNamespace `einv_gui_compare`; `einv_gui_tipShown` is whichever of the card and the name is
  on show, with the `width` and `height` kept on it, which `fnc_onFrame` uses to put it beside the pointer (left
  of it near the right edge, above it near the bottom). Not while dragging or with a menu open (`fnc_openMenu`
  deletes it).
- **Theme.** New keys in `fnc_themeBase` and `fnc_theme`: `warn`, `zoneWarn`, `zoneLoss`, `cellFull`,
  `cellBlocked`, `tooltipBg` (the last was only a default before).
- **Settings** (topic Weight, in this order): `einv_weight_heavyAt`, `einv_weight_overloadedAt`,
  `einv_weight_criticalAt` (everyone, kilograms), `einv_weight_effects` (everyone), `einv_weight_notify` (each
  player); `einv_gui_compareTooltip` (General, after "Replace the vanilla inventory"). The description of Limit by
  room only now says that past the red mark the soldier is Overloaded.
- **Multiplayer.** Tiers, their effects and the message are the player's own machine's business (ACE syncs its
  status effects); the duty factor is read by ACE's loop where the player is. Container weight is judged by whoever
  carries a move out, as before; the window only previews, and the previews use the same `roomByWeight`. No new
  network events. A looter filling a searched person's backpack moves that person's tier within a second on
  their machine.
- **Known limits.** Heavy is where *jogging* stops being free in ACE's model at ACE's jog speed; running uphill,
  raised weapons, wounds, heat and carrying a body (ACE's other duty factors) tire sooner than the mark says - it is
  steady on purpose. The body forecast covers grid targets and empty slots; a swap (a vest onto a worn vest) shows
  none - the comparison card shows the item's own weight difference. Moving something into a uniform lying
  inside a crate checks that uniform's load, not the crate's. The comparison's Armor is the item's own ACE armor at
  its main zone; ACE adds uniform, vest and helmet per hit point, so the value a hit meets is the sum. A group
  dragged over a container is still judged as a whole by mass (`fnc_groupMode`); only Take all, Put all in and
  the group quick move split a stack. A vest or other container with a maximum load of 0 reads as full.

## Locks, ACE cargo and radios (0.3.3) - supersedes the parts above it contradicts

Mia asked for three things: loaded crates as a box in the vehicle inventory with an Unload button, channel and
frequency of radios at the mouse with "Open radio" in the right-click menu, and locked crates shown as locked
in the window. The window's lock gates are in "Locks" above; this section is the other two, the shared helpers
and the pieces of storage they use.

- **One question, several mods: `einv_gui_fnc_compatCollect [names, args] -> ARRAY`.** Calls every function
  of the list that exists - the addon of a mod that is loaded - with the same arguments and joins what the
  arrays they return hold. The window never names another mod's function; it asks `[QEFUNC(compat_tfar,x),
  QEFUNC(compat_acre,x)]`, and TFAR and ACRE2, which never load together, answer. A CBA option that a compat
  addon replaces is not asked this way: `fnc_cbaOptions` keeps one guarded line per hider (kits, magazines,
  ACRE2), each answering a BOOL.
- **`einv_gui_fnc_stepAside [code, args]`.** For a mod's dialog that does not open over another dialog (TFAR
  and ACRE2 refuse while any dialog is open): the window closes, the code runs `STEP_ASIDE_DELAY` (0.2 s,
  as long as TFAR's own radio menu waits) later, and the window opens again on the same unit, container and
  second container once that dialog is closed - or at once when the code opened none. The window opens
  fresh: uniforms, vests and backpacks opened from inside a container and the kits' windows are closed again.
- **ACE cargo (`compat_ace_cargo`).**
  - *The section.* `fnc_getSections [lootSections]` adds, right under every container section of the loot
    column that has things loaded (`ace_cargo_loaded`, objects and class names), a section `id "cargo"`, titled
    with ACE's word for it, with `vehicle` (the holder), `parent` (the same, so the storage's ordering keeps it
    right under the vehicle, before the crates opened from it), `items` (a copy of the loaded list) and
    `drawer` (the name of its drawing function). Nothing while `ace_cargo_enable` is off; a locked container
    has no `container` any more and so no cargo. A crate that was opened from cargo is shown as a crate:
    `class` empty, ACE's name for it (custom name included) as the title.
  - *The cards* (`fnc_drawSection`, called by `fnc_drawSection` of gui for the `drawer` key with the same six
    arguments): a caption "CARGO" with the space used and in all (a tooltip says what the numbers are), then
    a card per thing in ACE's order: the editor picture on its grey (the crate icon where there is none), the
    name as ACE has it (in the loss colour when ACE cannot unload it at all), size and damage, and two buttons,
    Open or Close and Unload. The cards lie in the same block as the sections above them (same cell, width and
    left edge) and hold no grid - nothing to hover, drag onto or right-click. What a click needs is kept per
    build (`uiNamespace`); the buttons run a frame later.
  - *What a button may do* (`fnc_rowState [holder, item, unit]`): the first rule that applies decides, for Open
    and for Unload on their own. Open: the vehicle is locked (`locked >= 2`), the thing is a class name ACE has
    not made yet ("Packed away - unload it to look inside"), it has no inventory or is destroyed, or the crate is
    locked to the player (`einv_locks_fnc_canReach`, which says why). Unload: the vehicle is locked, ACE cannot
    unload that size, the vehicle is in the air (airdrops stay with ACE's own menu), the player is not within
    ACE's reach (5 m, `ace_interaction_fnc_getInteractionDistance`), or another unloading is under way. A
    button that may not act is drawn muted, says why in its tooltip and in the hint when pressed. A locked
    crate may be unloaded - a lock is about what is inside.
  - *Open / Close* (`fnc_toggleOpen`): the crate goes into the window's `opened` list as `[class, crate,
    vehicle]` and `einv_compat_ace_cargo_openedFrom` (local) is set on it; it then shows as a loot section
    like any crate - a loaded object keeps its own cargo, so it can be looked into and changed while it hangs in
    the vehicle - searched as its vehicle is, moved into and out of through the transactions like any crate
    (the root of a crate is itself; `einv_storage_fnc_inReach` measures to what it is attached under).
    `fnc_pruneOpened` drops it from the list at the next build once it is no longer in that vehicle's cargo,
    whoever unloaded it.
  - *Unloading* (`fnc_startUnload`, `fnc_unloadFrame`, `fnc_stopUnload`, `fnc_finishUnload`): ACE's own progress
    bar is not used - it closes every dialog first, which would close this window. The Unload button becomes a
    bar over the time ACE takes (`ace_cargo_fnc_getDelayItem`, else `ace_cargo_loadTimeCoefficient` times the
    size), kept up by a per-frame handler that applies ACE's own condition
    (`ace_cargo_fnc_canUnloadItem [item, vehicle, unit, false, true]`, without the search for a free place every
    frame) and stops quietly when the window is gone. One unloading at a time (`GVAR(unloading)`); a click on
    the bar stops it. At the end `ace_cargo_fnc_unloadItem` runs - the call ACE's menu ends in, so the place,
    Zeus's lists, a UAV's crew, the event `ace_cargoUnloaded` and ACE's carry after unloading are ACE's. The card
    is gone, ACE's "Unloaded ... from ..." text shows in the hint (`einv_gui_fnc_showHint`), and when ACE has the
    player carry or drag it now (`ace_cargo_carryAfterUnload` on, ACE dragging loaded, the thing not blocking it)
    the window closes, as ACE's menu closed before the carry started.
  - *Signature*: `fnc_signature` (what is loaded in everything the window looks into, and the unloading) is a
    part of `einv_gui_fnc_getSignature`'s `list`, so someone else loading or unloading redraws the cards.
  - Sounds: opening a crate and starting an unloading sound as the crate opened, the end as it lands.
- **Radios (`compat_tfar`, `compat_acre`).** The same function names in both, asked through `fnc_compatCollect`
  by the window: `fnc_tooltip [class, holder]` (texts joined after the name at the mouse, "AN/PRC-152 · Ch 3 ·
  152.6 MHz"), `fnc_hintParts` (channel and frequency, TFAR's alternate channel, "Active radio", "Switched off"),
  `fnc_inspectRows` (Channel, Frequency, Alternate, State), `fnc_menuChoices [class, holder, own, inSlot]`
  ("Open radio", "Use as active radio"), `fnc_open`, `fnc_makeActive`. `holder` is the long-range backpack's
  container object; `own` means the radio lies in the player's own uniform, vest or backpack, or the slot is
  the player's.
  - Everything is read-only from the mods' data. TFAR's `getSwSettings` writes default settings for a radio
    that has none, so the settings are read raw from `TFAR_RadioSettingsNamespace` (a long-range radio's from
    the backpack's variable `radio_settings`); ACRE2's data comes from `acre_sys_data_fnc_dataEvent` and only for a
    radio ACRE2 has set up. A prototype (TFAR) or base radio (ACRE2) says "Set up once someone carries it".
  - *Open radio* is the answer to "opening a TFAR radio from the inventory does not work": TFAR (and ACRE2)
    refuse to open a dialog while another one is open, so the window steps aside first (`fnc_stepAside`),
    TFAR gets `TF_sw_dialog_radio` / `TF_lr_dialog_radio` and its own `TFAR_fnc_onSwDialogOpen` /
    `TFAR_fnc_onLrDialogOpen` exactly as its own menus do, ACRE2 gets `acre_sys_gui_fnc_openRadio`. When the dialog is
    closed the window comes back. Only for the player's own radios: the radio slot, the uniform, vest and
    backpack, and the long-range radio of the backpack worn.
  - *Use as active radio* is the mod's own call (`TFAR_fnc_setActiveSwRadio`, `acre_api_fnc_setCurrentRadio`) and
    asks the window to look again (`einv_gui_fnc_requestRebuild`); where the radios lie afterwards is healed by
    the window's normal drift report.
  - *TFAR long-range settings survive moves.* TFAR keeps them on the backpack object, and the storage makes a new
    container object on every move. `einv_storage_carryVariables` is a list of variable names a container
    carries on its own object (`compat_tfar` adds `"radio_settings"` in preInit); `fnc_snapshot` reads those
    that are set into the snapshot's seventh element `[[name, value], ...]`, `fnc_restore` sets them, public, on
    the new object right after the container is cleared, whatever else goes wrong.
  - *ACRE2's dummy radio.* ACRE2 keeps `ItemRadioAcreFlagged` in the radio slot for the game's text chat and
    hides the slot in the vanilla inventory. With `compat_acre` that slot is fixed
    (`einv_compat_acre_fnc_isFixedSlot [unit, slot]`): it cannot be lifted (`fnc_startDrag`), taken off or
    dropped (`fnc_doUnequip`), it accepts nothing (`einv_storage_fnc_slotAccepts`, the one gate every equip path
    asks), its menu has Inspect only, its hint says "ACRE2 keeps this slot - radios go in your storage", and a
    guard in `einv_storage_guards` (`einv_compat_acre_fnc_guard`) answers `"Failed"` to `takeOff` and `putOn` of
    that slot for any transaction. ACRE2's own "Open" of the CBA item menu is left out of the window's menu on
    its radios (`einv_compat_acre_fnc_hideCbaOption`).
- **Refusals** (`fnc_flashHint [reason, details = []]`): `"Locked"` (`STR_einv_locks_Hint_Locked`) and
  `"NoBackpack"` are reasons of their own; `"TooHeavy"` with `[container, entry, count]` says how much is missing
  (`fnc_weightText`). `fnc_sendMoves` keeps those details per move in the in-flight record's fifth element
  (parallel to the records, `[]` for the kinds that carry no weight question).
- **Known limits.**
  - Locks: see "Locks" above. Not new here: the engine's "Rearm" scroll action may not respect `lockInventory`.
  - ACE cargo: no airdrop from the window (the pilot's ACE cargo menu does that); two players unloading the
    same thing at once is ACE's own race; the unload bar belongs to one window - it stops when the window closes.
  - Radios open only when the player carries them; the window comes back fresh after the radio's dialog (opened
    uniforms, vests and backpacks, kit windows closed); the settings of a radio in a crate show only once TFAR or
    ACRE2 has set them up (that happens when somebody carries it; the window never creates them).
  - "Use as active radio" is the mod's own swap on the player's gear, not a transaction of ours; it is local to the
    player's machine like the radio slot itself.
  - Built and checked in code only: nothing of this has run in the game yet.

## Cells only (0.4.0) - supersedes the parts above it contradicts

Weight limits no container any more: free cells are the only limit on what goes into a uniform, vest, backpack,
crate, vehicle or pile. The soldier's own weight (bar, tiers, ACE fatigue, the `weight` addon) is untouched.

- **Removed functions:** `einv_storage_fnc_roomByWeight`, `fnc_getLoadState`, and in gui `fnc_markWeight` /
  `fnc_clearWeightMarks` (the weight card's preview lives on as `fnc_previewWeight` / `fnc_clearWeightPreview`;
  `fnc_weightText` keeps only the soldier's "+2.4 kg: you will be Overloaded", `fnc_loadText` only "12.4 kg").
- **Removed setting and macros:** `einv_storage_gridOnly` ("Limit by room only", also the setup's Start line),
  `FULL_SHARE`, `FULL_FREE_MASS`, `NEAR_FULL`, `LOAD_BAR_H`, the theme colours `cellFull` and `cellBlocked`.
- **Removed section key and records:** `"maxLoad"` of every section, a kit's `"loadFraction"`, uiNamespace `loadBars`
  (no load bar, "full" chip or red free cells), the in-flight record's fifth element, the plan's fifth element
  (partial counts) and `GVAR(pendingHint)`. The reason `"TooHeavy"` and its hint strings are gone.
- **Now:** `fnc_hasRoom [container, entry]` is `fnc_hasSpace` plus the one kind rule left,
  `fnc_backpackIntoBackpack` (`"NoBackpack"`); a move with no cell given needs a free spot (`"NoRoom"`).
- **Stays:** `fnc_getMaxLoad` (config `maximumLoad`) as a sizing heuristic only - `fnc_blocksFor` sizes the "auto",
  "percent" and "pattern" default grids from it, it never limits anything. The items' `maxLoad` fact and the `load`
  selector key stay as a size proxy, as do the engine `maxLoad` asks (`canOpenPerson`, ACE cargo, ZEN).
- Built and checked in code only: nothing of this has run in the game yet.

## ACE Arsenal panel (0.4.0) - supersedes the parts above it contradicts

The own arsenal window is gone (display, catalog, hand-over of ACE's display, loadouts, camera, the
`[Enhanced Arsenal]` button, the Eden menu entry, `einv_arsenal_window`, `quickAddAmount`, `confirmUnique`,
`einv_arsenal_opened` / `closed`, compat_efak's `arsenalEditing` / `packNew` / `onGivenBack`). ACE Arsenal is the
arsenal; nothing of ACE is patched. While the uniform, vest or backpack tab of ACE's left bar is open (and the
unit wears it), a panel right beside ACE's list (IDC 15) shows that one container's grid.

- **Engine attached, as a guest.** `einv_gui_fnc_attach` runs on ACE's display a frame after
  `ace_arsenal_displayOpened` (driver `"draw3d"`, so Eden too). Two engine changes made that possible: the flag
  hook `guest` (the build sweeps only what it registered, mouse handlers go only on its own groups, the
  display's handlers never answer "taken") and the hook `footer` (replaces `fnc_drawFooter`, like `header`).
  Hook table (`fnc_hooks`): `guest`, `header` (none), `layout` (`fnc_layout`: `fnc_drawColumn` with the one
  section, `einv_gui_fnc_drawSection`, column id "storage", always unfolded; ACE's list registered as the zone
  "remove"), `footer` (`fnc_footer`: a two-line hint strip under the grid), `camera` (none), `keepOpen` (true),
  `frame`, `mouseDown` / `mouseUp` (`fnc_onMouse`: outside the panel taken, so the engine ignores it), `click`
  (double, Ctrl and Alt clicks swallowed - no equip or quick move past ACE), `dragCheck` (ground or zone ->
  the remove zone in the loss colour), `drop`, `ground` (both -> `fnc_remove`), `menu` (Remove, Remove all of
  this kind), `hint` (the idle line).
- **Geometry** (`fnc_panelRect`): top of ACE's list, bottom at the list's or above ACE's message line (IDC 9),
  whichever is higher; width STORAGE_COLS cells of `einv_gui_fnc_getCell` plus the column's padding and scroll bar,
  at most a third of the screen; the column scrolls when taller.
- **Keys:** a second KeyDown handler on ACE's display (`fnc_onKey`) hands the engine only R while dragging and
  Delete over the panel, never while one of ACE's fields has the cursor. ACE's own handler runs untouched.
- **Mouse:** a press on the panel empties `ace_arsenal_mouseButtonState` (at once and a frame later), and the
  frame hook keeps it empty while the engine holds something, so ACE's camera does not pan or turn. A button let
  go where no display event reached the engine ends the drag in the frame hook (`inputMouse 0`).

Events (all registered in preInit, so Eden has them):

| Event | Does |
|---|---|
| `ace_arsenal_displayOpened` | `fnc_onOpened`: state reset, KeyDown and list LBSelChanged handlers, attach a frame later (one more frame if the inventory is still closing) |
| `ace_arsenal_displayClosed` | `fnc_onClosed`: `einv_gui_fnc_onUnload`, state reset, BI helper deleted, `fnc_reportOverflow` a frame later (not Eden) |
| `ace_arsenal_cargoChanged` | `fnc_onCargoChanged`: what of an add did not land (engine refused by `maximumLoad`) is put in with `einv_storage_fnc_addNew` while there is a free spot; flags the frame-later pass |
| `ace_arsenal_itemsChanged` | `fnc_onItemsChanged`: for the open container's tab `fnc_reconcile` at once (before ACE greys its list) |
| `leftPanelFilled`, `rightPanelFilled`, `loadoutImported`, `onLoadoutLoad`, `showToggle` | `fnc_settle` a frame later |

- **Add path.** `fnc_snapshot` normalizes the container's places (`einv_storage_fnc_normalize`) and notes its
  counts by class, so after an add every old tile keeps its record and only the new things are laid out
  first-fit. `fnc_reconcile`: gains against the snapshot; overflow entries of a gained class are taken back
  out (`einv_storage_fnc_removeEntry`, at most the gained count), "No room in the vest - move things to free a
  1x2 space" in ACE's message line and the hint strip (`fnc_sayNoRoom`), ACE told with
  `ace_arsenal_fnc_fireItemsChangedEvent` (`fnc_tellAce`; without it the follow-up is called directly). An ACE
  without `itemsChanged` gets the same follow-up in the frame-later pass.
- **Remove path.** Drop outside the panel, Delete, or the menu: `fnc_remove` (the record first when the whole
  tile goes, then `removeEntry` with the dragged count) or `fnc_removeKind`; sound "giveBack" (UI only), then
  `fnc_tellAce`. A move inside the panel is the engine's normal place move (and stacking).
- **Frame-later pass** (`fnc_settle`, once a frame): fallback follow-up, snapshot, `fnc_syncAce` (row counts,
  load bar, `ace_arsenal_currentItems`, `ace_arsenal_fnc_updateRightPanel`), `fnc_ungrey` (rows ACE greyed by
  weight lit again where a stack has room or a spot of that size is free, one grid look per item size; the
  "+" of the picked row too, also on LBSelChanged), engine unit set to `ace_arsenal_center`, build - or after
  the drag if something is held.
- **Kept of the old arsenal:** the vanilla Virtual Arsenal handling (wrapper, `fnc_handleBIOpen`, safety net,
  red screen, mission hooks, leave-alone report) with `einv_arsenal_biArsenal` now `"ace"` (default, ACE Arsenal
  with the box's items on a local helper, `fnc_openBI`), `"block"`, `"vanilla"`; `einv_arsenal_biMessage`,
  `einv_arsenal_biPassThrough`; `fnc_isArsenalBox` (gui's `fnc_isSearched`), `fnc_canOpen` / `fnc_open` for the
  inventory's "Open Arsenal" (ACE's `openBox`, or BI's function for a vanilla box). Storage keeps `addNew`,
  `makePayload`, `countClass` and the loadout places (`CBA_loadoutGet` / `Set`), which ACE's loadouts carry.
- **Known limits.** Picking another uniform, vest or backpack in ACE's left list goes through `setUnitLoadout`:
  the containers are new objects and their arrangement starts first-fit. ACE Arsenal Extended's option panel
  stands where this panel does. Rows ACE leaves lit but the grid cannot take are not greyed (the add is taken
  back with the message). The undo is after the fact: other mods see ACE's add and then the removal. ACE
  internals read: IDCs 9, 15, 102, 701, `currentLeftPanel`, `currentItems`, `mouseButtonState`, the row alpha
  of `updateRightPanel`.
- Built and checked in code only: nothing of the panel has run in the game yet.

## Backpack slot (0.4.0) - supersedes the parts above it contradicts

The gear row of the player's equipment column is headgear | uniform | vest | backpack: the backpack item has a slot
of its own next to the vest, where it is put on, taken off or swapped. Its contents stay in the storage column.

- **Row:** `fnc_drawEquipmentCards` draws `backpack` (caption `STR_einv_gui_Slot_Backpack`, A3's `ui_gear_backpack_gs`
  like the other gear icons) as the fourth gear card. `_gearW` is `(width - 3 gaps) / 4`, still capped at 4.6 UNIT,
  and the cards spread over the width by `(width - _gearW) / 3`; a narrow column makes them a little smaller, the
  row never wraps. `_gearH` follows `_gearW`, so the height reservation (`_fixed`) is unchanged in form.
- **Same slot as uniform and vest, no special case:** one record (`slot` "backpack", `unit`), `SWAP_SLOTS` and the
  storage side (`slotFor`, `putOn`, `takeOff`, `unequip`) already knew it. Dropped on it a backpack goes on and the
  worn one goes where the dragged one lay (or settles, as with the vest); dragged off, the backpack leaves with
  its contents, never into itself or another backpack (`"IntoItself"`, `"NoBackpack"`); Ctrl+click and the menu's
  "Take off" are `fnc_quickUnequip`; hint, inspect and the long-range radio entries read the record as before.
- **Storage column:** the backpack section keeps its header and grid, and its box is still a slot record of the
  same id. The gear row is drawn first, so it is the first record the drag fallback over the column finds
  (`fnc_updateDrag`): a backpack let go anywhere there now lights the gear slot, also while none is worn (before,
  no slot existed then and the faint whole-column footprint showed). The loot bodies' doll is unchanged.
- Built and checked in code only: nothing of this has run in the game yet.

## Shaped grids and like= (0.4.0) - supersedes the parts above it contradicts

So a uniform, vest or backpack class can be given exactly the cells it has (the wizard's cell editor writes them).

- **Shaped compartments (`fnc_parseGrid`, `fnc_formatGrid`):** a piece of `grid=` (and of `einv_grid`) may be drawn
  instead of `WxH`: its rows from the top separated by `/`, `x` a cell, `-` a hole, every row as long as the first.
  `grid=xxxxxx/xx--xx/x----x` is one 6x3 compartment of 12 cells; `grid=xxxx/x--x+2x3` a 4x2 ring of 6 cells and a
  plain 2x3. A piece without digits is a shape, one with digits `WxH`. A shape is read to its smallest form (edge
  rows and columns of holes go); one with no hole left is written `WxH`, so the writer only draws what has holes.
  `/` was already a legal character; a row is never empty, so `//` (a comment in a `cba_settings.sqf`) never
  occurs. Limits as before, holes not counted: 8 across, 40 down, 24 compartments, 320 cells; a shape with no `x`,
  rows of different lengths or other characters are errors like any value that cannot be read. `pockets`/`rig`
  patterns and the older container table are rectangles only.
- **Shape everyone reads:** `fnc_blocksFor` (and so `fnc_getBlocks`, `fnc_getLayout` "blocks", `fnc_viewBlocks`)
  give `[[cols, rows, holes], ...]`, holes the cell indices `row * cols + col`, `[]` for a full rectangle;
  `[cols, rows]` from `einv_grids[]` or the old table is padded. Readers with `params ["_cols", "_rows"]` work as
  they did. Holes are taken from the start: `einv_storage_fnc_seedTaken` builds the taken-rows of `fnc_getLayout`,
  `fnc_plan`, `fnc_opPut` and `fnc_opPlaceMany` (so `fnc_hasSpace`, `fnc_findEntry`, quick moves and the authority
  never put anything on or across one). Cell counts subtract holes (`fnc_parseGrid`, `fnc_viewBlocks`' hidden
  cells, the gear comparison's room). gui: `fnc_createGrid` makes no control for a hole (`controlNull` in
  `"cells"`, `"holes"` on the grid); `fnc_drawCompartments` draws a shaped compartment's lines slot by slot,
  each pixel once, so a hole has neither surface nor line; `fnc_screenToCell` finds no cell on a hole (nothing to
  hover or click), except for a drag, whose footprint goes red over one (`fnc_hitsHole` in `fnc_updateDrag` and
  `fnc_groupMode`); `fnc_redrawTiles` compares the holes too.
- **like=CLASS (`fnc_parseRules`, `fnc_compileRules`, `fnc_resolve`):** a value key, written first (`like`, size,
  stack, grid, weight, name); its value is a class token like `class=` (letters, digits, `_`), compiled lowercase.
  `class=My_Vest > like=V_PlateCarrier1_rgr grid=6x4`: when the rule matches, every field of `LIKE_FIELDS`
  (footprint, stack, grid, weight - never name) still open and not set by the rule itself takes what `fnc_resolve`
  makes of the source class right then, through the same compiled rules - its own rules, mod config and presets. The
  source's grid is turned into the compartments it really has (`einv_storage_fnc_blocksFor` with its class, kind and
  load, as `["blocks", ...]`; "auto" by the target's load would be another grid; a source that is no container gives
  "auto"); its weight only when a rule sets one on it, else -1: the target keeps its own config weight. The resolve
  order is otherwise unchanged: a higher rule still wins a field, and the like rule closes the fields it fills. A
  circle, more than `LIKE_DEPTH` (8) like= one after the other, or a class no config knows gives the built-in answer
  for those fields (src "builtin") and one RPT line per problem (`GVAR(likeWarned)`). `fnc_explain` and byKind count
  `LIKE_FIELDS` as set by such a rule. The wizard says "like V_PlateCarrier1_rgr", "4×2 shaped, 6 cells".
- **Caching:** `fnc_getInfo` keeps an answer per class until the rules change; any change, the source's included,
  is a new compile and `fnc_loadRules` empties the whole store - nothing more to do.
- Built and checked in code only: nothing of this has run in the game yet.

## Wizard: Containers and Items steps (0.4.0) - supersedes the parts above it contradicts

Steps 3 (`items`, `fnc_drawItems`) and 4 (`containers`, `fnc_drawContainers`) are built; Groups is still greyed out.
Both are a class list on the left (`fnc_drawClassList`, cards by `fnc_drawResults`) and an editor on the right
(`fnc_drawItemEditor`, `fnc_drawCellEditor`). The design's virtual list, apply scopes, CfgEinvShapes and preview fills
were not built: one class at a time, one rule per class.

- **Class index (`fnc_buildIndex`, `fnc_indexChunk`):** uiNamespace `einv_setup_index` (HashMap: `rows`, `byClass`,
  `mods`, reading position, `token`, `tick`, `done`), built once per game session - classes do not change, and it stays
  out of save games. Read in pieces through `fnc_defer` (Eden too), each until `INDEX_BUDGET` (6 ms) has passed, the
  clock looked at every `INDEX_STRIDE` (64) entries; a run not seen for 1 s (the window closed and its queue was
  emptied) is taken over by the next step that asks, the token keeps one reader. Roots as getFacts: CfgWeapons types
  1/2/4/4096 and 131072 items (uniform 801, vest 701, headgear 605, attachments, rest), CfgMagazines with a picture,
  CfgGlasses, CfgVehicles with `maximumLoad > 0` (backpacks, `ReammoBox_F` crates, `AllVehicles` but not `CAManBase`);
  scope 2 only, no `..._Base`, the first root wins a name. Row (`ROW_*`, defines.hpp): lowercase class, configName,
  search text (class + name, lowercase), displayName, kind, family (weapon, magazine, gear, item, cargo), picture,
  mod name (`configSourceMod` -> `modParams`), load (a uniform's or vest's from its containerClass). Sorted by name when
  done. Vanilla with ACE is some thousands of rows; big mod packs tens of thousands - a progress line meanwhile.
- **List:** search (substring, case-insensitive over class and name, redrawn 0.15 s after the last key, the field keeps
  focus), kind chips (Containers: all / uniform / vest / backpack / cargo; Items: all / weapon / magazine / gear /
  item), "only classes with own rules" (any `class=` an own rule names, `fnc_ownClassRules`), pages of `LIST_PAGE`
  (30). Only the cards shown ask `einv_items_fnc_getInfo [class, draftRules, draftCache]` - the compiled draft Review
  uses - and say it with `fnc_answerText` ("6x4, 2 holes · own rule", "3 × 1x2 · preset", "like X"). State per step in
  `einv_setup_listState` `[text, chip, ownOnly, page]`; the class picked in `einv_setup_selection` ("items",
  "containers"); a class from `fnc_open`'s focus is picked and searched. Ctrl+F focuses the search.
- **Cell editor:** shows `einv_storage_fnc_blocksFor` of the draft's answer (patterns, auto and cells as the
  compartments they give - "Editing replaces the pattern with these cells"). Working copy `einv_setup_cellWork`
  (lowercase class -> `[blocks, picked]`), created by the first edit; a cell click toggles the hole in place (control and
  total updated, no redraw) unless it is the first change or another compartment; steppers 1-8 across, 1-40 down
  (holes outside the new size go), add (2x2, 1x1 when little room) and remove. The canvases never hold more places
  than `MAX_CELLS`; the total line shows cells against 320 and compartments against 24. Apply drops compartments
  without a cell and writes `grid=` with `einv_items_fnc_formatGrid` (shapes for holes, `WxH` otherwise; the parser
  trims edge rows and columns of holes). "Like another class" puts the list in picking mode (`einv_setup_likePick`); the
  pick writes `like=Y` and takes the class's own `grid=` away. Linked (like without own grid) the canvases are
  read-only until Unlink (takes `like` away). Back to the preset takes `grid` and `like` away.
- **Items editor:** width 1-8, height 1-8, stack 1-999 (stepper plus 1/5/10/20/50/100), stack off for kinds that never
  share a tile (src "forced"); working copy `einv_setup_itemWork`. Apply writes only what differs from now
  (`size=WxH`, `stack=N`); Back to the preset takes `footprint` and `stack` away.
- **Writing (`fnc_upsertRule [class, set, remove]`):** reads the draft text, merges every rule whose only condition is
  `class=X` (not `X+`, case-insensitive) into one, sets and removes the fields given, keeps the rest (name, weight,
  like), appends it as `class=X > ...` at the end - later rules win, so it beats a broader rule further down - and drops
  it when empty; then `fnc_commit` (undo step, redraw). Class names outside letters, digits and `_` are refused with a
  hint. Nothing reaches the game before Save. An older table setting still wins over the rules; the editor says so.
- Also fixed: the "changed" dot of the step pills sat on Groups instead of Start.
- Built and checked in code only: nothing of this has run in the game yet.
