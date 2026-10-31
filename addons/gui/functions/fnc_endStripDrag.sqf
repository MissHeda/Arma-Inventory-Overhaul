#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The mouse button let go of a hotbar slot's binding (fnc_startStripDrag), or the drag was cut short: on
 * another slot of the strip the two bindings change places (aio_hotbar_fnc_moveSlot), anywhere outside the
 * strip the slot is emptied (aio_hotbar_fnc_unbind) - the item itself is not touched -, on the strip between
 * its slots, or cancelled, nothing happens (fnc_stripTarget). The ghost goes and the hint goes back to what
 * the mouse is on.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Cancel: nothing is moved or removed <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_gui_fnc_endStripDrag;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_cancel", false]];

if (GVAR(stripDrag) isEqualTo []) exitWith {};

private _mouse = getMousePosition;
private _index = GVAR(stripDrag) select 0;
private _result = "stay";
private _target = -1;

if (!_cancel) then {
    [_display, _mouse, true] call FUNC(updateHover);

    _result = [_index, _mouse] call FUNC(stripTarget);

    if (_result isEqualTo "move") then {
        _target = ((uiNamespace getVariable [QGVAR(slots), []]) param [GVAR(hover) param [1, -1], []]) param [7, -1];
    };
};

ctrlDelete (GVAR(stripDrag) select 1);

GVAR(stripDrag) = [];
GVAR(press) = [];
GVAR(dragHintShown) = [];

// The hint goes back to what the mouse is on; the hotbar builds the window again after a change.
[_display, _mouse, true] call FUNC(updateHover);

switch (_result) do {
    case "move": {
        if (_target >= 0 && {!isNil QEFUNC(hotbar,moveSlot)}) then {
            [_index, _target] call EFUNC(hotbar,moveSlot);
        };
    };
    case "remove": {
        if (!isNil QEFUNC(hotbar,unbind)) then {
            [_index] call EFUNC(hotbar,unbind);
        };
    };
};
