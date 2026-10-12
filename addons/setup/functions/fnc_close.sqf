#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Closes the wizard - after asking, when the draft holds changes not saved: they would be gone.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_setup_fnc_close;
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {};

if (call FUNC(isDirty)) exitWith {
    [_display, LLSTRING(Discard_Confirm), LLSTRING(Discard_Yes), {
        (uiNamespace getVariable [QGVAR(display), displayNull]) closeDisplay 2;
    }] call FUNC(confirm);
};

_display closeDisplay 2;
