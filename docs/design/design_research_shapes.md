I changed no files. Below is the plan for shaped items in the Enhanced Inventory grid engine.

## Shaped items in the grid engine: design and change plan

### 1. Engine facts that shape the design

- **Layouts are local to each client.** `fnc_getLayout` keeps its records with a non-broadcast `setVariable`. The server's `move` handler (`addons/storage/XEH_postInit.sqf:11-18`) calls `moveEntry` with `[]` and `false`, so it only moves cargo and never checks grid space. Shapes are therefore enforced on each client only. "Every machine agrees" just means the definitions must be server-forced settings, which `einv_items_sizeTable` already is (isGlobal 1). Layout records never cross the network, so changing the record format has no multiplayer compatibility risk.
- **Rotation today is a single toggle.** `"rotated"` is a boolean, R swaps `GVAR(dragSize)`, pictures only turn 90°, and records store only `w,h` (turned = swapped). That is not enough for L, T or S shapes, which need four orientations. The 0° and 180° positions have the same `w,h` but different occupancy.
- **Tile backgrounds are semi-transparent** (`tileBg` alpha 0.095–0.19 in `fnc_theme.sqf`). If a shape is drawn from overlapping rectangles, the overlaps show brighter. A shape must be drawn as an exact partition of its area.
- **Two hot paths are linear in the number of tiles.** `fnc_tileAt` runs a findIf over all tiles, and `fnc_updateDrag` checks rectangle overlap against every tile on every frame. A per-grid cell→tile owner map fixes shapes and makes both faster.
- `tileBorder = []` and `hatch = false` in the only theme, so shape outlines and hatching are low priority.
- Cells are a whole number of pixels (`fnc_getCell`) and grid corners sit on pixels, so 1-pixel seam pieces line up exactly.

### 2. Data model (computed once per class in getInfo, cached in `GVAR(info)`)

New `getInfo` keys. `"size"` keeps its meaning, the upright bounding box `[w,h]`, so every existing reader still works.

| key | type | meaning |
|---|---|---|
| `size` | `[w,h]` | upright bounding box (unchanged) |
| `cells` | NUMBER | number of filled cells (a rectangle has `w*h`) |
| `forms` | ARRAY of 4 | one form per quarter turn clockwise (layout below) |
| `turns` | ARRAY | distinct orientations to try and cycle with R: square or plus → `[0]`, rectangle, I or S → `[0,1]`, L, T or U → `[0,1,2,3]` |
| `canon` | ARRAY of 4 | maps any turn to the distinct turn it equals; rectangle → `[0,1,0,1]`, square → `[0,0,0,0]` |
| `shape` | STRING | canonical text from `fnc_formatShape`: `"2x3"`, `"L3"` or `"10/11"`, for hints, inspect and export |

Form layout as macros in `addons/main/script_macros.hpp`:
```
#define FORM_W     0  // bounding box across
#define FORM_H     1  // bounding box down
#define FORM_CELLS 2  // [[col,row],...] filled, row-major
#define FORM_RUNS  3  // per row: [[startCol,len],...]  (rectangle: [[0,w]] each row)
#define FORM_RECTS 4  // [[c,r,w,h],...] exact partition: maximal row runs merged downwards while identical
#define FORM_SEAMS 5  // [[c,r,len],...] 1-px gap under row r between two different rects, over len columns
#define FORM_BODY  6  // [c,r,w,h] largest all-filled rectangle - the picture/"?"/search ring go here
#define FORM_FULL  7  // BOOL plain rectangle -> every fast path / old behaviour
```

A mask is always trimmed (no empty border rows or columns) and 4-connected, and its bounding box has `w <= STORAGE_COLS`. The default is a full rectangle, so `FORM_FULL` is true, there is one rect, no seams, the body is the whole box and the turns are `[0,1]` or `[0]`. In that case every function below falls back to exactly today's behaviour.

### 3. String format (one grammar for the CBA table, config, the wizard and export)

Shapes go into the existing size table. A shape implies its bounding box, so there is no second table where a size and a shape could contradict each other.

