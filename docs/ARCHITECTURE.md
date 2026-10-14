# Enhanced Inventory - architecture

This is the contract every file of the mod is written against, as the mod is on this branch (version 0.4.0). Function names,
arguments, HashMap keys and settings named here are binding: several people (and agents) write different files at the same time
and only meet through these interfaces. If something turns out wrong, fix it here and in the code together. How the mod got here
is the dated build log `docs/HISTORY.md`; this file describes only what is true now. `docs/BRIEFING.md` has the goal and the first
plan; the plan behind the rules engine and the wizard is `docs/design/design_synthesis.md` with the corrections in
`docs/design/design_critic.md`.

## 1. Overview

### What the mod is

Enhanced Inventory replaces the vanilla inventory (`RscDisplayInventory`) with a window of its own, built at run time from
controls: nothing is patched into the vanilla display, and the vanilla inventory stays only as the fallback (setting
`einv_gui_replaceVanilla`, `einv_gui_fnc_openVanilla`).

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
  `einv_items_rules`, built on a preset (section 2); **a setup wizard** edits that text without writing it by hand (section 6).
- **The ACE Arsenal panel.** There is no arsenal window of our own: while the uniform, vest or backpack tab of ACE Arsenal's left
  bar is open, the same window engine draws that container's grid and a staging space beside ACE's list (section 5).
- **Multiplayer by authority.** Every change to a container is a transaction run by the machine where that container's root is
  local; the server is the hub between machines (section 3).

CBA_A3 and ACE3 are hard requirements. Everything else (Enhanced First Aid Kits and Enhanced Utility Pouches, ACE cargo, ACE
vehicle lock, ACE magazine repack, TFAR, ACRE2, Zeus Enhanced) is optional: its addon is skipped when the mod is missing
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
  Arsenal box, a vehicle, a body, loot on the ground); `tools/generate_ui_textures.py` draws `addons/gui/ui/`.

### Addons

| Addon | Does |
|---|---|
| `main` | version, macros and the shared defines of `script_macros.hpp`. |
| `items` | what an item is (`einv_items_fnc_getInfo`) and the rules engine behind it: text, presets, compile, resolve. |
| `storage` | what a container holds and where it lies; what a unit wears; the transactions, hub, places sync and loadouts that change anything. |
| `gui` | the window: engine, Glass theme, layout, tiles, drag, menus, searching, sounds, looting pose, people, CBA item menu, kit windows. |
| `weight` | the soldier's load: `weight=` overrides into ACE's virtual load, the tiers Light, Heavy, Overloaded, Critical and their effects. |
| `locks` | who may open a crate or vehicle: one side, one group or the admins; the engine lock per client and the guard on every op. |
| `setup` | the setup wizard and its entry points. |
| `arsenal` | the grid panel on ACE Arsenal's display and the handling of the vanilla Virtual Arsenal. |
| `hotbar` | seven keys, 4 to 0, that use what lies on them; the HUD bar and the window's hotbar row. |
| `magazines` | repacking partly filled magazines in the window (needs `ace_magazinerepack`). |
| `compat_efak` | Enhanced First Aid Kits and Enhanced Utility Pouches: kits as floating windows, packing by drag and drop. |
| `compat_ace_cargo` | what ACE cargo has loaded in a vehicle or crate, as a "Cargo" section with Open and Unload. |
| `compat_ace_vehiclelock` | ACE's vehicle lock as one more lock of ours. |
| `compat_zen` | Zeus Enhanced: the "Inventory lock" menu and module. |
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
groups, rules, and a rule's values in the order `like`, `size`, `stack`, `grid`, `weight`, `name`. Read and written again, a text
stays the same, so two setups that mean the same compare as texts.

| Statement | Example | |
|---|---|---|
| header | `einv1 base=default cell=5` | only as the first statement. `base=` a preset id or `none`; `cell=` config mass per grid cell, 1 to 50, two decimals. No header reads as `einv1 base=default`; a newer `einvN` warns and reads what it can. |
| group | `@rifle_mags: kind=magazine mass<=20` | an id of `a-z 0-9 _`. The same id twice in one layer means either. An own group replaces the preset's group of that name; `@itself` inside it means the preset's definition (`@mag_rifle: @mag_rifle` then `@mag_rifle: class=X+` adds X). A definition that does not hold up (unknown group, a loop, deeper than `MAX_GROUP_DEPTH` 4) is left out and the one below counts again. |
| rule | `kind=grenade > stack=3` | conditions, then what it sets; the `>` only reads better. No condition means every item. A later rule beats an earlier one, field by field. |

Conditions - all must hold; `|` means either, `!` in front means not; at most `MAX_ALTERNATIVES` 64 choices:

