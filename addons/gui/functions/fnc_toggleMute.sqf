#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The speaker in the header: mutes the window's sounds for the looter, or lets them play again - the kinds
 * the player's settings name under "Mute button silences" (fnc_soundMuted): item moves, magazines,
 * containers, searching, the rest. Each player's own choice, kept in the profile.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_toggleMute;
 *
 * Public: No
 */

disableSerialization;

GVAR(muted) = !GVAR(muted);
profileNamespace setVariable [QGVAR(muted), GVAR(muted)];
saveProfileNamespace;

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _display) then {
    [_display] call FUNC(build);
};
