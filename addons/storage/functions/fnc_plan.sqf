#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Works out where several things go when they are moved together: for every item the first target, in the
 * order given, that has a free spot for it in one of its compartments (as fnc_hasSpace asks it) - and the
 * cell it takes there. Largest first, so a rucksack does not get the cells a handful of bandages have taken.
 * Free cells are the only limit: what the items weigh decides nothing here.
 *
 * Nothing is changed and nothing is asked of any machine but this one: each target is laid out from what
 * this machine reads of it now (fnc_getContents, fnc_getLayout), and what is planned into it counts for the
 * items after - 25 bandages never all plan the same cell. The authority runs the same layout on the same
 * synced data, so a plan only fails when someone changed the holder meanwhile; then the put falls back to
 * the first fit ("Put elsewhere") or bounces, and settlement takes over (fnc_settle).
 *
 * An item never goes into a target that is the container it is (a backpack tile) or lies in it
 * (fnc_liesIn). "ground" as a target always has room and takes no cell.
 *
 * Arguments:
 * 0: Items, entries as the window's tiles are - "class", "count", "key", "block", "col", "row", and
 *    "holder" for where they lie now (anything else they carry stays on them) <ARRAY of HASHMAPs>
 * 1: Targets in the order they are tried, [holder, root] each - a container, or "ground" <ARRAY>
 * 2: Options (default: empty) <HASHMAP>
 *    "start"  - [holder, compartment]: that compartment of that target is tried first
 *    "lifted" - items treated as gone from where they lie, as they are dragged away (default: none)
 *    "order"  - "size" (largest first, default) or "given"
 *
 * Return Value:
 * [assigned, left] <ARRAY>
 *   assigned - [[item, holder, root, cell], ...] in the order they were planned; cell is [col, row,
 *              compartment], with [.., width, height] when it lies turned, [] for the ground <ARRAY>
 *   left     - the items no target had room for <ARRAY>
 *
 * Example:
 * [_items, [[backpackContainer player, player]]] call einv_storage_fnc_plan;
 *
 * Public: No
 */

params [["_items", [], [[]]], ["_targets", [], [[]]], ["_options", createHashMap, [createHashMap]]];

private _order = _options getOrDefault ["order", "size"];
private _start = _options getOrDefault ["start", []];
private _lifted = _options getOrDefault ["lifted", []];

if (_items isEqualTo [] || {_targets isEqualTo []}) exitWith {[[], +_items]};

// Whether an entry of a layout is one of the lifted items: the same tile where it lies now.
private _fnc_isLifted = {
    params ["_entry", "_holder"];

    _lifted findIf {
        (_x getOrDefault ["holder", objNull]) isEqualTo _holder
        && {(_x getOrDefault ["key", ""]) isEqualTo (_entry getOrDefault ["key", ""])}
        && {(_x getOrDefault ["block", 0]) == (_entry getOrDefault ["block", 0])}
        && {(_x getOrDefault ["col", -1]) == (_entry getOrDefault ["col", -1])}
        && {(_x getOrDefault ["row", -1]) == (_entry getOrDefault ["row", -1])}
    } >= 0
};

// ---------------------------------------------------------------------------
// A target as the planning sees it, made when the first item asks for it:
//   ["ground"]  or  ["none"] for a holder that is neither the ground nor a container
//   ["grid", holder, root, blocks, open, taken, isBackpack]
// taken is per compartment a list of rows of booleans, true where something lies or a shaped compartment
// has a hole; rows past the end are free.
// ---------------------------------------------------------------------------
private _states = _targets apply {[]};

private _fnc_mark = {
    params ["_state", "_block", "_col", "_row", "_w", "_h"];

    private _grid = (_state select 5) select _block;
    private _cols = ((_state select 3) select _block) select 0;

    while {count _grid < _row + _h} do {
        private _line = [];

        for "_i" from 1 to _cols do {
            _line pushBack false;
        };

        _grid pushBack _line;
    };

    for "_r" from _row to (_row + _h - 1) do {
        private _cells = _grid select _r;

        for "_c" from _col to (_col + _w - 1) do {
            _cells set [_c, true];
        };
    };
};

private _fnc_isFree = {
    params ["_state", "_block", "_col", "_row", "_w", "_h"];

    ((_state select 3) select _block) params ["_cols", "_rows"];

    if (_col < 0 || {_row < 0} || {_col + _w > _cols} || {!(_state select 4) && {_row + _h > _rows}}) exitWith {false};

    private _grid = (_state select 5) select _block;
    private _free = true;

    for "_r" from _row to ((_row + _h - 1) min (count _grid - 1)) do {
        if (((_grid select _r) select [_col, _w]) findIf {_x} >= 0) exitWith {
            _free = false;
        };
    };

    _free
};

