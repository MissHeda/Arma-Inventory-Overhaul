#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The cell of a grid at a point on the screen. The one place that turns screen positions into cells -
 * hovering, and later dragging and dropping, all go through here, so scrolling only has to be taken
 * into account once (fnc_gridOrigin). A hole of a shaped compartment is no cell: nothing to hover or
 * click there - only a drag still finds the grid over one, so its footprint shows red (fnc_updateDrag).
 * A grid is one compartment, and a point is on it only where it has a cell: compartments drawn on a
 * canvas may share a box (grid=aaa/aba/aaa), and the hole of the one is the cell of the other.
 * A cell lies where its column and row start (fnc_createGrid "colX", "rowY"), and so it is drawn
 * (fnc_spanRect): the point's distance from the grid's corner, divided by the one cell, names a stretch,
 * and the grid's lookup for it ("colAt", "rowAt") the column or row it lies in - that one or the one
 * before, one comparison, whatever the size of the grid. The pixel after a cell belongs to it, and so does
 * the room a seam of a canvas opens inside one compartment (fnc_flowCompartments) where the cells across
 * it are the compartment's too: a tile over it is hovered all along. The room between two compartments -
 * outside both grids, or beside a hole of one - is on no cell.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Point on the screen, [x, y] - getMousePosition <ARRAY>
 * 2: A hole counts as a cell <BOOL> (default: false)
 * 3: Where the grid lies now, [visible box [x, y, w, h] of its column or [] for none, left, top of its cells] as
 *    fnc_hoverGeometry worked it out - given, the group chain is not walked again <ARRAY> (default: [])
 *
 * Return Value:
 * [column, row], or [] when the point is not on the grid <ARRAY>
 *
 * Example:
 * [_grid, getMousePosition] call einv_gui_fnc_screenToCell;
 *
 * Public: No
 */

disableSerialization;

params ["_grid", "_point", ["_holesToo", false], ["_where", []]];
_point params ["_pointX", "_pointY"];

if (_where isEqualTo []) then {
    // A row scrolled out of its column is not under the mouse, even where it would lie: the point has to
    // be inside the group's visible box as well.
    private _parent = _grid getOrDefault ["parent", controlNull];
    private _box = [];

    if (!isNull _parent) then {
        (ctrlPosition _parent) params ["_groupX", "_groupY", "_groupW", "_groupH"];

        private _outer = createHashMapFromArray [["rel", [_groupX, _groupY]], ["parent", ctrlParentControlsGroup _parent]];
        ([_outer] call FUNC(gridOrigin)) params ["_left", "_top"];

        _box = [_left, _top, _groupW, _groupH];
    };

    ([_grid] call FUNC(gridOrigin)) params ["_cornerX", "_cornerY"];

    _where = [_box, _cornerX, _cornerY];
};

_where params ["_box", "_originX", "_originY"];

if (_box isNotEqualTo [] && {
    _box params ["_left", "_top", "_boxW", "_boxH"];
    !(_pointX >= _left && {_pointX < _left + _boxW} && {_pointY >= _top} && {_pointY < _top + _boxH})
}) exitWith {[]};

// The column (row) a point _local from the corner lies in, -1 for none: the last one that starts in its
// stretch or before it, or the one before that one; and whether it lies past that one's pitch, in the room
// a seam opens. A grid made without the lookup has the plain pitch.
private _fnc_find = {
    params ["_local", "_starts", "_lookup", "_pitch"];

    private _stretch = floor (_local / _pitch);

    if (_lookup isEqualTo []) exitWith {[_stretch, false]};
    if (_local < 0 || {_local >= (_starts select (count _starts - 1)) + _pitch}) exitWith {[-1, false]};

    private _index = _lookup param [_stretch, count _starts - 1];

    if (_local < (_starts select _index)) then {
        _index = _index - 1;
    };

    [_index, _local >= (_starts select _index) + _pitch]
};

([_pointX - _originX, _grid getOrDefault ["colX", []], _grid getOrDefault ["colAt", []], _grid get "cellW"] call _fnc_find) params ["_col", "_gapX"];
([_pointY - _originY, _grid getOrDefault ["rowY", []], _grid getOrDefault ["rowAt", []], _grid get "cellH"] call _fnc_find) params ["_row", "_gapY"];

if (_col < 0 || {_row < 0} || {_col >= _grid get "cols"} || {_row >= _grid get "rows"}) exitWith {[]};

// In the room a seam opens inside the compartment, the cell before it - where the cells across it are the
// compartment's too, as a tile can lie over it there. Beside a hole it is room between two compartments.
if ((_gapX || {_gapY}) && {[_grid, _col, _row, [1, 2] select _gapX, [1, 2] select _gapY] call FUNC(hitsHole)}) exitWith {[]};
if (!_holesToo && {[_grid, _col, _row] call FUNC(hitsHole)}) exitWith {[]};

[_col, _row]
