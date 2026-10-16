#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A mouse button pressed or let go on ACE Arsenal's display (the display's own MouseButtonDown and MouseButtonUp
 * handlers, fnc_onOpened) while the question of fnc_confirmClose is up. The controls' own events do not reach
 * the answers on ACE's display (as with their hover, fnc_hoverConfirm), so the mouse is looked for on them
 * here: a left press on "Keep editing" or "Remove and close" is noted, and the same button let go on the same
 * answer gives it (fnc_closeConfirm, fnc_answerConfirm) a frame later - the card's controls are deleted by
 * it, and not inside the event of the display they are on. A press that is let go elsewhere answers nothing.
 * Every press and release is taken (true) while the question is up: ACE's note of the press, which would pan
 * or turn its camera, is emptied. With no question up it does nothing and takes nothing.
 *
 * Arguments:
 * 0: Pressed (true) or let go (false) <BOOL>
 * 1: ACE Arsenal's display <DISPLAY>
 * 2: Button, 0 left <NUMBER>
 * 3: Mouse X <NUMBER>
 * 4: Mouse Y <NUMBER>
 *
 * Return Value:
 * Taken <BOOL>
 *
 * Example:
 * [true, findDisplay 1127001, 0, 0.5, 0.5] call einv_arsenal_fnc_onConfirmMouse;
 *
 * Public: No
 */

disableSerialization;

params [["_down", true, [true]], "", ["_button", 0, [0]], ["_mouseX", 0, [0]], ["_mouseY", 0, [0]]];

if (isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])) exitWith {false};

if (!isNil QACEGVAR(arsenal,mouseButtonState)) then {
    ACEGVAR(arsenal,mouseButtonState) = [[], []];
};

if (_button != 0) exitWith {true};

// Which answer is under the mouse, -1 for none.
private _hit = (uiNamespace getVariable [QGVAR(confirmButtons), []]) findIf {
    if (isNull _x) then {
        false
    } else {
        (ctrlPosition _x) params ["_left", "_top", "_width", "_height"];

        _mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}
    }
};

if (_down) exitWith {
    GVAR(confirmPress) = _hit;
    true
};

private _pressed = GVAR(confirmPress);

GVAR(confirmPress) = -1;

if (_hit < 0 || {_hit != _pressed}) exitWith {true};

[{
    // Answered already - a second click, or the buttons' own event.
    if (isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])) exitWith {};

    if ((_this select 0) == 0) then {
        [] call FUNC(closeConfirm);
    } else {
        [] call FUNC(answerConfirm);
    };
}, [_hit]] call EFUNC(gui,later);

true
