#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a shape the way fnc_parseMask reads it - the way back, so a shape read and written again stays
 * the same. One with holes is drawn, rows separated by "/" ("x" a cell, "-" a hole); one without is
 * written WxH, the shorter of the two. A compartment of grid= (fnc_formatGrid) and an item's size=
 * (fnc_writeRules, fnc_getInfo's "shape") are written here alike.
 *
 * Arguments:
 * 0: Columns <NUMBER>
 * 1: Rows <NUMBER>
 * 2: Holes, the indices row * cols + col of the cells it does not have <ARRAY> (default: [])
 *
 * Return Value:
 * "2x3" or "xx/x-" <STRING>
 *
 * Example:
 * [2, 2, [3]] call einv_items_fnc_formatMask; // "xx/x-"
 *
 * Public: No
 */

params [["_cols", 1, [0]], ["_rows", 1, [0]], ["_holes", [], [[]]]];

if (_holes isEqualTo []) exitWith {format ["%1x%2", _cols, _rows]};

private _lines = [];

for "_r" from 0 to (_rows - 1) do {
    private _line = "";

    for "_c" from 0 to (_cols - 1) do {
        _line = _line + (["x", "-"] select ((_r * _cols + _c) in _holes));
    };

    _lines pushBack _line;
};

_lines joinString "/"
