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
 * A rule with like=X sets, besides what it sets itself, every field of LIKE_FIELDS still open - size,
 * stack, grid and weight, never the name - to what this function makes of X, asked now through the
 * same compiled rules: a later change to X follows, and a rule like=X grid=6x4 takes X's answer with
 * its own grid on top. X's answer is X's in full: its grid as the compartments X really has
 * (einv_storage_fnc_blocksFor with X's class, kind and load - "auto" by this item's own load would be
 * another grid). Its weight only when a rule sets one on X - else -1, and this item keeps its own
 * config's weight. Should X be no container, its grid is "auto". A class no config knows, a like= that comes back round to a class on its way, or more
 * than LIKE_DEPTH of them one after the other give the built-in answer for those fields instead,
 * named in the RPT once.
 *
 * Then: weapons, binoculars, uniforms, vests and backpacks never share a tile ("forced"), whatever any
 * rule says. size=mass becomes cells by the weight - the weight of the rules, if one sets it - and the
 * compiled mass per cell: rifles and launchers lie two rows high, everything else near square. No
 * item is wider than STORAGE_COLS or higher than MAX_ROWS.
 *
 * Arguments:
 * 0: The item's facts (fnc_getFacts) <HASHMAP>
 * 1: Compiled rules (fnc_compileRules) <HASHMAP>
 * 2: The classes a like= led here from, lowercase, the first first - only its own calls pass it <ARRAY>
 *    (default: [])
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

params [["_facts", createHashMap, [createHashMap]], ["_compiled", createHashMap, [createHashMap]], ["_chain", [], [[]]]];

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

private _likeAnswers = createHashMap;

// What like=CLASS gives: [answer per field of LIKE_FIELDS, it is the built-in one]. Asked once per
// class and call, and only when a rule with it matches.
private _fnc_like = {
    params ["_like"];

    private _known = _likeAnswers get _like;

    if (!isNil "_known") exitWith {_known};

    private _path = _chain + [_facts get "lc"];
    private _likeFacts = [_like] call FUNC(getFacts);
    private _problem = "";
    private _problemKey = "";

    switch (true) do {
        case (_like in _path): {
            // The circle alone, wherever it was entered: one RPT line for it, not one per class in it.
            private _circle = _path select [_path find _like];
            private _members = +_circle;

            _members sort true;
            _problem = format ["like= goes round in a circle: %1", (_circle + [_like]) joinString " > "];
            _problemKey = "circle:" + (_members joinString " ");
        };
        case (count _path > LIKE_DEPTH): {
            _problem = format ["more than %1 like= one after the other reach %2", LIKE_DEPTH, _like];
            _problemKey = "deep:" + _like;
        };
        case ((_likeFacts get "root") isEqualTo ""): {
            _problem = format ["like=%1 - no config knows this class", _like];
            _problemKey = "unknown:" + _like;
        };
    };

    private _answer = if (_problem isEqualTo "") then {
        private _resolved = [_likeFacts, _compiled, _path] call FUNC(resolve);
        private _likeKind = _likeFacts get "kind";
        private _grid = ["auto"];

        // The compartments that class has, not its spec: "auto", a share or a pattern would be laid
        // out by this item's own load and name. The storage addon lays them out; without it the spec.
        if (_likeKind in KINDS_CONTAINER) then {
            _grid = _resolved get "grid";

            if (!isNil QEFUNC(storage,blocksFor)) then {
                _grid = ["blocks", [
                    _likeFacts get "class",
                    [_likeKind, "crate"] select (_likeKind in ["crate", "vehicle"]),
                    _likeFacts get "maxLoad",
                    _grid,
                    (_compiled getOrDefault ["cell", DEFAULT_MASS_PER_CELL]) max CELL_MIN
                ] call EFUNC(storage,blocksFor)];
            };
        };

        // A weight only when a rule gives that class one: -1, none, leaves this item its own config's.
        private _weight = _resolved get "weight";

        [createHashMapFromArray [
            ["footprint", _resolved get "footprint"],
            ["stack", _resolved get "stack"],
            ["grid", _grid],
            ["weight", _weight]
        ], false]
    } else {
        if (isNil QGVAR(likeWarned)) then {
            GVAR(likeWarned) = createHashMap;
        };

        if !(_problemKey in GVAR(likeWarned)) then {
            GVAR(likeWarned) set [_problemKey, true];
            WARNING_1("Rules: %1 - the built-in answer instead",_problem);
        };

        [createHashMapFromArray [
            ["footprint", [1, 1, []]],
            ["stack", 1],
            ["grid", ["auto"]],
            ["weight", -1]
        ], true]
    };

    _likeAnswers set [_like, _answer];

    _answer
};

// One layer's rules, highest first; each takes the fields still open that it sets, if it matches -
// with like=, those it leaves to that class as well.
private _fnc_walk = {
    params ["_rules", "_indices", "_fields"];

    {
        if ((_need arrayIntersect _fields) isEqualTo []) exitWith {};

        (_rules select _x) params ["_conds", "_values", "_tag"];

        private _like = _values getOrDefault ["like", ""];
        private _offers = keys _values;

        if (_like isNotEqualTo "") then {
            _offers append LIKE_FIELDS;
        };

        private _sets = _offers arrayIntersect _need;

        if (_sets isNotEqualTo [] && {[_facts, _conds, _compiled, _memo] call FUNC(matches)}) then {
            {
                private _field = _x;

                if (_field in _values) then {
                    _result set [_field, _values get _field];
                    _src set [_field, _tag];
                } else {
                    ([_like] call _fnc_like) params ["_answer", "_builtin"];

                    _result set [_field, _answer get _field];
                    _src set [_field, [_tag, "builtin"] select _builtin];
                };
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
