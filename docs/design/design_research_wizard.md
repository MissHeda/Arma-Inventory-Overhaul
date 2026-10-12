# Setup wizard and rules: design for the UX track (read-only, no files changed)

## 0. Decisions

- **One setting holds the whole setup.** `einv_items_rules` is an EDITBOX with global = 1. Its default is `einv1 base=default`. The wizard only edits this text. CBA takes care of storage (client, mission, server, force), sync, JIP and its own settings import/export.
- **What the text holds.** A ruleset is a base preset plus your own statements. Base presets ship in config (`CfgEinvRulesets`), so a mod update can improve the default for everyone who has not changed it.
- **How rules apply.** Rules are an ordered list, and a later rule wins field by field. A rule can set three fields:
  - **footprint**: size and shape together, as one field
  - **stack**
  - **grid**: containers only
- **Layers, highest first:** your own rules, then mod config (`einv_*`), then preset rules, then the built-in fallback. Your own rules beat mod config, as the current code already does.
- **No language-dependent selectors.** Selectors only use class names, CfgPatches names, kinds and config numbers, so every machine resolves the same result. A search by display name is saved as a list of classes.
- **Where the code goes.**
  - The rules engine goes in `items`, because every machine runs it, including the dedicated server and headless clients.
  - The wizard goes in a new addon `setup` (`einv_setup`, requires `einv_gui`). It reuses the gui UI kit and `fnc_theme`.
- **Fold the other job's tables in before release.** `sizeTable`, `stackTable`, `containerTable` and the `massPerCell` / `stackSmall` sliders are unreleased. Each maps 1:1 into this format (section 3.5). If they stay, they compile as your own rules appended last.

---

## 1. Rule format (versioned text, fits one EDITBOX)

### 1.1 Grammar

```
ruleset   = header *(SEP statement)        SEP = ";" or a line break
header    = "einv1" *(" " ("base=" ID ["@" REV] | "cell=" NUMBER))
            base omitted = default, base=none = no preset; cell = config mass per cell
statement = group | rule | "#" comment-to-SEP
group     = "@" ID ":" cond *(" " cond)
            the same id twice in one layer = OR; an own-layer @id replaces the preset's @id
rule      = [cond *(" " cond)] " > " value *(" " value)
            all conds AND; an empty selector matches every item
cond      = ["!"] ( "@" ID *("|@" ID) | KEY OP VAL *("|" VAL) )      "|" = OR within one key
OP        = "=" | "~" (contains) | "<" | "<=" | ">" | ">="
```

- Only `[A-Za-z0-9_+./%:|@!<>=~#-]` plus space and `;` appear in the text. There are no double quotes, because CBA would double them when it stores the string.
- The parser is tolerant, like the existing `fnc_parseTable`. A statement it cannot read is dropped with an RPT warning that names it, and the rest still loads.
- If the header has a higher version than this mod knows, the parser reads it best-effort, skips unknown keys and warns.

### 1.2 Selector keys (every one gives the same answer on every machine)

| Key | Ops | Matches |
|---|---|---|
| `kind` | = | getInfo kind (rifle, handgun, launcher, binocular, muzzle, optic, rail, bipod, headgear, nvg, vest, uniform, map, gps, radio, compass, watch, item, magazine, grenade, backpack, goggles, unknown). Two extra kinds exist only in the facts: `crate` and `vehicle`, for CfgVehicles containers. |
| `cat` | = | misc, gear, weapon, ammo, medical (CATEGORY_*) |
| `class` | =, ~ | `=X` is exact, `=X+` is X plus every class inheriting from it (lineage), `~text` is a case-insensitive substring of the class name |
| `addon` | =, ~ | the defining CfgPatches class (first entry of `configSourceAddonList`), e.g. `addon~rhsusf_` |
| `author` | =, ~ | `getTextRaw author` (raw, so it does not depend on the game language) |
| `ammo` | =, ~ | the magazine's ammo class; `+` means descendants too |
| `well` | = | member of that `CfgMagazineWells` class |
| `for` | = | magazines that weapon loads, all muzzles (`CBA_fnc_compatibleMagazines`, worked out once at compile time) |
| `use` | = | rifle, handgun or launcher: the magazine is loaded by some scope-2 weapon of that kind. The reverse index is built lazily and costs about 1–3 s with large mod packs, so the shipped presets avoid it. |
| `rounds`, `mass`, `load` | < <= > >= = | magazine `count`; config mass in the mod's units (55 = 2.5 kg); `maxLoad` |

Two selectors are deliberately left out:
- **`name~`.** Display names are localized, so a German client and an English server would resolve different sizes and layouts would stop matching.
- **`configSourceMod`.** A workshop folder like `.../107410/843577117` and a server's `@rhsusaf` folder return different values.

