#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the window's right-click menu on a slot of the hotbar offers: "Clear hotbar 5" while something
 * lies on it, nothing while it is empty.
 *
 * Arguments:
 * 0: Slot index <NUMBER>
 *
 * Return Value:
 * Choices as the context menu takes them, [text, arguments, code] <ARRAY>
 *
 * Example:
 * [2] call aio_hotbar_fnc_stripMenu;
 *
 * Public: No
 */

params [["_index", -1, [0]]];

if ((GVAR(slots) param [_index, ""]) isEqualTo "") exitWith {[]};

private _key = [_index] call FUNC(keyName);

if (_key isEqualTo "") then {
    _key = str (_index + 1);
};

[[format [LLSTRING(Menu_Clear), _key], [_index], {_this call FUNC(unbind)}]]
