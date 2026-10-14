#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How far a span of a grid's cells - a tile, a footprint, a selection's frame - is drawn in on each side,
 * on a canvas's compartment whose cells border another compartment's (fnc_canvasInsets): a side is drawn
 * in as far as the furthest of its cells along it, so a tile keeps one straight edge and stays clear of
 * the gap wherever one of its cells meets the other compartment. Nothing on any other grid.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Column <NUMBER>
 * 2: Row <NUMBER>
 * 3: Width in cells <NUMBER> (default: 1)
 * 4: Height in cells <NUMBER> (default: 1)
 *
 * Return Value:
 * [left, top, right, bottom], screen width or height <ARRAY>
 *
 * Example:
 * [_grid, _col, _row, 2, 2] call einv_gui_fnc_spanInsets;
 *
 * Public: No
 */

params ["_grid", "_col", "_row", ["_w", 1], ["_h", 1]];

private _insets = _grid getOrDefault ["insets", []];

if (_insets isEqualTo []) exitWith {[0, 0, 0, 0]};

private _cols = _grid get "cols";
private _rows = _grid get "rows";
private _lastCol = ((_col + _w) min _cols) - 1;
private _lastRow = ((_row + _h) min _rows) - 1;
private _left = 0;
private _top = 0;
private _right = 0;
private _bottom = 0;

for "_r" from (_row max 0) to _lastRow do {
    _left = _left max (((_insets param [_r * _cols + _col, []]) param [0, 0]));
    _right = _right max (((_insets param [_r * _cols + _lastCol, []]) param [2, 0]));
};

for "_c" from (_col max 0) to _lastCol do {
    _top = _top max (((_insets param [_row * _cols + _c, []]) param [1, 0]));
    _bottom = _bottom max (((_insets param [_lastRow * _cols + _c, []]) param [3, 0]));
};

[_left, _top, _right, _bottom]