The wizard still shows mods by `configSourceMod` and `modParams` (name and logo), but writes rules as `addon~prefix`.

### 1.3 Value keys

| Value | Meaning |
|---|---|
| `size=WxH` | full rectangle, W at most STORAGE_COLS (8) |
| `size=mass` | Area = ceil(mass/cell) cells. Rifles, launchers and rockets lie 2 rows high (w = ceil(cells/2)). Everything else is near square (w = ceil(sqrt cells)). Width is clamped to 8. |
| `shape=NAME` or `shape=ROWS` | A named shape from the shapes track (e.g. `L3`), or an explicit mask: rows top to bottom separated by `/`, `1` = taken, e.g. `10/11` (L3 in 2×2), `111/010` (T4). The mask implies the size; with both, they must agree. A mask must be edge-connected with no empty outer row or column. |
| `stack=N` | 1 = does not stack |
| `grid=auto` | the current `getBlocks` behaviour: load/cell cells, laid out by the kind's pattern chosen by class hash |
| `grid=N` | N cells, laid out by that pattern |
| `grid=N%` | N % of auto |
| `grid=PATTERN[:N]` | `pockets`, `pockets_mixed`, `rig`, `mixed`, `plate`, `long`, `single`, `wide` (the getBlocks patterns, now named) |
| `grid=WxH+WxH...` | exact compartments |

Footprint is one field, so a later `shape=` fully replaces an earlier `size=` and the other way round. Size and shape never need reconciling.

### 1.4 Examples

```
einv1 base=default
kind=grenade > stack=3                                  # all grenades stack to 3
@mag_rifle > size=1x3                                   # step 2 edit of a group: one rule, not N entries
class~caseless_green kind=magazine > shape=10/11        # "the green mag" (Katiba 6.5 mm, plain and tracer): L, 3 cells; the other mags stay 1x2
class=ACE_fieldDressing+|ACE_packingBandage+ > stack=20
addon~rhsusf_ kind=magazine rounds>=100 > size=2x3      # every RHS USAF box of 100+ rounds
for=LMG_Mk200_F > size=2x2                              # whatever the Mk200 loads
well=CBA_556x45_STANAG > size=1x2                       # well name to check in config
!addon~ace_ cat=medical > stack=1                       # medical from other mods does not stack
@ak: kind=magazine class~762x39|545x39                  # own group (shows as a row in step 2)
@ak > size=1x2
class=B_Carryall_Base+ > grid=6x5+2x3+2x3               # Carryall and all its camos: main and two side pockets
kind=vest class~platecarrier > grid=plate:20
kind=backpack load>280 > grid=120%
```

Your own statements are usually under 1 KB.

**Export variants:**
- The setting text itself, compact.
- "Full", with the base inlined as `base=none`, so it survives changes to the default.
- A line ready for a server's `cba_settings.sqf`: `force einv_items_rules = "...";`

---

## 2. Shipped rulesets

`CfgEinvRulesets` lives in `items`:

```
class CfgEinvRulesets {
    class default { name = "$STR_..."; description = "$STR_..."; revision = 1; rules[] = {"...", ...}; };
    class tarkov  { ... };
    class weight  { ... };
};
```

`rules[]` holds one statement per element, joined with `;`. Other mods or communities can add their own preset classes, and they show up in step 1. A preset may declare `base=`, up to 4 levels deep, with cycles rejected.

### 2.1 `default` (revision 1)

This is the current `fnc_getSize` and stack logic as groups, so the starting behaviour does not change. Each step-2 row is one group with one rule. Overlaps are resolved by order, most specific last.

