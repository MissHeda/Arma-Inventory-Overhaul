#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Turns a paged compartment's grid to other rows: the rows [from, to) show, row "from" at the grid's corner. Where each
 * row starts and which row a stretch of one cell from the corner holds are worked out anew (fnc_createGrid "rowY",
 * "rowAt"), so everything drawn on the grid and the mouse (fnc_spanRect, fnc_screenToCell) follow. The controls are the
 * caller's: none of them is moved here.
 *
 * Arguments:
 * 0: Grid <HASHMAP>
 * 1: First row that shows <NUMBER>
 * 2: The row after the last that shows <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_grid, 10, 20] call einv_gui_fnc_setWindow;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]], ["_from", 0, [0]], ["_to", 0, [0]]];

private _rows = _grid get "rows";
private _cellH = _grid get "cellH";

_from = (_from max 0) min _rows;
_to = (_to min _rows) max _from;

private _rowY = [];

for "_row" from 0 to (_rows - 1) do {
    _rowY pushBack ((_row - _from) * _cellH);
};

private _rowAt = [];

for "_stretch" from 0 to (_rows - _from - 1) do {
    _rowAt pushBack (_from + _stretch);
};

_grid set ["rowFrom", _from];
_grid set ["rowTo", _to];
_grid set ["rowY", _rowY];
_grid set ["rowAt", _rowAt];

// The corners of the panel behind the rows that show (fnc_gridCorner): a hole in them makes it square.
[_grid] call FUNC(gridCorner);
