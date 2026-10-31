# Enhanced Inventory: implementation design for the setup wizard, rule-based definitions and shaped items

Read-only design. No files were changed. The three research reports are merged below. Contradictions are resolved in section 1. Section 5 fixes the interfaces up front. Section 6 splits the work into six packages with disjoint file sets that can be built in parallel. Section 7 sets the order. Section 8 lists what to check in the game.

---

## 0. Decisions in one page

1. **One setting holds the whole setup:** `aio_items_rules` (EDITBOX, isGlobal 1, default `aio1 base=default`).
   - It holds a short versioned rules text: a base preset plus your own statements.
   - The wizard only edits this text. CBA handles storage (client, mission, server, force), sync, JIP and its own import/export.
   - The unreleased tables (`aio_items_sizeTable`, `aio_items_stackTable`, `aio_storage_containerTable`) and the sliders `aio_items_massPerCell` and `aio_items_stackSmall` are retired. They map 1:1 into the rules (section 2.8).
2. **Batch editing through selectors:** kind, category, class (exact, with descendants, contains), CfgPatches addon, magazine well, the weapon a magazine fits, and mass, rounds and load comparisons. Named **groups** (`@mag_rifle`) are reusable selectors. Each row in the wizard's step 2 is a group.
3. **Layers, highest first:** your own rules, then mod config (`aio_gridShape` / `aio_gridSize[]` / `aio_stackSize` / `aio_grids[]` / `aio_slots`), then the preset rules, then the built-in fallback.
   - Within a layer, a later rule wins, field by field.
   - The fields are footprint (size and shape together), stack and grid.
4. **The shipped default (`CfgAioRulesets >> default`, revision 1) is an exact port of today's rules:** `fnc_getSize`, the stack rules in `fnc_getInfo` and `fnc_getBlocks`. Nothing changes for anyone until they edit. There are no shapes in the default.
   - Further presets: `tarkov` and `weight`.
   - Empty or unreadable text falls back to the default.
5. **Shapes:** one shape grammar (`2x3`, `L3`, `10/11`, optional `@1..3` turns) is used everywhere: rules, mod config, export, the wizard.
   - The grid engine gets four orientations, per-cell occupancy and per-tile cell owners.
   - A rectangle runs exactly today's code path.
6. **Wizard:** a new addon `setup` (`aio_setup`, requires `aio_gui`) with five steps: Start, Groups, Items, Containers, Review.
   - **Main entry:** a button in CBA Addon Options, in the free slot of CBA's bottom button row. It shows only while our category is selected.
   - **Fallback entries:** ESC > Options, an unbound keybind, the Eden Tools menu, a cog in the inventory header, and "Change size or shape..." on a tile.
7. **Multiplayer:** the setting is server/mission-wide.
   - Every machine compiles the same text and resolves the same sizes. The server publishes a hash, so a client with a different mod version is warned.
   - Layout records stay local, as today.
8. **Sharing:**
   - the bare rules text;
   - "full" with the preset inlined (`base=none`);
   - a ready CBA line `force aio_items_rules = "...";`, which works in our import, CBA's Import box and any `cba_settings.sqf`.

---

## 1. Contradictions between the reports, resolved

| # | Topic | cba / shapes report | wizard report | Decision and why |
|---|---|---|---|---|
| 1 | Data model | Keep the three class tables; the wizard writes them; shapes go into `sizeTable` | One `aio_items_rules` text with a rule language | **One rules setting.** Class tables can only batch through parent classes, so "all rifle magazines" or "all grenades" is impossible. That is exactly the batch editing the user asked for. One string means one share unit, one CBA row to force or lock, and no precedence question between two user layers. The tables are unreleased (0.1.11, no commits). If the user wants to keep them, the fallback is to compile them as own rules appended last (`class=X+ > size=…`), costing one extra function in WP1. |
| 2 | Statement separator, comments | CBA's `fnc_parse` splits on `;` without regard to strings. Never use `; " ' # \ // /*` | `;` separates, `#` comments | **`,` separates statements; no comments in the stored text.** `;`, LF and CR are still read as separators; the writer emits only `, `. Comments live only in the config presets (C++ comments). |
| 3 | Shape notation | `size` table value: `WxH`, `PRESET`, mask, `@N` | `shape=NAME\|ROWS` plus `size=WxH` | **One footprint field**, written `size=` or `shape=` (aliases) and parsed with the shapes grammar, plus `size=mass`. The writer uses `size=` for rectangles and `mass`, and `shape=` otherwise. A later footprint replaces an earlier one completely. |
| 4 | Seventh element of a layout record | `turns` (0..3) | mask | **`turns`**. 0° and 180° share a bounding box but occupy different cells, so the record needs the orientation. The mask comes from the class's info. |
| 5 | Mod config key for shapes | `aio_gridShape` | `aio_shape` | **`aio_gridShape`** (STRING, shape grammar), next to `aio_gridSize[]`; it wins over it. |
| 6 | CBA button | Bottom-row gap between Load (9021) and Import (9010), positioned relative to them; shown and hidden by polling; menu-mode apply through `cba_settings_fnc_import` into CBA's temp namespaces; CBA's OK commits | Button inside the combo's controls group; `ctrlActivate` CBA's OK, open the wizard elsewhere, reopen the CBA menu | **cba report**, which is verified against the CBA 3.19 source. Writing into the temp namespace makes CBA's row show our value (yellow), so there is no stale write-back. The user's other pending edits are not committed behind their back. Cancel and the discard prompt keep working. |
| 7 | Fallback entry points | pause menu, keybind, inventory header, Eden menu | adds a chat command and a LIST-setting hack | **pause menu, unbound keybind, Eden Tools menu, inventory header cog, tile context menu "Change size or shape..."**. The LIST-setting hack is rejected (it is a fake setting that shows in exports and only fires after OK). The chat command is dropped as redundant. |
| 8 | Who sees the inventory cog | everyone (read-only plus export) | only those allowed to save | **Everyone.** Non-admins get a read-only wizard so they can see and copy the server's setup. The tile entry "Change size or shape..." shows only to those who can save. |
| 9 | Default content | shapes: no shapes | `default` described as a port of today's logic, but it adds ACE IV, splint and kit anchors and a `med_small` group | **Revision 1 is an exact port; no class anchors.** Today's `sizeCorrections` is empty, so anchors would change behaviour. They come in a later revision after tuning in the game. A rule-less handle group `@medical: cat=medical` is added so medical items can be batch-edited. The magazine groups are made a true partition (`mag_small`, `mag_rifle`, `mag_large`, …) so each row's label is correct. |
| 10 | Preset revisions `base=x@rev` | – | `@rev` selects a revision | **Dropped in v1.** `base=` always means the installed preset. The server hash catches version drift. "Copy full" freezes a setup by inlining the preset. The config keeps `revision` for display only. |
| 11 | Per-display UI registries in gui | – | Move `created`/`grids` from uiNamespace onto the display | **Not done** (it would touch about 15 gui files that WP3 rewrites). Instead, `fnc_createGrid` gets a `register` parameter (false for the wizard). The wizard builds everything inside its own controls groups and never coexists with the inventory: every entry point closes the inventory first. |
| 12 | Selector keys | – | kind, cat, class, addon, author, ammo, well, for, use, rounds, mass, load | **v1:** kind, cat, class, addon, well, for, mass, rounds, load. **Later:** `use=` (a reverse index of 1–3 s), `ammo=`, `author=`. An unknown key drops the statement with a warning. |
| 13 | Ordering of your own rules | – | auto-sort plus an "Order by hand" switch | **The engine uses plain text order (later wins).** The wizard inserts each new rule at the end of its section (group rules, then filter rules, then class rules by lineage depth, deepest last). It never reorders existing rules. Custom order is done through "Edit as text" in step 5. There is no switch. |
| 14 | Crates and vehicles | – | Two extra kinds, `crate` and `vehicle` | **Adopted.** `getInfo` "kind" for a non-backpack CfgVehicles class becomes `vehicle` (isKindOf AllVehicles) or `crate`, instead of `unknown`. Nothing checks `"unknown"` today (grep). |
| 15 | Mission vs server priority | mission source: always `force` (1); server: 1, or 2 with an override box | "Force toggle 1 or 2" | **Mission (Eden): always priority 1. Server: 1, or 2 with "Override the mission's setup".** With isGlobal 1, a server value of 1 ties with a mission value of 1 and the mission wins. |
| 16 | Where the shape presets live | `GVAR(shapePresets)` in items XEH_preInit | – | **`CfgAioShapes` config** (WP2), cached lazily inside the shape functions. This keeps WP2 out of WP1's preInit. |

