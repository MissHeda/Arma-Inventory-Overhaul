#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The cell of a grid at a point on the screen. The one place that turns screen positions into cells -
 * hovering, and later dragging and dropping, all go through here, so scrolling only has to be taken
 * into account once (fnc_gridOrigin). A hole of a shaped compartment is no cell: nothing to hover or
 * click there - only a drag still finds the grid over one, so its footprint shows red (fnc_updateDrag).
 * A grid is one compartment, and a point is on it only where it has a cell: compartments drawn on a
 * canvas may share a box (grid=aaa/aba/aaa), and the hole of the one is the cell of the other.
 * On a canvas's compartment with seams (fnc_canvasSeams) the cells lie where the grid keeps them
 * ("colX", "rowY"); a point in a seam's gap inside the grid belongs to the cell before it (left, above),
 * so a tile that reaches over the seam has no dead strip; one past the last column or row is on no cell,
 * as one between two flowed blocks is.
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

// The last column (row) that starts at or before the point; a cell's pitch apart where the grid keeps no
// offsets. The gap of a seam belongs to the cell before it: with a column after it in the same grid, the
// strip is part of a tile that straddles the seam (aaa/aba/aaa, a 2x1 at (0,0)), and answering -1 there
// would make it unhoverable and flicker the drag footprint. Only past the last column (row) is -1 right.
private _fnc_find = {
    params ["_offsets", "_offset", "_pitch"];

    if (_offsets isEqualTo []) exitWith {floor (_offset / _pitch)};

    private _index = count _offsets - 1;

    while {_index >= 0 && {(_offsets select _index) > _offset}} do {
        _index = _index - 1;
    };

    [-1, _index] select (_index >= 0 && {_index < count _offsets - 1 || {_offset < (_offsets select _index) + _pitch}})
};

private _col = [_grid getOrDefault ["colX", []], _pointX - _originX, _grid get "cellW"] call _fnc_find;
private _row = [_grid getOrDefault ["rowY", []], _pointY - _originY, _grid get "cellH"] call _fnc_find;

if (_col < 0 || {_row < 0} || {_col >= _grid get "cols"} || {_row >= _grid get "rows"}) exitWith {[]};
if (!_holesToo && {[_grid, _col, _row] call FUNC(hitsHole)}) exitWith {[]};

[_col, _row]
