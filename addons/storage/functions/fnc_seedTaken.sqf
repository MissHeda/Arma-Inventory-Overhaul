#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The cells of each compartment that are taken before anything lies there: the holes of a shaped one
 * (einv_items_fnc_parseGrid, "xxx/x-x"). Every layout that looks for free cells - fnc_getLayout,
 * fnc_plan, fnc_opPut, fnc_opPlaceMany - starts from this, so a hole is never free and nothing has
 * to ask for holes again: an item can neither lie on one nor reach over one.
 *
 * The same form they all keep: per compartment one array of booleans per row, true where the cell is
 * taken. Rows are only there up to the last one with a hole; every row past the end is free.
 *
 * Arguments:
 * 0: Compartments [[cols, rows, holes], ...] (fnc_blocksFor); holes may be left out for none <ARRAY>
 *
 * Return Value:
 * Per compartment, rows of booleans <ARRAY>
 *
 * Example:
 * [[[3, 2, [4]]]] call einv_storage_fnc_seedTaken;
 *
 * Public: No
 */

params [["_blocks", [], [[]]]];

_blocks apply {
    _x params ["_cols", "", ["_holes", []]];

    private _grid = [];

    {
        private _row = floor (_x / _cols);

        while {count _grid <= _row} do {
            private _line = [];

            for "_i" from 1 to _cols do {
                _line pushBack false;
            };

            _grid pushBack _line;
        };

        (_grid select _row) set [_x mod _cols, true];
    } forEach _holes;

    _grid
}
