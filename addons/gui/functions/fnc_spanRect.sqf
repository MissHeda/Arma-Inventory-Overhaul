#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rectangle a span of a grid's cells covers - a tile, a footprint, a selection's frame: from the
 * first cell's corner to the last one's far edge, ending a pixel before the next cell as a cell does. On a
 * canvas's compartment it is drawn in on every side where one of its cells borders another compartment's
 * (fnc_spanInsets), as the cells are, so it stays clear of the gap between the two.
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

private _cellW = _grid get "cellW";
private _cellH = _grid get "cellH";

([_grid, _col, _row, _w, _h] call FUNC(spanInsets)) params ["_left", "_top", "_right", "_bottom"];

[
    _cornerX + _col * _cellW + _left,
    _cornerY + _row * _cellH + _top,
    _w * _cellW - pixelW - _left - _right,
    _h * _cellH - pixelH - _top - _bottom
]
