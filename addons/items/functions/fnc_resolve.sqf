#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the rules make of an item: its size, how many share a tile, a container's grid, a weight, a
 * name of its own, how its picture is drawn in its tile, which picture it is and the containers it may be
 * used from. Each of these is a field of its own and
 * goes to the first that has an answer, highest first:
 *
 *   own     - the rules text (later rules first), and after it the older tables (einv_items_sizeTable,
 *             einv_items_stackTable, einv_storage_containerTable), which therefore win over the text
 *   mod     - the item's own config: einv_size, einv_stack, einv_grid, einv_weight, einv_name,
 *             einv_icon, einv_picture, einv_use, einv_cat, and where one of those is not set the older einv_gridSize[], einv_stackSize, einv_grids[]
 *             or einv_slots (fnc_getFacts, fnc_readConfigKeys). A subclass has its parent's, and
 *             the rules text above still has the last word
 *   preset  - the preset chain (a derived preset after its base, later rules first), and after it
 *             einv_items_stackSmall when it is moved off its default
 *   all     - the text's rules with "all", everything else (later rules first): they answer only what
 *             every layer above left open, so they fill the gaps and never override a rule, a table, a
 *             mod or the preset - but for the preset's own everything else, its rules without any
 *             condition (the default's first, size=1x1 stack=1, reaches every item): a field only such a
 *             rule answered is open to them, and keeps the preset's answer where they have none
 *   builtin - 1x1, alone on its tile, a grid by load (a fifth more for what is worn: BUILTIN_WORN_GRID), the
 *             config's weight and name, the plain picture
 *
 * Only the rules that can be about the item's kind are asked (fnc_compileRules sorts them), and a
 * layer is left as soon as nothing it could still set is open.
 *
 * A rule with like=X sets, besides what it sets itself, every field of LIKE_FIELDS still open - size,
 * stack, grid and weight, never the name, icon, picture or use - to what this function makes of X, asked now through the
 * same compiled rules: a later change to X follows, and a rule like=X grid=6x4 takes X's answer with
 * its own grid on top. X's answer is X's in full: its grid as the compartments X really has
 * (einv_storage_fnc_blocksFor with X's class, kind and load - "auto" by this item's own load would be
 * another grid). Its weight only when a rule or X's own config (einv_weight) sets one on X - else -1,
 * and this item keeps its own config's weight. Should X be no container, its grid is "auto". A class
 * no config knows, a like= that comes back round to a class on its way, or more than LIKE_DEPTH of
 * them one after the other give the built-in answer for those fields instead, named in the RPT once.
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
 *   "footprint" - [w, h, holes] upright, holes the indices row * w + col of the cells a shaped item
 *                 (size=xx/x-) does not take, [] for a full rectangle <ARRAY>
 *   "stack"     - how many share a tile, at least 1 <NUMBER>
 *   "grid"      - for uniforms, vests, backpacks, crates, vehicles and kits the grid spec
 *                 (fnc_parseGrid), else [] <ARRAY>
 *   "weight"    - its weight in kg by the rules, -1 when none sets one <NUMBER>
 *   "name"      - its name by the rules, "" when none sets one <STRING>
 *   "icon"      - how its picture is drawn in its tile, [scale, across, down] (fnc_parseIcon), ICON_PLAIN
 *                 [1, 0, 0] when none sets it <ARRAY>
 *   "picture"   - the texture the rules give it (picture=, fnc_parsePicture), "" when none does <STRING>
 *   "use"       - the containers it may be used from where a setting limits what can be used there (use=,
 *                 fnc_parseUse), in the order uniform, vest, backpack; [] when none says <ARRAY of STRING>
 *   "cats"      - the categories the rules or the config put it in (cats=, einv_cat, fnc_parseGroups), in the
 *                 order of fnc_orderGroups; [] when none says: the built-in mapping then (fnc_defaultGroup) <ARRAY of STRING>
 *   "src"       - field -> where it came from: "own:<i>" (i-th rule of the text),
 *                 "legacy:<setting>:<i>", "mod:<config key>", "preset:<preset>:<i>", "all:<i>" (the
 *                 i-th rule of the text, one with "all"), "builtin", "forced" <HASHMAP>
 *
 * Example:
 * [["arifle_MX_F"] call einv_items_fnc_getFacts, call einv_items_fnc_currentRules] call einv_items_fnc_resolve;
 *
 * Public: No
 */

params [["_facts", createHashMap, [createHashMap]], ["_compiled", createHashMap, [createHashMap]], ["_chain", [], [[]]]];

private _kind = _facts get "kind";
private _need = ["footprint", "weight", "name", "icon", "picture", "use", "cats"];

if !(_kind in KINDS_SINGLE) then {
    _need pushBack "stack";
};

if (_kind in KINDS_CONTAINER) then {
    _need pushBack "grid";
};

private _result = createHashMap;
private _src = createHashMap;
private _memo = createHashMap;

((_compiled getOrDefault ["byKind", createHashMap]) getOrDefault [_kind, [[], [], [], []]]) params [
    "_ownIndices", "_presetIndices", "_ownFields", "_presetFields", ["_fallbackIndices", []], ["_fallbackFields", []]
];

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

// The fields a preset's rule without conditions answered - the preset's own everything else, which the
// text's "all" rules come before.
private _caught = [];

// One layer's rules, highest first; each takes the fields still open that it sets, if it matches -
// with like=, those it leaves to that class as well. With the fourth argument, what a rule without
// conditions takes is noted in _caught.
private _fnc_walk = {
    params ["_rules", "_indices", "_fields", ["_noteCaught", false]];

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

            if (_noteCaught && {_conds isEqualTo []}) then {
                _caught append _sets;
            };

            _need = _need - _sets;
        };
    } forEach _indices;
};