```
einv_items_sizeTable := entry (("," | ";" | newline) entry)*
entry  := class ":" shape                      (exact class or nearest parent, fnc_findInTable)
shape  := base ["@" ("1"|"2"|"3")]             optional quarter turns clockwise
base   := INT "x" INT                          full rectangle, W across, H down   e.g. 2x3
        | PRESET                               e.g. L3, T4   (case-insensitive, starts with a letter, no 'x')
        | row ("/" row)*                       free mask, rows top to bottom, 1 = filled, 0 = free
row    := ("0"|"1")+                           shorter rows are padded with 0
```

Example: `rhs_30Rnd_545x39_7N10_AK:L3, rhs_30Rnd_545x39_AK:1x2, CUP_30Rnd_545x39_AK_M:10/11@1, arifle_MX_F:5x2`. The exact class beats a parent class, which is how one magazine gets L3 while its siblings stay 1x2.

Presets live in `GVAR(shapePresets)` in `items/XEH_preInit.sqf` (name → mask), with a reverse map for `formatShape`:

| preset | mask | box | cells |
|---|---|---|---|
| L3 | `10/11` | 2x2 | 3 |
| L4 | `10/10/11` | 2x3 | 4 |
| J4 | `01/01/11` | 2x3 | 4 |
| T4 | `111/010` | 3x2 | 4 |
| S4 | `011/110` | 3x2 | 4 |
| Z4 | `110/011` | 3x2 | 4 |
| U5 | `101/111` | 3x2 | 5 |
| P5 | `11/11/10` | 2x3 | 5 |
| L5 | `10/10/10/11` | 2x4 | 5 |

- L3 and its "J" twin are the same shape under rotation. L4/J4 and S4/Z4 are mirror images, and there is no mirroring because `ctrlSetAngle` cannot flip a texture.
- An entry is rejected with a warning in the RPT naming it when it is empty, disconnected, wider than `STORAGE_COLS`, uses characters other than 0/1, or has a bad `@` value.
- Parse order: preset name first, then `WxH` (contains `x` between digits), then mask.
- `fnc_formatShape` writes `WxH` for a full rectangle, the preset name when the upright mask equals a preset exactly, and the mask otherwise. Export and import therefore round-trip.
- New config key for other mods: `einv_gridShape = "L3";` (a string, same grammar). It goes before `einv_gridSize[]` in precedence.

Shipped default: no shapes, everything stays rectangular as in Tarkov. The presets are there for users to pick.

### 4. Rotation model

- `turns` is 0..3, counted clockwise. One clockwise step in a W×H box maps cell `(c,r)` to `(H-1-r, c)` and the box becomes H×W. A rectangle `[c,r,w,h]` becomes `[H-r-h, c, h, w]`.
- The body is computed **only for form 0** (largest area; ties go to the squarer rectangle, then top-left). Forms 1–3 get the rotated body. Recomputing it per form could pick a different rectangle on a tie, and the picture would no longer turn with the mask.
- Picture angle = `90*turns`.
- R cycles through the `turns` list. For a rectangle that is a toggle between 0 and 1, exactly as today, so rectangles never show upside down. Shapes that look the same at 180° (S, I) also only toggle.
- `"rotated"` stays on entries as `turns mod 2 == 1` for compatibility. The new entry key is `"turns"`.

### 5. Function-by-function changes

#### items (`addons/items/functions/`)

- **New `fnc_parseShape [text]` → `[w,h,cells]` (cells `[]` = full) or `[]`.**
  - Strip whitespace, lowercase, split off `@N`, resolve the preset.
  - `WxH`: digits only, both at least 1, width capped at `STORAGE_COLS`, same as `getSize`.
  - Mask: split on `/`, convert rows with `toArray`, only 48/49 allowed, collect `[c,r]` for each 49, then trim by min/max col and row.
  - Connectivity: breadth-first search over the cells with a HashMap keyed by `[c,r]` (array keys work), 4 neighbours, `count seen == count cells`.
  - Reject if `w > STORAGE_COLS`. Apply `@N` with the rotation formula. If `count == w*h`, return `[w,h,[]]`.
