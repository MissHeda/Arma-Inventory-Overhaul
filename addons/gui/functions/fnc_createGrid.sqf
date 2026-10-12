#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws an empty grid - one compartment of a container: one faint square per cell, a pixel apart, and
 * registers it in (uiNamespace getVariable [QGVAR(grids), []]) so the mouse finds its tiles.
 *
 * One control per cell rather than lines across: the window is see-through, and two lines crossing
 * would show a brighter dot at every corner. Squares with a gap between them never overlap. A tile
 * hides the cells under it (fnc_createTile), so it reads as one piece.
 *
 * The cells go straight into the parent - no group of its own per grid: a group nested in the
 * scrolling column would take the mouse wheel from it. The grid's corner sits on a pixel and a cell is
 * a whole number of them (fnc_getCell), so every edge of the grid falls on a pixel.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Top left corner [x, y] - relative to the group inside one <ARRAY>
 * 3: Rows <NUMBER>
 * 4: Theme <HASHMAP>
 * 5: Id of the section it shows, e.g. "vest" <STRING> (default: "")
 * 6: Columns - a compartment's own width <NUMBER> (default: STORAGE_COLS)
 *
 * Return Value:
 * The grid <HASHMAP>
 *   "parent"  - the group the grid lies in, controlNull for the display <CONTROL>
 *   "rel"     - its top left corner in the parent, on a pixel <ARRAY>
 *   "cols", "rows" <NUMBER>
 *   "cellW", "cellH" - one cell, as screen width and height <NUMBER>
 *   "cells"   - a control per cell, row by row <ARRAY>
 *   "tiles"   - the entries lying on it, see fnc_createTile <ARRAY>
 *   "section" - the section id <STRING>
 *
 * Example:
 * [_display, _group, [0, 0.05], 6, _theme, "vest"] call einv_gui_fnc_createGrid;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_position", "_rows", "_theme", ["_section", ""], ["_cols", STORAGE_COLS]];
_position params ["_relX", "_relY"];

(call FUNC(getCell)) params ["_cellW", "_cellH"];

private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _left = _originX + round ((_relX - _originX) / pixelW) * pixelW;
private _top = _originY + round ((_relY - _originY) / pixelH) * pixelH;

private _color = _theme getOrDefault ["cell", [1, 1, 1, 0.045]];

if (_color isEqualTo []) then {
    _color = [0, 0, 0, 0];
};

private _cells = [];

for "_row" from 0 to (_rows - 1) do {
    for "_col" from 0 to (_cols - 1) do {
        private _cell = [_display, "EINV_PanelRect", _parent, [
            _left + _col * _cellW,
            _top + _row * _cellH,
            _cellW - pixelW,
            _cellH - pixelH
        ]] call FUNC(uiCreate);

        _cell ctrlSetBackgroundColor _color;
        _cells pushBack _cell;
    };
};

private _grid = createHashMapFromArray [
    ["parent", _parent],
    ["rel", [_left, _top]],
    ["cols", _cols],
    ["rows", _rows],
    ["cellW", _cellW],
    ["cellH", _cellH],
    ["cells", _cells],
    ["tiles", []],
    ["section", _section]
];

(uiNamespace getVariable [QGVAR(grids), []]) pushBack _grid;

_grid
