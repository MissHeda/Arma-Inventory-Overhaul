#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A press on a row of the settings card (fnc_openSizeMenu, fnc_settingsDefs): a switch flips, a list goes to its next value and a
 * number one step up - with the right mouse button a list and a number go back. Written to CBA at once, so CBA's options show it
 * too, and the window is built again behind the card. A setting a server or a mission forces does not change.
 *
 * Arguments:
 * 0: Index of the row in fnc_settingsDefs <NUMBER>
 * 1: Mouse button <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1, 0] call aio_gui_fnc_settingsRow;
 *
 * Public: No
 */

params ["_index", ["_button", 0]];

(call FUNC(settingsDefs)) param [_index, []] params [["_setting", ""], "", "", ["_kind", ""], "_default", ["_data", []]];

if (_setting isEqualTo "" || {[_setting] call FUNC(settingForced)}) exitWith {};

private _value = missionNamespace getVariable [_setting, _default];
private _back = _button == 1;

_value = switch (_kind) do {
    case "check": {!_value};
    case "list": {
        _data params ["_values"];

        private _at = (_values find _value) max 0;
        private _count = count _values;

        _values select ((_at + ([1, _count - 1] select _back)) mod _count)
    };
    case "step": {
        _data params ["_least", "_most", "_step"];

        ((_value + ([_step, -_step] select _back)) max _least) min _most
    };
    default {_value};
};

missionNamespace setVariable [_setting, _value];

if (!isNil "CBA_settings_fnc_set") then {
    [_setting, _value, 0, "client"] call CBA_settings_fnc_set;
};

// Written to the profile at once: "Real weapon pictures" was off again after a restart (Mia, 0.6.107) - the profile is otherwise
// only saved when the game closes the way it should.
saveProfileNamespace;

// An order picked means the columns in that order: what was placed by hand goes.
if (_setting isEqualTo QGVAR(columnOrder) && {(missionNamespace getVariable [QGVAR(layoutRects), ""]) isNotEqualTo ""}) then {
    ["reset"] call FUNC(layoutDrag);
};

[] call FUNC(elementsChanged);
