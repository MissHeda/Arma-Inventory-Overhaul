#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes the window, runs something that opens a dialog of another mod, and opens the window again on the
 * same containers once that dialog is closed. For a radio's dialog (einv_compat_tfar, einv_compat_acre): TFAR
 * and ACRE2 refuse to open theirs while any dialog is open, so it cannot be opened over this window.
 *
 * The code runs a moment after the window closed (STEP_ASIDE_DELAY), as TFAR's own radio menu waits
 * before it opens a radio. If it opened a dialog, the window waits for that to close; if it opened none -
 * the mod said why not - the window comes straight back. The window opens fresh: the uniforms, vests and
 * backpacks opened from inside a container are closed again, and so are the kits' windows.
 *
 * Arguments:
 * 0: Code that opens the dialog <CODE>
 * 1: Its arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_id"]; [_id] call acre_sys_gui_fnc_openRadio}, ["ACRE_PRC152_ID_1"]] call einv_gui_fnc_stepAside;
 *
 * Public: No
 */

params [["_code", {}, [{}]], ["_args", []]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _back = [GVAR(unit), GVAR(container), GVAR(secondary)];

if (!isNull _display) then {
    _display closeDisplay 2;
};

[{
    params ["_code", "_args", "_back"];

    private _fnc_back = {
        params ["_unit", "_container", "_secondary"];

        // Only for the same player, alive, with no window open meanwhile.
        if (alive _unit && {_unit isEqualTo ACE_player} && {isNull (uiNamespace getVariable [QGVAR(display), displayNull])}) then {
            [_unit, _container, _secondary] call FUNC(open);
        };
    };

    _args call _code;

    if (!dialog) exitWith {
        _back call _fnc_back;
    };

    [{!dialog}, _fnc_back, _back] call CBA_fnc_waitUntilAndExecute;
}, [_code, _args, _back], STEP_ASIDE_DELAY] call CBA_fnc_waitAndExecute;
