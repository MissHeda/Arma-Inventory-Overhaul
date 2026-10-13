#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where each entry lies in a holder: in which of its compartments (fnc_getBlocks) and on which cell,
 * upright or turned a quarter. Every entry gets "block", "col", "row", "w", "h" (as it lies), "holes"
 * (the cells of its box a shaped item does not take, as it lies, einv_items_fnc_footprintAs),
 * "rotated" and "overflow" set on it, and "key" where it had none (fnc_entryKey) - the entry HashMaps
 * change in place. A shaped item takes only its own cells: something else may lie in the corner an L
 * leaves open (fnc_cellsFree, fnc_takeCells).
 *
 * A pure function of the holder's places (fnc_readPlaces), its entries and the rules: every machine
 * draws the same picture from the same data, and nothing is written here - the authority persists the
 * picture when the records drifted from the cargo (fnc_normalize). Nothing in it depends on the order
 * the engine lists cargo in for items that look different, on the machine or on time.
 *
 *   1. exact - the n-th record of a key goes to the n-th entry of that key (fnc_getContents gives
 *      entries of one key in a fixed order: a split stack full tiles first), when its size matches
 *      the way round it says, its compartment exists and its cells are free. Records are taken in their
 *      order, so of two that claim the same cells the first wins everywhere.
 *   2. kin - every record still unused, in order, goes to the first unplaced entry of the same kind
 *      (fnc_layoutKey; entries sorted by key and index) whose size matches it either way round, when its
 *      cells are free: a repacked magazine, a radio that got its instance class, a kit made ready stay
 *      where they lay.
 *   3. first fit - the rest, largest first (then category, kind, key, index): compartment after
 *      compartment, row by row, upright, else turned a quarter (a square box only when it is a shape
 *      that turned takes other cells).
 * A record is [key, col, row, w, h, block, rot], rot 1 when it lies turned a quarter clockwise. One
 * written before rot existed has six elements: it lies turned when its width is not the upright one.
 * An entry no compartment has room for - the engine took it from a script or another mod - is
 * "overflow": shown apart, never lost. The ground and a grid with no object of its own (a kit of
 * Enhanced First Aid Kits, einv_compat_efak) have no compartments: one STORAGE_COLS wide that grows with
 * what lies there, always a row more than it needs.
 *
 * Arguments:
 * 0: Holder - a container, or the key of a grid with no object ("kit:" + lowercase class) <OBJECT or
 *    STRING>
 * 1: Entries (fnc_getContents) <ARRAY>
 * 2: Unused - kept for its callers, which pass whether to keep the layout; nothing is ever kept here
 *    <ANY> (default: nil)
 * 3: Places to lay out from instead of the holder's own: [revision, records] or just the records
 *    <ARRAY> (default: fnc_readPlaces)
 *
 * Return Value:
 * HashMap <HASHMAP>
 *   "entries"  - all of them, placed
 *   "blocks"   - the compartments [[cols, rows, holes], ...] (fnc_blocksFor) - the open grid's with the
 *                rows it needs now
 *   "overflow" - the entries with no room
 *   "records"  - one per placed entry, canonical (fnc_readPlaces): [key, col, row, w, h, block, rot]. A
 *                holder of another type that lists nothing keeps the records it was laid out from: a
 *                kit whose contents have not arrived yet would otherwise lose its arrangement
 *   "drift"    - the records laid out from are not exactly "records" - the authority should persist
 *                these (fnc_normalize)
 *   "revision" - the revision of the places laid out from, -1 for records given without one
 *
 * Example:
 * private _container = backpackContainer player;
 * [_container, [_container] call einv_storage_fnc_getContents] call einv_storage_fnc_getLayout;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_entries", [], [[]]], "", "_given"];

// A key has no compartments and no object; isNull would fail on it.
private _isKey = _holder isEqualType "";
private _valid = if (_isKey) then {_holder isNotEqualTo ""} else {!isNull _holder};

private _places = [0, []];

