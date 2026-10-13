#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where the columns and rows of a span of a grid's cells lie from its first cell, for a shaped tile or
 * footprint drawn on a canvas's compartment with seams (fnc_canvasSeams): fnc_shapeRects puts each cell
 * of the shape on its own cell of the grid, the gap of a seam between them. [] on any other grid, where
 * a cell's pitch says it.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Column <NUMBER>
 * 2: Row <NUMBER>
 * 3: Width in cells <NUMBER>
 * 4: Height in cells <NUMBER>
 *
 * Return Value:
 * [colX, rowY], or [] for the plain pitch <ARRAY>
 *
 * Example:
 * [_grid, _col, _row, 2, 2] call einv_gui_fnc_spanSeams;
 *
 * Public: No
 */

params ["_grid", "_col", "_row", "_w", "_h"];

if ((_grid getOrDefault ["colX", []]) isEqualTo [] && {(_grid getOrDefault ["rowY", []]) isEqualTo []}) exitWith {[]};

([_grid, _col, _row] call FUNC(cellOffset)) params ["_left", "_top"];

private _colX = [];
private _rowY = [];

for "_i" from 0 to (_w - 1) do {
    _colX pushBack ((([_grid, _col + _i, _row] call FUNC(cellOffset)) select 0) - _left);
};

for "_i" from 0 to (_h - 1) do {
    _rowY pushBack ((([_grid, _col, _row + _i] call FUNC(cellOffset)) select 1) - _top);
};

[_colX, _rowY]
