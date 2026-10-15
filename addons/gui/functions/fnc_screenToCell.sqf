#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The cell of a grid at a point on the screen. The one place that turns screen positions into cells -
 * hovering, and later dragging and dropping, all go through here, so scrolling only has to be taken
 * into account once (fnc_gridOrigin). A hole of a shaped compartment is no cell: nothing to hover or
 * click there - only a drag still finds the grid over one, so its footprint shows red (fnc_updateDrag).
 * A grid is one compartment, and a point is on it only where it has a cell: compartments drawn on a
 * canvas may share a box (grid=aaa/aba/aaa), and the hole of the one is the cell of the other.
 * Every cell lies at the plain pitch, a canvas's compartment's too, and is drawn there at the same size
 * (fnc_createGrid, fnc_spanRect): the point is divided by the one cell, so the cell it finds is the cell
 * under it.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Point on the screen, [x, y] - getMousePosition <ARRAY>
 * 2: A hole counts as a cell <BOOL> (default: false)
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

params ["_grid", "_point", ["_holesToo", false]];
_point params ["_pointX", "_pointY"];

// A row scrolled out of its column is not under the mouse, even where it would lie: the point has to
// be inside the group's visible box as well.
private _parent = _grid getOrDefault ["parent", controlNull];
private _visible = true;

if (!isNull _parent) then {
    (ctrlPosition _parent) params ["_groupX", "_groupY", "_groupW", "_groupH"];

    private _outer = createHashMapFromArray [["rel", [_groupX, _groupY]], ["parent", ctrlParentControlsGroup _parent]];
    ([_outer] call FUNC(gridOrigin)) params ["_left", "_top"];

    _visible = _pointX >= _left && {_pointX < _left + _groupW} && {_pointY >= _top} && {_pointY < _top + _groupH};
};

if (!_visible) exitWith {[]};

([_grid] call FUNC(gridOrigin)) params ["_originX", "_originY"];

private _col = floor ((_pointX - _originX) / (_grid get "cellW"));
private _row = floor ((_pointY - _originY) / (_grid get "cellH"));

if (_col < 0 || {_row < 0} || {_col >= _grid get "cols"} || {_row >= _grid get "rows"}) exitWith {[]};
if (!_holesToo && {[_grid, _col, _row] call FUNC(hitsHole)}) exitWith {[]};

[_col, _row]
