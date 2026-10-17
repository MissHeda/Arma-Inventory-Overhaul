#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which corners of a box lie on a corner of its grid's panel (fnc_drawCompartments): a tile, an empty cell, a selection, an
 * outline or a drag footprint that reaches the panel's corner has to follow its round corner (fnc_uiSurface,
 * fnc_uiOutline) - only that one corner, two for a box as wide or as high as the compartment. The panel runs from the first
 * cell's corner to the last cell's far edge, so the box is compared with those four places (a pixel apart counts as the
 * same). A paged compartment (fnc_setWindow) has the corners of the rows that show; a grid with no round corners (square
 * look, shaped panel, overflow, a preview, "corner" 0, fnc_gridCorner) answers at once.
 *
 * Arguments:
 * 0: Grid, see fnc_createGrid <HASHMAP>
 * 1: Box [x, y, w, h], where the cells lie as the box does - in the grid's group (the default) or on the screen <ARRAY>
 * 2: Where the grid's corner lies in that same place, [x, y] - the grid's "rel" for a box in its group, fnc_gridOrigin for
 *    the screen <ARRAY> (default: the grid's "rel")
 *
 * Return Value:
 * [radius in pixels, [top left, top right, bottom left, bottom right] <BOOL>], [] when it touches none <ARRAY>
 *
 * Example:
 * [_grid, [_left, _top, _width, _height]] call einv_gui_fnc_cornerRadii;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]], ["_box", [], [[]]], ["_origin", []]];

private _radius = _grid getOrDefault ["corner", 0];

if (_radius < 2 || {count _box < 4}) exitWith {[]};

if (_origin isEqualTo []) then {
    _origin = _grid getOrDefault ["rel", []];
};

private _colX = _grid getOrDefault ["colX", []];
private _rowY = _grid getOrDefault ["rowY", []];
private _rowFrom = _grid getOrDefault ["rowFrom", 0];
private _rowTo = _grid getOrDefault ["rowTo", _grid getOrDefault ["rows", 0]];

if (count _origin < 2 || {_colX isEqualTo []} || {_rowTo <= _rowFrom} || {_rowTo > count _rowY}) exitWith {[]};

_origin params ["_originX", "_originY"];

private _panelLeft = _originX + (_colX select 0);
private _panelTop = _originY + (_rowY select _rowFrom);
private _panelRight = _originX + (_colX select (count _colX - 1)) + (_grid get "cellW") - pixelW;
private _panelBottom = _originY + (_rowY select (_rowTo - 1)) + (_grid get "cellH") - pixelH;

_box params ["_x", "_y", "_w", "_h"];

private _slackX = pixelW * 1.5;
private _slackY = pixelH * 1.5;
private _atLeft = abs (_x - _panelLeft) < _slackX;
private _atRight = abs (_x + _w - _panelRight) < _slackX;
private _atTop = abs (_y - _panelTop) < _slackY;
private _atBottom = abs (_y + _h - _panelBottom) < _slackY;

private _mask = [_atLeft && _atTop, _atRight && _atTop, _atLeft && _atBottom, _atRight && _atBottom];

if !(true in _mask) exitWith {[]};

[_radius, _mask]
