#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a slot's key is called now, as the player has it set in Configure Addons - "5", "Shift+4". The
 * first of its keybinds, if it has several.
 *
 * Arguments:
 * 0: Slot index <NUMBER>
 *
 * Return Value:
 * Key name, "" when the slot has no key <STRING>
 *
 * Example:
 * [0] call einv_hotbar_fnc_keyName;
 *
 * Public: No
 */

params [["_index", 0, [0]]];

private _entry = [CBA_SETTINGS_EINV, format [QGVAR(slot%1), _index + 1]] call CBA_fnc_getKeybind;

if (isNil "_entry") exitWith {""};

private _keybind = (_entry param [8, []]) param [0, []];

if (_keybind isEqualTo []) exitWith {""};

_keybind params [["_key", 0, [0]], ["_modifiers", [], [[]]]];

if (_key <= 0) exitWith {""};

[_key, _modifiers] call CBA_fnc_localizeKey
