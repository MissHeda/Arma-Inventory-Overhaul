#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "placeMany": lifts several tiles of one holder and puts all of them down at once; refused as a
 * whole ("Taken") when any cell is not free once all of them are lifted, or when two of them would lie
 * on one cell. Each tile is the very one at its place (fnc_findEntry, exact), else "Gone"; a cell has
 * the tile's size, either way round, else "Failed". The final arrangement is checked as a whole; only
 * places change, never the cargo.
 *
 * A cell is [col, row, block, w, h] - w and h as it will lie, the tile's own when left out.
 *
 * Arguments:
 * 0: Args, [holder, [[entry array, cell], ...]] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Taken", "NoRoom", "NotLocal", "Moved",
 *     "IntoItself", "OutOfReach", "Bounced", "Skipped", "Failed", a guard's reason or a reason already
 *     in words)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (einv_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[cursorObject, _moves], _context] call einv_storage_fnc_opPlaceMany;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_holder", objNull, [objNull, ""]], ["_moves", [], [[]]]];

if (_moves isEqualTo []) exitWith {["", [], []]};

private _view = [_holder, []] call FUNC(findEntry);

if (count _view == 0) exitWith {["Moved", [], []]};

// Every tile where the requester saw it, each cell in its size.
private _placing = [];
private _status = "";

{
    _x params [["_entryArray", [], [[]]], ["_cell", [], [[]]]];

    private _entry = [_holder, _entryArray, true] call FUNC(findEntry);

    if (count _entry == 0 || {_entry getOrDefault ["lifted", false]}) exitWith {
        _status = "Gone";
    };

    (([_entry getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]]) params [["_w", 1, [0]], ["_h", 1, [0]]];
    _cell params [
        ["_col", -1, [0]],
        ["_row", -1, [0]],
        ["_block", 0, [0]],
        ["_cellW", _entry getOrDefault ["w", _w], [0]],
        ["_cellH", _entry getOrDefault ["h", _h], [0]]
    ];

    if !([_cellW, _cellH] isEqualTo [_w, _h] || {[_cellW, _cellH] isEqualTo [_h, _w]}) exitWith {
        _status = "Failed";
    };

    _entry set ["lifted", true];
    _placing pushBack [_entry, [_col, _row, _block, _cellW, _cellH]];
} forEach _moves;

if (_status isNotEqualTo "") exitWith {
    {
        (_x select 0) deleteAt "lifted";
    } forEach _placing;

    [_status, [], []]
};

// The cells of everything else, per compartment rows of booleans - the lifted ones stand in nobody's
// way, a shaped compartment's holes in everybody's (fnc_seedTaken).
private _blocks = _view getOrDefault ["blocks", []];
private _open = _view getOrDefault ["open", false];
private _taken = [_blocks] call FUNC(seedTaken);

private _fnc_mark = {
    params ["_block", "_col", "_row", "_w", "_h"];

    if (_block < 0 || {_block >= count _blocks}) exitWith {};

    private _cols = (_blocks select _block) select 0;
    private _grid = _taken select _block;

    while {count _grid < _row + _h} do {
        private _line = [];

        for "_i" from 1 to _cols do {
            _line pushBack false;
        };

        _grid pushBack _line;
    };

    for "_r" from (_row max 0) to (_row + _h - 1) do {
        private _line = _grid select _r;

        for "_c" from (_col max 0) to ((_col + _w - 1) min (_cols - 1)) do {
            _line set [_c, true];
        };
    };
};

private _fnc_free = {
    params ["_block", "_col", "_row", "_w", "_h"];

    if (_block < 0 || {_block >= count _blocks}) exitWith {false};

    (_blocks select _block) params ["_cols", "_rows"];

    if (_col < 0 || {_row < 0} || {_col + _w > _cols} || {!_open && {_row + _h > _rows}}) exitWith {false};

    private _grid = _taken select _block;
    private _free = true;

    for "_r" from _row to ((_row + _h - 1) min (count _grid - 1)) do {
        if (((_grid select _r) select [_col, _w]) findIf {_x} >= 0) exitWith {
            _free = false;
        };
    };

    _free
};

{
    if (
        (_x getOrDefault ["count", 1]) > 0
        && {!(_x getOrDefault ["overflow", false])}
        && {!(_x getOrDefault ["lifted", false])}
    ) then {
        [_x getOrDefault ["block", -1], _x getOrDefault ["col", 0], _x getOrDefault ["row", 0], _x getOrDefault ["w", 1], _x getOrDefault ["h", 1]] call _fnc_mark;
    };
} forEach (_view getOrDefault ["entries", []]);

// Put down one after the other: each takes its cells, so two never share one.
{
    (_x select 1) params ["_col", "_row", "_block", "_w", "_h"];

    if !([_block, _col, _row, _w, _h] call _fnc_free) exitWith {
        _status = "Taken";
    };

    [_block, _col, _row, _w, _h] call _fnc_mark;
} forEach _placing;

{
    (_x select 0) deleteAt "lifted";
} forEach _placing;

if (_status isNotEqualTo "") exitWith {[_status, [], []]};

// Its record moves - an entry that had none (it lay in the overflow row, or was not laid down yet) gets
// one. The view follows.
private _records = ([_holder] call FUNC(readPlaces)) param [1, []];

{
    _x params ["_entry", "_cell"];
    _cell params ["_col", "_row", "_block", "_w", "_h"];

    private _key = _entry getOrDefault ["key", ""];
    private _had = !(_entry getOrDefault ["overflow", false]) && {
        _records findIf {
            (_x param [0, ""]) isEqualTo _key
            && {(_x param [1, -1]) == (_entry getOrDefault ["col", -2])}
            && {(_x param [2, -1]) == (_entry getOrDefault ["row", -2])}
            && {(_x param [5, -1]) == (_entry getOrDefault ["block", -2])}
        } >= 0
    };

    [_holder, _entry, _cell, !_had] call FUNC(setPlace);

    _entry set ["block", _block];
    _entry set ["col", _col];
    _entry set ["row", _row];
    _entry set ["w", _w];
    _entry set ["h", _h];
    _entry set ["rotated", _w != _h && {_w == ((([_entry getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]]) select 1)}];
    _entry set ["overflow", false];
} forEach _placing;

["", [], []]
