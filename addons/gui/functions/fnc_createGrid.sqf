#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Lays out an empty grid - one compartment of a container: one faint square per cell, a pixel apart, and
 * registers it in (uiNamespace getVariable [QGVAR(grids), []]) so the mouse finds its tiles.
 *
 * One control per cell rather than lines across: the window is see-through, and two lines crossing
 * would show a brighter dot at every corner. Squares with a gap between them never overlap. A tile
 * hides the cells under it (fnc_createTile), so it reads as one piece.
 *
 * The squares are not made here: fnc_drawCells makes them once the tiles lie on the grid, and only for the
 * cells no tile covers - a full pile of ninety tiles would otherwise make ninety squares only to hide them.
 * Until then "cells" holds controlNull for every cell; fnc_drawCells makes a square where a tile has gone.
 * Whoever puts tiles on the grid calls it after them (fnc_drawCompartments, fnc_redrawTiles).
 *
 * The cells go straight into the parent - no group of its own per grid: a group nested in the
 * scrolling column would take the mouse wheel from it. The grid's corner sits on a pixel and a cell is
 * a whole number of them (fnc_getCell), so every edge of the grid falls on a pixel.
 *
 * A shaped compartment's holes (einv_items_fnc_parseGrid, "xxx/x-x") get no control at all: nothing
 * is drawn there and nothing there can be hovered. Their place in "cells" holds controlNull for good
 * (fnc_drawCells passes over them), so a cell is still found at row * cols + col, and whatever shows or
 * hides cells passes over a hole without a word.
 *
 * Every cell of every grid is the same size with the same gap to the next, whichever compartment of a
 * container it belongs to. A canvas's compartment (grid=aab/acc) may reach over a seam that opens the
 * canvas between two others (fnc_flowCompartments): its columns and rows then do not all lie at the plain
 * pitch. Where each starts is kept on the grid ("colX", "rowY"), and so is, for finding a cell from a
 * point at once, which column or row each stretch of one pitch from the corner holds ("colAt",
 * "rowAt"). Every grid has them, the plain pitch where nothing opens up. A cell is its column's and its
 * row's place from the corner, and so is everything drawn on a grid (fnc_spanRect, fnc_shapeRects) and
 * the cell under a point (fnc_screenToCell).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Top left corner [x, y] - relative to the group inside one <ARRAY>
 * 3: Rows <NUMBER>
 * 4: Theme <HASHMAP>
 * 5: Id of the section it shows, e.g. "vest" <STRING> (default: "")
 * 6: Columns - a compartment's own width <NUMBER> (default: STORAGE_COLS)
 * 7: Holes - the indices row * cols + col of the cells it does not have <ARRAY> (default: [])
 * 8: Where its columns and rows start from its corner, [colX, rowY] as fnc_flowCompartments gives a
 *    canvas's compartment; [] for the plain pitch <ARRAY> (default: [])
 *
 * Return Value:
 * The grid <HASHMAP>
 *   "parent"  - the group the grid lies in, controlNull for the display <CONTROL>
 *   "rel"     - its top left corner in the parent, on a pixel <ARRAY>
 *   "cols", "rows" <NUMBER>
 *   "cellW", "cellH" - one cell, as screen width and height <NUMBER>
 *   "colX", "rowY" - where each column and row starts from the corner <ARRAY>
 *   "colAt", "rowAt" - per stretch of one cell from the corner, the last column (row) that starts in it
 *               or before it: a point there lies in that one or the one before (fnc_screenToCell) <ARRAY>
 *   "cells"   - a control per cell, row by row, controlNull for a hole and for a cell whose square is
 *               not made yet (fnc_drawCells) <ARRAY>
 *   "cellColor" - the squares' colour <ARRAY>
 *   "holes"   - the cells it does not have, as given <ARRAY>
 *   "tiles"   - the entries lying on it, see fnc_createTile <ARRAY>
 *   "section" - the section id <STRING>
 *
 * Example:
 * [_display, _group, [0, 0.05], 6, _theme, "vest"] call einv_gui_fnc_createGrid;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_position", "_rows", "_theme", ["_section", ""], ["_cols", STORAGE_COLS], ["_holes", []], ["_offsets", [], [[]]]];
_position params ["_relX", "_relY"];
_offsets params [["_colX", [], [[]]], ["_rowY", [], [[]]]];

(call FUNC(getCell)) params ["_cellW", "_cellH"];

// Where each column and row starts: as given for a canvas's compartment, else at the plain pitch.
if (count _colX != _cols) then {
    _colX = [];

    for "_col" from 0 to (_cols - 1) do {
        _colX pushBack (_col * _cellW);
    };
};

if (count _rowY != _rows) then {
    _rowY = [];

    for "_row" from 0 to (_rows - 1) do {
        _rowY pushBack (_row * _cellH);
    };
};

// Per stretch of one pitch from the corner, the last column (row) that starts before the stretch ends. A
// column is a pitch wide and starts at least a pitch after the one before it, so a point in that stretch
// lies in that column or in the one before it: one look and one comparison find it (fnc_screenToCell).
private _fnc_lookup = {
    params ["_starts", "_pitch"];

    private _lookup = [];
    private _count = count _starts;

    if (_count == 0) exitWith {_lookup};

    private _index = 0;
    private _stretches = ceil (((_starts select (_count - 1)) + _pitch) / _pitch - 0.0001);

    for "_stretch" from 0 to (_stretches - 1) do {
        private _end = (_stretch + 1) * _pitch;

        while {_index + 1 < _count && {(_starts select (_index + 1)) < _end}} do {
            _index = _index + 1;
        };

        _lookup pushBack _index;
    };

    _lookup
};

private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _left = _originX + round ((_relX - _originX) / pixelW) * pixelW;
private _top = _originY + round ((_relY - _originY) / pixelH) * pixelH;

private _color = _theme getOrDefault ["cell", [1, 1, 1, 0.045]];

if (_color isEqualTo []) then {
    _color = [0, 0, 0, 0];
};

// No square yet: fnc_drawCells makes those no tile covers, once the tiles lie on the grid.
private _cells = [];
_cells resize (_rows * _cols);
_cells = _cells apply {controlNull};

private _grid = createHashMapFromArray [
    ["parent", _parent],
    ["rel", [_left, _top]],
    ["cols", _cols],
    ["rows", _rows],
    ["cellW", _cellW],
    ["cellH", _cellH],
    ["colX", _colX],
    ["rowY", _rowY],
    ["colAt", [_colX, _cellW] call _fnc_lookup],
    ["rowAt", [_rowY, _cellH] call _fnc_lookup],
    ["cells", _cells],
    ["cellColor", _color],
    ["holes", _holes],
    ["tiles", []],
    ["section", _section]
];

(uiNamespace getVariable [QGVAR(grids), []]) pushBack _grid;

_grid
