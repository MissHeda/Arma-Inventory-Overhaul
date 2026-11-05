#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a server or a mission forces a player's CBA setting (set with a priority of 1 or more on "server" or "mission"): then
 * what the player sets is not taken, and what sets it in the window shows it can not be changed - the palette button is not drawn
 * (fnc_paletteForced), a row of the size popover is dimmed and still (fnc_openSizeMenu).
 *
 * Arguments:
 * 0: The setting's variable <STRING>
 *
 * Return Value:
 * Forced <BOOL>
 *
 * Example:
 * [QGVAR(cellScale)] call aio_gui_fnc_settingForced;
 *
 * Public: No
 */

params [["_setting", "", [""]]];

// CBA's settings are required, but the functions used here are its internals: should they ever be gone, nothing is forced.
if (isNil "cba_settings_fnc_priority") exitWith {false};

private _forced = false;

{
    private _holder = missionNamespace getVariable [format ["cba_settings_%1", _x], objNull];

    if (!isNull _holder && {!isNil {_holder getVariable _setting}}) then {
        private _priority = [_setting, _x] call cba_settings_fnc_priority;

        if (_priority isEqualType true) then {
            _priority = parseNumber _priority;
        };

        if (_priority >= 1) then {
            _forced = true;
        };
    };
} forEach ["server", "mission"];

_forced
