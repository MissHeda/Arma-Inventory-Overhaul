#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A mouse button came up (the "mouseUp" hook): ends the turning of the camera or the moving of its point.
 * Taken only when the camera was being turned, so a right click that never began there is the window's own;
 * the left button's release is always the window's.
 *
 * Arguments:
 * 0: Button <NUMBER>
 * 1: Mouse position [x, y] <ARRAY>
 *
 * Return Value:
 * Taken <BOOL>
 *
 * Example:
 * [1, getMousePosition] call einv_arsenal_fnc_onMouseUp;
 *
 * Public: No
 */

params [["_button", 0, [0]]];

// The left button lets go of the point the camera looks at.
if (_button == 0) exitWith {
    GVAR(cameraPan) = [];

    false
};

if (_button != 1 || {GVAR(cameraDrag) isEqualTo []}) exitWith {false};

GVAR(cameraDrag) = [];

true