private _fnc_state = {
    params ["_index"];

    private _known = _states select _index;

    if (_known isNotEqualTo []) exitWith {_known};

    (_targets select _index) params [["_holder", objNull], ["_root", objNull]];

    private _state = ["none"];

    if (_holder isEqualType "" && {_holder isEqualTo "ground"}) then {
        _state = ["ground"];
    };

    if (_holder isEqualType objNull && {!isNull _holder}) then {
        private _contents = [_holder] call FUNC(getContents);
        private _layout = [_holder, _contents] call FUNC(getLayout);
        private _blocks = _layout get "blocks";
        private _open = ([_holder] call FUNC(getBlocks)) isEqualTo [];

        // A shaped compartment's holes are taken from the start (fnc_seedTaken).
        _state = ["grid", _holder, _root, _blocks, _open, [_blocks] call FUNC(seedTaken), getNumber (configOf _holder >> "isBackpack") == 1];

        // What lies there, less what is lifted away: its cells are taken.
        {
            if ([_x, _holder] call _fnc_isLifted) then {continue};

            if (!(_x getOrDefault ["overflow", false]) && {(_x getOrDefault ["block", -1]) >= 0}) then {
                [_state, _x get "block", _x get "col", _x get "row", _x get "w", _x get "h"] call _fnc_mark;
            };
        } forEach (_layout get "entries");
    };

    _states set [_index, _state];

    _state
};

// The first free spot for a size, the given compartment first: [compartment, col, row], [] for none.
private _fnc_find = {
    params ["_state", "_w", "_h", "_first"];

    private _spot = [];
    private _blocks = _state select 3;
    private _blockOrder = [];

    if (_first >= 0 && {_first < count _blocks}) then {
        _blockOrder pushBack _first;
    };

    for "_i" from 0 to (count _blocks - 1) do {
        if (_i != _first) then {
            _blockOrder pushBack _i;
        };
    };

    {
        private _block = _x;

        (_blocks select _block) params ["_cols", "_rows"];

        // The open grid has no end: looking one row past the last one taken always finds room.
        private _lastRow = if (_state select 4) then {count ((_state select 5) select _block)} else {_rows - _h};

        for "_row" from 0 to _lastRow do {
            for "_col" from 0 to (_cols - _w) do {
                if ([_state, _block, _col, _row, _w, _h] call _fnc_isFree) exitWith {
                    _spot = [_block, _col, _row];
                };
            };

            if (_spot isNotEqualTo []) exitWith {};
        };

        if (_spot isNotEqualTo []) exitWith {};
    } forEach _blockOrder;

    _spot
};

// ---------------------------------------------------------------------------
// The items, largest first (then category, class, and the order they came in - so the same items always
// plan the same way).
// ---------------------------------------------------------------------------
private _sequence = [];

{
    private _info = [_x getOrDefault ["class", ""]] call EFUNC(items,getInfo);

    (_info getOrDefault ["size", [1, 1]]) params ["_w", "_h"];

    _sequence pushBack ([
        [_forEachIndex, 0, "", _forEachIndex],
        [-(_w * _h), _info getOrDefault ["category", 0], toLowerANSI (_x getOrDefault ["class", ""]), _forEachIndex]
    ] select (_order isEqualTo "size"));
} forEach _items;

_sequence sort true;

private _assigned = [];
private _left = [];

{
    private _item = _items select (_x select 3);
    private _class = _item getOrDefault ["class", ""];
    private _info = [_class] call EFUNC(items,getInfo);

    (_info getOrDefault ["size", [1, 1]]) params ["_w", "_h"];

    private _isBackpack = (_info getOrDefault ["kind", ""]) isEqualTo "backpack";
    private _inside = _item getOrDefault ["container", objNull];
    private _done = false;

    {
        private _state = [_forEachIndex] call _fnc_state;
        private _kind = _state select 0;

        if (_kind isEqualTo "none") then {continue};

        // The ground always has room and needs no cell.
        if (_kind isEqualTo "ground") exitWith {
            _assigned pushBack [_item, "ground", (_targets select _forEachIndex) param [1, objNull], []];
            _done = true;
        };

        _state params ["", "_holder", "_root", "", "", "", "_holderIsBackpack"];

        // Not into itself, nor into anything lying in it.
        if (!isNull _inside && {_holder isEqualTo _inside || {[_holder, _inside] call FUNC(liesIn)}}) then {continue};

        // A backpack never goes into a backpack.
        if (_isBackpack && {_holderIsBackpack}) then {continue};

        private _firstBlock = if (_start isNotEqualTo [] && {(_start select 0) isEqualTo _holder}) then {_start param [1, -1]} else {-1};
        private _turned = false;
        private _spot = [_state, _w, _h, _firstBlock] call _fnc_find;

        // Fits nowhere upright: turned a quarter, as a player would.
        if (_spot isEqualTo [] && {_w != _h}) then {
            _spot = [_state, _h, _w, _firstBlock] call _fnc_find;
            _turned = _spot isNotEqualTo [];
        };

        if (_spot isEqualTo []) then {continue};

        _spot params ["_block", "_col", "_row"];

        private _cellW = [_w, _h] select _turned;
        private _cellH = [_h, _w] select _turned;

        [_state, _block, _col, _row, _cellW, _cellH] call _fnc_mark;

        _assigned pushBack [_item, _holder, _root, [[_col, _row, _block], [_col, _row, _block, _cellW, _cellH]] select _turned];
        _done = true;
    } forEach _targets;

    if (!_done) then {
        _left pushBack _item;
    };
} forEach _sequence;

[_assigned, _left]
