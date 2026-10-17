#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The tiles the window shows now for an action waiting in the hands' queue (fnc_queueMoves): each source of
 * the entry is found as fnc_drawPending finds the tiles of a move in flight - by the grid's holder (a kit's
 * grid by its layout key), its compartment, and the tile's cell and key. One that moved meanwhile, or lies
 * in a section the window does not show, is simply not among them. The worn item of a take off is found as the
 * tile that stands for its slot, where the window shows a body's gear as tiles.
 *
 * A tile is looked up by its cell: the first time a grid is asked about, its tiles are indexed by cell, so a
 * queue of N entries costs N lookups, not N scans of every tile. Pass one cache for all the entries of one
 * pass (a HashMap, filled here) to share the index; the window must not change between the calls that share it.
 *
 * Arguments:
 * 0: The queue entry <HASHMAP>
 * 1: Cache shared by several calls, empty at first (default: a new one) <HASHMAP>
 *
 * Return Value:
 * [[grid, tile], ...] - the grids' own HashMaps, not copies <ARRAY>
 *
 * Example:
 * [GVAR(handQueue) select 0] call einv_gui_fnc_queueTiles;
 *
 * Public: No
 */

params [["_entry", createHashMap, [createHashMap]], ["_cache", createHashMap, [createHashMap]]];

private _found = [];

// The grids items can lie on - not a body's worn gear, not the overflow - each as [grid, holder, block, cells,
// whether the cells are indexed], and the grids that stand for a body's gear.
if !("meta" in _cache) then {
    private _all = uiNamespace getVariable [QGVAR(grids), []];

    _cache set ["meta", (_all select {
        !(_x getOrDefault ["virtual", true]) && {!(_x getOrDefault ["overflow", false])}
    }) apply {
        [
            _x,
            if ((_x getOrDefault ["kit", ""]) isEqualTo "") then {
                _x getOrDefault ["holder", _x getOrDefault ["container", objNull]]
            } else {
                _x getOrDefault ["holder", _x getOrDefault ["layoutKey", ""]]
            },
            _x getOrDefault ["block", 0], createHashMap, false
        ]
    }];

    _cache set ["virtual", _all select {_x getOrDefault ["virtual", false]}];
};

{
    _x params ["_holder", "_key", ["_block", 0], ["_col", -1], ["_row", -1]];

    private _cellKey = format ["%1_%2", _col, _row];

    {
        _x params ["_grid", "_gridHolder", "_gridBlock", "_cells", "_indexed"];

        if (_gridHolder isNotEqualTo _holder || {_gridBlock != _block}) then {continue};

        private _tiles = _grid getOrDefault ["tiles", []];

        if (!_indexed) then {
            {
                private _at = format ["%1_%2", _x getOrDefault ["col", -2], _x getOrDefault ["row", -2]];
                private _list = _cells getOrDefault [_at, []];

                if (_list isEqualTo []) then {
                    _cells set [_at, _list];
                };

                _list pushBack _forEachIndex;
            } forEach _tiles;

            _x set [4, true];
        };

        private _index = (_cells getOrDefault [_cellKey, []]) findIf {
            private _tile = _tiles select _x;
            private _tileKey = _tile getOrDefault ["key", ""];

            if (_tileKey isEqualTo "") then {
                _tileKey = [_tile] call EFUNC(storage,entryKey);
            };

            _tileKey isEqualTo _key
        };

        if (_index >= 0) exitWith {
            _found pushBack [_grid, _tiles select ((_cells get _cellKey) select _index)];
        };
    } forEach (_cache get "meta");
} forEach (_entry getOrDefault ["sources", []]);

// The worn item a take off or swap lifts, when it shows as a tile: a body's worn gear stands for its slots on a grid
// of its own (a "virtual" one, each tile carrying its slot's id).
(_entry getOrDefault ["slot", []]) params [["_unit", objNull], ["_slotId", ""]];

if (_slotId isNotEqualTo "") then {
    {
        private _grid = _x;

        if ((_grid getOrDefault ["unit", objNull]) isEqualTo _unit) then {
            private _tiles = _grid getOrDefault ["tiles", []];
            private _index = _tiles findIf {(_x getOrDefault ["slot", ""]) isEqualTo _slotId};

            if (_index >= 0) then {
                _found pushBack [_grid, _tiles select _index];
            };
        };
    } forEach (_cache get "virtual");
};

_found
