#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which tile of a grid covers a cell.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Cell, [column, row] <ARRAY>
 *
 * Return Value:
 * Index into the grid's tiles, -1 for an empty cell <NUMBER>
 *
 * Example:
 * [_grid, [3, 1]] call einv_gui_fnc_tileAt;
 *
 * Public: No
 */

params ["_grid", "_cell"];
_cell params ["_col", "_row"];

(_grid get "tiles") findIf {
    private _left = _x get "col";
    private _top = _x get "row";

    _col >= _left && {_col < _left + (_x get "w")} && {_row >= _top} && {_row < _top + (_x get "h")}
}
