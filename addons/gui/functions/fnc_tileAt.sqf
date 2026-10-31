#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which tile of a grid covers a cell. A shaped item (size=xx/x-) covers only its own cells: over one of
 * its holes ("holes" as it lies, einv_storage_fnc_getLayout) it is not found - the tile that lies there
 * is, or none.
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

    private _w = _x get "w";

    _col >= _left && {_col < _left + _w} && {_row >= _top} && {_row < _top + (_x get "h")}
    && {!(((_row - _top) * _w + _col - _left) in (_x getOrDefault ["holes", []]))}
}
