#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the drop key is called now, as the player has it set in Configure Addons - "G", "Shift+G". The first of
 * its keybinds, if it has several. The footer shows it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Key name, "" when the key is not set <STRING>
 *
 * Example:
 * call aio_gui_fnc_dropKeyName;
 *
 * Public: No
 */

if (isNil "CBA_fnc_getKeybind") exitWith {""};

private _entry = [CBA_SETTINGS_AIO, QGVAR(drop)] call CBA_fnc_getKeybind;

if (isNil "_entry") exitWith {""};

private _keybind = (_entry param [8, []]) param [0, []];

if (_keybind isEqualTo []) exitWith {""};

_keybind params [["_key", 0, [0]], ["_modifiers", [], [[]]]];

if (_key <= 0) exitWith {""};

[_key, _modifiers] call CBA_fnc_localizeKey
