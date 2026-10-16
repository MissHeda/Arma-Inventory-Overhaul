#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Lights up the answer of fnc_confirmClose's card that the mouse is on, and puts the others back. The buttons
 * light up by their own MouseEnter and MouseExit (einv_gui_fnc_uiButton) as well, but on ACE Arsenal's display
 * those did not reach them, so every frame (fnc_onFrame) the mouse is looked for on them here: the colours
 * are the button's own, set only when the state changed.
 *
 * Arguments:
 * 0: Mouse [x, y] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [getMousePosition] call einv_arsenal_fnc_hoverConfirm;
 *
 * Public: No
 */

disableSerialization;

params [["_mouse", getMousePosition, [[]], 2]];

private _group = uiNamespace getVariable [QGVAR(confirm), controlNull];

if (isNull _group) exitWith {};

(ctrlPosition _group) params ["_groupX", "_groupY"];
_mouse params ["_mouseX", "_mouseY"];

{
    if (!isNull _x) then {
        (ctrlPosition _x) params ["_left", "_top", "_width", "_height"];

        private _over = _mouseX >= _groupX + _left && {_mouseX < _groupX + _left + _width}
            && {_mouseY >= _groupY + _top} && {_mouseY < _groupY + _top + _height};

        if (_over isNotEqualTo (_x getVariable [QGVAR(lit), false])) then {
            _x setVariable [QGVAR(lit), _over];

            // The surface the button keeps: its rectangles take the colour as background, its round corners as text colour.
            (_x getVariable [QEGVAR(gui,surface), [[], [], [], []]]) params ["_rects", "_corners", "_normal", "_hover"];

            private _color = [_normal, _hover] select _over;

            {_x ctrlSetBackgroundColor _color} forEach _rects;
            {_x ctrlSetTextColor _color} forEach _corners;
        };
    };
} forEach (uiNamespace getVariable [QGVAR(confirmButtons), []]);
