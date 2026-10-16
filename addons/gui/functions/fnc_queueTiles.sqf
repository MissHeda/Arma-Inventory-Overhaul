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
 * Arguments:
 * 0: The queue entry <HASHMAP>
 *
 * Return Value:
 * [[grid, tile], ...] - the grids' own HashMaps, not copies <ARRAY>
 *
 * Example:
 * [GVAR(handQueue) select 0] call einv_gui_fnc_queueTiles;
 *
 * Public: No
 */

params [["_entry", createHashMap, [createHashMap]]];

private _found = [];

{
    _x params ["_holder", "_key", ["_block", 0], ["_col", -1], ["_row", -1]];

    {
        private _grid = _x;

        if (_grid getOrDefault ["virtual", true] || {_grid getOrDefault ["overflow", false]}) then {continue};

        private _gridHolder = if ((_grid getOrDefault ["kit", ""]) isEqualTo "") then {
            _grid getOrDefault ["holder", _grid getOrDefault ["container", objNull]]
        } else {
            _grid getOrDefault ["holder", _grid getOrDefault ["layoutKey", ""]]
        };

        if (_gridHolder isNotEqualTo _holder || {(_grid getOrDefault ["block", 0]) != _block}) then {continue};

        private _tiles = _grid getOrDefault ["tiles", []];

        private _index = _tiles findIf {
            (_x getOrDefault ["col", -2]) == _col && {(_x getOrDefault ["row", -2]) == _row} && {
                private _tileKey = _x getOrDefault ["key", ""];

                if (_tileKey isEqualTo "") then {
                    _tileKey = [_x] call EFUNC(storage,entryKey);
                };

                _tileKey isEqualTo _key
            }
        };

        if (_index >= 0) exitWith {
            _found pushBack [_grid, _tiles select _index];
        };
    } forEach (uiNamespace getVariable [QGVAR(grids), []]);
} forEach (_entry getOrDefault ["sources", []]);

// The worn item a take off or swap lifts, when it shows as a tile: a body's worn gear stands for its slots on a grid
// of its own (a "virtual" one, each tile carrying its slot's id).
(_entry getOrDefault ["slot", []]) params [["_unit", objNull], ["_slotId", ""]];

if (_slotId isNotEqualTo "") then {
    {
        private _grid = _x;

        if (_grid getOrDefault ["virtual", false] && {(_grid getOrDefault ["unit", objNull]) isEqualTo _unit}) then {
            private _tiles = _grid getOrDefault ["tiles", []];
            private _index = _tiles findIf {(_x getOrDefault ["slot", ""]) isEqualTo _slotId};

            if (_index >= 0) then {
                _found pushBack [_grid, _tiles select _index];
            };
        };
    } forEach (uiNamespace getVariable [QGVAR(grids), []]);
};

_found
