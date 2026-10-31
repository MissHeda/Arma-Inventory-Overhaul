#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Deletes every cell square of a grid - and the pieces that round the squares at the corners of its panel (fnc_drawCells) - and
 * leaves the cells not made, as a hole is (a paged compartment turns a page, fnc_showPage, or draws its box anew, fnc_redrawTiles).
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_grid] call einv_gui_fnc_clearCells;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]]];

private _cells = _grid getOrDefault ["cells", []];

{ctrlDelete _x} forEach _cells;

{
    {ctrlDelete _x} forEach _y;
} forEach (_grid getOrDefault ["cellParts", createHashMap]);

_grid set ["cells", _cells apply {controlNull}];
_grid set ["cellParts", createHashMap];
