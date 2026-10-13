#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the cells an item would take are free: every cell of its box but its own holes (a shaped
 * item, size=xx/x-, einv_items_fnc_footprintAs) - so an L can lie with something small in the corner
 * it leaves open. Every layout that looks for free cells asks this (fnc_getLayout, fnc_plan, fnc_opPut,
 * fnc_opPlaceMany), on rows of booleans as fnc_seedTaken starts them, so all of them agree on what
 * fits. Whether the box lies inside its compartment at all is for the caller to say.
 *
 * Arguments:
 * 0: One compartment's rows of booleans, true where taken; rows past the end are free <ARRAY>
 * 1: Column <NUMBER>
 * 2: Row <NUMBER>
 * 3: Width as it lies <NUMBER>
 * 4: Height as it lies <NUMBER>
 * 5: Its holes as it lies, indices row * width + col <ARRAY> (default: [])
 *
 * Return Value:
 * Every cell it takes is free <BOOL>
 *
 * Example:
 * [_taken select 0, 2, 1, 2, 2, [3]] call einv_storage_fnc_cellsFree;
 *
 * Public: No
 */

params ["_grid", "_col", "_row", "_w", "_h", ["_holes", []]];

private _free = true;

for "_r" from _row to ((_row + _h - 1) min (count _grid - 1)) do {
    private _line = (_grid select _r) select [_col, _w];

    if (_holes isEqualTo []) then {
        _free = _line findIf {_x} < 0;
    } else {
        private _base = (_r - _row) * _w;

        {
            if (_x && {!((_base + _forEachIndex) in _holes)}) exitWith {_free = false};
        } forEach _line;
    };

    if (!_free) exitWith {};
};

_free