- **New `fnc_shapeForms [w,h,cells]` → `[forms, turns, canon]`.**
  1. Expand `[]` into all cells.
  2. Compute the body for form 0 by brute force: for each pair of rows r0..r1, AND the row lines and take the longest run of true. Area = len × rows; ties go to `len min rows`, then top-left.
  3. For t = 0..3:
     - Sort the cells row-major. Key = `[w,h,cells]`; `_keys find _key` gives duplicates. Store canon, and add t to `turns` when the key is new.
     - Runs: walk the sorted cells and extend the last run of the row when `start+len == c`.
     - Rects: walk the rows. A run identical (`[c,len]`) to an open rect of the previous row extends its height, otherwise it opens a new rect. Arrays are shared by reference.
     - Seams: build a rect-id grid. A seam sits at `(c,r)` when `(c,r)` and `(c,r+1)` are both filled and their rect ids differ. Group consecutive columns into `[c,r,len]`.
     - `full = count == w*h`.
     - Then rotate the cells and the body and swap w/h.
- **New `fnc_formatShape [w,h,cells]` → string** (see §3).
- **`fnc_parseTable`, size branch (lines 54-63):** replace the WxH-only parse with `[_value] call FUNC(parseShape)`. Store `[w,h,cells]` and widen the warning text. The stack branch is unchanged.
- **`fnc_getSize`:** return `[w,h,cells]`.
  - `_fnc_valid` (lines 29-33): `count _s >= 2 && {(_s select [0,2]) isEqualTypeArray [0,0]} && {w>=1} && {h>=1}`.
  - Precedence: table → `isText (_config >> QGVARMAIN(gridShape))` through `parseShape` → `einv_gridSize[]` → corrections (may hold shapes) → rules (`[w,h,[]]`).
  - Line 114: cap only full shapes (masks were already checked in `parseShape`).
- **`fnc_getInfo`** (lines 178, 189, 197):
  - `(... getSize) params ["_w","_h","_cells"]`
  - `([_w,_h,_cells] call FUNC(shapeForms)) params ["_forms","_turns","_canon"]`
  - Set `size [_w,_h]`, `cells`, `forms`, `turns`, `canon`, and `shape` (formatShape).
  - Line 189 compares `[_w,_h] isEqualTo [1,1]`, same meaning as before.
- **`XEH_PREP.hpp`:** register `parseShape`, `shapeForms` and `formatShape`.
- **`XEH_preInit`:** add `GVAR(shapePresets)` and its reverse map.
- **Setting description** (`Setting_SizeTable_Desc`): mention presets, masks and `@N`.

#### storage (`addons/storage/functions/`)

**`fnc_getLayout`**

- **`_fnc_isFree [block,col,row,form]`:**
  - The bounds check against the bounding box stays as it is (the box is tight).
  - When `FORM_FULL`, keep the current row-slice loop (lines 59-61).
  - Otherwise:
    ```
    {
        private _r = _row + _forEachIndex;
        if (_r > _last) exitWith {};
        private _line = _grid select _r;
        if (_x findIf {(_line select [_col + (_x select 0), _x select 1]) findIf {_x} >= 0} >= 0) exitWith {_free = false};
    } forEach (_form select FORM_RUNS);
    ```
- **`_fnc_take [block,col,row,form]`:** grow the rows as now, then for each run of each row `for "_c" from (_col+start) to (_col+start+len-1) do {_line set [_c,true]}`. A rectangle has one run per row, so the work is identical to today.
- **Reading records** (line 93): `_x isEqualType [] && {count _x >= 6} && {(_x select [0,6]) isEqualTypeArray ["",0,0,0,0,0]}`.
- **Reconcile** (lines 127-146):
  - `params [..., "_block", ["_turns",-1]]`.
  - If the turns are not in 0..3 (an old record), derive them as today: `[0,1] select (_w != _h && {_recordW == _h} && {_recordH == _w})`.
  - `_turns = _canon select _turns`, `_form = _forms select _turns`.
  - The record is accepted only if the form's W/H equal the record's W/H and `isFree` with the form succeeds. This also re-places items whose shape changed mid-mission.
  - Set `w`, `h`, `turns`, `rotated` and `cells`.
- **Order** (line 157): `[-(_info get "cells"), -(w*h), category, class, index]`, and read `_x select 4` at line 192. For rectangles cells equals w×h, so the order is unchanged.
- **`_fnc_find [form]`:** same loop bounded by `FORM_W`/`FORM_H`. Optional micro-optimisation: test the form's first filled cell before calling `isFree`.
- **Auto-turn** (lines 197-208): `{ _spot = [_forms select _x] call _fnc_find; if (_spot isNotEqualTo []) exitWith {_turns = _x} } forEach (_info get "turns");`. Then take the spot and set w/h/turns/rotated from that form. Rectangles keep "upright first, then turned".
- Overflow entries stay upright with turns 0.
- **Store** (line 242): `[class, col, row, w, h, block, turns]`.