| Condition | |
|---|---|
| `kind=rifle\|handgun` | the kinds of `fnc_getFacts`: `rifle`, `handgun`, `launcher`, `binocular`, `muzzle`, `optic`, `rail`, `bipod`, `headgear`, `nvg`, `vest`, `uniform`, `map`, `gps`, `radio`, `compass`, `watch`, `item`, `magazine`, `grenade`, `backpack`, `goggles`, `vehicle`, `crate`, `unknown`. |
| `cat=medical` | `misc`, `gear`, `weapon`, `ammo`, `medical` (`CATEGORY_NAMES`). |
| `class=X`, `class=X+`, `class~abc` | that class; X and every class built on it (any mod's); a part of the class name, `MIN_SEARCH` 3 letters at least. Class case is kept in the text and matched in lowercase. |
| `addon=x`, `addon~abc` | the CfgPatches class that brought it in. |
| `well=X` | a magazine of that magazine well. |
| `for=X` | a magazine the weapon X loads. |
| `mass<=20`, `rounds>=50`, `load>160` | config mass, a CfgMagazines count, a container's maximumLoad (the size proxy); `=`, `<`, `<=`, `>`, `>=`. |
| `@group`, `@a\|@b` | a member of that group. |

Values - what a rule sets. `like` is written first, the others in any order:

| Value | |
|---|---|
| `like=CLASS` | everything the rules make of that class but its name; see "like=" below. A class token: letters, digits, `_`. |
| `size=2x3` (alias `shape=`) | the footprint, across and down, at most `STORAGE_COLS` and `MAX_ROWS` when read (cut with a warning). `size=mass`: as many cells as it weighs (the rules' weight if set) per cell - rifles and launchers two rows high, everything else near square. `size=xx/x-` is a mask: rows from the top split by `/`, `x` a cell, `-` a hole, so `xx/x-` is an L of three cells in a 2x2 box. A value of only `x`, `-`, `/` is a mask, any other made of letters, digits, `/` and `@` is a named shape, which is not read (warned, the rest of the rule kept). A mask is one block (no `+`, no letters), at most `SHAPE_MAX` 8 each way (a larger one keeps its top left 8x8, with a note), at least one cell, read to its smallest form (edge rows and columns of holes go) and written back the shortest way (`size=xx/xx` comes back `2x2`). Whatever the rule says, the resolved footprint is cut to `SHAPE_MAX` each way: the wizard draws an item on a board that size. |
| `stack=10` | 1 to `MAX_STACK` 999. |
| `grid=...` | containers only, see below. |
| `weight=1.25` | the item's weight in kg instead of config's: digits and one dot, rounded to the gram, at most `MAX_WEIGHT` 1000. |
| `name=Field_kit` | the name it shows, at most `MAX_NAME` 100 characters: `_` is a space and `%5F` an underscore; letters, digits, `-` and `.` stand as they are, every other character is `%XX` per UTF-8 byte (`Field kit (3)` is `Field_kit_%283%29`). `fnc_encodeName` writes it, `fnc_decodeName` reads it. |

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

What may stand in a statement: letters, digits, space, tab and `_ + . / % : | @ ! < > = ~ -`. Never a `;`, a quote, `#` or a
backslash: CBA's export, import and every `cba_settings.sqf` split lines at `;`, and the preprocessor reads the others. The
EDITBOXes (rules and the three tables) use `einv_items_fnc_sanitizeText` as CBA's sanitizer, which turns `;` and line breaks into
commas and drops quotes, `#` and backslashes as they are typed.

Left out, each with a warning that names it (RPT on load, the wizard's Review): a statement with any other character, an unknown
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
| `CELL_MIN`, `CELL_MAX` | 1, 50 | the header's `cell=` and the slider |
| `PERCENT_MIN`, `PERCENT_MAX` | 10, 500 | `grid=120%` |
| `MAX_STATEMENTS`, `TEXT_MAX` | 500, 16384 | statements and characters of a text |
| `MAX_GROUP_DEPTH`, `MAX_CHAIN`, `LIKE_DEPTH` | 4, 4, 8 | groups in groups, presets on presets, `like=` after `like=` |

A value past a limit is cut down to it and said so; one that cannot be read is left out. The window makes a control per cell,
which is why a typo in a rule must not build tens of thousands of them.

### Which answer wins (`fnc_resolve`)

Each field - footprint, stack, grid, weight, name - goes to the first layer that has an answer, highest first:

1. **forced** - rifles, handguns, launchers, binoculars, uniforms, vests and backpacks always stack 1 (`KINDS_SINGLE`), whatever
   any rule says: each carries attachments or contents of its own, and a tile moves only one of them.
2. **the older tables** - `einv_items_sizeTable`, `einv_items_stackTable`, `einv_storage_containerTable`, compiled as `class=X+`
   rules appended after the text's own, each table sorted shallow-first (fewest parents first) so the nearest class listed wins.
   They sit in the same layer as the text but come after it, so a table beats the text.
3. **the own text** - `einv_items_rules`, a later rule before an earlier one.
4. **the item's mod config** - `einv_gridSize[]`, `einv_stackSize`, `einv_grids[]`, then `einv_slots`. Grids and slots from config
   stay within the limits above.
5. **the preset chain** - `base=` and its own bases, up to `MAX_CHAIN` deep, a derived preset's rules before its base's, a later
   rule before an earlier one. `einv_items_stackSmall`, when moved off its default 10, is this layer's last word on `@item_small`:
   it beats the preset's stacks, not a rule or a mod.
6. **builtin** - 1x1, stack 1, `grid=auto`, config weight, config name.

Only the rules that can be about the item's kind are asked (`fnc_compileRules` sorts them by kind), and a layer is left as soon as
nothing it could still set is open. Afterwards `size=mass` becomes cells, stacks become whole numbers of at least 1, the footprint
is cut to `SHAPE_MAX`, and non-containers get no grid. `fnc_explain [class, compiled]` lists every layer that has a say, highest
first, with what it sets and wins (for the debug console; the wizard words the answer and its source with
`einv_setup_fnc_answerText`). The `src` tags are `own:<i>`, `legacy:<setting>:<i>`, `mod:<config key>`, `preset:<id>:<i>`,
`builtin` and `forced`.

For a container **object** (`einv_storage_fnc_getBlocks`), its own `einv_grid` beats all of these for its compartments (section
3). Mass per grid cell: the header's `cell=`, else the nearest preset in the chain with a `cell` over 0, else the slider
`einv_items_massPerCell` (default 5); clamped to 1 to 50.

### like=CLASS

`class=My_Vest > like=V_PlateCarrier1_rgr grid=6x4`: when the rule matches, every field of `LIKE_FIELDS` (footprint, stack, grid,
weight - never the name) that is still open and not set by the rule itself takes what `fnc_resolve` makes of the source class
right then, through the same compiled rules (its own rules, mod config and presets). A later change to the source follows. The
source's grid becomes the compartments it really has (`einv_storage_fnc_blocksFor` with its class, kind and load, as `["blocks",
...]` - "auto" by the target's load would be another grid); a source that is no container gives "auto". Its weight is taken only
when a rule sets one on it, else -1 and the target keeps its own config weight. A higher rule still wins a field, and the like
rule closes the fields it fills. A circle, more than `LIKE_DEPTH` 8 like= one after the other, or a class no config knows gives
the built-in answer for those fields (src `builtin`) and one RPT line per problem (`einv_items_likeWarned`). `fnc_explain` counts
`LIKE_FIELDS` as set by such a rule.

### Presets

A preset is a class of `CfgEinvRulesets` with `name`, `description`, `revision` (shown only; `base=` always means the preset as
installed), `base`, `cell` (-1 to leave it to its base or the slider), `rules[]` (statements of the same language, one per
element, no commas) and `class Groups` (the wizard's rows). The group ids are what own rules refer to and a preset's id is what a
text names in `base=`: never rename one. Other mods may add presets as classes there.

- **`default`** (revision 2): relaxed. The mod's classic sizes and stacks - rifles 3x2 to 6x2 by mass, handguns 2x1, launchers
  6x2, magazines 1x1, 1x2 or 2x2 by mass, belts 2x2, rockets 1x3 and 2x3, grenades 1x1 stack 5, small items 1x1 stack 10 - and
  uniforms `grid=120%`, vests `grid=120%`, the three backpack groups `grid=120%` (by load up to 160, up to 280, above), crates and
  vehicles `grid=auto`. The groups are a partition (an item is in at most one, `medical` excepted, which is only a handle for the
  wizard), so a rule for one never reaches into another.
- **`realism`** (revision 2, built on `default`): longer rifles by one column, uniforms `grid=pockets:4`, vests `grid=rig`, fixed
  backpack grids (`4x5`, `5x6`, `6x7`) with larger tiles, stacks as in `default`.
- **`weight`** (revision 2, built on `default`, `cell=4`): `size=mass`, so every item takes as many cells as it weighs, containers
  back to `grid=auto` so a full grid is a full load, grenades, small items and small magazines stack 10.
- **`tarkov` is an alias for `realism`.** `PRESET_ALIASES` maps `base=tarkov` to `realism` in `fnc_parseRules` (one RPT line,
  `einv_items_aliasWarned`) and in `fnc_compileRules`' chain (another mod's preset built on the old id), unless a preset of the
  old name exists.

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
| `grid` | ARRAY | containers: the grid spec (`fnc_parseGrid`: `["auto"]`, `["cells", N]`, `["percent", P]`, `["pattern", name, N]`, `["blocks", [[cols, rows, holes, pos], ...]]`), `[]` for anything else |
| `src` | HashMap | field -> where it came from |
| `configMass`, `configDisplayName`, `configShort` | | config's values, whatever the rules say |
| `weightOverride`, `nameOverride` | NUMBER, STRING | the rules' weight in kg (-1 for none), the rules' name ("" for none) |
| `lc`, `root`, `rounds`, `lineage`, `addon`, `mod` | | from `fnc_getFacts`: lowercase class, config root, a CfgMagazines `count`, lowercase classes from itself up, the CfgPatches class, what its own config says about size, stack and grid |

`fnc_getFacts` takes kinds from config by weapon `type` and ItemInfo type (its header lists them); any other CfgWeapons class is
`item` - CBA's misc item class counts there although it inherits the bipod type; CfgMagazines with count 1 and mass up to 15 are
`grenade`; CfgVehicles with `isBackpack` 1 are `backpack`, others of `AllVehicles` `vehicle`, the rest `crate`. A class no config
knows is `unknown`, under its own name.

### Functions

| Function | Public | |
|---|---|---|
| `fnc_getFacts [class]`, `fnc_getInfo [class, compiled, cache]` | Yes | config facts; the answer above |
| `fnc_footprintAs [class or info, rot]` | Yes | `[w, h, holes]` as it lies, upright or turned |
| `fnc_parseRules [text]` | Yes | -> AST: `version`, `base`, `cell` (-1 for none), `groups` `[[id, conds], ...]`, `rules` `[[conds, values], ...]`, `warnings`; a condition is `[negated, key, op, values]` (a group reference has key `"@"`), a rule's values a HashMap of `like`, `footprint`, `stack`, `grid`, `weight`, `name` |
| `fnc_writeRules [ast, header = true]` | Yes | -> canonical text |
| `fnc_compileRules [text, legacy = true]` | Yes | -> compiled; `legacy` reads the tables and stackSmall too |
| `fnc_currentRules []` | Yes | the rules in effect, compiled again first when `fnc_rulesInputs` changed |
| `fnc_explain [class, compiled]`, `fnc_encodeName`, `fnc_decodeName`, `fnc_getProtection [class]` | Yes | every layer's say; `name=` encoding; the zones a vest, uniform or helmet covers (with `fnc_getArmor`: ACE's own armor number) |
| `fnc_parseGrid [text]`, `fnc_formatGrid [spec]`, `fnc_parseMask`, `fnc_formatMask`, `fnc_turnMask` | No | grid specs and masks; `fnc_parseMask` is the one reader of masks, for items and compartments alike |
| `fnc_compileCond`, `fnc_matches`, `fnc_parseTable [text, type, warnings]`, `fnc_sanitizeText` | No | conditions; the older tables; the EDITBOXes' sanitizer |
| `fnc_resolve [facts, compiled]` | No | -> `footprint`, `stack`, `grid`, `weight` (kg, -1), `name` ("" none), `src` |
| `fnc_rulesInputs []` | No | `[rules text, size table, stack table, container table, stackSmall, massPerCell]` |
| `fnc_loadRules [text]` | No | compiles when the inputs changed; a text stands in for the setting (testing, `einv_items_rulesOverride`), `""` ends that |
| `fnc_checkServerRules [published]` | No | warns once when the server reads the same settings differently |

The compiled form is plain data, no code (it is kept in missionNamespace): `text`, `ast`, `base`, `chain`, `cell`, `warnings`, the
groups (`groups`, `groupKeys`, `groupSource`, `groupOrder`), the rules (`own` = the text's, then the tables'; `preset`; each
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

### What the wizard writes (`einv_setup_fnc_upsertRule`)

`[class, set, remove]` writes what the Items or Containers step sets for one class into the draft, as that class's own rule
`class=X > ...`. `set` is a HashMap of `footprint` (`"2x3"` or a mask), `stack`, `grid` (as `fnc_formatGrid` writes it) and `like`
(a class); `remove` is an array of fields to take away. The rules written for exactly that class (`einv_setup_fnc_ownClassRules`)
become one; whatever else they set - a name, a weight - stays. The rule goes **last**: later rules win, so a broader rule further
down (a group, a kind) would otherwise still decide what the class gets and the step would show something other than what was just
applied. A rule left with nothing to set goes altogether. It returns false for a class name the language cannot hold, and ends in
`fnc_commit` (an undo step, the step drawn again).

### `tools/check_default_ruleset.sqf`

Not part of the mod; copied into a mission and started with `[] execVM "check_default_ruleset.sqf"` with the mods to check
(vanilla, ACE, a large pack). It checks that the shipped `default` preset gives every item the size and stack, and every container
the compartments, that the code before the rules gave - but for what is intended (grids 10 wide, at most 400 cells, containers at
120 % of their load) - that the groups are a partition, that texts and names round-trip, that `base=tarkov` builds on `realism`
and that canvases (`grid=aaa/aba/aaa`) round-trip. The summary shows as a hint; every finding goes to the RPT and the clipboard.

## 3. Storage

What a container holds, where it lies on its grid, what a unit wears, and every change to any of it. All functions are `Public:
No` unless noted. Entries and sections are HashMaps.

### Entries (`fnc_getContents [container]`)

One entry per tile, weapons first, then backpacks, magazines, items. Weapons and backpacks are a tile each (every one may carry
other attachments or contents); every magazine is a tile (own rounds), except the ones that stack (grenades and the like, `getInfo
"stack"` over 1), which share a tile only with the same rounds; plain items are counted together by class and split at their stack
size. A null container gives `[]`.

| Key | |
|---|---|
| `class` | STRING |
| `count` | NUMBER, at least 1 |
| `ammo`, `capacity` | NUMBER, rounds in a magazine and in a full one; 0 for anything else |
| `attachments` | ARRAY, a weapon's `weaponsItemsCargo` entry, `[]` otherwise |
| `container` | OBJECT, a uniform, vest or backpack lying here: its own container object from `everyContainer`; objNull otherwise |
| `key` | STRING, the key of its place record (`fnc_entryKey`) |

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

Patterns by kind when none is named (the class's own pick is a sum over its name, so a model always looks the same): uniform -
`pockets` (1x2) or `pockets_mixed`, at most six from the load; vest - `rig` (1x2), `mixed`, `plate` or `long`, at most sixteen;
backpack - `single`, one compartment as near square as `STORAGE_COLS` allows; crates and vehicles - `wide`, one compartment
`STORAGE_COLS` wide. A given number (`24`, `einv_slots`) is met exactly; one from the load is a rough measure. The load is
`fnc_getMaxLoad` (config `maximumLoad`, -1 for a weapon holder or null): since weight limits nothing, it only sizes the "auto",
"percent" and "pattern" grids.

`fnc_getBlocks [container]` finds what to ask for a real one. First answer wins:

1. The object's **`einv_grid`**: a STRING grid as in `grid=` (`"6x4+2x3"`, `"rig:16"`, `"xxx/x-x"`, a canvas, `"auto"`), set by a
   mission with the public flag on a crate, a vehicle, or a unit's uniform, vest or backpack container: `_crate setVariable
   ["einv_grid", "6x4+2x3", true]`. One that cannot be read is named in the RPT once (cache `einv_storage_objectGrids`) and the
   rules count instead. Scripts of this mod may give the compartments as they are, `[[cols, rows], ...]`: taken exactly, never cut
   to `MAX_ROWS` (the Arsenal's staging space).
2. The rules for its class (`getInfo "grid"`): the older container table, the text, config `einv_grids[]` / `einv_slots`, the
   preset, else "auto".

The ground has no compartments and no limit: `[]`; the window draws it as one open grid, `STORAGE_COLS` wide, always a row more
than it needs and at least three rows. A uniform or vest container's class derives from a weapon holder, so `fnc_isGroundHolder`
excludes `ContainerSupply`: only a pile is a ground. A backpack with a load of 0 takes an own grid like any other.

### Places and the layout (`fnc_getLayout`)

`[holder, entries, _, places]` -> HashMap: `entries` (all, placed), `blocks` (as `fnc_blocksFor`; the open grid's with the rows it
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
3. **first fit** - the rest, largest first (then category, kind, key, index): compartment after compartment, row by row, upright,
   else turned. A square rectangle never turns; a shape in a square box turns when turned it takes other cells.

An entry no compartment has room for (a script or another mod added it) is `overflow`: shown apart, never lost.

**Place records** are `[key, col, row, w, h, block, rot]`: `w` and `h` as it lies, `rot` 0 upright or 1 turned a quarter
clockwise, always written with `rot`. A record without it (saved places, loadouts, snapshots, payloads of older shape; six
elements) reads as turned when its `w` is not the upright one, and `fnc_getLayout` counts no drift for that alone. The holes of a
shaped item always come from its class at use time (`einv_items_fnc_footprintAs [class, rot]`), so only `rot` is stored and
synced.

**Rotation convention.** Turned is a quarter clockwise, as the picture turns (`ctrlSetAngle 90`): the cell `(c, r)` of an upright
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

### Room (`fnc_hasSpace`, `fnc_hasRoom`, `fnc_plan`)

- `fnc_hasSpace [container, entry]`: a free spot in one of the compartments, laid out once more with the entry added from the
  places everyone shares; nothing is kept. The ground and a kit always have room (they grow). A stackable entry **first fills the
  partly filled piles of its own key** (a magazine only stacks with the same rounds) - the layout never merges into a pile - and
  only what is left needs free spots, one per stack's worth.
- `fnc_hasRoom [container, entry]`: `fnc_hasSpace` plus the one kind rule left, `fnc_backpackIntoBackpack` (reason
  `"NoBackpack"`). The cargo commands add whatever they are given, so a window, mission or mod asks this before it puts anything
  in. `fnc_moveEntry` and `fnc_unequip` ask when they get no cell; the machine that runs the op asks again and decides.
- `fnc_plan [items, targets, options]` -> `[assigned, left]`: where several things go when moved together - the first target, in
  the order given, with a spot for each, largest first (option `"order"`: `"given"` keeps the order), counting what is already
  planned. Options `"start"` ([holder, compartment] tried first) and `"lifted"` (items treated as gone from where they lie).
  `"ground"` as a target always has room and takes no cell. Nothing is asked of any machine but this one. An item never goes into
  a target that is the container it is or lies in it (`fnc_liesIn`).

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
lifted and put down at once, refused as a whole when any cell is not free), `sort`, `normalize`, `move` (within one root), `take`,
`put`, `putGround` (on the server), `takeOff`, `putOn`, `repack`, and compat's `kitTake`, `kitPut`, `kitPlace`, `kitMove`,
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
object attached to the holder, not cargo the engine counts: a pile holding only a backpack was deleted, backpack included (0.4.0, a
worn backpack dropped to the ground vanished, a vest did not). `GroundWeaponHolder_Scripted` is the same holder the engine never
deletes, so the mod deletes it itself: `fnc_pruneScriptedPile [pile]`, called by `fnc_execute` for every ground pile a phase touched
and by `fnc_opPutGround` for the piles a bounced put-down left empty. A pile of that type that is local and, a frame later, still
holds no item, weapon, magazine or backpack is deleted (a frame, so the answer and the window's rebuild finish first). Engine-made
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

### Loadouts

CBA's loadouts carry the arrangement. `fnc_onLoadoutGet` (event `CBA_loadoutGet`) writes `einv_layout = [1, [uniform, vest,
backpack]]` into the extended info - the records of `fnc_readPlaces` with the key cut down to `fnc_layoutKey` of its class - and
`fnc_onLoadoutSet` (`CBA_loadoutSet`) writes them back with `fnc_writePlaces` where the unit is local, else sends them to its
machine (`einv_storage_loadoutPlaces`, `fnc_onLoadoutPlaces`). Only well-formed records are kept; a record the new items do not
match drops out at the next layout, and a loadout without the key leaves everything to the first fit. Both handlers are registered
in preInit on every machine, Eden too.

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
while the slot is empty. `fnc_putOn` uses `addBackpack`, which fills the container at once. The client setting
**`einv_storage_debugDrop`** (default off; a dedicated server reads its own) writes `einv drop:` lines for each step to the RPT.

**Dragged out of the window** (0.4.0: a backpack dragged from the gear row onto the 3D middle left no pile and nothing on the ground;
a vest did not vanish). `einv_gui_fnc_updateDrag` makes the target `["ground", -1, 0, 0, true, ""]` outside every panel, and
`fnc_endDrag` gives a slot's item to `fnc_doUnequip [unit, slot, "ground", []]` - the menu Drop's own call, only inside the mouse-up
event instead of a frame later. The window makes no pile, asks no hook (`ground` is asked only by `fnc_quickUnequip`,
`fnc_dropToGround`, `fnc_quickMove`), and `fnc_settle` works from the phases, not the window's in-flight record; with no pile in
reach `fnc_getGroundHolder` makes one. The step that differs from a vest's is the engine's cleanup of a pile holding only a backpack,
an object of its own and no item cargo, which the scripted holder avoids (see Ground above). `fnc_opPutGround` still looks at such a
pile a frame later and, gone, puts the backpack down once more (an RPT error). Two RPT lines per backpack put on a pile are
always written, whatever `einv_storage_debugDrop` says: `fnc_addPayload`'s "Backpack CLASS put on pile NETID (N backpacks there)" and
`fnc_opPutGround`'s a frame later "Backpack CLASS on pile NETID a frame later: pile gone / there with N backpacks". The trace starts at the drag: `fnc_endDrag` (where, target, call), `fnc_doUnequip` (every slot, refusals),
`fnc_sendMoves` (the request id the storage's lines carry), `fnc_afterAction` (each step's result, the pile, whether it shows).

### Public functions and tables

Public: `einv_storage_fnc_request`, `fnc_moveEntry`, `fnc_equip`, `fnc_unequip`, `fnc_getEquipment`, `fnc_getNearby`,
`fnc_readPlaces`, `fnc_rootOf`, `fnc_dumpPlaces`, `fnc_addNew`. Other addons extend the storage only through tables they fill in
preInit: `einv_storage_ops` (op name -> function name), `einv_storage_guards`, `einv_storage_carryVariables` and
`einv_storage_holderTypes` (a holder that is no object, by the part of its key before `:`; `kit` from compat_efak: `entries`,
`root`, `verify`, and the names of its ops for `take`, `put`, `place`, `move`).

## 4. GUI window engine (gui)

Everything on the window except the dim layer is created at run time; a build deletes what the last one made and makes it again.
Functions are `Public: No` unless noted (`fnc_open`, `fnc_openPerson`, `fnc_openVanilla`, `fnc_playSound`, `fnc_requestRebuild`
are public).

### Opening, attaching, building

- **Opening.** The unit's `InventoryOpened` handler (`fnc_onInventoryOpened`, put on whichever unit the player is by
  `fnc_initUnit` from the CBA `unit` event) answers true, which keeps the vanilla display away, and the window opens a frame later
  (`fnc_open`). Every true starts a 1.5 s grace time (`GVAR(blockedUntil)`, `BLOCK_GRACE`); a vanilla inventory that still loads
  during it or while the window is open - Better Inventory patches `RscDisplayInventory` and runs its own XEH `InventoryOpened`
  handler, any mod may `createDisplay` it - is closed by `fnc_guardVanilla` (an `Extended_DisplayLoad_EventHandlers` entry on
  `RscDisplayInventory`, and a check each `CHECK_INTERVAL` in `fnc_onFrame`). A false answer ends the grace time, so
  `fnc_openVanilla` and the switched-off setting are never closed. Better Inventory's put/take stack move is held off with its
  `bettInv_stackMove` flag while the window is open. With `einv_gui_replaceVanilla` off the vanilla inventory opens - in multiplayer only on the player's own gear:
  whatever other players can reach (crate, vehicle, body, person, a pile with something in it) opens here regardless, since the
  engine's inventory is not serialised with the authorities and two players could take the same item.
- **Attaching.** `fnc_attach [display, unit, container, secondary, hooks = createHashMap, driver = "pfh"]` -> BOOL makes any
  display that carries the dim layer (`IDC_DIM` 9601) and the first control (`IDC_FIRST` 9602) **the window**: it sets the unit
  and containers, starts all window state afresh, adds the mouse handlers, builds once and starts the frame. It refuses when
  another display is the window (one session at a time; uiNamespace `einv_gui_display`). The inventory attaches with no hooks, ACE
  Arsenal's panel with a table of them. `fnc_onUnload` stops the frame and empties hooks and zones. A top-level control with
  `IDC_KEEP` 9603 survives the build's sweep.
- **State** (documented variable by variable in `gui/XEH_preInit.sqf`): who and what - `einv_gui_unit`, `container`, `secondary`,
  `person`, `personMode`; the frame - `frameDriver`, `nextCheck`, `nextSignature`, `hooks`; what the build made (controls, so in
  uiNamespace) - `created`, `grids`, `slots`, `hint`, `windows`, `scrollRestore`; the mouse - `hover`, `press`, `dragging`,
  `dragTarget`, `dragSize`, `dragRot`, `dragCount`, `dragGroup`, `selection`, `bandPress`; the moves - `inFlight`, `answers`,
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
- **`fnc_onFrame`** each frame: hover, the drag or band, the focus rule, kit windows moving, the search animation; every
  `CHECK_INTERVAL` 0.25 s the "stay open" checks; once a second the **signature** `fnc_getSignature` -> `[own, list, loot]`. `own`
  (the unit's loadout, ACE's virtual load, the places revision of its containers, the weight limits' key) or `list` (sections
  shown, what lies around, what was opened, bodies' gear, kit and lock stamps, the containers' `locked` state) changed:
  `fnc_build`. Only some `loot` parts (cargo and places revision of a section) changed: `fnc_redrawTiles` draws those sections'
  tiles again, and answers false before touching anything when compartments, overflow tiles, the button or the folded-rows line
  changed. Nothing is built while a tile or frame is held. A window covered by another display (`fnc_isCovered`) keeps still and
  only checks whether to close.
- **Moves under way.** The window predicts nothing: `fnc_sendMoves` turns each move into phases (at most `BATCH_MAX` moves per
  transaction, the next chunk when the answer came; kinds `move`, `equip`, `unequip`, `swap`, `sort`, `placeMany`; a kit through
  its holder type's ops). Moved tiles stay faded and cannot be lifted, their target cells outlined (`einv_gui_inFlight`,
  `fnc_drawPending`) until the answer and the new places arrived (`einv_gui_answers`, finished by `fnc_afterAction`, at the latest
  `ANSWER_WAIT` 3 s after the answer; given up after `PENDING_TIMEOUT` 15 s); each sounds when finished. On
  `einv_items_rulesChanged` an open window is built again once a held tile is let go.

### Geometry and the cell

`UNIT = safezoneH / 40` (a row, about 27 px at 1080p). Everything see-through meets on whole pixels (`SQUARE`, `UNSQUARE`,
`SNAP_*`). Header `HEAD_Y = safezoneY + UNIT * 0.6`, `HEAD_H = UNIT * 1.6`; content from `CONTENT_Y = safezoneY + UNIT * 3` to
`CONTENT_B = safezoneY + safezoneH - UNIT * 2.6`; footer `FOOT_Y`, `FOOT_H = UNIT * 1.4`; `MARGIN_X = SQUARE(UNIT * 1.2)`.
**`fnc_getCell`** -> `[cellW, cellH]`, whole pixels, the same across and down: `round(((UNIT * 1.45) min UNSQUARE(safezoneW / 52))
/ pixelH)`. Every grid uses it. 52 cells across is what two columns of `STORAGE_COLS` 10 cells with their boxes (13 cells each),
the equipment column and the middle take at 16:9 - 37 px at 1920x1080, which leaves the middle 5 UNIT for the soldier while
looting.

### Themes

`fnc_themeBase` returns a HashMap with every key; a look copies it and overrides. There is one look, **Glass** (`fnc_theme`, id
`"main"`, in the feel of Arma's and ACE's menus and Enhanced First Aid Kits); `einv_gui_styles` holds that one entry, kept as a
list so a look could be added. `fnc_theme` adds `equipmentPanel` (a pane under the equipment cards), `titleIcons` and `onAccent`.
The camera switch is kept in the profile (`einv_gui_cameraOn`).

| Key | |
|---|---|
| `id`, `name`, `font`, `fontBold`, `upper` | style id and name; `PuristaMedium`, `PuristaSemibold`; captions in capitals (`fnc_caption`) |
| `radius` | panel corner radius as a height (0 = square; Glass `UNIT * 0.45`) |
| `dim`, `dimCamera`, `panel`, `panelBorder` | the screen's dim colour without and with the camera; column background (`[]` for none), 1 px frame |
| `inspectBg`, `tooltipBg`, `card` | the inspect card and kit windows; the comparison card and mouse tooltip; section header and card |
| `slot`, `slotEmpty`, `slotBorder`, `slotCaption` (`"none"`, `"above"`, `"tab"`, `"inside"`), `slotCaptionBg`, `slotIcon`, `slotAccent`, `hatch` | slots |
| `cell`, `tileBg` (five colours by `CATEGORY_*`), `tileBorder`, `tileName`, `tileCount` (`"text"`, `"pill"`, `"badge"`), `tileCountBg`, `tileCountColor`, `tileAmmoBar` | grid cells and tiles |
| `raised` | the small flat box of a stack's "3/10" and a hotbar slot's count |
| `text`, `text2`, `muted`, `accent`, `accentSoft`, `line`, `gain`, `loss`, `warn`, `info` | colours |
| `barTrack`, `barFill`, `button`, `buttonHover`, `buttonText`, `keyBg`, `keyText`, `keyRound` | bars, buttons, key hints in the footer |

**The "ace" theme** is not a second look but the `theme` hook of the Arsenal panel (`einv_arsenal_fnc_theme`), which edits the
theme in place for that display only: `radius` 0, `panel` `[0,0,0,0.5]`, `panelBorder` black, `text` white, own keys `headBg`
`[0,0,0,1]` and `headFont` `RobotoCondensed` (ACE's sort bar, for the panel's title band). The id stays, so
column scrolls survive builds. Tiles keep Glass.

### The UI kit

`fnc_uiPanel`, `fnc_uiLabel`, `fnc_uiIcon`, `fnc_uiPicture`, `fnc_uiFrame`, `fnc_uiBar`, `fnc_uiRing`, `fnc_uiShape`,
`fnc_uiHatch`, `fnc_uiKeyHint` and `fnc_uiButton [display, parent, rect, id, text, icon, theme, code]` (left click runs `code`
with `[1, id]`, right click `[-1, id]`) take a `parent` (`controlNull` for the display, a group for relative coordinates), snap to
pixels and register top-level controls in `einv_gui_created`.
`fnc_safePicture [path]` -> path or "": a file path (`\` or `/`) ending .paa/.jpg/.png, or none when its .paa exists, that
`fileExists` finds - asked once per path (uiNamespace `einv_gui_pictures`); `#(...)` passes. `fnc_uiPicture` / `fnc_uiPictureTurned`
draw nothing for ""; the wizard's index and editors, the Arsenal header and ACE cargo's cards ask it too (`picture = "picturething"`).

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
| `key` | `[display, key, shift, ctrl, alt]` | BOOL, true = handled - after the hotbar and selection keys, before Delete and the Gear key | `fnc_onKeyDown` |
| `submit` | `[edit]` | nothing - Return in a field | `fnc_onKeyDown` |
| `dragCheck` | `[dragTarget, entry, sourceGrid, slotSource]` | the target as it is to stand, `[]` for none, nil to leave it - last of everything | `fnc_updateDrag` |
| `drop` | `[kind, sourceIndex, tileIndex, slotSource, entry, count, targetIndex, col, row, w, h, targetSlot, place, rot]` (**14**) | BOOL, true = handled - after the `!fits` exit | `fnc_endDrag` |
| `ground` | `[source, count]` | BOOL, true = handled - `source` is `[unit, slot]` or `[grid index, tile index]`, count -1 for all | `fnc_quickUnequip`, `fnc_dropToGround`, `fnc_quickMove`, just before each falls back to the ground |
| `fold` | `[container]` | BOOL, true = the window keeps its folds itself (`einv_gui_collapsed` is left alone, the window is drawn again) | `fnc_toggleSection` |
| `menu` | `[display]` | choices - replace the default, `[]` = no menu, nil = the default | `fnc_contextMenu` |
| `filter` | `[]` | nothing - after the tiles were faded for the search | `fnc_applyFilter` |
| `tileBadge` | `[class]` | a texture or `""` - a mark `SQUARE(UNIT * 0.42)` in a tile's top left corner | `fnc_createTile`, `fnc_drawSlot` |
| `hint` | `[kind "tile" / "slot" / "none", class, record]` | parts `[[text, colourKey], ...]` after the gui's own; for `"none"` the whole idle hint | `fnc_updateHover` |
| `inspectRows` | `[class, count, ammo, attachments]` | rows `[label, text]` or `[label, fraction, text]` before the Mod row | `fnc_drawInspect` |

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

`| equipment | free middle | storage | loot |` (`fnc_layoutGlass`). The context (`fnc_build`) carries `unit`, `container`,
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
  with one section per container; the column's `id` (`"storage"`, `"loot"`) is how `fnc_build` keeps its scroll
  (`fnc_scrollPixels`, restored a frame later through `einv_gui_scrollRestore`). Cells are controls created directly in the group:
  a nested group would eat the wheel.
- **Section** (`fnc_drawSection`): a caption tab (folds it, `fnc_toggleSection`; the contents' weight on the right,
  `fnc_loadText`, only told), a box with the container's picture and short name, and the grid. Beside the tab "Take all" (loot) or
  "Put all in" (own) (`fnc_takeAll`, `fnc_putAll`, `fnc_putAllTarget`: from the contents, not from what is drawn; what is not
  searched stays), and a cross on a container opened from inside another (`fnc_closeNested`). Beyond the keys of the storage's
  sections (section 3) a section may say `drawer` (a function name another addon draws it with: ACE cargo's cards), `placeholder`
  (a container the unit lacks: a hatched box that is its slot when it has an `owner`), `worn` + `unit` (a body's compact doll,
  `fnc_drawEquipmentDoll`), `locked` (a padlock and one muted line, nothing of what it holds; `lockTip` adds an open padlock). Own
  sections start open, crates found around start folded; `einv_gui_collapsed` holds the containers the player turned the other
  way.
- **Compartments.** `fnc_flowCompartments [layout, cell]` -> `[places, height]`, drawn by `fnc_drawCompartments [display,
  parent, [left, top], section, layout, places, theme, window]`. Flowed compartments (`pos` `[]`) lie side by side as far as
  `STORAGE_COLS` cells reach, then on the next line, `COMPARTMENT_GAP` (0.22 cell, pixel-rounded) between blocks. A compartment
  with a `pos` lies on its **canvas** exactly where it was drawn, every cell at the plain pitch; the canvas is one piece of the
  flow. **Insets:** a cell side that borders a cell of *another* compartment (not a hole, the canvas's edge or its own
  compartment's cell; a corner is no side) is drawn in by half of `COMPARTMENT_GAP`, the cell on the left/top of the seam
  taking the smaller pixel half, so the two add up to the flow's gap and the two frames sit as two flowed blocks' do. A
  compartment never gets a gap inside itself (the middle of `abbbbbc/abbbbbc` stays one block while its neighbours show
  theirs). `fnc_canvasInsets [blocks, cell]` -> per compartment per cell `[left, top, right, bottom]` (`[]` when it borders
  no other); the place is `[x, y, insets]`, the grid keeps `"insets"`, `fnc_createGrid` draws its cells and
  `fnc_drawCompartments` its lines (each cell's frame, joined into bands without overlap) drawn in by them. Tiles and every rect
  on a grid (`fnc_spanRect` via `fnc_tileRect`, selection, pending, band, drag footprint) shrink a side by the furthest inset of
  their cells along it (`fnc_spanInsets`); `fnc_shapeRects` takes those four as its box's insets. `fnc_screenToCell` is plain pitch.
- **Grids and tiles.** `fnc_createGrid [display, parent, [relX, relY], rows, theme, section id, cols, holes, insets]` -> a
  HashMap: `parent`, `rel`, `cols`, `rows`, `cellW`, `cellH`, `cells` (a **hole** has no control: `controlNull`), `holes`,
  `insets`, `tiles`, `section`, and from `fnc_drawCompartments` `container`, `virtual`, `kit`, `layoutKey`, `unit`, `block`, `pos`,
  `overflow`, `window`, `holder`, `root`, `side` (a source grid adds `source`). `fnc_createTile [display, grid, entry, theme]`
  draws the surface in the category's colour over the entry's cells only (a shaped tile: runs of cells with one-pixel bridges;
  `"backgrounds"` and `"rect"` kept for hover, flash, reveal and the repack film), the picture (turned along when `rotated`), the
  short name, a stack's count and a magazine's fill; `fnc_tileAt` and `fnc_hitsHole` miss holes. A class whose `stack` is over 1
  shows **"count/stack"** ("3/10", "1/10" too) on a small flat box in the `raised` colour at the bottom right; one that does not
  stack shows nothing; a magazine's rounds then move to the bottom left. Counts over a picture stand on a dark pill
  (`fnc_drawCountBackdrop`, sized for the widest text the label can become, since a repack writes rounds live). The fill bar
  (`einv_gui_magazineFillBar`) shows on magazines that are not full.
- **Tall compartments.** `fnc_viewBlocks [layout, holder]` -> `[blocks, hidden, foldable, cells]` shows a tall compartment down to
  its last row in use plus `COLLAPSE_SPARE_ROWS` 2, at least `COLLAPSE_MIN_ROWS` 4, and only folds when that hides
  `COLLAPSE_HIDE_MIN` 4 rows or more; one line under the grid, "+32 empty rows (256 cells)", opens them (`fnc_toggleRows`,
  `einv_gui_expanded`). A positional compartment never folds; kit windows and the own storage column are not folded. Only the
  view: the grid stays whole.
- **Kit windows** (`fnc_drawWindows`, `fnc_drawWindow [display, section, theme, fresh]`): a kit or pouch is a floating glass
  window - a title row (picture, name, "12 / 60 mass", a cross) and a scroll body with the kit's grid (`window` = its key). Open
  windows are `einv_gui_windowOrder` (bottom first), placed by `fnc_placeWindow` beside the tile they were opened from, moved by a
  press on the title, raised by any press (`fnc_raiseWindow`: that window alone is made again, last), opened by `fnc_openWindow
  [key, anchor]`, closed by the cross, Escape on the topmost, or `fnc_closeWindow [key]`. **Hit testing** is by layer (`fnc_topAt
  [point]` -> `"inspect"`, a window key or `""`): menu, inspect card, windows (top first), columns; hover, drag targets, press,
  context menu and quick move all go through it.

### Drag, selection, quick moves

- **Lift.** A press (`fnc_onMouseButton`) becomes a drag after `DRAG_THRESHOLD` 0.008 (`fnc_startDrag`: the picture follows as a
  ghost, `fnc_makeGhost`; the source fades; a footprint shows green where it fits, red where not). A stack goes whole, **Shift**
  half; the **wheel** changes the count (`fnc_onMouseZ`), the middle button takes all; **R** turns what is held (`fnc_rotateDrag`:
  `einv_gui_dragRot` apart from `einv_gui_dragSize`, a quarter clockwise and back, the item staying held by the same cell). Column
  and window edges scroll while dragging. Nothing is lifted that could go nowhere (a living person's item the player may not
  touch).
- **Where it lands** (`fnc_updateDrag`; `einv_gui_dragTarget` is `["grid", gridIndex, col, row, fits, why not, "", place]`,
  `["slot", ...]`, `["kitTile", ...]`, `["hotbar", slot, ...]`, `["repack", ...]`, `["zone", ...]`, `["ground", ...]` or
  `["group", ...]`): on a grid the footprint must lie inside the compartment on free cells (a hole is red; an item's own holes
  over free cells are fine; cells a move under way goes to count as taken), another container must be able to carry it
  (`fnc_checkTouch`; `fnc_backpackIntoBackpack` is the one kind rule), and a uniform, vest or backpack never goes into itself
  (`fnc_liesIn`). On an own slot it fits when `slotAccepts` says so; worn gear over the same slot of another unit is exchanged
  (`fnc_canSwap`, `fnc_doSwap`); outside every panel it goes on the ground. `fnc_endDrag` hands the result to `fnc_sendMoves` (or
  the `drop` hook).
- **Group mode** (`einv_gui_dragGroup`, `fnc_groupMode`): whole stacks, no turning, no wheel; over a grid *keep* (one compartment,
  every tile's cell free or lifted), *pack* (`einv_storage_fnc_plan` into the hovered container: an outline green, amber or red,
  "4 / 6" on the counter), *kit* (the kit decides) or *none* (into itself, a slot, a person's container the player may not put
  into). `fnc_sendPlan` sends keep and pack: tiles that stay in their holder are one `placeMany`, the others one move each with
  the planned cell.
- **Selection** (inventory only): click selects, Ctrl+click toggles, Shift+click takes the range, a frame dragged from an empty
  cell (`fnc_startBand`, `fnc_updateBand`, `fnc_endBand`) takes what it touches, Ctrl+A the section (`fnc_selectSection`). Refs
  are `[holder, key, compartment, col, row]` (`einv_gui_selection`), found again on every build by `fnc_selectionTiles`; one side
  at a time (`own` or `loot`); searched tiles only. **Double click** moves a tile over (`fnc_quickMove`: from own gear into the
  loot column's containers in order, else the ground; from loot into uniform, vest, backpack), opens a kit or nested container, or
  moves a whole selection (`fnc_quickMoveGroup`); Alt+click puts on (`fnc_quickEquip`); Ctrl+click on a slot takes off
  (`fnc_quickUnequip`); Delete and "Drop" put the selection on the ground.

### Menus, hints, the weight card

- **Context menu** (`fnc_contextMenu`, `fnc_openMenu [display, choices, at]`, `fnc_closeMenu`): a choice is `[text, args, code,
  options]`; options `icon`, `color`, `tooltip`, `enabled` (false: muted, the click swallowed, the menu stays), `separator`. What
  a tile, a slot and free cells offer is in `fnc_contextMenu`'s header; kits, arsenal boxes, radios and the hotbar add theirs.
  **Right click with a menu open:** `fnc_openMenu` keeps the menu's rectangle (uiNamespace `einv_gui_menuRect`, cleared by
  `fnc_closeMenu`); a right press beside it closes it and goes on as an ordinary right click, so the tile under the mouse gets its
  menu in the same go (on empty space nothing opens); a press on the menu and every left press are the menu's.
- **Hints:** `fnc_updateHover` names what the mouse is on in the footer; `fnc_showHint [text, colourKey]`; `fnc_flashHint [reason,
  details]` (a reason key such as `"NoRoom"`, `"LookOnly"`, `"Locked"`, `"NoBackpack"`, any other text as it is, `""` nothing);
  `fnc_dragHint`; `fnc_infoHint [kind, args]` for the weight card and each caption. The **inspect card** (`fnc_inspect`,
  `fnc_drawInspect`) and the **comparison card** (`fnc_compareRows`, `fnc_drawCompare`, `einv_gui_compareTooltip`: over a vest,
  uniform, helmet or backpack that is not the soldier's own, "vs. <worn item>" with Armor, Covers, Space, Weight) float over the
  columns. The **search field** (`fnc_drawFilter`, `fnc_applyFilter`) fades non-matching tiles.
- **The weight card** reads `einv_weight_fnc_getLoad` (ACE's total, the rules' weights and EFAK's kits included), the limits and
  the tier. The bar has no tick marks or zone strip; it fills by load over the Critical limit. The fill, the tier's words and the
  preview take **`fnc_weightColor [unit, load, theme]`**: `text2` in Light, `accent` in Heavy, `loss` in Overloaded and Critical,
  blending into the next tier's colour over the last 6 % of the bar before its limit. The right text is the tier and its effect
  ("Heavy · jogging tires you", `einv_weight_fnc_tierText`); the left the load and where the next tier starts ("12.4 kg · Heavy at
  26.7 kg", `Load_Next`; nothing at Critical); on a narrow column the next limit goes first, then the effect. Lifting something
  from outside the soldier's own gear (`fnc_isOwnStorage`) puts a **preview** of the added weight on the bar
  (`einv_gui_weightBar`, `fnc_previewWeight`, `fnc_clearWeightPreview`) in the colour of the tier it lands in, and the hint says
  "+2.4 kg: you will be Overloaded (46.9 kg)" (`fnc_weightText`) - a forecast, never a refusal.

### Searching, sounds, the looting pose

- **Searching** (`fnc_isSearched`, `fnc_markHidden`, `fnc_animateSearch`, `fnc_showSearch`, `fnc_revealTile`, `fnc_learn`): loot
  of the kinds the settings name (bodies, persons, containers, ground; never the player's own gear, an object with
  `einv_noSearch`, an ACE arsenal box) shows as "?" tiles until searched, `einv_gui_searchTime` seconds per cell. What a player
  knows is counted per container and class (local), in the arrangement's order, so everyone reveals the same top-left ones; what
  you put in you know. The queue entry is `[container, class, row, col, cells, block]`, revealed one item at a time with a ring
  and a circling magnifier; a found tile is drawn anew in place, a build only when the section's first find brings Take all.
- **Sounds** (`fnc_playSound [action, class, container, world, ui]`, public): by family from the config `CfgEinvSounds`
  (`gui/CfgEinvSounds.hpp`; its header explains the layers): `Default`, 17 item families and 4 container families (crate, vehicle,
  body, ground), Arma's own files only; the family is the item's config `einv_sound`, else `fnc_soundFamily`. Actions: `lift`,
  `move`, `drop`, `equip`, `unequip`, `attach`, `detach`, `loadMag...`, `unloadMag`, `rotate`, `open`, `close`, `search`,
  `uncover`, `inspect`, `giveBack`. The looter hears them on the UI channel (`einv_gui_soundVolume`, `einv_gui_sounds`); others
  within the action's range hear a quieter copy (`einv_gui_soundsWorld`: `fnc_sendNoise` -> the target event `einv_gui_noise`,
  `fnc_onNoise`; never from the Arsenal).
- **Looting pose** (`einv_gui_animation`): Arma's own inventory states `Ainv<Perc|Pknl|Ppne>Mstp...` (`fnc_poseState`) played with
  `playMoveNow` on the local unit by `fnc_poseStart` (guarded by `fnc_canPose`), watched by `fnc_poseCheck`, ended by
  `fnc_poseEnd` only while the soldier is still in an `Ainv` state, so nothing ACE started is fought. He kneels at bodies, at
  piles holding something unsearched and at crates lower than `LOW_TARGET` 0.6 m. **Moving stops looting**
  (`einv_gui_moveToStop`): a movement key closes the window while it was opened on something or a search runs (not keys with Ctrl
  or Alt).

### People, the CBA menu and other mods in the window

- **Living persons.** Every soldier carries one scroll action per client (`fnc_addPersonAction`; agents through the player's
  `fnc_addAgentAction`); `fnc_openPerson` (public) opens the window on the whole person and tells them (`fnc_notifyPerson`).
  `fnc_canOpenPerson` -> `"whole"`, `"backpack"` or `""`; `fnc_canTouchPerson` takes `"items"` or `"worn"`; the server settings
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
list, 17 sort bar, 102 "+", 701 load bar, 9 message line, 40 "Remove all", 2010 / 2012 / 2014 the left tabs;
`ace_arsenal_currentLeftPanel`, `currentItems`, `mouseButtonState`, `virtualItemsFlat`; the row data `lnbData [row, 0]` and
`lnbValue [row, 2]`). `fnc_compatCheck` looks once at preInit whether they exist (`ACE_TESTED` "3.21.2"; another version gets one
RPT line); not ready, ACE Arsenal opens without the panel. Its known limits are listed in section 9.

### Lifecycle and events

Registered in preInit, so Eden has them too.

| Event | Does |
|---|---|
| `ace_arsenal_displayOpened` | `fnc_onOpened`: state reset, `KeyDown` / `KeyUp` and the list's `LBSelChanged` / `MouseButtonDown` handlers, and `einv_gui_fnc_attach` a frame later (one more if the inventory is still closing), driver `"draw3d"` |
| `ace_arsenal_displayClosed` | `fnc_onClosed`: `einv_gui_fnc_onUnload`, state reset, the BI helper and the staging crate deleted a frame later, `fnc_reportOverflow` a frame later (not in Eden) |
| `ace_arsenal_cargoChanged` | `fnc_onCargoChanged`: what of an add the engine refused by `maximumLoad` is put in with `einv_storage_fnc_addNew` while there is a free spot; flags the frame-later pass |
| `ace_arsenal_itemsChanged` | `fnc_onItemsChanged`: for the open container's tab `fnc_reconcile` at once, before ACE greys its list |
| `leftPanelFilled`, `rightPanelFilled`, `loadoutImported`, `onLoadoutLoad`, `showToggle` | `fnc_settle` a frame later |

The hook table (`einv_arsenal_fnc_hooks`, section 4) sets `guest`, `theme` (the "ace" theme), `header` (none), `layout`
(`fnc_layout`), `footer` (`fnc_footer`: the hint line), `camera` (none: ACE's), `keepOpen` (true: ACE decides when it
closes), `frame`, `mouseDown` / `mouseUp` (`fnc_onMouse`: outside the panel taken, so the engine ignores it), `click`
(`fnc_onClick`: double, Ctrl and Alt clicks swallowed - no equip or quick move past ACE), `wheel`, `dragCheck`, `drop`, `ground`
(-> `fnc_remove`), `fold`, `menu` (Remove, Remove all of this kind) and `hint`. `fnc_onKey` hands the engine only R while dragging
and Delete over the panel, never while a field has the cursor. A drop outside the panel never goes to the ground: it takes the
item out.

### The panel

- **Rect** (`fnc_panelRect`): top at ACE's sort bar (IDC 17, else the list's top), bottom at the list's bottom, like ACE's right
  column; width `STORAGE_COLS` cells of `einv_gui_fnc_getCell` plus padding and scroll bar, at most `PANEL_MAX_SHARE` 1/3
  of the screen. `fnc_layout` draws one flat block in ACE's `[0,0,0,0.5]` and black frame. **Header**: from the sort bar's top, a band
  `HEAD_BAND_SCALE` 1.6 times its height (the column starts that much lower than ACE's list) and as black (`ACE_SORT_BG`), the
  container's picture (`getInfo "picture"`) at the band's height and its name in RobotoCondensed, 1.3x ACE's row text, centred. **Sections** in `einv_gui_fnc_drawColumn`
  (id `"storage"`): the open container, then staging; both with `"box"` false, so `einv_gui_fnc_drawSection` draws no picture
  box and the grid starts at the left edge (the inventory keeps its boxes). The column reaches down to the **hint line**, the
  block's last band: no box of its own, a line in the frame colour over it, `EINV_ArsenalHint` in ACE's message size (5 units),
  lines as tall as the sort bar - one, two while staging holds something (the note, in the accent colour, from the `hint`
  hook; the idle text is cut to one line, Ctrl+wheel only where it fits beside). ACE's list is registered as the zone `"remove"`.
- **Folds.** A caption's chevron folds its section (the `fold` hook), kept per container class - lowercase, the staging space as
  `"staging"` - in `einv_arsenal_folded` while ACE's window is open: ACE makes a new uniform, vest or backpack for every one
  picked, so folding per object would be lost. `fnc_layout` notes `foldKeys` `[[container, key], ...]` and sets each section's
  `folded` to `key in folded` XOR `container in einv_gui_collapsed`, so the inventory's own list is never touched.
- **Staging space** (`fnc_staging`): `Box_NATO_Support_F` by `createVehicleLocal` at the first draw, hidden, no simulation,
  emptied, at the unit's feet (in reach), `einv_noSearch`, **`einv_storage_localOnly`**. Only for a soldier whose moves the
  storage runs on this machine at once (`fnc_isLocalRoot`: the player's own unit, any unit in single player and Eden); objNull for
  any other. Because `localOnly` objects count as local roots, moves between the container (root: the player) and staging (its own
  root) run here with the normal reach, lock and verify checks. Its grid grows (`fnc_growStaging`, from `fnc_layout`'s drawer
  just before its section): `einv_grid = [[STORAGE_COLS, rows]]` with rows = the lowest row in use (plus the heights of overflow
  entries) + `STAGING_FREE_ROWS` 4, at least `STAGING_MIN_ROWS` 10 and the rows that fill the column down to the hint line, at
  most `STAGING_MAX_ROWS` 100 (its own cap, since `MAX_ROWS` 40 also bounds item and compartment sizes in the rules); rows past
  the column scroll; `getBlocks` takes that form exactly. Section id `"staging"`, side `"own"`, a crate icon (`tabIcon`) before
  its caption. `fnc_onClosed` deletes it with its contents. `fnc_onDrop` notes `einv_arsenal_watch` `[container, class, count,
  until]` and the frame hook calls `fnc_syncAce` and `fnc_tellAce` once the count changed (`WATCH_TIME` 3 s at most).

### Add, remove, reconcile

- **ACE's own "+"**: `fnc_snapshot` normalizes the container's places (`einv_storage_fnc_normalize`) and notes its counts by
  class, so after an add every old tile keeps its record and only the new things are laid out first-fit. `fnc_reconcile`: gains
  against the snapshot; overflow entries of a gained class are taken back out (`einv_storage_fnc_removeEntry`, at most the gained
  count), "No room in the vest - move things to free a 1x2 space" appears in ACE's message line and the hint line
  (`fnc_sayNoRoom`), and ACE is told with `ace_arsenal_fnc_fireItemsChangedEvent` (`fnc_tellAce`; an ACE without it gets the
  follow-up in the frame-later pass). Nothing else is ever taken out.
- **List drag.** The list's own `MouseButtonDown` handler (`fnc_onListPress`) notes a left press on it (where, Shift, the frame;
  not on the scroll bar's 6 %) and reads no row: the list moves its selection to the pressed row only after that handler, so
  `lnbCurSelRow` still named the row before, and a row had to be picked before it could be dragged. The frame hook starts a drag
  once the mouse moved more than `DRAG_THRESHOLD` and more across than along; else it stays ACE's click. `fnc_listDrag`: the row
  `lnbCurSelRow` if the list's `LBSelChanged` (`einv_arsenal_listSel`, `fnc_onOpened`) picked one since the press, else the row
  under the press (list top, `rowHeight` or `sizeEx` of its config, `ctrlScrollValues`; none on the blank area), its class from
  `lnbData [row, 0]`, not a unique item (`lnbValue [row, 2]` 1), a virtual off-screen source grid `"aceList"` whose tile carries
  `dragEntry` with `count` = the stack (Shift: all); then `einv_gui_press` and `einv_gui_fnc_startDrag`. `fnc_dragCheck`: only a
  grid of the panel is a target (else `[]`). The drop (`fnc_onDrop`) calls `fnc_addTo [container, class, count, [col, row, block,
  w, h]]`: `normalize`, then `addItemToUniform` / `Vest` / `Backpack` for the open container, `addNew` for staging and for what
  the engine refused, the cell as a new record (`setPlace`); then `syncAce` and `tellAce`.
- **Wheel and remove.** During a list drag the engine's wheel sets the count on the ghost. Else `fnc_onWheel`: plain is the
  column's scroll; **Ctrl** over a tile adds one of its class (`fnc_addTo`, if in `ace_arsenal_virtualItemsFlat`) or takes one out
  (`fnc_remove`). A drop outside the panel, Delete, the menu or Ctrl+wheel down remove (`fnc_remove`: the record first when the
  whole tile goes, then `removeEntry` with the dragged count; `fnc_removeKind`), with sound `giveBack` and `fnc_tellAce`.
- **Frame-later pass** (`fnc_settle`, once a frame however often asked): fallback follow-up, snapshot, `fnc_syncAce` (row counts,
  load bar, `ace_arsenal_currentItems`, `ace_arsenal_fnc_updateRightPanel`), **`fnc_ungrey`** (rows ACE greyed by weight are lit
  again where a stack has room or a spot of that size is free, one grid look per item size; also the "+" of the picked row; unique
  items and backpacks are left to ACE), the engine unit set to `ace_arsenal_center`, build - or after the drag if something is
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
| CBA's Addon Options, a button in the bottom row (between Load and Import) while this mod's page is open | menu | `fnc_initCbaMenu` (`Extended_DisplayLoad_EventHandlers >> RscDisplayGameOptions`); missing CBA controls mean no button and nothing else breaks |
| ESC > Options > Inventory setup | direct | `CBA_fnc_addPauseMenuOption` with the display `einv_setup_RscWizard` (idd 9620) |
| Eden: Tools menu | direct | `Display3DEN.hpp`, over display 313; saves into the scenario |
| keybind `einv_setup_openWizard` (unbound) | direct | `fnc_openFromGame [step, class]`; a running mission only |
| the inventory's cog (`einv_gui_fnc_drawHeader`) | direct | `fnc_openFromGame`; the tooltip says read-only when `fnc_canEdit` says so; the inventory comes back on close (`einv_setup_reopenInventory`), as a person window when it was one |

- `fnc_open [parent = displayNull, mode = "direct", step = 0, class = ""]` (public) -> display; one wizard at a time, an open
  inventory closes first. The wizard has no CBA settings of its own: it edits `einv_items_rules` and has one keybind,
  `einv_setup_openWizard`. `fnc_canEdit [mode]` (public) -> HashMap `canSave`, `source` (`"server"`, `"mission"`, `""`),
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
it (0.4.0). A popover therefore takes the focus into the layer (a button of no size on its card) before its content is drawn, its
full-screen hit area closes it on a click beside the card and lets nothing through, and the keys wait while one is open
(`fnc_onKeyDown`, `fnc_onKeyUp`); `fnc_closePopover` hides the layer and gives the focus back to the sink.

### State and the draft

`einv_setup_steps = [[id, name key, function], ...]`: `start` (`fnc_drawStart`), `items` (`fnc_drawItems`), `containers`
(`fnc_drawContainers`), `review` (`fnc_drawReview`); step functions get `[display, group, theme, args]`. Group rules (`@group >
...`) have no step of their own: they are edited in the Review step's text. missionNamespace holds the mode, `target` (canEdit's
answer), `readOnly`, the draft (`origin`, `originSource`, `draft` (AST), `draftText` (canonical), `draftRules` (compiled),
`draftCache`, `parseWarnings`, `clean`, `sourceEmpty`, `undo`, `redo`), the window (`step`, `focus`, `selection`, `theme`) and
what steps keep between redraws (`listState`, `cellWork`, `itemWork`, `cellMode`, `cellBrush`, `sameAs`, `startAdvanced`, ...);
controls stay in uiNamespace. **Every edit ends in `fnc_commit [ast, redraw = true]`** (an undo step, `fnc_setDraft`, redraw);
`fnc_setDraft [text]` parses, writes out again, compiles with a fresh cache and raises the local event `einv_setup_draftChanged
[draftText]`. A change that writes out the same text is no change.

### Steps

- **Start** (`fnc_drawStart`): one plain page. Title and two sentences; the preset cards (`fnc_shippedPresets` plus the player's
  own, `fnc_personalPresets`) with the "keep own rules" switch; "Now in use" (with where Save goes, Import, Review and save)
  beside "What you changed" (`fnc_drawChanges`: the own rules as sentences, `fnc_describeRule`, to open at their class or take
  away); and, folded at the bottom (`einv_setup_startAdvanced`, closed by default), "Advanced - Cell size" with "1 cell = X kg":
  stepper, kg value and source, the preset's value back. It sizes every container no rule draws, by its load, and every item the
  Weight preset sizes by mass.
- **Items** (`fnc_drawItems`) and **Containers** (`fnc_drawContainers`): a class list on the left (`fnc_drawClassList`, cards by
  `fnc_drawResults`, 30 to a page) and an editor on the right. One class at a time, one rule per class. "Only classes with own
  rules" lists, on Items, classes whose rules set `footprint` or `stack`; on Containers, `grid` or `like` (`fnc_ownClassRules`'
  `named`).
- **Review** (`fnc_drawReview`): one column, no rules grammar unless asked for. "What changes" (`fnc_drawChanges [.., "saved"]`)
  lists every difference between the draft and `clean` (what is saved where the wizard saves: the setup in effect when it opened,
  saved or reloaded; on a client that may not save, the one in use), each line in words and marked new / changed / removed, with
  a cross that takes that one change back, and under it the count against the Default preset. Warnings only when there are any.
  Then where Save goes (or why it may not, in red), the force-over-the-mission switch where `canEdit` allows it, and one row:
  Export (copies `fnc_exportText "cba"` where `copyToClipboard` works - server, single player, Eden; an MP client gets the text
  fold opened on the CBA line to copy by hand), Import... (`fnc_openImport`, anchored under the button), Reset to default
  (`fnc_confirm`, then `RULES_DEFAULT`), Save on the right. Two folds, closed whenever the wizard opens (`reviewDrafts`,
  `reviewText`): "Saved drafts" (`fnc_personalPresets`, still stored as `einv_setup_presets` in the profile, shown as drafts so
  they are not taken for Default / Realism) and "Show as text" (own / full / CBA line, read only until Edit text sets `textEdit`;
  Apply text commits and closes the editing).
- **`fnc_changeRows [against = "saved" | "default", describe = true]`** is the one diff behind both lists and the header count:
  rows `[kind, status, label, words, picture, before, class, statement, undo]` for the preset, the cell size, the override switch
  (saved only), then every group and rule matched by what it is for (a group by name, a rule by its conditions), so a class given
  another size is one "changed" row. A single-class rule shows the class's picture and display name plus `fnc_describeRule [..,
  valuesOnly = true]`. `undo` is `[code, args]` and ends in `fnc_commit` (undo/redo keep working); a removed statement goes back
  after the one it followed, since a later rule wins. Reference setups are parsed once per text (`changeRefs`).
  `fnc_countChanges` counts these rows (`describe = false`), so the header chip, the step dots and Review agree. Start's "What you
  changed" is the same card against the Default preset (`"default"`): preset, cell size and every own rule.

### The class index

`fnc_buildIndex` / `fnc_indexChunk` read config in pieces of `INDEX_BUDGET` 6 ms (through `fnc_defer`, so it runs in Eden) into
uiNamespace for the whole game session: every public weapon, item, magazine with a picture, pair of goggles, backpack (including
those with a load of 0 - an own grid gives them room), crate and vehicle with a cargo space, one row each (`ROW_*`). What the
rules make of a class is not in it; it is asked (`getInfo` with the draft) only for the rows shown.

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
  vests, backpacks), an 8x8 canvas where a click makes a place one of the item's cells, the tile preview, and a warning while the
  cells are not one piece (Apply off). Apply writes `class=X > size=WxH` or `size=xx/x-`, and `stack=N`.
- **Blocks mode** (`fnc_drawCellBlocks`): the switch "Paint | Blocks" (`einv_setup_cellMode`, 0/1, kept for the session). One
  small drawing per compartment (a click toggles a hole), width and height steppers for the picked one, Add and Remove; working
  copy `{blocks, picked}`; Apply writes the blocks joined by `+` (flow layout). A class drawn as a canvas gets a note that Blocks
  loses the positions. Switching converts the working copy: Paint -> Blocks takes the components in reading order without `pos`;
  Blocks -> Paint lays them out and colours them as loading does.
- **Same as another class** (`fnc_drawSameAs`): a popover on the button (`fnc_popover`): a search over the index's containers
  minus itself, 8 to a page. A pick offers **Follow X** (writes `like=X` and removes the own `grid`, which would win over it) and
  **Copy cells of X** (X's `fnc_classBlocks` into a working copy in the current mode, `unlink` set when the class has `like=`, so
  Apply also removes it). A linked class shows X's cells read-only with a chip "Same as X · Unlink"; a copied working copy is
  editable even while `like=` stands.
- **Working copies**: `einv_setup_cellWork` (lowercase class -> a painted canvas, or `blocks` and `picked`; optional `unlink`),
  `einv_setup_itemWork`; the first change makes the copy, Discard drops it, "Back to the preset" removes `grid` and `like`. Apply
  checks no cell, `MAX_CELLS`, `MAX_BLOCKS` and a drawing taller than `MAX_ROWS`, and writes through `fnc_upsertRule`. A grid laid
  out by load or by a pattern is shown as the compartments it gives; editing it writes those cells instead.
- **Preview** (`fnc_drawPreview`): the window's own `flowCompartments` with the blocks Apply would write, so painted
  compartments sit 1:1 where they were painted, their cells drawn in by the same insets, and blocks flow; an item's tile on a
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
  `storage fnc_partFor` puts on a carried weapon), `""` (refused). Binding is refused for what is not carried (`fnc_canBindFrom`).
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
  key binds the item, over a hotbar slot it swaps the two, Delete empties it. `fnc_checkKeys` names, once per profile, every other
  keybind on the same keys. `fnc_bind [index, class, from, checked]`, `fnc_unbind`, `fnc_use` are public.
- **The bar on the screen** (`RscTitles >> einv_hotbar_RscHud`, `CfgUIGrids` entry `einv_hotbar_grid`, movable in Arma's layout
  editor): seven boxes (key, picture, count, a thin bar) and a message line, run by `fnc_hudPing` / `fnc_hudFrame` /
  `fnc_hudDraw`; `fnc_hudWanted` hides it in dialogs, Zeus, when unconscious, in the map; then `einv_hotbar_hudMode` decides.
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
`fnc_openVanilla`, `fnc_sendMoves`, `fnc_quickMove` and the guard.

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

### compat_ace_cargo, compat_tfar, compat_acre, compat_zen, compat_ace_vehiclelock

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
  `fnc_apply`, `fnc_groupDialog`, `fnc_groups`, `fnc_targets`); the lock goes through `einv_locks_fnc_setLock`.
- **compat_ace_vehiclelock.** ACE's vehicle lock as a provider of `einv_locks` (`fnc_check`):
  `ace_vehiclelock_LockVehicleInventory` on, the player on foot, a Car, Tank or Helicopter, `locked` 2 or 3, and no key by
  `ace_vehiclelock_fnc_hasKeyForVehicle`. ACE blocks only the vanilla display 602, which this window never opens - without the
  provider ACE's lock would be bypassed.

## 8. Settings

Every CBA setting of the mod (`initSettings.inc.sqf` of each addon), all under the category "Enhanced Inventory". Scope **client**
is `0` (each player's own value), **global** is `1` (the same for everyone; the server or mission decides). Descriptions in the
stringtables are wrapped as BRIEFING asks.

| Setting | Type | Scope | Default | |
|---|---|---|---|---|
| `einv_items_rules` | EDITBOX | global | `einv1 base=default` | the setup (section 2); runs `fnc_loadRules` |
| `einv_items_massPerCell` | SLIDER 2 to 20 | global | 5 | fallback mass per cell |
| `einv_items_stackSmall` | SLIDER 1 to 50 | global | 10 | `@item_small`'s stack, only when moved off 10 |
| `einv_items_sizeTable`, `einv_items_stackTable` | EDITBOX | global | "" | older tables, `class:WxH` / `class:N`; win over the text |
| `einv_storage_containerTable` | EDITBOX | global | "" | `class:N` or `class:WxH+WxH`; wins over the text |
| `einv_storage_nearbyRange` | SLIDER 1 to 5 | global | 3 | m, how far crates and piles count as nearby |
| `einv_storage_debugDrop` | CHECKBOX | client | off | log backpack drops to the RPT |
| `einv_gui_replaceVanilla` | CHECKBOX | client | on | the window instead of the vanilla inventory |
| `einv_gui_compareTooltip` | CHECKBOX | client | on | the comparison card for vests, uniforms, helmets, backpacks |
| `einv_gui_showNearby` | CHECKBOX | client | on | nearby piles and crates as boxes in the loot column |
| `einv_gui_magazineFillBar` | CHECKBOX | client | on | the bar on magazines that are not full |
| `einv_gui_sounds` | CHECKBOX | client | on | the inventory's sounds |
| `einv_gui_soundVolume` | SLIDER 0 to 2 | client | 1 | their volume |
| `einv_gui_soundsWorld` | CHECKBOX | global | on | players nearby hear someone loot |
| `einv_gui_animation` | LIST | global | While looting | Off, While looting, Always: the looting pose |
| `einv_gui_moveToStop` | CHECKBOX | client | on | a movement key closes the window while looting |
| `einv_gui_searchTime` | SLIDER 0 to 3 | global | 0.4 | seconds per cell searched; 0 shows everything |
| `einv_gui_searchBodies`, `searchPersons`, `searchContainers` | CHECKBOX | global | on | what has to be searched |
| `einv_gui_searchGround` | CHECKBOX | global | off | loose items on the ground too |
| `einv_gui_personNotify` | CHECKBOX | global | on | the person whose gear is opened is told |
| `einv_gui_personOpen` | LIST | global | Everyone | Everyone, Unconscious and captives, Only the unconscious |
| `einv_gui_personItems` | LIST | global | Everyone | who may take items from and put into a living person's gear: Everyone, Unconscious and captives, Nobody - look only |
| `einv_gui_personWorn` | LIST | global | Unconscious and captives | who may take off what a living person wears: Everyone, Unconscious and captives, Nobody |
| `einv_arsenal_biArsenal` | LIST | global | `ace` | the vanilla Virtual Arsenal: `ace` (ACE Arsenal with the box's items), `block`, `vanilla` |
| `einv_arsenal_biMessage` | EDITBOX | global | "" | the line on the "not allowed" screen |
| `einv_hotbar_enabled` | CHECKBOX | global | on | the hotbar row, bar and keys |
| `einv_hotbar_leaderKeys` | CHECKBOX | client | on | leave the keys to Arma while leading AI |
| `einv_hotbar_hudMode` | LIST | client | While in use | Never, While in use, Always |
| `einv_hotbar_hudTime` | SLIDER 1 to 15 | client | 4 | seconds the bar stays after a key |
| `einv_magazines_repack` | CHECKBOX | global | on | the window's own repack |
| `einv_weight_heavyAt` | SLIDER 0 to 100 | global | 0 | kg; 0 follows ACE's fatigue |
| `einv_weight_overloadedAt` | SLIDER 10 to 100 | global | 45 | kg |
| `einv_weight_criticalAt` | SLIDER 10 to 150 | global | 60 | kg, at least 1 above Overloaded |
| `einv_weight_effects` | CHECKBOX | global | on | no sprinting from Overloaded, walking only at Critical |
| `einv_weight_notify` | CHECKBOX | client | on | a message when the tier changes with the inventory closed |
| `einv_locks_zeusOpens` | CHECKBOX | global | on | Zeus may open locked containers |

CBA keybinds: `einv_hotbar_slot1` to `slot7` (4 to 0), `einv_hotbar_show`, `einv_setup_openWizard` (unbound). Kept in the player's
profile: `einv_gui_cameraOn`, `einv_gui_searchMuted`, `einv_hotbar_slots`.

**What missions and other mods may set** (all optional): on an object `einv_grid` (a grid text, public), `einv_noSearch`,
`einv_nearby = false`, `einv_noAccess` (a person); in a mission `einv_arsenal_biPassThrough`; in an item's config `einv_gridSize[]
= {w, h}`, `einv_stackSize`, `einv_grids[] = {{cols, rows}, ...}`, `einv_slots`, `einv_sound = "family"`; a preset as a class of
`CfgEinvRulesets`; a sound family or action in `CfgEinvSounds`; a lock through `einv_locks_fnc_setLock` or `addProvider`; an op,
guard or carried variable in the storage's tables (section 3).

## 9. Known limits and untested

### Known limits

- **Transactions and multiplayer.** A client's connection dropping inside one send batch can lose a payload it took, or settle a
  put again (the hub names it in the RPT). Changes outside this machinery - ACE medical treatment, EFAK's own pouch, the engine's
  scroll-menu actions, scripts - are not serialised with ours; a script error in our own code exactly between an engine change and
  its journal line returns that payload once more. A machine that holds a phase and hangs holds it until it answers or leaves (the
  hub re-sends every 10 s, the window stops showing it as pending after 15 s; nothing is re-added on a timeout). The vanilla
  inventory in multiplayer opens only on own gear. The player's own arrangement reaches others up to 2 s after their moves; moves
  in the last 2 s before a player quits (not dies) with the window closed are never broadcast. A client whose rules differ from
  the server's draws other sizes and asks for normalises (at most every 30 s): fix the settings. Nested containers rely on the
  same `netId` on every machine. Settlement skips guards by design: an item can go back into a container that was locked meanwhile -
  it came from there.
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
  and everything removed with the weight limit; the panel's ACE look, staging space, list drag, wheel and focus rule; the backpack
  as the fourth gear slot; shaped grids, `like=`, shaped items with rotation, positional compartments with insets, width 10, the
  presets `default` revision 2, `realism` and `weight` revision 2; the wizard (Start, Items, Containers with paint, Blocks and
  Same as, Review); the window details (the menu's right-click fall-through, the weight card without ticks, count pills, the
  n/stack badge); the backpack drop with its safety nets and `einv_storage_debugDrop`; `hasSpace` with partial stacks.
- **Features older than that but newer than the 0.2.3 test**: the sound families and the looting pose, "moving stops looting", the
  magazine fill bar and the repack, the weight tiers with their effects and the comparison card, the window's lock gates, ACE
  cargo, TFAR and ACRE2 radios, the vanilla Virtual Arsenal handling.
- **Three gate tests that were never run**: whether variables on nested objects reach other machines (G1; both ways are kept), the
  jog speed in ACE's fatigue model that Heavy is derived from (G2; `JOG_SPEED` is ACE's number), whether the engine's "Rearm"
  respects `lockInventory` (G4). Also unconfirmed: that the topmost group takes the mouse wheel (so nothing under a kit window
  scrolls) and that a group's fade carries its controls (the kit windows' fade-in).
- **Multiplayer on a dedicated server**: the hub, the handshake and the nested copies are designed for it; `HISTORY.md` records no
  dedicated-server run.
