#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The speaker in the header: mutes the rustle while loot is searched, or lets it play again. Each
 * player's own choice, kept in the profile like the camera switch.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_toggleSearchSound;
 *
 * Public: No
 */

disableSerialization;

GVAR(searchMuted) = !GVAR(searchMuted);
profileNamespace setVariable [QGVAR(searchMuted), GVAR(searchMuted)];
saveProfileNamespace;

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _display) then {
    [_display] call FUNC(build);
};