if (isNil "_given") then {
    if (_valid) then {_places = [_holder] call FUNC(readPlaces)};
} else {
    if !(_given isEqualType []) then {_given = []};

    _places = if (_given isEqualTypeArray [0, []]) then {_given} else {[-1, _given]};
};

_places params ["_revision", "_in"];

private _blocks = if (_isKey) then {[]} else {[_holder] call FUNC(getBlocks)};
private _open = _blocks isEqualTo [];

if (_open) then {
    _blocks = [[STORAGE_COLS, 1e6, []]];
};

// Per compartment, one array of booleans per row, true where something lies - or where a shaped
// compartment has a hole, so nothing is ever placed on one (fnc_seedTaken). Rows are only added once
// something lies in them, so every row past the end is free.
private _taken = [_blocks] call FUNC(seedTaken);

private _fnc_isFree = {
    params ["_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    if (_block < 0 || {_block >= count _blocks}) exitWith {false};

    (_blocks select _block) params ["_cols", "_rows"];

    if (_col < 0 || {_row < 0} || {_col + _w > _cols} || {_row + _h > _rows}) exitWith {false};

    [_taken select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)
};

private _fnc_take = {
    params ["_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    [_taken select _block, (_blocks select _block) select 0, _col, _row, _w, _h, _holes] call FUNC(takeCells);
};

// The holes of an entry as it lies: its own upright, its turned ones turned (rot 1).
private _fnc_holes = {
    params ["_index", "_rot"];

    ([_infos select _index, _rot] call EFUNC(items,footprintAs)) select 2
};

// The way round a record says for an entry: its rot, or for a record from before rot its size - turned
// when it is not as wide as the entry upright.
private _fnc_rot = {
    params ["_rot", "_entry", "_w"];

    if (_rot isEqualTo 0 || {_rot isEqualTo 1}) exitWith {_rot};

    parseNumber (_w != (_entry get "w"))
};

// A record's size fits an entry the way round it says: upright as the rules size it, or turned a
// quarter.
private _fnc_sizeFits = {
    params ["_entry", "_w", "_h", "_rot"];

    private _upW = _entry get "w";
    private _upH = _entry get "h";

    ([[_upW, _upH], [_upH, _upW]] select (_rot == 1)) isEqualTo [_w, _h]
};

private _fnc_put = {
    params ["_index", "_block", "_col", "_row", "_w", "_h", "_rot"];

    private _entry = _entries select _index;
    private _holes = [_index, _rot] call _fnc_holes;

    [_block, _col, _row, _w, _h, _holes] call _fnc_take;

    _entry set ["rotated", _rot == 1];
    _entry set ["holes", _holes];
    _entry set ["w", _w];
    _entry set ["h", _h];
    _entry set ["block", _block];
    _entry set ["col", _col];
    _entry set ["row", _row];
};

// ---------------------------------------------------------------------------
// The entries: upright size, key, and per key the index of each in the order they came.
// ---------------------------------------------------------------------------
private _byKey = createHashMap;     // key -> entry indices, in order
private _meta = [];                 // per entry: [key, index within its key, kind (fnc_layoutKey), category]
private _infos = [];                // per entry: what einv_items_fnc_getInfo gives for its class

{
    private _entry = _x;
    private _class = _entry getOrDefault ["class", ""];
    private _info = [_class] call EFUNC(items,getInfo);

    (_info get "size") params ["_w", "_h"];

    _infos pushBack _info;
    _entry set ["w", _w];
    _entry set ["h", _h];
    _entry set ["holes", (_info getOrDefault ["footprint", [_w, _h, []]]) param [2, []]];
    _entry set ["rotated", false];
    _entry set ["overflow", false];

    private _key = _entry getOrDefault ["key", ""];

    if (_key isEqualTo "") then {
        _key = [_entry] call FUNC(entryKey);
        _entry set ["key", _key];
    };

    private _list = _byKey get _key;

    if (isNil "_list") then {
        _list = [];
        _byKey set [_key, _list];
    };

    _list pushBack _forEachIndex;
    _meta pushBack [_key, count _list - 1, [_class] call FUNC(layoutKey), _info get "category"];
} forEach _entries;

private _placed = _entries apply {false};
private _used = _in apply {false};

// ---------------------------------------------------------------------------
// 1. Exact: the n-th record of a key to the n-th entry of that key.
// ---------------------------------------------------------------------------
private _seen = createHashMap;

{
    if (_x isEqualType [] && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}) then {
        _x params ["_key", "_col", "_row", "_w", "_h", "_block", ["_given", -1]];

        private _n = _seen getOrDefault [_key, 0];

        _seen set [_key, _n + 1];

        private _index = (_byKey getOrDefault [_key, []]) param [_n, -1];

        if (_index >= 0) then {
            private _entry = _entries select _index;
            private _rot = [_given, _entry, _w] call _fnc_rot;

            if ([_entry, _w, _h, _rot] call _fnc_sizeFits && {[_block, _col, _row, _w, _h, [_index, _rot] call _fnc_holes] call _fnc_isFree}) then {
                [_index, _block, _col, _row, _w, _h, _rot] call _fnc_put;
                _placed set [_index, true];
                _used set [_forEachIndex, true];
            };
        };
    };
} forEach _in;

// ---------------------------------------------------------------------------
// 2. Kin: records still unused to unplaced entries of the same kind. The class of a record is the part
// of its key before the first "|".
// ---------------------------------------------------------------------------
private _kinOf = createHashMap;     // kind -> [[key, index within key, entry index], ...]

{
    if !(_placed select _forEachIndex) then {
        _x params ["_key", "_n", "_kind"];

        private _list = _kinOf get _kind;

        if (isNil "_list") then {
            _list = [];
            _kinOf set [_kind, _list];
        };

        _list pushBack [_key, _n, _forEachIndex];
    };
} forEach _meta;

if (count _kinOf > 0) then {
    {
        _y sort true;
    } forEach _kinOf;

    {
        if (!(_used select _forEachIndex) && {_x isEqualType []} && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}) then {
            _x params ["_key", "_col", "_row", "_w", "_h", "_block", ["_given", -1]];

            private _candidates = _kinOf getOrDefault [[(_key splitString "|") param [0, ""]] call FUNC(layoutKey), []];

            // Kin may differ in shape within the same box: each candidate is asked with its own holes.
            if (_candidates isNotEqualTo []) then {
                private _rot = 0;
                private _at = _candidates findIf {
                    private _candidate = _x select 2;

                    _rot = [_given, _entries select _candidate, _w] call _fnc_rot;

                    !(_placed select _candidate) && {[_entries select _candidate, _w, _h, _rot] call _fnc_sizeFits}
                    && {[_block, _col, _row, _w, _h, [_candidate, _rot] call _fnc_holes] call _fnc_isFree}
                };

                if (_at >= 0) then {
                    private _index = (_candidates select _at) select 2;

                    [_index, _block, _col, _row, _w, _h, _rot] call _fnc_put;
                    _placed set [_index, true];
                    _used set [_forEachIndex, true];
                };
            };
        };
    } forEach _in;
};