---

## 2. Rule-based definitions

### 2.1 The setting

```sqf
// items/initSettings.inc.sqf, ----- Grids ----- (the only setting left there; a text box, so last anyway)
[
    QGVAR(rules), "EDITBOX",
    [LLSTRING(Setting_Rules), LLSTRING(Setting_Rules_Desc)],
    [CBA_SETTINGS_AIO, LLSTRING(SubCategory_Grids)],
    "aio1 base=default",
    1,
    {params ["_text"]; [_text] call FUNC(loadRules)}
] call CBA_fnc_addSetting;
```

The `aio_items_rules` variable is the **text**. The compiled form is `aio_items_ruleset`. Do not reuse the setting's name for it.

Description, wrapped about every 40 characters:
`How big every item is, its shape, how\nmany share a tile and how containers\nare split into compartments - one text\nfor everyone.\n\nEasiest with the setup wizard: the\nInventory setup button at the bottom of\nthis page, or ESC > Options.\n\nCopy this text to share a setup. What\ncannot be read is left out and named in\nthe RPT; empty means the default.`

`gridOnly` (storage, checkbox) stays. Everything else listed in decision 1 is removed.

### 2.2 Grammar (final)

```
text       := statement { SEP statement }
SEP        := "," | ";" | LF | CR            read; the writer only ever emits ", "
statement  := header | groupdef | rule | ""  blank statements are skipped silently
header     := "aio" INT { " " hopt }        first statement only; missing = "aio1 base=default"
hopt       := "base=" ID | "cell=" NUMBER    base=none: no preset; cell 1..50 (config mass per cell)
groupdef   := "@" ID ":" cond { " " cond }   the same id twice in one layer = OR;
                                             an own definition replaces the preset's definition of that id
rule       := { cond " " } [ "> " ] value { " " value }
                                             at least one value; no condition = every item;
                                             a bare ">" token is only for readability
cond       := [ "!" ] ( "@" ID { "|@" ID } | KEY OP VAL { "|" VAL } )   "|" = OR, spaces = AND
value      := ("size" | "shape") "=" FOOT | "stack=" INT | "grid=" GRID
FOOT       := "mass" | SHAPE                 SHAPE: section 3.2
GRID       := "auto" | INT | INT "%" | PATTERN [ ":" INT ] | INT "x" INT { "+" INT "x" INT }
PATTERN    := pockets | pockets_mixed | rig | mixed | plate | long | single | wide
ID         := [a-z0-9_]+                     case-insensitive, stored lower case
```

