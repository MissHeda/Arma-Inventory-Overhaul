#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the camera on the soldier is not the player's to choose: a server or a mission forces the
 * setting einv_gui_cameraDefault (a CBA force line, priority 1 or more), so the window opens as that says
 * and the header's camera button would only fight it. fnc_drawHeader draws no button then, and
 * fnc_toggleCamera does nothing.
 *
 * A server value that is only a default (priority 0) leaves the choice to the player.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Forced <BOOL>
 *
 * Example:
 * call einv_gui_fnc_cameraForced;
 *
 * Public: No
 */

// CBA's settings are required, but the functions used here are its internals: should they ever be gone, the
// player keeps the button.
if (isNil "cba_settings_fnc_priority") exitWith {false};

private _setting = QGVAR(cameraDefault);
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
