#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What letting go of a hotbar slot's binding would do at the mouse (fnc_startStripDrag): "move" over another
 * slot of the strip (the slot's number is the eighth element of its record), "stay" over the same slot
 * or on the strip between its slots, "remove" anywhere else. Reads GVAR(hover), which the caller keeps up to
 * date (fnc_updateHover).
 *
 * Arguments:
 * 0: Number of the slot held <NUMBER>
 * 1: Mouse position [x, y] <ARRAY>
 *
 * Return Value:
 * "move", "stay" or "remove" <STRING>
 *
 * Example:
 * [2, getMousePosition] call einv_gui_fnc_stripTarget;
 *
 * Public: No
 */

params ["_index", "_mouse"];

private _over = -1;

if ((GVAR(hover) param [0, ""]) isEqualTo "slot") then {
    _over = ((uiNamespace getVariable [QGVAR(slots), []]) param [GVAR(hover) select 1, []]) param [7, -1];
};

if (_over >= 0 && {_over != _index}) exitWith {"move"};
if (_over == _index) exitWith {"stay"};

private _box = GVAR(stripDrag) param [2, []];

if (_box isEqualTo []) exitWith {"stay"};

_mouse params ["_mouseX", "_mouseY"];
_box params ["_left", "_top", "_right", "_bottom"];

["remove", "stay"] select (_mouseX >= _left && {_mouseX < _right} && {_mouseY >= _top} && {_mouseY < _bottom})