// ---------------------------------------------------------------------------
// 3. First fit: largest first, then by category, kind, key and index - so the same contents always come
// out the same.
// ---------------------------------------------------------------------------
private _order = [];

{
    if !(_placed select _forEachIndex) then {
        (_meta select _forEachIndex) params ["_key", "_n", "_kind", "_category"];

        _order pushBack [-((_x get "w") * (_x get "h")), _category, _kind, _key, _n, _forEachIndex];
    };
} forEach _entries;

_order sort true;

private _overflow = [];

// The first free spot for that size and those holes, compartment after compartment, row by row.
private _fnc_find = {
    params ["_w", "_h", ["_holes", []]];

    private _spot = [];

    {
        _x params ["_cols", "_rows"];
        private _block = _forEachIndex;

        // The open grid: past its last row everything is free, so looking one row further always ends.
        private _lastRow = if (_open) then {count (_taken select _block)} else {_rows - _h};

        for "_row" from 0 to _lastRow do {
            for "_col" from 0 to (_cols - _w) do {
                if ([_block, _col, _row, _w, _h, _holes] call _fnc_isFree) exitWith {_spot = [_block, _col, _row]};
            };

            if (_spot isNotEqualTo []) exitWith {};
        };

        if (_spot isNotEqualTo []) exitWith {};
    } forEach _blocks;

    _spot
};

