#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a point of the screen lies on the panel - the grid's column and the hint line under it - as the
 * last build drew it (fnc_layout). With no panel drawn, nowhere.
 *
 * Arguments:
 * 0: Point [x, y] <ARRAY> (default: the mouse)
 *
 * Return Value:
 * On the panel <BOOL>
 *
 * Example:
 * [getMousePosition] call einv_arsenal_fnc_isOver;
 *
 * Public: No
 */

params [["_point", getMousePosition, [[]], 2]];

if (GVAR(panelRect) isEqualTo []) exitWith {false};

_point params ["_pointX", "_pointY"];
GVAR(panelRect) params ["_left", "_top", "_width", "_height"];

_pointX >= _left && {_pointX < _left + _width} && {_pointY >= _top} && {_pointY < _top + _height}
