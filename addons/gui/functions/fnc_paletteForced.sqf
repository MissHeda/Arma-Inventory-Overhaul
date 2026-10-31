#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a server or a mission forces the colours (the CBA setting aio_gui_paletteText, set with a priority of 1 or more on
 * "server" or "mission"): then everyone wears those, and the palette button is not drawn (fnc_paletteAllowed).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Forced <BOOL>
 *
 * Example:
 * call aio_gui_fnc_paletteForced;
 *
 * Public: No
 */

// CBA's settings are required, but the functions used here are its internals: should they ever be gone, nothing is forced.
if (isNil "cba_settings_fnc_priority") exitWith {false};

private _setting = QGVAR(paletteText);
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