```
einv1 base=none cell=5
> size=1x1 stack=1
# weapons
@rifle_light: kind=rifle mass<=55
@rifle_medium: kind=rifle mass>55 mass<=90
@rifle_heavy: kind=rifle mass>90 mass<=150
@rifle_xheavy: kind=rifle mass>150
@handgun: kind=handgun
@launcher: kind=launcher
@rifle_light > size=3x2
@rifle_medium > size=4x2
@rifle_heavy > size=5x2
@rifle_xheavy > size=6x2
@handgun > size=2x1
@launcher > size=6x2
# ammunition
@mag_rifle: kind=magazine
@mag_pistol: kind=magazine mass<=5
@mag_heavy: kind=magazine mass>20
@belt: kind=magazine rounds>=50 mass>15
@rocket: kind=magazine rounds=1 mass>15 mass<=60
@rocket_heavy: kind=magazine rounds=1 mass>60
@grenade: kind=grenade
@mag_rifle > size=1x2
@mag_pistol > size=1x1
@mag_heavy > size=2x2
@belt > size=2x2
@rocket > size=1x3
@rocket_heavy > size=2x3
@grenade > size=1x1 stack=5
# attachments
@optic_small: kind=optic mass<=8
@optic_large: kind=optic mass>8
@muzzle: kind=muzzle
@rail_bipod: kind=rail|bipod
@optic_small > size=1x1
@optic_large > size=2x1
@muzzle > size=2x1
@rail_bipod > size=1x1
# items by mass (ACE's misc items are kind=item)
@item_small: kind=item mass<=10
@item_medium: kind=item mass>10 mass<=30
@item_large: kind=item mass>30 mass<=60
@item_xlarge: kind=item mass>60
@item_small > size=1x1 stack=10
@item_medium > size=2x1
@item_large > size=2x2
@item_xlarge > size=3x2
# medical, after items
@med_small: cat=medical mass<=3
@med_small > size=1x1 stack=10
class=ACE_bloodIV|ACE_plasmaIV|ACE_salineIV > size=1x2 stack=1
class=ACE_bloodIV_500|ACE_plasmaIV_500|ACE_salineIV_500 > size=1x2 stack=2
class=ACE_bloodIV_250|ACE_plasmaIV_250|ACE_salineIV_250 > size=1x1 stack=3
class=ACE_splint > size=1x2 stack=4
class=ACE_surgicalKit|ACE_personalAidKit > size=2x1
class=ACE_bodyBag > size=2x2
# worn gear
@assigned: kind=map|gps|radio|compass|watch
@goggles: kind=goggles
@nvg_binocular: kind=nvg|binocular
@headgear: kind=headgear
@assigned > size=1x1
@goggles > size=1x1
@nvg_binocular > size=2x1
@headgear > size=2x2
# containers: as items and their grids
@uniform: kind=uniform
@vest: kind=vest
@backpack_small: kind=backpack load<=160
@backpack_medium: kind=backpack load>160 load<=280
@backpack_large: kind=backpack load>280
@uniform > size=2x2 grid=auto
@vest > size=3x3 grid=auto
@backpack_small > size=3x3 grid=auto
@backpack_medium > size=4x4 grid=auto
@backpack_large > size=4x5 grid=auto
kind=crate|vehicle > grid=auto
```

- It is about 2.6 KB and lives only in config, not in the setting.
- The class anchors only match when ACE is loaded.
- RHS, CUP and other mods are handled by the mass and rounds rules, which do not depend on any mod. That gives 30-round magazines 1×2, 100/200-round boxes 2×2 and 9 mm pistol magazines 1×1.
- Every threshold is a starting value to tune in the game. Step 3 shows where each item lands.

### 2.2 `tarkov`

```
einv1 base=default
@grenade > stack=1
@item_small > stack=1
@med_small > stack=1
@rifle_light > size=4x2
@rifle_medium > size=5x2
@rifle_heavy > size=6x2
@rifle_xheavy > size=7x2
@uniform > grid=pockets:4
@vest > grid=rig
@backpack_small > size=4x4 grid=4x5
@backpack_medium > size=5x5 grid=5x6
@backpack_large > size=5x6 grid=6x7
```

Fixed grids per backpack bracket, almost nothing stacks, longer rifles.

### 2.3 `weight` (volume follows mass, so the grid enforces Arma's load)

```
einv1 base=default cell=4
> size=mass
@grenade|@item_small|@med_small|@mag_pistol > stack=10
```

All containers stay on `grid=auto`.

---

## 3. Compile, resolve, cache

### 3.1 Facts (static per class, cached for good in `einv_items_facts`)

Split `fnc_getInfo` into two parts:
- **`fnc_getFacts`**: config only, never cleared.
- **The resolved part**: cleared whenever the rules change.

Facts:
- `kind`, `cat`, `mass`, `rounds`, `load`, `root`
- `lineage`: lowercase configNames from the class itself up through `inheritsFrom`
- `addon`, `author` (raw)
- `ammoLineage` (magazines)
- `wells`: from a reverse index of `CfgMagazineWells` built once
- `modConfig`: `einv_gridSize[]`, `einv_shape`, `einv_stackSize`, `einv_grids[]`, `einv_slots`

The localized name and picture are kept for the UI but are never used for matching.

### 3.2 Compile (`einv_items_fnc_compileRules [text] -> HashMap`)

1. Parse your own statements into layer U.
2. Expand the `base` chain from `CfgEinvRulesets` into layer P. The base is parsed first. `@rev` picks that revision; if it is unknown, the current one is used with an RPT warning.
3. Group table: P definitions, then U. A U definition of an existing id replaces it. Several definitions of one id within a layer are ORed.
4. Expand each rule's group references into DNF, a list of alternatives, each a list of conditions. Above 32 alternatives the rule is rejected with a warning.
5. Precompile conditions:
   - sets as HashMaps
   - `class=X+` as a check against the lineage
   - numbers as `[field, op, n]`
   - `for=` resolved to a set of magazines
   - `use=` triggers the lazy reverse index
   
   Conditions are sorted cheapest first: kind, then numbers, then sets, then substrings.
