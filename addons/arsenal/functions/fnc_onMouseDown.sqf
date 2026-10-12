#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A mouse button went down (the "mouseDown" hook): in the free middle, on no panel, tile or slot, the right
 * button starts turning the camera, the left one starts moving the point the camera looks at (the camera's
 * frame follows the mouse while it is held), and a second left click soon after the first puts the view
 * back (the left click itself is left to the window: it is not taken).
 *
 * The middle is the rectangle the layout left for the soldier (fnc_cameraRect). Where the screen has none
 * (4:3) it is the screen between the header and the footer, less the panels - the column of the catalog
 * included - and what floats over them (the inspect card, the kit windows).
 *
 * Arguments:
 * 0: Button <NUMBER>
 * 1: Mouse position [x, y] <ARRAY>
 * 2: Shift held <BOOL>
 * 3: Ctrl held <BOOL>
 * 4: Alt held <BOOL>
 * 5: Only answer whether the mouse is in the free middle, do nothing (the wheel asks that) <BOOL>
 *    (default: false)
 *
 * Return Value:
 * Taken - with the last argument, in the free middle <BOOL>
 *
 * Example:
 * [1, getMousePosition, false, false, false] call einv_arsenal_fnc_onMouseDown;
 *
 * Public: No
 */

params [["_button", 0, [0]], ["_mouse", [], [[]]], "", "", "", ["_testOnly", false, [false]]];

if ((_button > 1 && {!_testOnly}) || {isNull GVAR(camera)} || {count _mouse < 2}) exitWith {false};

_mouse params ["_mouseX", "_mouseY"];

// Inside the rectangle of the soldier, or between header and footer when there is none ...
private _inside = if (GVAR(cameraRect) isEqualTo []) then {
    _mouseY >= CONTENT_Y && {_mouseY < CONTENT_B} && {_mouseX >= safezoneX} && {_mouseX < safezoneX + safezoneW}
} else {
    GVAR(cameraRect) params ["_rectX", "_rectY", "_rectW", "_rectH"];

    _mouseX >= _rectX && {_mouseX < _rectX + _rectW} && {_mouseY >= _rectY} && {_mouseY < _rectY + _rectH}
};

// ... and on nothing: no card or window over it, no column.
if (_inside && {([_mouse] call EFUNC(gui,topAt)) isNotEqualTo ""}) then {
    _inside = false;
};

if (_inside) then {
    // The panels, and the catalog's column - which goes with them while the panels are hidden and covers
    // nothing then.
    private _blocks = +EGVAR(gui,panels);

    if (!GVAR(hidden)) then {
        _blocks pushBack ((uiNamespace getVariable [QGVAR(column), createHashMap]) getOrDefault ["rect", []]);
    };

    private _covers = _blocks findIf {
        _x params [["_left", 0], ["_top", 0], ["_width", 0], ["_height", 0]];

        _mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}
    };

    if (_covers >= 0) then {
        _inside = false;
    };
};

if (!_inside || {_testOnly}) exitWith {_inside};

if (_button == 1) exitWith {
    GVAR(cameraDrag) = _mouse;

    true
};

// The left button moves the point the camera looks at, from here (fnc_cameraFrame).
GVAR(cameraPan) = _mouse;

// Twice within the double click time, about in one place, it resets the view.
GVAR(cameraClick) params ["_before", "_where"];

if (diag_tickTime - _before <= DOUBLE_CLICK && {(_where distance2D _mouse) < 0.02}) then {
    call FUNC(cameraReset);

    GVAR(cameraClick) = [-1, [0, 0]];
} else {
    GVAR(cameraClick) = [diag_tickTime, _mouse];
};

false
