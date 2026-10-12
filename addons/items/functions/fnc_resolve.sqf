#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the rules make of an item: its size, how many share a tile, a container's grid, a weight and a
 * name of its own. Each of these is a field of its own and goes to the first that has an answer,
 * highest first:
 *
 *   own     - the rules text (later rules first), and after it the older tables (einv_items_sizeTable,
 *             einv_items_stackTable, einv_storage_containerTable), which therefore win over the text
 *   mod     - the item's own config: einv_gridSize[], einv_stackSize, einv_grids[] or einv_slots
 *   preset  - the preset chain (a derived preset after its base, later rules first), and after it
 *             einv_items_stackSmall when it is moved off its default
 *   builtin - 1x1, alone on its tile, a grid by load, the config's weight and name
 *
 * Only the rules that can be about the item's kind are asked (fnc_compileRules sorts them), and a
 * layer is left as soon as nothing it could still set is open.
 *
 * Then: weapons, binoculars, uniforms, vests and backpacks never share a tile ("forced"), whatever any
 * rule says. size=mass becomes cells by the weight - the weight of the rules, if one sets it - and the
 * compiled mass per cell: rifles and launchers lie two rows high, everything else near square. No
 * item is wider than STORAGE_COLS or higher than MAX_ROWS.
 *
 * Arguments:
 * 0: The item's facts (fnc_getFacts) <HASHMAP>
 * 1: Compiled rules (fnc_compileRules) <HASHMAP>
 *
 * Return Value:
 * What the rules make of it <HASHMAP>
 *   "footprint" - [w, h, cells], cells [] for a full rectangle <ARRAY>
 *   "stack"     - how many share a tile, at least 1 <NUMBER>
 *   "grid"      - for uniforms, vests, backpacks, crates and vehicles the grid spec
 *                 (fnc_parseGrid), else [] <ARRAY>
 *   "weight"    - its weight in kg by the rules, -1 when none sets one <NUMBER>
 *   "name"      - its name by the rules, "" when none sets one <STRING>
 *   "src"       - field -> where it came from: "own:<i>" (i-th rule of the text),
 *                 "legacy:<setting>:<i>", "mod:<config key>", "preset:<preset>:<i>", "builtin",
 *                 "forced" <HASHMAP>
 *
 * Example:
 * [["arifle_MX_F"] call einv_items_fnc_getFacts, call einv_items_fnc_currentRules] call einv_items_fnc_resolve;
 *
 * Public: No
 */

params [["_facts", createHashMap, [createHashMap]], ["_compiled", createHashMap, [createHashMap]]];

private _kind = _facts get "kind";
private _need = ["footprint", "weight", "name"];

if !(_kind in KINDS_SINGLE) then {
    _need pushBack "stack";
};

if (_kind in KINDS_CONTAINER) then {
    _need pushBack "grid";
};

private _result = createHashMap;
private _src = createHashMap;
private _memo = createHashMap;

((_compiled getOrDefault ["byKind", createHashMap]) getOrDefault [_kind, [[], [], [], []]]) params ["_ownIndices", "_presetIndices", "_ownFields", "_presetFields"];

// One layer's rules, highest first; each takes the fields still open that it sets, if it matches.
private _fnc_walk = {
    params ["_rules", "_indices", "_fields"];

    {
        if ((_need arrayIntersect _fields) isEqualTo []) exitWith {};

        (_rules select _x) params ["_conds", "_values", "_tag"];

        private _sets = (keys _values) arrayIntersect _need;

        if (_sets isNotEqualTo [] && {[_facts, _conds, _compiled, _memo] call FUNC(matches)}) then {
            {
                _result set [_x, _values get _x];
                _src set [_x, _tag];
            } forEach _sets;

            _need = _need - _sets;
        };
    } forEach _indices;
};

[_compiled getOrDefault ["own", []], _ownIndices, _ownFields] call _fnc_walk;

// What the item's own mod says, for what is still open.
private _mod = _facts get "mod";

if ("footprint" in _need && {"gridSize" in _mod}) then {
    (_mod get "gridSize") params ["_w", "_h"];

    _result set ["footprint", [_w, _h, []]];
    _src set ["footprint", "mod:einv_gridSize"];
    _need = _need - ["footprint"];
};

if ("stack" in _need && {"stackSize" in _mod}) then {
    _result set ["stack", _mod get "stackSize"];
    _src set ["stack", "mod:einv_stackSize"];
    _need = _need - ["stack"];
};

if ("grid" in _need) then {
    if ("grids" in _mod) then {
        // Within the same limits as compartments in the rules: whole compartments only.
        private _blocks = (_mod get "grids") apply {[((floor (_x select 0)) max 1) min STORAGE_COLS, ((floor (_x select 1)) max 1) min MAX_ROWS]};
        private _total = 0;
        private _kept = [];

        {
            _total = _total + (_x select 0) * (_x select 1);

            if (_total > MAX_CELLS || {count _kept >= MAX_BLOCKS}) exitWith {};

            _kept pushBack _x;
        } forEach _blocks;

        _result set ["grid", ["blocks", _kept]];
        _src set ["grid", "mod:einv_grids"];
        _need = _need - ["grid"];
    } else {
        if ("slots" in _mod) then {
            _result set ["grid", ["cells", (_mod get "slots") min MAX_CELLS]];
            _src set ["grid", "mod:einv_slots"];
            _need = _need - ["grid"];
        };
    };
};

[_compiled getOrDefault ["preset", []], _presetIndices, _presetFields] call _fnc_walk;

// What nothing set.
{
    _result set [_x, switch (_x) do {
        case "footprint": {[1, 1, []]};
        case "stack": {1};
        case "grid": {["auto"]};
        case "weight": {-1};
        default {""};
    }];
    _src set [_x, "builtin"];
} forEach _need;

// A uniform, vest or backpack holds things of its own and a weapon carries its attachments - a tile
// shows and moves only one of them with what it holds, so the others' would be lost.
if (_kind in KINDS_SINGLE) then {
    _result set ["stack", 1];
    _src set ["stack", "forced"];
};

// A mod's config or a rule may say 0 or a fraction; a tile holds whole items, at least one.
_result set ["stack", (floor (_result get "stack")) max 1];

if !(_kind in KINDS_CONTAINER) then {
    _result set ["grid", []];
};

// size=mass: as many cells as it weighs, by the weight the rules give it.
private _footprint = _result get "footprint";

if (_footprint isEqualTo "mass") then {
    private _weight = _result get "weight";
    private _mass = [_facts get "mass", _weight / MASS_TO_KG] select (_weight >= 0);
    private _cell = (_compiled getOrDefault ["cell", DEFAULT_MASS_PER_CELL]) max CELL_MIN;
    private _area = (ceil (_mass / _cell)) max 1;
    private _w = 1;
    private _h = 1;

    if (_kind in ["rifle", "launcher"]) then {
        _h = 2 min _area;
        _w = ceil (_area / _h);
    } else {
        _w = ceil (sqrt _area);
        _h = ceil (_area / _w);
    };

    _footprint = [_w, _h, []];
};

_footprint params ["_w", "_h", ["_cells", []]];

_result set ["footprint", [(_w min STORAGE_COLS) max 1, (_h min MAX_ROWS) max 1, _cells]];
_result set ["src", _src];

_result
