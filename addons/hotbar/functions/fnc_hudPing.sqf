#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Shows the bar on the screen for a few seconds (the setting "Hotbar shown for"), when it is set to show
 * while in use, and keeps it up to date from then on (fnc_hudFrame). Called wherever the bar has
 * something to say: a key, a binding, a message.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_hotbar_fnc_hudPing;
 *
 * Public: No
 */

if (!(call FUNC(isActive)) || {GVAR(hudMode) == 0}) exitWith {};

GVAR(hudUntil) = diag_tickTime + GVAR(hudTime);

if (GVAR(hudPFH) < 0) then {
    GVAR(hudPFH) = [FUNC(hudFrame), 0] call CBA_fnc_addPerFrameHandler;
};