6. Bucket by kind. For every kind (about 25), precompute an array of rule references in descending order, for U and P separately. Each array holds the rules whose alternatives can match that kind, merged with the rules that have no kind condition. Resolve then never sorts.
7. Store `hash = hashValue` of the expanded canonical text, plus `cell`.

### 3.3 Resolve (`einv_items_fnc_resolve [class, compiled = GVAR(rules), cache = GVAR(resolved)]`)

```
key = toLowerANSI class; cache hit -> return it
f = getFacts class
need = {fp, stack} + {grid} if f.kind in [uniform, vest, backpack, crate, vehicle]
for layer in [U, MOD, P, BUILTIN]:
    U, P:    for r in compiled.layer.byKind[f.kind] (descending):
                 if r.fields ∩ need ≠ ∅ and match(f, r): take those fields, src = "u:<i>" / "p:<preset>:<i>"; need -= them
                 stop as soon as need is empty
    MOD:     fp <- einv_shape / einv_gridSize, stack <- einv_stackSize, grid <- einv_grids / einv_slots   (only what is still needed)
    BUILTIN: fp [1,1] full, stack 1, grid auto
finalize: size=mass -> formula with compiled.cell; w > STORAGE_COLS -> clamp (a mask that is too wide is dropped to a rectangle, warned once);
          stack = floor max 1
result {size [w,h], mask "" | "10/11", cells, stack, grid, src {field -> source}}
cache set key
```

`fnc_getInfo` stays the public entry point. It returns facts plus the resolved values, adding the keys `shape`, `cells`, `grid` and `src`. `fnc_getBlocks` asks for `getInfo get "grid"` instead of `containerSpecs` / `einv_grids` / `einv_slots`. Those config keys are now read by resolve's mod layer.

Required refactor: split `getBlocks` into an object-to-class part and `fnc_blocksFor [class, kind, maxLoad, grid]`, which is pure. Step 4 can then preview without a real container.

`einv_items_fnc_explain [class, compiled]` returns every matching rule from top to bottom, with the fields it set and whether it won. It powers the "Why?" popover in the wizard.

Typical cost:
- Resolving one class: about 50 rules × 3 conditions, roughly 0.05–0.2 ms.
- Opening the inventory: about 100 classes resolved once, then cached.

### 3.4 Determinism in multiplayer

The same text plus the same config gives the same result on every machine. To catch version drift (`base=default` with a different mod version):
- After compiling, the server sets `einv_items_rulesHash` (public).
- Each client compares it with its own hash and, on a mismatch, logs to the RPT and shows a hint to admins: "Your Enhanced Inventory resolves sizes differently from the server; update the mod".

Layout records grow by one element, the mask: `[class, col, row, w, h, block, mask]`. Reconcile then only keeps a record whose footprint still matches, either way round.

### 3.5 Old settings mapped into this format

| Old | New |
|---|---|
| `sizeTable "X:WxH"` | `class=X+ > size=WxH` |
| `stackTable "X:N"` | `class=X+ > stack=N` |
| `containerTable "X:N"` / `"X:6x4+2x3"` | `class=X+ > grid=N` / `grid=6x4+2x3` |
| `massPerCell` | header `cell=` |
| `stackSmall` | `@item_small > stack=N` (and `@med_small`) |
| `einv_items_sizeCorrections` | the class anchors in `default` |

The old tables matched the nearest parent. The wizard keeps that behaviour by sorting class rules by lineage depth, deepest last.

---

## 4. Saving, permissions, sync, live pickup

| Where | Opens | Saves | Stored in | Reaches others |
|---|---|---|---|---|
| Eden | yes | yes | CBA source `mission` (mission.sqm) | ships with the mission |
| Singleplayer / editor preview | yes | yes | source `server` (own profile) | — |
| MP host | yes | yes | source `server` | CBA broadcast to all clients, JIP included |
| MP dedicated, logged-in admin (`IS_ADMIN_LOGGED`) | yes | yes | source `server`, as CBA's Server tab does it | CBA broadcast |
| Other players | view only | no; export and personal presets only | `profileNamespace einv_setup_presets` `[[name, text, date]]` | — |

- **Save** calls `["einv_items_rules", text, priority, source] call CBA_settings_fnc_set`. A "Force" toggle sets priority 1, or 2 for the server, as EFAK's `fnc_applyPreset` does. The header chip shows where the active value comes from, using CBA's get and priority per source.
- **Conflicts.** At save time the wizard compares the active text with the text it started from. If someone else saved in between, it offers: reload and replay my edits, overwrite, or cancel.
- **Live pickup, on every machine.** The setting's script runs `einv_items_fnc_loadRules`, which:
  1. compiles the text; if that fails, it falls back to `base=default` and warns
  2. swaps `GVAR(rules)` and clears `GVAR(resolved)` and `GVAR(info)`; facts stay
  3. increments `GVAR(rulesRevision)`
  4. on the server, publishes the hash
  5. raises the local CBA event `einv_items_rulesChanged`