**Other storage functions**

- **`fnc_setPlace`:**
  - `_turns = _entry getOrDefault ["turns",0]`. If `count _cell >= 5`: `_w`/`_h` from the cell and `_turns = _cell param [5, -1]` (−1 means getLayout derives it).
  - Write 7-element records (lines 48 and 66) and relax the findIf type check (line 54).
  - Optional: also match `(_x param [6,-1]) in [-1, entry turns]`. This guards the rare case of two same-class items whose bounding boxes share an anchor without overlapping.
- **`fnc_getSlot`** (lines 75-85): add `["turns",0]`.
- **`fnc_entryToArray` / `fnc_entryFromArray`:** append `turns` at index 10, default 0. The server ignores it.
- **No change:** `fnc_hasSpace` (dry-runs getLayout, so it is shape-aware automatically), `fnc_moveEntry`, `fnc_getContents`, `fnc_getBlocks`, `fnc_hasRoom`.
- **Possible later extension:** non-rectangular compartments, e.g. `10/11` pieces in `containerTable`. getLayout would pre-mark hole cells as taken, and createGrid would hide them and set their owner to −2.

#### gui (`addons/gui/functions/`)

- **`fnc_createGrid`:** add `["owner", _cells apply {-1}]`, a flat `cols*rows` cell→tile-index array.
- **New `fnc_shapePieces [form, cellW, cellH]` → `[[dx,dy,w,h],...]`, rects first.**
  - rects: `[c*cellW, r*cellH, w*cellW - pixelW, h*cellH - pixelH]`
  - seams: `[c*cellW, (r+1)*cellH - pixelH, len*cellW - pixelW, pixelH]`
  - Together they are an exact, overlap-free partition: L3 → 3 controls, T4 → 3, U5 → 4, a rectangle → 1. Used by createTile, the drag footprint, and the wizard's preview.
