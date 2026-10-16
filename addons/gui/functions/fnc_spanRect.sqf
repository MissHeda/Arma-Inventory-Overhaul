#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rectangle a span of a grid's cells covers - a tile, a footprint, a selection's frame: from the
 * first cell's corner to the last one's far edge, ending a pixel before the next cell as a cell does: on
 * every grid it covers exactly the cells it spans. A cell lies where its column and row start
 * (fnc_createGrid "colX", "rowY"): on a canvas's compartment that reaches over a seam
 * (fnc_flowCompartments), a span over it covers the room between its cells too, as one piece. A span
 * that sticks out of the grid (a footprint at its edge) goes on at the plain pitch past either end.
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
private _colX = _grid getOrDefault ["colX", []];
private _rowY = _grid getOrDefault ["rowY", []];
private _lastCol = _col + _w - 1;
private _lastRow = _row + _h - 1;

// A span inside the grid - a tile, a selection, nearly every footprint: four looks into the grid's places.
if (_col >= 0 && {_row >= 0} && {_w >= 1} && {_h >= 1} && {_lastCol < count _colX} && {_lastRow < count _rowY}) exitWith {
    private _left = _colX select _col;
    private _top = _rowY select _row;

    [
        _cornerX + _left,
        _cornerY + _top,
        (_colX select _lastCol) - _left + _cellW - pixelW,
        (_rowY select _lastRow) - _top + _cellH - pixelH
    ]
};

// Where column (row) _index starts from the corner: the grid's own place for it, the plain pitch before
// the first and on from the last.
private _fnc_start = {
    params ["_starts", "_index", "_pitch"];

    private _count = count _starts;

    if (_index >= 0 && {_index < _count}) exitWith {_starts select _index};
    if (_index < 0 || {_count == 0}) exitWith {_index * _pitch};

    (_starts select (_count - 1)) + (_index - _count + 1) * _pitch
};

private _left = [_colX, _col, _cellW] call _fnc_start;
private _top = [_rowY, _row, _cellH] call _fnc_start;

[
    _cornerX + _left,
    _cornerY + _top,
    ([_colX, _lastCol, _cellW] call _fnc_start) - _left + _cellW - pixelW,
    ([_rowY, _lastRow, _cellH] call _fnc_start) - _top + _cellH - pixelH
]
