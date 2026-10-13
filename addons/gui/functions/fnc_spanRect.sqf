#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rectangle a span of a grid's cells covers - a tile, a footprint, a selection's frame: from the
 * first cell's corner to the last one's far edge, ending a pixel before the next cell as a cell does. On a
 * canvas's compartment with a seam inside the span (fnc_canvasSeams) it reaches over the gap, so a tile
 * lying across one reads as one piece (fnc_cellOffset says where each cell lies).
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: The grid's top left corner [x, y] - "rel", or on the screen (fnc_gridOrigin) <ARRAY>
 * 2: Column <NUMBER>
 * 3: Row <NUMBER>
 * 4: Width in cells <NUMBER> (default: 1)
 * 5: Height in cells <NUMBER> (default: 1)
 *
 * Return Value:
 * [x, y, w, h] <ARRAY>
 *
 * Example:
 * [_grid, [_gridX, _gridY], _col, _row, 2, 1] call einv_gui_fnc_spanRect;
 *
 * Public: No
 */

params ["_grid", "_corner", "_col", "_row", ["_w", 1], ["_h", 1]];
_corner params ["_cornerX", "_cornerY"];

([_grid, _col, _row] call FUNC(cellOffset)) params ["_left", "_top"];
([_grid, _col + _w - 1, _row + _h - 1] call FUNC(cellOffset)) params ["_lastX", "_lastY"];

[
    _cornerX + _left,
    _cornerY + _top,
    _lastX - _left + (_grid get "cellW") - pixelW,
    _lastY - _top + (_grid get "cellH") - pixelH
]