- **`fnc_createTile`:**
  - `_turns = (_info get "canon") select ((_entry getOrDefault ["turns", [0,1] select rotated]) mod 4)`, `_form = forms select _turns`.
  - Cell loop (replaces lines 61-67): for each `FORM_CELLS` entry inside the grid, `ctrlShow false` on that cell and `_owner set [_i, count (_grid get "tiles")]`. Only filled cells give way, so other tiles can sit in the empty cells of the box.
  - Backgrounds: full → `[[0,0,_width,_height]]` (keeps the current overflow clip); shape → `shapePieces`. One `EINV_PanelRect` per piece with `_color`.
  - Store `"backgrounds"` (all pieces), `"background"` (the first), and `"bodyRect"` (screen rect of `FORM_BODY`, in the parent's coordinates).
  - Picture and attachments: in the padded body rect. Turns 0 → `uiPicture`; 1/2/3 → `uiPictureTurned` with angle `90*turns` and aspect = form 0 body w/h (today `_sizeW/_sizeH`, the same for rectangles). Attachments only at turns 0, as now.
  - Name: in the top run (`(runs select 0)`, last run), right-aligned in its width.
  - Ammo bar and count: in the bottom run (`(runs select (h-1))`, last run). The pill and badge x positions and `_bottom` come from that run rectangle instead of `_left`/`_width`/`_top+_height`. For a rectangle the top and bottom runs are the full width, so nothing changes.
  - Hidden tiles: `uiHatch` per rect piece (not seams); the "?" in the body rect.
  - `tileBorder`: unused today. For shapes, skip it, or add outline segments later if a theme needs them.
- **`fnc_tileAt`:** `(_grid getOrDefault ["owner", []]) param [_row * (_grid get "cols") + _col, -1]`. This is O(1) and hits only filled cells. `screenToCell` already bounds-checks.
- **`fnc_onMouseButton`:** no change. The grab offset at line 110 is relative to the box, and `tileAt` guarantees the grabbed cell is a filled one.
- **`fnc_startDrag`:**
  - `GVAR(dragTurns) = canon select entry turns`; `GVAR(dragSize)` from that form.
  - Footprint becomes a **pool**: as many `EINV_PanelRect` controls as the largest piece count over all forms of the item (1 for rectangles). Created before the ghost to keep z-order, stored as an array in `dragFootprint`.
  - Add `GVAR(dragTurns) = 0` to `XEH_preInit`.
- **`fnc_makeGhost`:**
  - The ghost rect is the form's body: `[bc*cellW, br*cellH, bw*cellW, bh*cellH]`. Offsets come from `ctrlPosition` as now.
  - Angle = `90*dragTurns` through the generalised `uiPictureTurned`, replacing the `_turned` detection at line 36. That check compares w with the size, which cannot see a 180° turn.
  - Set `dragAngle`, and set `dragPieces = [form, cellW, cellH] call FUNC(shapePieces)` so it is not recomputed every frame.
- **`fnc_rotateDrag`:**
  - Return false if `count (info get "turns") < 2` (replaces the `_w == _h` check).
  - `_next` = the next entry of `turns`, cyclically.
  - Grab cell: rectangle → keep the transpose at line 35. Shape → apply `(_next-_old+4) mod 4` clockwise steps of `(c,r)→(H-1-r,c)` with an H/W swap per step, so the grabbed cell stays a filled cell under the mouse.
  - Set `dragTurns` and `dragSize` from the new form, then call `makeGhost` and `updateDrag`.
- **`fnc_updateDrag`:**
  - Ghost: `if (_angle != 0) then {_ghost ctrlSetAngle [_angle,0.5,0.5]}` (replaces the 90-only line 70).
  - Counter: at the bottom-right of the body rect.
  - Bounds check at line 209 stays on the box.
  - Overlap (replaces lines 213-223):
    ```
    private _self = [-1, _tileIndex] select (_targetIndex == _sourceIndex);
    private _blocked = (_form select FORM_CELLS) findIf {
        private _o = _owner param [(_row + (_x select 1)) * _cols + _col + (_x select 0), -1];
        _o >= 0 && {_o != _self}
    } >= 0;
    ```
    This is O(cells) per frame instead of O(tiles).
  - Footprint (replaces lines 250-263): for each piece of `dragPieces`, offset from the target cell, clip to the grid box (origin to `cols*cellW - pixelW`), hide pieces that end up fully outside, show the rest green or red. Hide the unused pool controls. The piece under the mouse is always inside.
  - On a slot: piece 0 takes the slot rect and the others are hidden. `_fnc_show` takes the control as a parameter.
- **`fnc_endDrag`:**
  - Delete every control in the footprint pool (line 28; type is now an array).
  - `_cell = [_col,_row,_block,_w,_h,GVAR(dragTurns)]`.
  - The "dropped where it lies" check (lines 114-117) also compares `GVAR(dragTurns)` with the entry's turns, because 0° and 180° have the same w,h.
- **`fnc_uiPictureTurned`:** new parameter 6 `_angle` (default 90).
  - If `_angle mod 180 == 0`: build the control in the shape it shows (`_long = _boxW min (_boxH*_aspect)`, w = `_long*pixelW`, h = `(_long/_aspect)*pixelH`).
  - Otherwise use the current swapped maths.
  - Then `ctrlSetAngle [_angle,0.5,0.5]`.
- **`fnc_updateHover`:**
  - `_fnc_light` (lines 134-145): loop `ctrlSetBackgroundColor` over `"backgrounds"`.
  - Hint size (lines 270, 287, 329): full → `w×h` as now; shape → for example `"2×2 · L3"` or `"2×2 · 3 cells"` (needs a stringtable key).
- **`fnc_inspect`** (lines 71-72): the same size text.
- **`fnc_flashTile`:** one fading flash control per entry in `"backgrounds"`, using `ctrlPosition` and the parent group of each.
- **`fnc_showSearch`:** centre and size the ring from `_tile getOrDefault ["bodyRect", ctrlPosition _background]`.
- **`fnc_revealFx`:** `if !(_x in _backgrounds)`.
- **`fnc_markHidden`** (line 47): search cost from `cells`, not `w*h` (getLayout sets entry `"cells"`; fall back to w*h). `animateSearch` reads it unchanged through `_head select 4`.
- **`fnc_drawSection`:** no change. Overflow entries get their own compartment the size of their box with turns 0, and the empty cells show as empty grid.
- **No change:** `fnc_findTile` (anchor = top-left of the box, matched with class), `fnc_screenToCell`, `fnc_applyFilter`, `fnc_animateSearch`, `fnc_contextMenu` (sort just clears the records), `fnc_applyMove`, `fnc_quickMove`, `fnc_quickUnequip`, `fnc_doUnequip`, `fnc_onServerAnswer` (these pass the cell, which now carries turns).

### 6. Every place that assumes rectangles today

- **items:**
  - `fnc_getSize.sqf` 29-33, 39-48, 114
  - `fnc_parseTable.sqf` 54-63
  - `fnc_getInfo.sqf` 178, 189, 197
- **storage:**
  - `fnc_getLayout.sqf` 49-64, 66-82, 93, 113-118, 127-146, 157, 165-189, 197-208, 234, 242
  - `fnc_setPlace.sqf` 36-43, 48, 54, 66
  - `fnc_getSlot.sqf` 75-85
  - `fnc_entryToArray.sqf` 30-31, `fnc_entryFromArray.sqf`
- **gui:**
  - `fnc_createTile.sqf`: 51-58 (size and clip), 61-67 (cell hiding), 70-73, 91-93 (single background), 97 (hatch), 101-104 (mark), 109-118 (90° only, picture over the whole box), 121-125, 127-134 (name across the box), 139-204 (count and bar on the box edges), 210 (frame), 214
  - `fnc_tileAt.sqf` 22-27
  - `fnc_startDrag.sqf` 43-48
  - `fnc_updateDrag.sqf` 60-81, 69-71, 213-223, 250-263
  - `fnc_endDrag.sqf` 28, 43, 98, 114-117
  - `fnc_makeGhost.sqf` 32-43
  - `fnc_rotateDrag.sqf` 27-35
  - `fnc_uiPictureTurned.sqf` 60
  - `fnc_markHidden.sqf` 47
  - `fnc_flashTile.sqf` 32-44
  - `fnc_showSearch.sqf` 34-45
  - `fnc_revealFx.sqf` 27-38
  - `fnc_updateHover.sqf` 134-145, 270, 287, 329
  - `fnc_inspect.sqf` 71-72
- **Uses the box but is still correct:** `fnc_drawSection.sqf` 186, 296-299; `fnc_onMouseButton.sqf` 110; `fnc_findTile.sqf` 35-37.

### 7. Performance

- **Item info:** the forms are built once per class (8×8 masks at most) and cached. The cost is negligible.
- **getLayout:**
  - Full forms keep the old fast path.
  - Shapes iterate one runs list per bounding-box row, which costs about the same as a rectangle.
  - Extra orientations are tried only when an item fits nowhere upright.
  - `hasSpace` still costs one getLayout.
- **Hover and drag get faster:** `tileAt` goes from O(tiles) to O(1), and the per-frame overlap check in `updateDrag` goes from O(tiles) to O(cells). This is a net gain for large crates.
- **Controls:** a shaped tile needs its rects plus seams (about 3–4 controls instead of 1). Rectangles need no extra controls. The owner array is written in the cell-hiding loop that already exists. The footprint pool is created once per drag.

### 8. Multiplayer, sharing and fallback

- Shapes travel inside the existing global size table, so the server forces them for everyone. Export and import use the same grammar, with `fnc_formatShape` producing the canonical text.
- A setting change clears `GVAR(info)`. Stored records whose form no longer fits get re-placed on the next getLayout.
- Fallback for a bad entry: a warning in the RPT, the entry is left out, and the next source in precedence applies, down to the rectangle rules. With nothing set, everything stays rectangular.
- The wizard can reuse this directly: `parseShape` to validate as the user types, `formatShape` for export, and `shapeForms` + `shapePieces` for a live preview. A toggle grid of up to 4×4 cells with a preset dropdown, plus R to preview the turns, would produce the mask string.

### 9. To check in the game

1. **Rotation direction of `ctrlSetAngle`.** The plan assumes clockwise (screen y points down). If it turns out counter-clockwise, change the single rotation formula in `fnc_shapeForms` to `(c,r)→(r, W-1-c)` and the body rotation to match.
2. **Pictures at 180° and 270°** through the generalised `uiPictureTurned`.
3. **Pictures fill only the body rectangle**, e.g. the 2×1 part of an L3. Drawing over the whole box would cover tiles lying in its empty cells, so this is a deliberate trade-off.
4. **Seams line up pixel-exactly** under the semi-transparent tile colours.
5. **No mirroring:** J4 and L4 (and Z4 and S4) must stay separate presets.