{
    private _index = _x select 5;
    private _entry = _entries select _index;
    private _w = _entry get "w";
    private _h = _entry get "h";
    private _holes = [_index, 0] call _fnc_holes;
    private _turnedHoles = [_index, 1] call _fnc_holes;
    private _spot = [_w, _h, _holes] call _fnc_find;

    // Fits nowhere upright: turned a quarter, as a player would - a shape turns with it, and one in a
    // square box is tried turned too when that takes other cells.
    if (_spot isEqualTo [] && {_w != _h || {_holes isNotEqualTo _turnedHoles}}) then {
        _spot = [_h, _w, _turnedHoles] call _fnc_find;

        if (_spot isNotEqualTo []) then {
            _entry set ["w", _h];
            _entry set ["h", _w];
            _entry set ["rotated", true];
            _entry set ["holes", _turnedHoles];
            _w = _entry get "w";
            _h = _entry get "h";
            _holes = _turnedHoles;
        };
    };

    if (_spot isEqualTo []) then {
        _entry set ["overflow", true];
        _overflow pushBack _entry;
    } else {
        _spot params ["_block", "_col", "_row"];

        [_block, _col, _row, _w, _h, _holes] call _fnc_take;
        _entry set ["block", _block];
        _entry set ["col", _col];
        _entry set ["row", _row];
    };
} forEach _order;

// The open grid shows the rows it uses, one more to put things in, and never fewer than three.
if (_open) then {
    _blocks = [[STORAGE_COLS, (count (_taken select 0) + 1) max 3, []]];
};

// Lined up in a row of their own under the compartments, each in its own cell span.
private _col = 0;
{
    _x set ["block", -1];
    _x set ["col", _col];
    _x set ["row", 0];
    _col = _col + (_x get "w");
} forEach _overflow;

// ---------------------------------------------------------------------------
// The records of this picture, canonical: by key, and within a key in the entries' order - the same
// order fnc_writePlaces keeps. A holder of another type that lists nothing keeps the records it was laid
// out from: a kit of Enhanced First Aid Kits lists nothing until that mod synced its contents here, and
// its arrangement must not be thrown away for a list that is only not there yet.
// ---------------------------------------------------------------------------
private _source = if (_isKey && {_entries isEqualTo []}) then {
    (_in select {_x isEqualType [] && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}}) apply {_x select [0, 7]}
} else {
    (_entries select {!(_x get "overflow")}) apply {
        [_x get "key", _x get "col", _x get "row", _x get "w", _x get "h", _x get "block", parseNumber (_x get "rotated")]
    }
};

private _groups = createHashMap;
private _keys = [];

{
    private _key = _x select 0;
    private _group = _groups get _key;

    if (isNil "_group") then {
        _group = [];
        _groups set [_key, _group];
        _keys pushBack _key;
    };

    _group pushBack _x;
} forEach _source;

_keys sort true;

private _out = [];

{
    _out append (_groups get _x);
} forEach _keys;

// Nothing to persist for no holder. A record from before rot says the same as one with the rot its size
// gives: no drift for that alone, so older places are not all written again at once.
private _drift = _valid && {
    (_in apply {
        if (_x isEqualType [] && {count _x == 6} && {_x isEqualTypeArray ["", 0, 0, 0, 0, 0]}) then {
            private _size = ([((_x select 0) splitString "|") param [0, ""]] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]];

            _x + [parseNumber ((_x select 3) != (_size select 0))]
        } else {
            _x
        };
    }) isNotEqualTo _out
};

createHashMapFromArray [
    ["entries", _entries],
    ["blocks", _blocks],
    ["overflow", _overflow],
    ["records", _out],
    ["drift", _drift],
    ["revision", _revision]
]