- **The gui listens for that event.** If the inventory is open, it cancels a drag, closes the menu and runs `fnc_build` on the next frame. The revision also goes into `fnc_getSignature` as a safety net.
  - Records whose footprint changed are placed again first-fit.
  - What fits nowhere shows as red overflow. Nothing leaves the cargo.
- **The wizard listens too.** If its draft is clean, it reloads from the new active text. If the draft has changes, it shows a banner.
- **Before the settings are read.** If `getInfo` runs first, `GVAR(rules)` is nil, so resolve compiles the default lazily.

---

## 5. Wizard UI (`EINV_SetupDialog`, glass, same geometry defines)

### 5.1 Entry points

1. **Button in CBA Addon Options**, shown only while our category is selected.
   - Hook: `Extended_DisplayLoad_EventHandlers >> RscDisplayGameOptions` (idd 151; EFAK's `fnc_reopenSettings` already checks `findDisplay 151`).
   - On the next frame, find CBA's addon combo by control type and by its entries containing our category, rather than by a hard-coded IDC.
   - Create our button inside the combo's own controls group, so it hides and shows with CBA's page. Toggle it in `LBSelChanged`.
   - On click, activate CBA's OK button (`ctrlActivate`) so pending edits in the menu are saved, then open the wizard on display 49, 313 or 46. When the wizard closes, reopen the CBA menu the way `fnc_reopenSettings` does.
   - This avoids CBA's open menu writing its stale editbox value back over ours.
2. **Eden:** Tools menu entry (Display3DEN menu strip).
3. **Inventory header:** a gear icon for those allowed to save. The context menu also gets "Change size / shape..." on a tile, which opens step 3 with that class already selected. That is the green-magazine case in one click. The inventory closes first.
4. **Fallback** if a CBA update breaks the hook:
   - a CBA keybind, "Open inventory setup"
   - the chat command `#einv setup` (`CBA_fnc_registerChatCommand`)
   - an EFAK-style LIST setting, "Setup wizard: — / Open now", which resets itself after it fires

### 5.2 Frame (all steps)

```
header : [Inventory setup] (1 Start)(2 Groups)(3 Items)(4 Containers)(5 Save)   [Server - forced - 4 changes] [x]
content: CONTENT_Y..CONTENT_B, glass panels per step (uiPanel, theme panel/card)
footer : [ESC] Close  [Ctrl+Z] Undo  [Ctrl+F] Search    <hint>                         [Back] [Next] / [Save]
```

- The step pills are free to click; the steps are not forced in order. The current pill is filled in `accent` with `onAccent` text. A step with changes gets an accent dot.
- **Draft model:**
  - `GVAR(draft)` is the parsed own layer: `base`, `cell`, `groups` `[[id, alternatives]]`, `rules` `[[conds, values, section, created]]`.
  - `GVAR(origin)` is the active text at the time the wizard opened.
  - Undo and redo are stacks of canonical texts.
  - The wizard has its own compiled draft and its own resolve cache, so the running game is not affected until Save.

### 5.3 Step 1: Start

- **Preset cards in a row:** Default, Tarkov-like, Weight-like, Empty (`base=none`), plus one card per extra `CfgEinvRulesets` class and per saved personal preset. Each card shows:
  - name and three lines of description
  - a mini preview: a real `createGrid` 8×4 with tiles laid out by `getLayout` under that preset's rules. The sample is `arifle_MX_F`, 3× `30Rnd_65x39_caseless_mag`, `HandGrenade` and `FirstAidKit`.
  - The selected card gets an accent `uiRing`.
- **Below the cards:**
  - "Your own rules: 7" with a choice: keep them on top of the new preset, or start empty.
  - "Mass per cell" stepper, showing "1 cell = 0.23 kg".
  - "Import a shared setup..." opens the import popover (5.8).
- **Status card:** "Active now: base=default + 7 rules · from server (forced) · you can save to: server".

### 5.4 Step 2: Groups (batch editing)

- A table with one row per group: the preset's groups first, then your own. Family chips filter the rows: Weapons, Ammo, Attachments, Items, Medical, Worn gear, Containers.
- **Columns:**
  - **Group:** localized label from `STR_einv_setup_Group_<id>` (own ids are shown with `_` as space), an example picture, and "covers 214 items". The count is the number of indexed classes whose footprint winner is this row.
  - **Size:** a `1×2` button that opens the footprint popover (W/H steppers plus cell editor).
  - **Shape:** a small mask glyph, which opens the same popover.
  - **Stack:** toggle plus count stepper (2–100); the stepper is disabled while the toggle is off.
  - **Grid:** container rows only, a chip ("auto", "24 cells", "rig", "3 blocks") that jumps to step 4.
  - **Reset** (↺): only shown when the row differs from the preset.
  - **Items** (magnifier): opens step 3 filtered to this group.
- **Editing a cell** writes or updates exactly one own rule `@id > field=value`, in the "group rules" section. It is updated in place and never duplicated.
- **"+ New group"** opens a builder:
  - name field
  - condition rows: key dropdown, operator, value field with autocomplete from the index for kinds, addons and wells
  - a live match count

### 5.5 Step 3: Items (browser)

```
+-- Filters 22% ---------+-- Results 48% (virtual list) ---------------------------+-- Selection 30% -----------+
| [search name/class]    | [ ] pic  Name / class (muted)   kind  size  stk  from   | picture (1) / collage (n)  |
| Kind  (rifle 312)...   | [x] pic  6.5mm 30Rnd Mag        mag   1x2   1    Rifle m| name, class, mod + logo,   |
| Mod   (RHS USAF 840)...|   ... about 25 pooled rows ...                          | kg, rounds/load            |
| Group (Rifle mags)...  | 1,284 matches - 3 selected  [all matches] [clear]       | Now: 1x2 rect  [preset: Ri…]|
| [only changed]         | column headers sort (icon_sort_asc/desc)                |      stack 1   [built-in]  |
| [only stackable]       |                                                         | Size [-1+] x [-2+]         |
| [only shaped]          |                                                         | Shape: cell editor         |
| [show weapon presets]  |                                                         | Stack [toggle] [-10+]      |
|                        |                                                         | Apply to: (3 selected)     |
|                        |                                                         |  (214 matching) (group) (+variants) |
|                        |                                                         | [Apply] [Revert] [Why?]    |
+------------------------+---------------------------------------------------------+----------------------------+
| Your rules (drawer): 1. Magazines whose class contains "caseless_green" -> L-shape, 3 cells     [edit] [x]   |
```

- **Search** matches the lowercase display name and the class name. It waits 150 ms after typing stops (`CBA_fnc_waitAndExecute` with a token).
- **Row clicks:**
  - click toggles the row
  - Shift+click selects a range
  - Ctrl+A selects all matches
  - double click opens Inspect (`fnc_inspect`)
  - right click opens a row menu: Why, Copy class, Filter by this mod, Filter by this group
  
  The selection is a set of lowercase classes and survives filtering ("3 selected, 1 hidden by filter").
- **Detail panel:** the resolved values, each with a source chip. A click on a chip highlights that rule in the drawer or in step 2.
- **Multiple selection:** mixed values show as "1×2 / 2×2 (mixed)". Only fields you touch are written ("dirty fields"), so ticking "Can stack" on 30 bandages writes only `stack=`.
- **Cell editor:**
  - W×H steppers (1–8 × 1–6), a grid of clickable cells, a quick-shapes row (rectangle, I, L, J, T, S, Z from the shapes track), rotate and mirror buttons, and a cell count
  - the item's picture over the mask in its category's tile colour
  - invalid masks (not connected, or an empty edge) are outlined in `loss` and cannot be applied
- **Apply scopes, each creating or updating one rule:**
  - **Selected:** `class=a+|b+|c+`. "+variants" is on by default, so unique-instance classes (TFAR/ACRE radios, EFAK kits) follow their base class.
  - **Everything matching the search and filters:**
    - kind, addon, group and well filters become conditions
    - if every match contains the search text in its class name, it becomes `class~text`
    - otherwise (the search only matched display names), the wizard asks: "matched by name: saved as these 37 classes (names differ by game language)". This writes `class=` lists.
  - **Their group:** edits that group's row, the same as step 2.
- **A rule with the same selector** is updated rather than added again. Own rules are auto-sorted by section: group rules, then filter rules, then class rules by lineage depth, then creation order. So "the green one is L3" always beats "rifle mags 1×2", whichever was edited first. The drawer has an "Order by hand" switch for power users.
- **"Why?"** opens a popover with every matching rule. Rules that were overridden are struck through, and the winner of each field is shown in accent.

### 5.6 Step 4: Containers

- **Left side:**
  - tabs: Uniforms, Vests, Backpacks, Crates & vehicles
  - container group rows like step 2 (the backpack brackets, uniform, vest)
  - a virtual list of classes with picture, name, load in kg and the resolved grid ("4 pouches · 14 cells" plus its source)
- **Right side, the editor:**
  - a segmented mode switch: By load (auto), Cells, % of load, Pattern, Compartments
  - **Cells:** a stepper
  - **%:** a stepper from 50 to 200
  - **Pattern:** a dropdown (pockets, pockets_mixed, rig, mixed, plate, long, single, wide) plus a cell count
  - **Compartments:** rows "Block n: [W]×[H] [up] [down] [x]", plus "Add block"
  - Apply scopes as in step 3.
- **Live preview:**
  - the real `fnc_createGrid` per compartment, at the inventory's own cell size. It scales down only if it does not fit, which needs an optional cell-size parameter.
  - "Fill with" dropdown: Empty, Rifleman, Medic, Autorifleman, Grenadier. The sample loadout is placed by the real `getLayout` first-fit into the blocks from `fnc_blocksFor`.
  - overflow is shown red: "3 items don't fit"
  - "Engine load 280 (12.7 kg) · grid 36 cells" puts mass next to volume

### 5.7 Step 5: Review and save

- **Changes:** a diff against the base preset as plain sentences, rendered from stringtable templates, e.g. "Rifle magazines take 1×3 instead of 1×2", "Magazines whose class contains 'caseless_green' are L-shaped (3 cells)". Each has [jump] and [x].
- **Warnings:**
  - a rule matches nothing
  - a rule is completely overridden by later rules
  - values were dropped or clamped
  - classes from mods that are not loaded (kept, but inactive)
  - name searches that were turned into class lists
  - the text is longer than 16 KB (suggest a group instead of a list)
- **Text:** a read-only multi-line field (new `EINV_EditArea`, ST_MULTI, large maxChars) with the character count, buttons for Copy / Copy full / Copy as `cba_settings.sqf` line, and an advanced "Edit as text" mode that re-parses live.
- **Save card:**
  - target: Server, Mission (Eden only), Only for me (personal preset), each disabled with its reason
  - Force toggle
  - **Save** (accent)
  - "Save as my preset..."
  - "Reset to default" (sets `base=default` and clears your own rules, after a confirmation card)
  - If the server's `cba_settings.sqf` locks the setting, the card says so and offers "Copy as cba_settings line" instead.

### 5.8 Popovers and keys

- **Popovers** reuse `fnc_openMenu`'s catcher-plus-card pattern: footprint, group builder, import, confirm, Why.
- **Import:** paste field, then Parse, which shows a summary (base, groups, rules, warnings, unknown classes). Then choose "Replace my rules" or "Add on top".
- **Keys:**
  - Esc closes, asking first when there are unsaved changes
  - Ctrl+Z / Ctrl+Y undo and redo
  - Ctrl+F focuses the search
  - Up/Down move through the list, Space toggles, PageUp/PageDown scroll
  - Return applies; it is read in onKeyUp, because an edit field swallows the KeyDown (briefing)
  - R rotates in the cell editor

---

## 6. UI kit additions and refactors (gui)

- **Per-display registries.** `fnc_uiCreate` and `fnc_createGrid` currently push into the global `uiNamespace` arrays `created` and `grids`. They should keep them on the display (`_display getVariable`), so the wizard and the inventory never delete or hit-test each other's controls.
- **New pieces:**
  - `fnc_uiToggle` (uses the existing toggle_on/off textures)
  - `fnc_uiStepper` (chevron icons)
  - `fnc_uiEdit` (generalised from `drawFilter`: placeholder, change code, focus sink)
  - `fnc_uiChip` (pill, active state)
  - `fnc_uiSegmented`
  - `fnc_uiDropdown` (built on `openMenu`)
  - `fnc_uiList` (virtual list, see section 7)
  - `fnc_uiCellEditor`
  - `fnc_uiMask` (mask glyph made of rectangles)
- **New config classes:**
  - `EINV_EditArea`: ST_MULTI + ST_NO_RECT, large maxChars
  - `EINV_SetupDialog`: idd 9620, only the dim layer, everything else created at run time, like the inventory
- **New items functions:** `fnc_getFacts`, `fnc_parseRules`, `fnc_writeRules` (canonical form, config-case class names), `fnc_compileRules`, `fnc_loadRules`, `fnc_resolve`, `fnc_explain`.
- **New setup functions:** `fnc_open [step, focusClass]`, `fnc_canEdit`, `fnc_buildIndex`, `fnc_filter`, `fnc_drawStart`, `fnc_drawGroups`, `fnc_drawItems`, `fnc_drawContainers`, `fnc_drawReview`, `fnc_applyEdit [scope, fields]`, `fnc_save [target, force]`, `fnc_import`, `fnc_onOptionsLoad`.
- **New storage function:** `fnc_blocksFor`.
- The CBA setting `einv_items_rules` goes last in the Grids subcategory (text boxes come last).

---

## 7. Performance (thousands of classes)

- **Class index, built once and kept in `uiNamespace`.** Config cannot change without a game restart, so a second open in the same game session is instant.
  - `configClasses` with a scope-2 condition over CfgWeapons, CfgMagazines, CfgGlasses and CfgVehicles (`isBackpack == 1`; containers on the step 4 tab). Each call runs in one go, about 50–150 ms with large packs, behind an "Indexing..." overlay drawn one frame earlier.
  - Facts are then extracted in chunks of about 500 per frame with a progress bar, roughly 0.4 s for 8k classes.
  - Weapon presets (`baseWeapon` differs from the class) are hidden by default; they inherit their base class's result anyway. That cuts about 30–40 % of the rows.
- **Entries are compact arrays, not HashMaps:**
  `[lcClass, class, searchText, name, kind, cat, mass, rounds, load, picture, modKey, root]`
  - buckets: kind to indices, modKey to indices
  - filtering intersects the buckets first, then runs `select` with `find` on `searchText` (about 5–15 ms for 8k entries)
  - sorting uses an `apply`'d key with `sort`, not `BIS_fnc_sortBy`
- **Virtual list:**
  - a fixed pool of visible rows + 2 (about 25 rows × about 9 controls, created once, about 30–60 ms)
  - scrolling by wheel, scroll-bar thumb or keys only re-fills texts and pictures with `ctrlSetText`, about 2 ms
  - never one control per result, and no `EINV_ScrollGroup` with 5000 children
  - fallback if the pool is too much work: a theme-coloured `RscListNBox`, which is engine-virtualised, with selection drawn as a checkbox column
- **Lazy pictures and lazy resolve:**
  - only pooled rows get a picture; a missing picture gets an icon
  - no `getTextureInfo` in lists
  - only visible rows are resolved (draft cache)
  - step 2 coverage counts and "matches N" are worked out in background chunks (about 300 classes per frame) after each edit, showing "…" until done
- **Other costs:**
  - compiling the draft after an edit takes a few ms
  - after an edit, the draft resolve cache is cleared and only the visible rows are re-resolved
  - `use=` and other reverse indexes are only built when a rule needs them

---

## 8. Check before building

- **CBA Addon Options internals:**
  - that the display is `RscDisplayGameOptions` (idd 151)
  - how to find the addon combo and its controls group
  - whether the OK button is IDC 1
  - whether the menu writes back only the settings that were changed in it
- **CBA writes from a client:** that `CBA_settings_fnc_set` with source `server` from a logged-in admin client is forwarded to the server. Also how a setting locked by the server's `cba_settings.sqf` reports itself.
- **Clipboard in multiplayer:** `copyToClipboard` / `copyFromClipboard` are restricted in MP. Ctrl+C / Ctrl+V in `EINV_EditArea` is the path that always works.
- **Long text:** that CBA's EDITBOX and the mission attribute accept 10–20 KB strings, and whether this CBA version's multi-line EDITBOX option is worth using for the setting.
- **Config names:** magazine well names (e.g. `CBA_556x45_STANAG`), ACE item masses behind the `med_small` threshold, and the vanilla example classes (`30Rnd_65x39_caseless_green`, `B_Carryall_Base`, `V_PlateCarrier*`). Step 3 of the wizard is the tool to check them in the game.
- **Owned by other tracks:**
  - the shapes track: shape names (L3, …), the mask encoding for layout records, and how pictures draw on shapes that are not rectangles
  - the storage track: whether full magazines with more than one round may stack (suggested: only equal-ammo or full ones)

All findings are from these files:
- `C:\Users\Heda\GitHub Repos\Arma-Inventory-Redesign\docs\ARCHITECTURE.md`, `docs\BRIEFING.md`
- `addons\items\functions\fnc_getInfo.sqf`, `fnc_getSize.sqf`, `fnc_parseTable.sqf`, `fnc_findInTable.sqf`, `addons\items\initSettings.inc.sqf`, `addons\items\XEH_preInit.sqf`
- `addons\storage\functions\fnc_getBlocks.sqf`, `fnc_parseContainerTable.sqf`, `addons\storage\initSettings.inc.sqf`, `addons\storage\XEH_postInit.sqf`
- `addons\gui\defines.hpp`, `RscBase.hpp`, `RscInventory.hpp`, `XEH_preInit.sqf`, `functions\fnc_ui*.sqf`, `fnc_theme.sqf`, `fnc_openMenu.sqf`, `fnc_inspect.sqf`, `fnc_drawFilter.sqf`, `fnc_createGrid.sqf`, `fnc_drawColumn.sqf`
- `C:\Users\Heda\GitHub Repos\Enhanced-First-Aid-Kits\addons\core\functions\fnc_applyPreset.sqf`, `fnc_reopenSettings.sqf`: the EFAK pattern for writing CBA settings and reopening the menu