- Tokens are split on spaces.
- Tokens are classified by key: `size`, `shape`, `stack` and `grid` are values; everything else is a condition. A condition token after a value is an error.
- **Allowed characters:** letters, digits and `_ + . / % : | @ ! < > = ~ ,` plus space. A statement containing anything else (notably `" ' # \`) is dropped with an RPT warning that names it.
- The writer never emits `//`. Masks have no empty rows.
- If the header version is higher than 1, the text is read best-effort with one warning.

### 2.3 Selector keys (same answer on every machine)

| Key | Ops | Matches |
|---|---|---|
| `kind` | `=` | getInfo kind. Values: rifle, handgun, launcher, binocular, muzzle, optic, rail, bipod, headgear, nvg, vest, uniform, map, gps, radio, compass, watch, item, magazine, grenade, backpack, goggles, crate, vehicle, unknown. An unknown value is warned about. |
| `cat` | `=` | misc, gear, weapon, ammo, medical (CATEGORY_*) |
| `class` | `=` `~` | `=X` exact; `=X+` X and everything inheriting from it (lineage); `~t` the lower-case class name contains t |
| `addon` | `=` `~` | the first entry of `configSourceAddonList`, lower case. `addon~rhsusf_` |
| `well` | `=` | the magazine is listed in that `CfgMagazineWells` class (lazy reverse index, built once) |
| `for` | `=` | the magazine is in `compatibleMagazines <weapon>` (resolved once at compile time) |
| `mass` `rounds` `load` | `= < <= > >=` | config mass (tenths of a pound); a magazine's `count` (raw, so also for kind grenade); maxLoad as in getInfo (crates and vehicles: `maximumLoad`) |

- Display names (localized) and `configSourceMod` (the folder differs per machine) are never used for matching.
- The wizard shows mod names, but writes `addon~prefix` or `addon=a|b`.

### 2.4 Values

- **Footprint.** `size=WxH`, `size=L3`, `shape=10/11@1`, … through `parseShape` (WP2).
  - `size=mass` gives an area of `ceil(mass / cell)` cells (at least 1).
  - Rifles and launchers lie 2 rows high: h = min(2, area), w = ceil(area / h).
  - Everything else is near square: w = ceil(sqrt area), h = ceil(area / w).
  - The width is clamped to STORAGE_COLS.
- **`stack=N`:** N from 1 to 999. 1 means it does not stack.
  - It is forced to 1 for rifle, handgun, launcher, binocular, uniform, vest and backpack (source `forced`), exactly as today.
- **`grid=`:** containers only (uniform, vest, backpack, crate, vehicle). Ignored on other kinds. Resolved specs:
  - `auto` → `["auto"]`
  - `24` → `["cells", 24]`
  - `120%` → `["percent", 120]` (10..500)
  - `rig` → `["pattern", "rig", -1]`; `rig:16` → `["pattern", "rig", 16]`
  - `6x4+2x3` → `["blocks", [[6,4],[2,3]]]` (w ≤ STORAGE_COLS, h ≤ MAX_ROWS)

### 2.5 Shipped rulesets (`items/CfgAioRulesets.hpp`, WP1)

```cpp
class CfgAioRulesets {
    class default {
        name = CSTRING(Ruleset_Default);
        description = CSTRING(Ruleset_Default_Desc);
        revision = 1;
        base = "";      // "" = none
        cell = 5;       // -1 = inherit from base
        rules[] = {
            "size=1x1 stack=1",
            "@rifle_light: kind=rifle mass<=55", "@rifle_medium: kind=rifle mass>55 mass<=90",
            "@rifle_heavy: kind=rifle mass>90 mass<=150", "@rifle_xheavy: kind=rifle mass>150",
            "@handgun: kind=handgun", "@launcher: kind=launcher",
            "@rifle_light > size=3x2", "@rifle_medium > size=4x2", "@rifle_heavy > size=5x2",
            "@rifle_xheavy > size=6x2", "@handgun > size=2x1", "@launcher > size=6x2",
            // magazines: a partition, ordered so that later wins reproduces today's first match
            "@mag_large: kind=magazine mass>20", "@mag_rifle: kind=magazine mass>5 mass<=20",
            "@mag_small: kind=magazine mass<=5", "@rocket: kind=magazine rounds=1 mass>15 mass<=60",
            "@rocket_heavy: kind=magazine rounds=1 mass>60", "@belt: kind=magazine rounds>=50 mass>15",
            "@grenade: kind=grenade",
            "@mag_large > size=2x2", "@mag_rifle > size=1x2", "@mag_small > size=1x1",
            "@rocket > size=1x3", "@rocket_heavy > size=2x3", "@belt > size=2x2",
            "@grenade > size=1x1 stack=5",
            "@optic_small: kind=optic mass<=8", "@optic_large: kind=optic mass>8",
            "@muzzle: kind=muzzle", "@rail_bipod: kind=rail|bipod",
            "@optic_small > size=1x1", "@optic_large > size=2x1", "@muzzle > size=2x1", "@rail_bipod > size=1x1",
            "@item_small: kind=item mass<=10", "@item_medium: kind=item mass>10 mass<=30",
            "@item_large: kind=item mass>30 mass<=60", "@item_xlarge: kind=item mass>60",
            "@medical: cat=medical",            // handle only, no rule: lets step 2 batch-edit medical items
            "@item_small > size=1x1 stack=10", "@item_medium > size=2x1",
            "@item_large > size=2x2", "@item_xlarge > size=3x2",
            "@assigned: kind=map|gps|radio|compass|watch", "@goggles: kind=goggles",
            "@nvg_binocular: kind=nvg|binocular", "@headgear: kind=headgear",
            "@assigned > size=1x1", "@goggles > size=1x1", "@nvg_binocular > size=2x1", "@headgear > size=2x2",
            "@uniform: kind=uniform", "@vest: kind=vest",
            "@backpack_small: kind=backpack load<=160", "@backpack_medium: kind=backpack load>160 load<=280",
            "@backpack_large: kind=backpack load>280", "@crate: kind=crate|vehicle",
            "@uniform > size=2x2 grid=auto", "@vest > size=3x3 grid=auto",
            "@backpack_small > size=3x3 grid=auto", "@backpack_medium > size=4x4 grid=auto",
            "@backpack_large > size=4x5 grid=auto", "@crate > grid=auto"
        };
        class Groups {   // wizard labels; family = filter chip; example = optional class for the row picture
            class rifle_light { name = CSTRING(Group_rifle_light); family = "weapons"; example = ""; };
            // ... one class per group id above
        };
    };
    class tarkov {
        name = CSTRING(Ruleset_Tarkov); description = CSTRING(Ruleset_Tarkov_Desc); revision = 1;
        base = "default"; cell = -1;
        rules[] = {
            "@grenade > stack=1", "@item_small > stack=1",
            "@rifle_light > size=4x2", "@rifle_medium > size=5x2", "@rifle_heavy > size=6x2", "@rifle_xheavy > size=7x2",
            "@uniform > grid=pockets:4", "@vest > grid=rig",
            "@backpack_small > size=4x4 grid=4x5", "@backpack_medium > size=5x5 grid=5x6",
            "@backpack_large > size=5x6 grid=6x7"
        };
    };
    class weight {
        name = CSTRING(Ruleset_Weight); description = CSTRING(Ruleset_Weight_Desc); revision = 1;
        base = "default"; cell = 4;
        rules[] = { "size=mass", "@grenade|@item_small|@mag_small > stack=10" };
    };
};
```

- **Group ids and families.** The group ids are API: own rules refer to them, so never rename one.
  - Families: weapons, ammo, attachments, items, worn, containers. The containers family is uniform, vest, the three backpacks and crate.
  - Other mods may add preset classes. A `base` chain may be at most 4 deep; cycles are rejected with a warning.
- **Known small difference.** Today `stackSmall` keys on the final size `[1,1]`. `@item_small` keys on mass ≤ 10. An item with mass ≤ 10 whose mod sets `aio_gridSize` to something larger now stacks by 10 unless the mod also sets `aio_stackSize`. Accept this and document it.

### 2.6 Compile, resolve and cache (items, WP1)

**Facts** (`fnc_getFacts`, cached in `GVAR(facts)`, never cleared):
- class, lc, root, kind, category, mass, rounds, maxLoad
- lineage (lower case, self first)
- addon
- mod: gridShape, gridSize, stackSize, grids, slots
- name, short, description, picture (display only)

**Compile** (`fnc_compileRules`, never throws):
1. Parse your own text into layer U.
2. Expand the base chain from config into layer P, base first, then the derived presets.
3. Build the group table: P definitions, then U. A U id replaces the P id; several definitions in one layer are ORed.
4. Compile the conditions:
   - sets as HashMaps;
   - `class=X+` as a lineage test;
   - numbers as `[field, op, n]`;
   - `for=` becomes a magazine set;
   - `well=` triggers the reverse index;
   - group references stay references, evaluated recursively (depth ≤ 4).
   Conditions are sorted cheapest first: kind, then numbers, then sets, then substrings.
5. Bucket by kind. A rule's possible kinds come from its positive `kind=` conditions, or from its positive group references whose every alternative has a kind; otherwise it can match any kind. For every kind, U and P each get an array of rule indices, latest first.
6. Store `cell` (own header, else the chain's last non-negative value, else 5), `hash = hashValue str [cell, expanded canonical statements]` and the warnings.
7. An unknown base falls back to `default` with a warning.

**Resolve** (`fnc_resolve [facts, compiled]`):
```
need = [footprint, stack] + [grid] if kind in [uniform, vest, backpack, crate, vehicle]
U  : for idx in byKind[kind].own (latest first): if fields∩need and matches -> take, src "own:<idx>"
MOD: footprint <- gridShape (parseShape) | gridSize[] valid; stack <- stackSize; grid <- grids[] | slots>0   ("mod:<key>")
P  : same walk as U over the preset rules, src "preset:<presetId>:<n>"
BUILTIN: [1,1,[]], 1, ["auto"]                                                                              ("builtin")
finalize: "mass" -> formula; width clamp; stack floor max 1, forced 1 for weapons/containers ("forced")
```

**getInfo** (`[class, compiled, cache]`):
- returns a copy of the facts plus the resolved values;
- `shapeForms` provides forms, turns and canon; `formatShape` provides shape;
- cached per lower-case class;
- if `GVAR(ruleset)` is nil (getInfo runs before the settings), it compiles `aio1 base=default` lazily.

**Live reload** (`fnc_loadRules [text]`, the setting script, on every machine):
1. Compile.
2. Set `GVAR(ruleset)` and `GVAR(massPerCell) = cell`.
3. Clear `GVAR(info)`; facts stay.
4. Increment `GVAR(rulesRevision)`.
5. On the server: `missionNamespace setVariable [QGVAR(rulesHash), hash, true]`.
6. On a client: compare with the server's hash (here and in a PV handler set in preInit). On a mismatch: warn once in the RPT and systemChat `LLSTRING(Warning_HashMismatch)`.
7. Raise `[QGVAR(rulesChanged), [revision]] call CBA_fnc_localEvent`.

**Cost:** resolving one class is about 50 rules × 3 conditions, roughly 0.05–0.2 ms, and is cached. Building the forms takes microseconds.

### 2.7 Saving, permissions and sharing

| Where | Target source | Priority | Note |
|---|---|---|---|
| Eden | `mission` | 1 (always force) | stored in the scenario attributes; the user must save the scenario |
| SP, host (`isServer`) | `server` | 1, or 2 with "Override the mission's setup" | own profile; CBA broadcasts, JIP included |
| MP client, logged-in admin or whitelisted (`cba_settings_fnc_whitelisted`) | `server` | as above | `CBA_settings_fnc_set` forwards to the server; the change returns via the setting script |
| Other players | read-only | – | can export, and can keep personal presets in `profileNamespace "aio_setup_presets"` (`[[name, text, date]]`) |
| CBA menu, "client" tab selected | read-only | – | hint: "switch to the Server or Mission tab" (client values never apply to an isGlobal setting) |
| Locked by `cba_settings.sqf` (`cba_settings_serverConfig` / `cba_settings_missionConfig` has the setting) | read-only | – | offers "Copy as cba_settings line" instead |

**Menu mode** (opened from the CBA button). The wizard never calls `set`:

```sqf
private _prio = ["force ", "force force "] select (_source == "server" && {_override}); // mission: always "force "
[format ["%1aio_items_rules = %2;", _prio, str _text], _source] call cba_settings_fnc_import;
```

- CBA's row turns yellow, and CBA's OK commits the value.
- The wizard's button reads "Apply to Addon Options" and closes the wizard after applying.

**Direct mode** (every other entry point):

```sqf
["aio_items_rules", _text, _prio, _source, true] call CBA_settings_fnc_set
```

**Conflicts.** At save, compare the active text with the text the wizard opened from (`GVAR(origin)`). If they differ, offer: reload and replay my edits / overwrite / cancel.

**Import** accepts:
- a bare rules text;
- one or more CBA lines. Run `[_text, true, _source, false] call cba_settings_fnc_parse` and keep only `aio_items_rules` (compared with `toLower`).

**Export variants:**
- own: the text as stored;
- full: the base inlined as `base=none` plus the expanded statements;
- cba: `force aio_items_rules = "…";`

Copying works through a selectable `AIO_EditArea` (Ctrl+A, Ctrl+C), which works everywhere. A "Copy" button (`copyToClipboard`) is shown only when `isServer || !isMultiplayer`. Import goes through a paste box.

### 2.8 Old settings mapped (WP1 removes them; the wizard needs no legacy import)

| Old | New |
|---|---|
| `sizeTable X:WxH` | `class=X+ > size=WxH` |
| `stackTable X:N` | `class=X+ > stack=N` |
| `containerTable X:N` / `X:6x4+2x3` | `class=X+ > grid=N` / `grid=6x4+2x3` |
| `massPerCell` | header `cell=` |
| `stackSmall` | `@item_small > stack=N` |
| `sizeCorrections` | class anchors in a later revision of `default` |

Nearest-parent-wins becomes "class rules sorted by lineage depth, deepest last", which the wizard's writer guarantees.

---

## 3. Shaped items in the grid engine (shapes report, adopted with the changes above)

### 3.1 Facts the design relies on

- Layout records are local (`setVariable` without broadcast). The server's move handler does not check grid space, so changing the record format has no multiplayer risk.
- Tile backgrounds are semi-transparent. A shape must therefore be drawn as an exact partition (rects plus 1-px seams), never as overlapping rectangles.
- `fnc_tileAt` and the overlap test in `fnc_updateDrag` are O(tiles) today. A per-grid cell → tile owner array makes shapes possible and makes both O(1) or O(cells).

### 3.2 Shape grammar (WP2; used by rules, `aio_gridShape` and the wizard)

```
SHAPE := BASE [ "@" ("1"|"2"|"3") ]         quarter turns clockwise
BASE  := INT "x" INT | PRESET | ROW { "/" ROW }
ROW   := ("0"|"1")+                         shorter rows padded with 0
```

- Parse order: preset name (case-insensitive), then `WxH`, then mask.
- A mask must be trimmed, 4-connected, at most STORAGE_COLS wide and made of 0 and 1 only. Otherwise the result is `[]` with a warning.
- `fnc_formatShape` writes:
  - `WxH` for a full rectangle;
  - `PRESET` or `PRESET@N` when the mask equals a preset turned N quarters (smallest N);
  - the mask otherwise.
  Text therefore round-trips.

**Presets** (`CfgAioShapes`, `class L3 { mask = "10/11"; };`):

| preset | mask | preset | mask |
|---|---|---|---|
| L3 | `10/11` | S4 | `011/110` |
| L4 | `10/10/11` | Z4 | `110/011` |
| J4 | `01/01/11` | U5 | `101/111` |
| T4 | `111/010` | P5 | `11/11/10` |
| L5 | `10/10/10/11` | | |

There is no mirroring, because `ctrlSetAngle` cannot flip a texture.

### 3.3 Data model

`main/script_macros.hpp` (WP2):

```
#define FORM_W 0      // bounding box across
#define FORM_H 1      // bounding box down
#define FORM_CELLS 2  // [[col,row],...] filled, row-major
#define FORM_RUNS 3   // per row [[startCol,len],...]
#define FORM_RECTS 4  // exact partition [[c,r,w,h],...]
#define FORM_SEAMS 5  // [[c,r,len],...] 1-px gap under row r between two different rects
#define FORM_BODY 6   // [c,r,w,h] largest all-filled rectangle (picture, "?", search ring)
#define FORM_FULL 7   // BOOL plain rectangle -> today's fast paths
```

- A form is `[W, H, CELLS, RUNS, RECTS, SEAMS, BODY, FULL]`.
- **Rotation:** clockwise, `(c,r) → (H-1-r, c)`. A rect `[c,r,w,h]` becomes `[H-r-h, c, h, w]`.
- **Body:** computed for form 0 only (largest area; ties go to the squarer rectangle, then top-left) and rotated with the mask.
- **Turns:** a square or plus has `[0]`; a rectangle, I or S has `[0,1]`; L, T or U has `[0,1,2,3]`. `canon` maps any turn to the distinct one it equals.
- **getInfo keys:**
  - unchanged: `size` (upright box `[w,h]`)
  - new: `cells`, `forms`, `turns`, `canon`, `shape`
- **Entry keys** set by getLayout: `w`, `h` (as it lies), `turns` (0..3), `rotated` (= turns mod 2 == 1, kept for compatibility), `cells`, `block`, `col`, `row`, `overflow`.
- **Records:** `[class, col, row, w, h, block, turns]`. A 6-element record derives its turns as today.

### 3.4 Engine behaviour (WP2 storage, WP3 gui)

**getLayout:**
- **isFree / take:** walk `FORM_RUNS`; a full form keeps the current row-slice loop.
- **Reconcile:**
  1. Map the record's turns through canon.
  2. Accept the record only if the form's W/H equal the record's and the cells are free. This also re-places items whose shape changed.
- **Order:** `[-cells, -(w*h), category, class, index]`.
- **Auto-turn:** try `turns` in order. For rectangles that is "upright first, then turned", exactly as today.

**setPlace and the network:**
- The cell becomes `[col, row, block, w, h, turns]`.
- `entryToArray` / `entryFromArray` carry `turns` at index 10.
- `getSlot` sets `turns` 0.

**gui:**
- `createGrid` adds `owner` (cols×rows array of tile index or −1).
- `createTile` hides only the filled cells, writes their owner, and draws one `AIO_PanelRect` per `shapePieces` piece. It stores `backgrounds`, `background` (first) and `bodyRect`. The picture, "?", name and count are laid out in the body, top run and bottom run.
- `tileAt` becomes an O(1) owner lookup.
- **Drag:**
  - The footprint is a pool of panel controls (the largest piece count over all forms).
  - The overlap test checks the owners of the form's cells.
  - R cycles `turns`, and the grabbed cell follows the rotation.
  - `GVAR(dragTurns)` is passed in the cell.
  - "Dropped where it lies" also compares the turns.
- `uiPictureTurned` gets an angle parameter (0/90/180/270).
- hover, inspect, flash, search ring, reveal and markHidden use backgrounds, bodyRect and cells.
- **Hint text:** a full shape shows `w×h`; otherwise `2×2 · L3` or `2×2 · 3 cells`.

**Previews for the wizard:**
- Entries may carry `"info"` (a pre-resolved info HashMap). `getLayout` and `createTile` use it instead of calling `getInfo`.
- `getLayout` takes an optional blocks parameter.
- `createGrid` takes `register` and a cell-size override.

### 3.5 Performance

- Rectangles cost exactly what they cost today.
- A shape costs about 3–4 controls instead of 1.
- Hover and drag get faster: tileAt goes from O(tiles) to O(1), and the per-frame overlap from O(tiles) to O(cells).

---

## 4. The wizard

### 4.1 Entry points

1. **CBA Addon Options button** (WP6, `fnc_initCbaMenu`):
   - Hooked through `Extended_DisplayLoad_EventHandlers >> RscDisplayGameOptions`. Our entry runs after CBA's (config order; `aio_main` → `cba_main` → `cba_settings`).
   - It creates an `RscButtonMenu` in the gap between Load (IDC 9021) and Import (IDC 9010), positioned relative to them.
   - It is shown only while group 4301 is visible and `lbData` of the combo 4312 equals our category key. The category key is read as `toLower ((cba_settings_default getVariable ["aio_items_rules", []]) param [4, CBA_SETTINGS_AIO])`. The display's `MouseMoving` + `MouseHolding` handlers and `LBSelChanged` sync it.
   - The click handler runs `[ctrlParent btn, "menu", 0, ""] call aio_setup_fnc_open`.
   - It is null-guarded: if CBA changes, the button silently does not appear.
   - The code is in the cba report (section 1, "fnc_initCbaMenu.sqf"); swap `aio_items_sizeTable` for `aio_items_rules`.
2. **ESC > Options > Inventory setup:** `CBA_fnc_addPauseMenuOption` (verified in `cba_ui`) with display class `aio_setup_RscWizard`. Its onLoad defaults to direct mode, step 0.
3. **Keybind** "Open inventory setup": `CBA_fnc_addKeybind`, unbound, mission only.
4. **Eden:** a Tools menu entry (`Display3DEN` menu strip, config only).
5. **Inventory:**
   - a cog in the header (everyone);
   - the tile context menu "Change size or shape..." (only when `canSave`), which opens step 2 (Items) with the class focused and selected.
6. **How they open the wizard:**
   - Items 3 and 5 go through `aio_setup_fnc_openFromGame`, which closes the inventory and opens the wizard on display 46 on the next frame.
   - Item 1 opens it as a child of the CBA display.
   - Item 2 is opened by the engine as a child of the interrupt display.
   - Item 4 opens it on display 313.

### 4.2 Frame and model (WP4)

- `aio_setup_RscWizard`: idd 9620, a dim layer only; everything else is created at run time with the gui UI kit in its own controls groups.
- **Header:** title, step pills (1 Start, 2 Groups, 3 Items, 4 Containers, 5 Review; freely clickable; an accent dot means changed), a source chip ("Server · forced · 4 changes" or "Read-only"), and close.
- **Footer:** Esc, Ctrl+Z, Ctrl+Y, Ctrl+F hints, then Back / Next / Save (or Apply).
- **Draft:**
  - `GVAR(draft)` is the AST from parseRules; `GVAR(draftText)` the canonical text.
  - `GVAR(draftRules)` is the compiled draft; `GVAR(draftCache)` its own getInfo cache.
  - The running game is untouched until Save.
- **Undo and redo:** stacks of texts, 50 deep.
- **Rules changed while the wizard is open:** if the draft is clean, it reloads from the active text; if dirty, a banner offers [Reload] [Keep mine].
- **Keys:**
  - Esc asks first when there are unsaved changes.
  - Return is read in onKeyUp, because edit fields swallow KeyDown.
  - Ctrl+Z / Ctrl+Y undo and redo; Ctrl+F focuses the search.
  - Other keys go to `GVAR(stepKey)`.

### 4.3 Steps

**Step 1, Start (WP4):**
- **Preset cards:**
  - Default, Tarkov-like, Weight-like, Empty (`base=none`), plus every other `CfgAioRulesets` class and every personal preset.
  - Each card shows name, description and a mini preview: `fnc_previewGrid` on an 8×4 grid with arifle_MX_F, 3× 30Rnd_65x39_caseless_mag, HandGrenade and FirstAidKit, under that preset compiled.
- **Choosing a preset:** "Keep your N own rules on top" / "Start empty".
- **Cell stepper (1..50):** "1 cell = 0.23 kg" (`cell × MASS_TO_KG`).
- **Import...** opens a popover.
- **Status card:** active base, number of own rules, where the value comes from, and where you can save.

**Step 2, Groups (WP5):**
- **Rows:** one per group id in the compiled draft, the preset's groups first, then your own. Family chips filter them.
- **Columns:**
  - Group: label, example picture, "covers N" from `ruleStats`;
  - Size: a button that opens the footprint popover;
  - Shape glyph (`uiMask`);
  - Stack: toggle plus stepper; disabled for forced kinds;
  - Grid: a chip, containers only; it jumps to step 4;
  - Reset (shown only when the row differs from the preset);
  - Show items: opens step 3 filtered to this group.
- **Editing a cell** upserts exactly one own rule `@id > field=value` (`fnc_upsertRule`).
- **"New group"** opens a builder: name, condition rows (key, op, value with autocomplete from the index), a live match count. It writes `@id: …`.

**Step 3, Items (WP5):**
- **Filters:** search (class or localized name, debounced 150 ms), kind, mod, group, only changed / stackable / shaped, show weapon presets.
- **Virtual list:** a pooled list with selection (click, Shift range, Ctrl+A).
- **Detail panel:** resolved values with source chips, the size steppers, the cell editor (W×H, cell toggles, quick shapes from `CfgAioShapes`, rotate), and a stack toggle plus count. Only fields you touch are written.
- **Apply scopes:**
  - **Selected** (`class=a+|b+`; "+variants" on by default);
  - **Everything matching:** the filters become conditions. If every match contains the search text in its class name, it becomes `class~text`. Otherwise it is saved as a class list with a warning about the game language;
  - **Their group** (the same as step 2).
- **Rules drawer:** each own rule as a sentence (`describeRule`) with edit and remove.
- **"Why?"** opens a popover from `aio_items_fnc_explain`.

**Step 4, Containers (WP5):**
- **Tabs:** uniforms, vests, backpacks, crates and vehicles.
- **Group rows and a class list** showing load (kg) and the resolved grid with its source.
- **Editor modes:** By load, Cells, % of load, Pattern (+ cells), Compartments (block rows plus "Add block").
- **Live preview:** `blocksFor` → `previewGrid`, with "Fill with: Empty / Rifleman / Medic" (fixed vanilla class lists in WP5), the overflow in red ("3 items don't fit"), and "Load 280 (12.7 kg) · 36 cells".

**Step 5, Review (WP4):**
- **Changes:** a sentence per own rule (`describeRule`) with [jump] and [x].
- **Warnings** (from `ruleStats` and the compile):
  - matches nothing;
  - fully overridden;
  - dropped or clamped values;
  - classes of mods not loaded;
  - name searches saved as classes;
  - text over 8 KB.
- **Text area:**
  - copy buttons for own, full and CBA line;
  - "Edit as text", which re-parses live and shows the warnings.
- **Save card:**
  - target: Server, Mission (Eden only) or Only for me (personal preset), each disabled with its reason;
  - Override toggle (server only);
  - Save or Apply;
  - Save as my preset...;
  - Reset to default (with a confirmation).

### 4.4 Performance (WP5)

**Class index:**
- built once per game session in uiNamespace;
- `configClasses` with scope 2 over CfgWeapons, CfgMagazines, CfgGlasses and CfgVehicles (backpacks; for step 4 also `ReammoBox_F` descendants);
- facts are read in chunks of about 500 per frame behind a progress overlay.

**Rows** are compact arrays: `[lc, class, searchText, name, kind, category, mass, rounds, load, picture, addon, modName, isPreset]`, with kind and mod buckets.

**List and counts:**
- The list has a fixed pool of visible rows + 2; scrolling only sets texts and pictures. There is never one control per result.
- Only visible rows are resolved through the draft cache.
- Coverage counts (`ruleStats`) run in background chunks of about 300 classes per frame, cancelled by a token, and show "…" until done.

---

## 5. Interface contract (fixed before work starts)

### 5.1 Config, settings, variables, events

| Name | Type | Owner |
|---|---|---|
| CBA setting `aio_items_rules` | STRING (the text) | WP1 |
| `aio_items_ruleset` | compiled HashMap (see 5.2), nil until the first compile | WP1 |
| `aio_items_rulesRevision` | NUMBER, starts at 0 | WP1 |
| `aio_items_rulesHash` | STRING, public, set by the server | WP1 |
| `aio_items_massPerCell` | NUMBER (5); a plain variable, no longer a setting; read by `blocksFor` | WP1 |
| `aio_items_info` / `aio_items_facts` | caches (lower-case class → HashMap) | WP1 |
| local event `aio_items_rulesChanged` | args `[revision]` | WP1 raises; WP6 (inventory) and WP4 (wizard) listen |
| `CfgAioRulesets >> id` | `name`, `description`, `revision`, `base`, `cell`, `rules[]`, `class Groups { class <id> { name; family; example; } }` | WP1 |
| `CfgAioShapes >> NAME >> mask` | STRING | WP2 |
| item config keys | `aio_gridShape` (STRING), `aio_gridSize[]`, `aio_stackSize`, `aio_grids[]`, `aio_slots` | read by WP1 (mod layer) |
| `FORM_*` macros | `main/script_macros.hpp` | WP2 |
| local event `aio_setup_draftChanged` | args `[draftText]` | WP4 raises; WP5 listens |

### 5.2 items functions

| Function | Arguments | Returns | Owner |
|---|---|---|---|
| `aio_items_fnc_parseShape` | `[text]` | `[w, h, cells]`, where cells `[]` = full and `[[c,r],…]` is row-major; `[]` if invalid. "mass" is not handled here. | WP2 |
| `aio_items_fnc_shapeForms` | `[w, h, cells]` | `[forms (4 × FORM array), turns ARRAY, canon ARRAY(4)]` | WP2 |
| `aio_items_fnc_formatShape` | `[w, h, cells]` | STRING (`2x3` / `L3@1` / `10/11`) | WP2 |
| `aio_items_fnc_parseRules` | `[text]` | AST HashMap (below) | WP1 |
| `aio_items_fnc_writeRules` | `[ast]` | canonical STRING: header, then groups, then rules, joined with `", "`; ` > ` before the values; value order footprint, stack, grid | WP1 |
| `aio_items_fnc_compileRules` | `[text]` | compiled HashMap (below) | WP1 |
| `aio_items_fnc_loadRules` | `[text]` | nothing (the live reload in 2.6) | WP1 |
| `aio_items_fnc_getFacts` | `[class]` | facts HashMap (2.6), shared, read-only | WP1 |
| `aio_items_fnc_matches` | `[facts, conds, compiled]` | BOOL (conds = AST conditions or compiled ones) | WP1 |
| `aio_items_fnc_resolve` | `[facts, compiled]` | HashMap `footprint [w,h,cells]`, `stack`, `grid` (spec), `src` (field → tag `own:<i>`, `preset:<id>:<i>`, `mod:<key>`, `builtin`, `forced`) | WP1 |
| `aio_items_fnc_getInfo` (Public) | `[class, compiled (opt), cache (opt)]` | info HashMap: old keys plus `cells`, `forms`, `turns`, `canon`, `shape`, `grid`, `src`, `lineage`, `addon`. Without `compiled`: the active rules and cache. With `compiled` but no cache: uncached. | WP1 |
| `aio_items_fnc_explain` | `[class, compiled]` | `[[layer, index, statementText, fieldsSet, fieldsWon], …]`, highest priority first | WP1 |
| `aio_storage_fnc_blocksFor` | `[class, kind, maxLoad, gridSpec, cell]` | blocks `[[cols, rows], …]` (2.4 specs; the patterns from today's getBlocks; `[[STORAGE_COLS,0]]` when the cells are ≤ 0) | WP1 |

**AST** (shared by WP1, WP4 and WP5):

```
HashMap "version" 1, "base" "default"|"none"|id, "cell" NUMBER (-1 = not set),
        "groups" [[id, conds], ...]  (text order),  "rules" [[conds, values], ...]  (text order),
        "warnings" [STRING, ...]
cond   = [negated BOOL, key STRING, op STRING, vals ARRAY of STRING]
         group reference: key "@", op "=", vals = ids;  class "=X+" keeps the "+" on the value; class case kept
values = HashMap, any of "footprint" STRING (canonical shape text or "mass"), "stack" NUMBER, "grid" STRING (canonical)
```

**Compiled:**

```
HashMap "text" (canonical own text), "base", "chain" [ids], "cell", "groups" HashMap id -> [alternatives],
        "own" [[conds, values, tag], ...], "preset" [...], "byKind" HashMap kind -> [ownIdx desc, presetIdx desc],
        "hash", "warnings"
```

### 5.3 storage and gui changes others rely on

| Function | Change | Owner |
|---|---|---|
| `aio_storage_fnc_getLayout` | `[container, entries, store = true, blocks = nil]`. Entries may carry `"info"`. Sets `turns`, `rotated`, `cells`. Records gain turns. | WP2 |
| `aio_storage_fnc_setPlace` | cell `[col, row, block, w, h, turns]` | WP2 |
| `aio_gui_fnc_createGrid` | `[display, parent, position, rows, theme, section = "", cols = STORAGE_COLS, register = true, cell = []]`. The grid gains `owner`. | WP3 |
| `aio_gui_fnc_createTile` | uses `_entry get "info"` when present | WP3 |
| `aio_gui_fnc_shapePieces` | `[form, cellW, cellH]` → `[[dx, dy, w, h], …]`, rects first | WP3 |
| `aio_gui_fnc_uiPictureTurned` | new parameter 6: angle (default 90) | WP3 |

### 5.4 setup functions and state

**State** (WP4 creates; WP5 and WP6 read):
- missionNamespace:
  - `aio_setup_mode` ("menu" | "direct"), `aio_setup_target` (canEdit result), `aio_setup_readOnly`
  - `aio_setup_origin`, `aio_setup_draft`, `aio_setup_draftText`, `aio_setup_draftRules`, `aio_setup_draftCache`
  - `aio_setup_step` (0..4), `aio_setup_focus` (class), `aio_setup_selection` (HashMap lower-case class → true)
  - `aio_setup_stepKey` (CODE `[key, shift, ctrl, alt, up]` → BOOL)
  - `aio_setup_theme`
- uiNamespace: `aio_setup_display`, `aio_setup_content`, `aio_setup_popover`, `aio_setup_openArgs`, `aio_setup_index` (WP5).

| Function | Arguments | Returns | Owner |
|---|---|---|---|
| `fnc_open` | `[parentDisplay, mode "menu"\|"direct", step 0..4, focusClass ""]` | display | WP4 |
| `fnc_canEdit` | `[mode]` | HashMap `canSave`, `source` (`server`\|`mission`\|`""`), `override` (BOOL: priority 2 allowed), `locked`, `reason` (STRING) | WP4 |
| `fnc_getActive` | `[]` | STRING (menu mode: CBA temp value first) | WP4 |
| `fnc_commit` | `[ast, redraw = true]` | nothing; pushes undo, compiles the draft, resets the draft cache, raises `draftChanged` | WP4 |
| `fnc_showStep` | `[step, args = []]` | nothing; recreates the content group and calls `fnc_draw*` | WP4 |
| step draw functions | `[display, group, theme, args]` | nothing (WP4: drawStart, drawReview; WP5: drawGroups, drawItems, drawContainers; drawItems args `[focusClass]`) | – |
| `fnc_popover` | `[display, anchorRect, [w, h], title, drawCode, args]` | inner group; `drawCode` gets `[display, inner, theme, args]`; only one at a time | WP4 |
| `fnc_closePopover`, `fnc_confirm [display, text, yesLabel, code, args]` | | | WP4 |
| `fnc_describeRule` | `[rule (AST [conds, values]), ast]` | STRING sentence | WP4 |
| `fnc_uiToggle` | `[display, parent, rect, value, theme, code, args, enabled = true]` | controls, hit area last; `code` gets `[newValue, args]` | WP4 |
| `fnc_uiStepper` | `[display, parent, rect, value, [min, max, step], theme, code, args, format = "%1", enabled = true]` | same convention | WP4 |
| `fnc_uiEdit` | `[display, parent, rect, text, placeholder, theme, code, args, multiLine = false, enabled = true]` | controls, edit last; `code` gets `[text, submitted BOOL, args]` | WP4 |
| `fnc_uiChip` | `[display, parent, rect, label, active, theme, code, args, enabled = true]` | same | WP4 |
| `fnc_uiSegmented` | `[display, parent, rect, labels, index, theme, code, args, enabled = true]` | same; `code` gets `[newIndex, args]` | WP4 |
| `fnc_uiDropdown` | `[display, parent, rect, [[label, value], …], value, theme, code, args, enabled = true]` | same; uses `fnc_popover` | WP4 |
| `fnc_previewGrid` | `[display, parent, [x, y], blocks ([] = [[8, 4]]), classes, theme, compiled, cache, cell = []]` | HashMap `controls`, `overflow`, `size` | WP5 |
| `fnc_buildIndex` | `[onDone]` | nothing (async; the result goes in `aio_setup_index`) | WP5 |
| `fnc_ruleStats` | `[compiled, onDone]` | token; `onDone` gets HashMap `own` → `[[matched, won], …]`, `groups` → id → `[members, footprintWins]` | WP5 |
| `fnc_initCbaMenu` | `[display]` (DisplayLoad) | nothing | WP6 |
| `fnc_openFromGame` | `[step, focusClass]` | nothing; closes the inventory, then opens on display 46 on the next frame | WP6 |

**Textures:** WP6 adds `\z\aio\addons\gui\ui\icon_{setup,undo,redo,rotate,plus,minus,reset}_ca.paa`. WP4 and WP5 reference these paths. Until they exist, use `icon_auto` / `icon_swap` / chevrons.

### 5.5 Stringtable keys owned by one package but used by another

- **items (WP1):**
  - `Setting_Rules`, `Setting_Rules_Desc`
  - `Ruleset_{Default,Tarkov,Weight}` and their `_Desc`
  - `Group_<id>` for all 32 ids in 2.5
  - `Family_{weapons,ammo,attachments,items,worn,containers}`
  - `Warning_HashMismatch`
  - Removed: `Setting_MassPerCell*`, `Setting_StackSmall*`, `Setting_SizeTable*`, `Setting_StackTable*`.
- **gui (WP3):** `Hint_SizeShape` = `%1×%2 · %3`, `Hint_SizeCells` = `%1×%2 · %3 cells`.
- **setup (WP4 writes them all; WP5 and WP6 use them by these exact names, prefix `STR_aio_setup_`):**
  - **For WP6:**
    - `OpenWizard` = "Inventory setup"
    - `OpenWizard_Tooltip` = "Sizes, shapes, stacks and container grids for everyone"
    - `OpenWizard_ReadOnly` = "See and copy the inventory setup"
    - `Keybind_Open` = "Open inventory setup"
    - `ChangeShape` = "Change size or shape..."
  - **For WP5, step 2:**
    - `Groups_All` = "All"
    - `Col_Group` = "Group", `Col_Size` = "Size", `Col_Shape` = "Shape", `Col_Stack` = "Stack", `Col_Grid` = "Grid"
    - `Groups_Covers` = "covers %1 items"
    - `Groups_Reset` = "Back to the preset", `Groups_ShowItems` = "Show its items"
    - `Groups_New` = "New group", `Groups_Own` = "Your groups"
    - `Builder_Name` = "Name", `Builder_AddCondition` = "Add condition", `Builder_Matches` = "%1 items match", `Builder_Create` = "Create"
    - `Key_kind` "Kind", `Key_cat` "Category", `Key_class` "Class", `Key_addon` "Addon", `Key_well` "Magazine well", `Key_for` "Fits weapon", `Key_mass` "Mass", `Key_rounds` "Rounds", `Key_load` "Load"
    - `Op_is` "is", `Op_isOrInherits` "is or inherits from", `Op_contains` "contains", `Op_not` "not", `Op_lt` "less than", `Op_le` "at most", `Op_gt` "more than", `Op_ge` "at least"
  - **For WP5, step 3:**
    - `Items_Search` "Search name or class", `Items_Kind` "Kind", `Items_Mod` "Mod", `Items_Group` "Group"
    - `Items_OnlyChanged` "Only changed", `Items_OnlyStackable` "Only stackable", `Items_OnlyShaped` "Only shaped", `Items_ShowPresets` "Show weapon presets"
    - `Items_Matches` "%1 matches · %2 selected", `Items_Hidden` "%1 hidden by the filter"
    - `Items_SelectAll` "Select all", `Items_Clear` "Clear"
    - `Col_Name` "Name", `Col_Kind` "Kind", `Col_From` "From"
    - `Items_Now` "Now", `Items_Mixed` "%1 (mixed)", `Items_CanStack` "Can stack", `Items_PerTile` "Per tile"
    - `Items_ApplyTo` "Apply to", `Scope_Selected` "Selected (%1)", `Scope_Matching` "Everything matching (%1)", `Scope_Group` "Their group", `Items_Variants` "Include variants"
    - `Items_Apply` "Apply", `Items_Revert` "Revert", `Items_Why` "Why?"
    - `Items_ByName` "Found by name, so saved as these %1 classes: names differ by game language."
    - `Items_Rules` "Your rules", `Items_Edit` "Edit", `Items_Remove` "Remove", `Items_Indexing` "Reading %1 classes..."
    - `Items_CopyClass` "Copy class", `Items_FilterMod` "Filter by this mod", `Items_FilterGroup` "Filter by this group", `Items_Inspect` "Inspect"
    - `Src_own` "Your rule %1", `Src_preset` "Preset: %1", `Src_mod` "Set by its mod", `Src_builtin` "Built in", `Src_forced` "Always 1 for this kind"
    - `Shape_Rectangle` "Rectangle", `Shape_Rotate` "Rotate (R)", `Shape_Cells` "%1 cells", `Shape_Invalid` "Cells must touch each other and reach every edge", `Shape_Mass` "By mass"
    - `Why_Title` "Why %1 looks like this", `Why_Wins` "wins", `Why_Overridden` "overridden"
  - **For WP5, step 4:**
    - `Tab_Uniforms` "Uniforms", `Tab_Vests` "Vests", `Tab_Backpacks` "Backpacks", `Tab_Crates` "Crates and vehicles"
    - `Cont_Load` "Load %1 (%2 kg)", `Cont_Cells` "%1 cells", `Cont_Blocks` "%1 compartments · %2 cells", `Cont_Overflow` "%1 items don't fit"
    - `Mode_Auto` "By load", `Mode_Cells` "Cells", `Mode_Percent` "% of load", `Mode_Pattern` "Pattern", `Mode_Blocks` "Compartments"
    - `Block_N` "Block %1", `Block_Add` "Add block"
    - `Pattern_{pockets,pockets_mixed,rig,mixed,plate,long,single,wide}` "Pockets", "Mixed pockets", "Magazine rig", "Mixed pouches", "Plate carrier", "Long pouches", "One compartment", "Full width"
    - `Fill` "Fill with", `Fill_Empty` "Empty", `Fill_Rifleman` "Rifleman", `Fill_Medic` "Medic"
  - WP4 adds its own keys freely. A key that WP5 or WP6 find missing goes onto the integration list (section 7).

---

## 6. Work packages (disjoint file sets)

Applies to all packages:
- English only; CBA macros (`GVAR`, `QGVAR`, `FUNC`, `EFUNC`, `LLSTRING`, `CSTRING`, `ELSTRING`).
- Plain-English comments in the project's style, with function headers (Arguments, Return Value, Example, Public).
- Settings ordered numbers > switches > lists > text; setting descriptions wrapped with `\n` about every 40 characters.
- `hemtt check` clean.
- Nobody edits a file outside their list.

### WP1: Rules engine (items + container blocks)

**Creates:**
- `addons/items/CfgAioRulesets.hpp`
- `addons/items/functions/fnc_getFacts.sqf`, `fnc_parseRules.sqf`, `fnc_writeRules.sqf`, `fnc_compileRules.sqf`, `fnc_loadRules.sqf`, `fnc_matches.sqf`, `fnc_resolve.sqf`, `fnc_explain.sqf`
- `addons/storage/functions/fnc_blocksFor.sqf`
- `tools/check_default_ruleset.sqf`: a debug-console script with today's `getSize` and stack switch inlined. It compares them with `getInfo` under `base=default` for every scope-2 class and lists mismatches (expect only the documented stackSmall case).

**Changes:**
- `addons/items/config.cpp`: include `CfgAioRulesets.hpp` and WP2's `CfgAioShapes.hpp`.
- `addons/items/XEH_PREP.hpp`: every items function, including WP2's `parseShape`, `shapeForms`, `formatShape`.
- `addons/items/XEH_preInit.sqf`: `facts`, `info`, `massPerCell = 5`, `rulesRevision = 0`, and the hash PV handler on clients. Remove `sizeCorrections`, `sizeByClass`, `stackByClass`.
- `addons/items/initSettings.inc.sqf`: only `aio_items_rules`.
- `addons/items/stringtable.xml`
- `addons/items/script_component.hpp`, if it needs macros.
- `addons/items/functions/fnc_getInfo.sqf`: facts plus resolve plus forms; crate/vehicle kinds; optional `compiled` and `cache`.
- `addons/storage/functions/fnc_getBlocks.sqf`: object → class, kind and maxLoad, then `blocksFor` with `getInfo "grid"` and `EGVAR(items,massPerCell)`.
- `addons/storage/XEH_PREP.hpp`: −parseContainerTable, +blocksFor.
- `addons/storage/XEH_preInit.sqf`: −containerSpecs.
- `addons/storage/initSettings.inc.sqf`: −containerTable; gridOnly stays.
- `addons/storage/stringtable.xml`: −ContainerTable keys.

**Deletes:**
- `addons/items/functions/fnc_getSize.sqf`, `fnc_parseTable.sqf`, `fnc_findInTable.sqf`
- `addons/storage/functions/fnc_parseContainerTable.sqf`

**Done when:**
- Parse → write → parse is stable.
- `aio1 base=default` reproduces today's sizes, stacks and blocks (the check script).
- A bad statement only drops itself.
- An unknown base falls back to default.

### WP2: Shape model and layout engine

**Creates:**
- `addons/items/CfgAioShapes.hpp`
- `addons/items/functions/fnc_parseShape.sqf`, `fnc_shapeForms.sqf`, `fnc_formatShape.sqf`. Presets are cached lazily in `aio_items_shapePresets` and `aio_items_shapeNames`, created inside these functions.

**Changes:**
- `addons/main/script_macros.hpp`: `FORM_*`.
- `addons/storage/functions/fnc_getLayout.sqf`: forms, turns, records, optional blocks, entry `"info"`.
- `fnc_setPlace.sqf`, `fnc_getSlot.sqf`, `fnc_entryToArray.sqf`, `fnc_entryFromArray.sqf`

**Done when:**
- Rectangles behave byte-identically, including old 6-element records.
- L3 occupies 3 cells, and a 1×1 item fits in its free corner.
- `formatShape(parseShape(x))` is canonical and round-trips.
- Disconnected or too-wide masks are rejected with a warning.

### WP3: Shaped tiles in the window (gui)

**Creates:** `addons/gui/functions/fnc_shapePieces.sqf`

**Changes:**
- `addons/gui/XEH_PREP.hpp`
- `addons/gui/XEH_preInit.sqf`: `dragTurns`
- `addons/gui/stringtable.xml`: the two hint keys
- `addons/gui/functions/`: `fnc_createGrid.sqf`, `fnc_createTile.sqf`, `fnc_tileAt.sqf`, `fnc_startDrag.sqf`, `fnc_makeGhost.sqf`, `fnc_rotateDrag.sqf`, `fnc_updateDrag.sqf`, `fnc_endDrag.sqf`, `fnc_uiPictureTurned.sqf`, `fnc_updateHover.sqf`, `fnc_inspect.sqf`, `fnc_flashTile.sqf`, `fnc_showSearch.sqf`, `fnc_revealFx.sqf`, `fnc_markHidden.sqf`

**Done when:**
- With no shapes set, the window looks and behaves as before.
- An L3 tile is drawn as rects plus seams with no bright overlaps.
- R cycles 4 orientations for L or T and 2 for a rectangle.
- The footprint turns red over occupied cells only.
- Hover and drag never pick a tile through an empty cell of a shape.

### WP4: Wizard shell, saving and sharing, steps 1 and 5, widgets

**Creates** (all in `addons/setup/`):
- `$PBOPREFIX$` (`z\aio\addons\setup`)
- `config.cpp`: CfgPatches `aio_setup`, requires `aio_gui`; includes `CfgEventHandlers.hpp`, `RscWizard.hpp` and WP6's `Display3DEN.hpp`.
- `CfgEventHandlers.hpp`:
  - PreStart and PreInit;
  - `Extended_DisplayLoad_EventHandlers >> RscDisplayGameOptions >> aio_setup = "_this call (uiNamespace getVariable ['aio_setup_fnc_initCbaMenu', {}])"`.
- `script_component.hpp`
- `defines.hpp`: includes `\z\aio\addons\gui\defines.hpp`, then re-points `UI_TEX` to the gui textures (`QPATHTOEF(gui,ui\NAME.paa)`); IDD 9620.
- `XEH_PREP.hpp`: own PREPs plus `#include "XEH_PREP_steps.hpp"` (WP5) and `#include "XEH_PREP_entry.hpp"` (WP6).
- `XEH_preStart.sqf`: PREP, so uiNamespace has the functions in menus.
- `XEH_preInit.sqf`: state, plus `if (hasInterface) then {#include "initEntryPoints.inc.sqf"}` (WP6).
- `RscWizard.hpp`: `aio_setup_RscWizard` and `AIO_EditArea` (`AIO_Edit` with ST_MULTI, large `maxChars`).
- `stringtable.xml`: including every WP5 and WP6 key in 5.5.
- `functions/`: `fnc_open`, `fnc_onLoad`, `fnc_onUnload`, `fnc_onKey`, `fnc_canEdit`, `fnc_getActive`, `fnc_commit`, `fnc_undo`, `fnc_drawFrame`, `fnc_showStep`, `fnc_drawStart`, `fnc_drawReview`, `fnc_save`, `fnc_importText`, `fnc_exportText`, `fnc_describeRule`, `fnc_popover`, `fnc_closePopover`, `fnc_confirm`, `fnc_uiToggle`, `fnc_uiStepper`, `fnc_uiEdit`, `fnc_uiChip`, `fnc_uiSegmented`, `fnc_uiDropdown` (all `.sqf`)

**Done when:**
- The wizard opens in direct mode and in menu mode, and is read-only where the 2.7 table says so.
- Save goes through `set` (direct mode) or temp import (menu mode), and Cancel in CBA discards it.
- Export and import round-trip.
- Undo and redo work, and the conflict prompt appears when someone else saved in between.

### WP5: Wizard steps 2–4, class index, list and cell editor

**Creates** (in `addons/setup/`):
- `XEH_PREP_steps.hpp`
- `functions/`: `fnc_buildIndex`, `fnc_filterIndex`, `fnc_ruleStats`, `fnc_upsertRule`, `fnc_applyEdit`, `fnc_uiList`, `fnc_uiMask`, `fnc_uiCellEditor`, `fnc_previewGrid`, `fnc_drawGroups`, `fnc_groupBuilder`, `fnc_drawItems`, `fnc_footprintPopover`, `fnc_whyPopover`, `fnc_drawContainers` (all `.sqf`)

**Changes:** none outside this list. It uses WP4's widgets and popover, WP3's `createGrid` / `createTile` / `shapePieces`, WP2's `getLayout` with blocks and info, and WP1's functions.

**Done when:**
- With 8k classes, indexing takes under about 1 s with a progress bar, and scrolling stays at about 2 ms per step.
- "The green magazine is L3 and the others 1×2" takes three clicks and writes one class rule that beats the group rule.
- A group edit writes or updates exactly one `@id` rule.
- The container preview matches the real inventory.

### WP6: Entry points, CBA menu button, live reload in the inventory, icons

**Creates:**
- `addons/setup/XEH_PREP_entry.hpp`
- `addons/setup/initEntryPoints.inc.sqf`: `CBA_fnc_addPauseMenuOption` with `aio_setup_RscWizard`, and an unbound `CBA_fnc_addKeybind` that calls `openFromGame [0, ""]`.
- `addons/setup/Display3DEN.hpp`: Tools entry; `action` calls `[findDisplay 313, 'direct', 0, ''] call (uiNamespace getVariable 'aio_setup_fnc_open')`.
- `addons/setup/functions/fnc_initCbaMenu.sqf`, `fnc_openFromGame.sqf`
- new textures `addons/gui/ui/icon_{setup,undo,redo,rotate,plus,minus,reset}_ca.paa`

**Changes:**
- `addons/gui/functions/fnc_drawHeader.sqf`: the cog, for everyone; the tooltip is `OpenWizard` or `OpenWizard_ReadOnly`.
- `addons/gui/functions/fnc_contextMenu.sqf`: "Change size or shape..." when `(["direct"] call aio_setup_fnc_canEdit) get "canSave"`; it calls `openFromGame [2, class]`.
- `addons/gui/XEH_postInit.sqf`: on `aio_items_rulesChanged`, if `findDisplay IDD_INVENTORY` is open, call `closeMenu` and then `fnc_build` on the next frame. The build already ends any drag. Placements that no longer fit are re-placed or shown as overflow, and nothing leaves the cargo.
- `tools/generate_ui_textures.py`: the new icons.

**Done when:**
- The button appears only on our category, disappears on search, category switch and the vanilla page, and silently does nothing if CBA's IDCs change.
- Every fallback opens the wizard.
- Changing the setting mid-mission redraws an open inventory.

---

## 7. Order, dependencies and integration

1. **Before WP1:** the job currently adding the three tables must land first, because WP1 rewrites and removes its files. Otherwise WP1 rebases onto it.
2. **All six packages start in parallel** against section 5. Runtime dependencies, to keep in mind when testing:
   - WP1 ↔ WP2: getInfo calls `shapeForms` / `formatShape`; parseRules calls `parseShape`.
   - WP3 needs the getInfo keys and FORM macros from WP1 and WP2.
   - WP4 and WP5 need WP1, plus WP3 for previews. WP4 step 1 previews need WP5's `previewGrid`.
   - WP6 needs WP4's `open` / `canEdit`.
   - Owners of the shared files: the PREP lists for WP2, WP5 and WP6 functions are written by WP1 (items) and WP4 (setup), as fixed above.
3. **Merge order:** WP2 → WP1 → WP3 → WP4 → WP5 → WP6, then `hemtt check`.
4. **Integration step** (sequential, after the merge):
   - a new section "Setup wizard and rules (2026-10-08)" in `docs/ARCHITECTURE.md`, superseding the getSize, table and sizeCorrections parts;
   - `addons/main/script_version.hpp` to 0.2.0 (new feature);
   - add any setup stringtable keys that WP5 or WP6 reported missing;
   - a README note on `aio_gridShape` and `CfgAioRulesets` for other mods;
   - then `hemtt launch` for the in-game checks below.

---

## 8. In-game checks (from all three reports)

1. **`ctrlSetAngle` direction:** the design assumes clockwise. If it turns counter-clockwise, change only the rotation formula in `fnc_shapeForms` to `(c,r)→(r,W-1-c)`. Also check pictures at 180° and 270°, and that the picture sits in the body rect only.
2. **Seams:** they meet pixel-exactly under the semi-transparent tile colours, with no bright lines.
3. **CBA:**
   - the button shows and hides correctly (including search and the vanilla page);
   - the category key is read correctly;
   - menu-mode import turns our row yellow, OK commits and Cancel lists our setting;
   - the client tab is read-only;
   - a logged-in admin's direct save reaches the server and comes back through the setting script;
   - a setting locked by `cba_settings.sqf` reports itself as locked.
4. **Long text:** `ctrlSetText` of a 20 KB string on `RscEdit` / CBA's row returns the full string (`count ctrlText`). Check the mission attribute with 10 KB. Until confirmed, warn above 8 KB.
5. **`CBA_fnc_addPauseMenuOption`:** opens the wizard from the SP and MP interrupt menus. Check the keybind on display 46 and the Eden Tools entry (preInit runs in Eden; postInit does not).
6. **Default equivalence:** run `tools/check_default_ruleset.sqf` with vanilla, ACE and a large mod pack.
7. **Multiplayer:** two clients agree on layouts after a mid-mission rules change. A client with a different preset revision gets the hash warning.
8. **Config names:** that `30Rnd_65x39_caseless_green`, `B_Carryall_Base` and the magazine wells named in examples exist. Step 3 of the wizard is the tool to check them.
9. **Clipboard in MP:** Ctrl+A / Ctrl+C in `AIO_EditArea` works for clients. `copyToClipboard` is shown only where it works.