[_compiled getOrDefault ["own", []], _ownIndices, _ownFields] call _fnc_walk;

// What the item's own mod says, for what is still open. The keys written like the rules (einv_size and
// the like) come first, the older ones only where those leave a field open.
private _mod = _facts get "mod";

if ("footprint" in _need) then {
    if ("size" in _mod) then {
        _result set ["footprint", _mod get "size"];
        _src set ["footprint", "mod:" + QGVARMAIN(size)];
        _need = _need - ["footprint"];
    } else {
        if ("gridSize" in _mod) then {
            (_mod get "gridSize") params ["_w", "_h"];

            _result set ["footprint", [_w, _h, []]];
            _src set ["footprint", "mod:" + QGVARMAIN(gridSize)];
            _need = _need - ["footprint"];
        };
    };
};

if ("stack" in _need) then {
    if ("stack" in _mod) then {
        _result set ["stack", _mod get "stack"];
        _src set ["stack", "mod:" + QGVARMAIN(stack)];
        _need = _need - ["stack"];
    } else {
        if ("stackSize" in _mod) then {
            _result set ["stack", _mod get "stackSize"];
            _src set ["stack", "mod:" + QGVARMAIN(stackSize)];
            _need = _need - ["stack"];
        };
    };
};

if ("grid" in _need) then {
    if ("grid" in _mod) then {
        // Read by the rules' own reader, so already within their limits.
        _result set ["grid", _mod get "grid"];
        _src set ["grid", "mod:" + QGVARMAIN(grid)];
        _need = _need - ["grid"];
    } else {
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
            _src set ["grid", "mod:" + QGVARMAIN(grids)];
            _need = _need - ["grid"];
        } else {
            if ("slots" in _mod) then {
                _result set ["grid", ["cells", (_mod get "slots") min MAX_CELLS]];
                _src set ["grid", "mod:" + QGVARMAIN(slots)];
                _need = _need - ["grid"];
            };
        };
    };
};

if ("weight" in _need && {"weight" in _mod}) then {
    _result set ["weight", _mod get "weight"];
    _src set ["weight", "mod:" + QGVARMAIN(weight)];
    _need = _need - ["weight"];
};

if ("name" in _need && {"name" in _mod}) then {
    _result set ["name", _mod get "name"];
    _src set ["name", "mod:" + QGVARMAIN(name)];
    _need = _need - ["name"];
};

if ("icon" in _need && {"icon" in _mod}) then {
    _result set ["icon", _mod get "icon"];
    _src set ["icon", "mod:" + QGVARMAIN(icon)];
    _need = _need - ["icon"];
};

if ("picture" in _need && {"picture" in _mod}) then {
    _result set ["picture", _mod get "picture"];
    _src set ["picture", "mod:" + QGVARMAIN(picture)];
    _need = _need - ["picture"];
};

if ("use" in _need && {"use" in _mod}) then {
    _result set ["use", _mod get "use"];
    _src set ["use", "mod:" + QGVARMAIN(use)];
    _need = _need - ["use"];
};

if ("cats" in _need && {"cats" in _mod}) then {
    _result set ["cats", _mod get "cats"];
    _src set ["cats", "mod:" + QGVARMAIN(cat)];
    _need = _need - ["cats"];
};

[_compiled getOrDefault ["preset", []], _presetIndices, _presetFields, true] call _fnc_walk;

// Everything else (all): what no rule, table, mod or preset answered - the gaps, and only those - and
// what only the preset's everything else did. Of those, what the text's has no answer for stays the
// preset's.
if (_fallbackIndices isNotEqualTo []) then {
    _need append _caught;

    [_compiled getOrDefault ["fallback", []], _fallbackIndices, _fallbackFields] call _fnc_walk;

    _need = _need - _caught;
};

// What nothing set.
{
    _result set [_x, switch (_x) do {
        case "footprint": {[1, 1, []]};
        case "stack": {1};
        // A uniform, vest or backpack a fifth roomier than its load, the rest exactly by it.
        case "grid": {[["auto"], BUILTIN_WORN_GRID] select (_kind in WORN_KINDS)};
        case "weight": {-1};
        case "icon": {ICON_PLAIN};
        case "use": {[]};
        case "cats": {[]};
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

_footprint params ["_w", "_h", ["_holes", []]];

// A shape from the rules is within SHAPE_MAX already, and a size=mass one is cut to it here: an item is
// never wider or taller than the Items drawing, whatever the container's columns are. Should a box ever be
// cut down, its holes would no longer fit it, and a full rectangle is the safe reading.
private _fitW = (_w min SHAPE_MAX) max 1;
private _fitH = (_h min SHAPE_MAX) max 1;

if (_fitW != _w || {_fitH != _h}) then {
    _holes = [];
};

_result set ["footprint", [_fitW, _fitH, _holes]];
_result set ["src", _src];

_result
