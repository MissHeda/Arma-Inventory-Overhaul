#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Tells ACRE to show its notifications (a radio's channel, a message) over the Enhanced Arsenal as it does over
 * ACE's own window. ACRE keeps a list of displays by their IDD for that and has only ACE's; this adds ours,
 * once. Nothing happens, and nothing is needed, when ACRE is not loaded.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * ACRE knows the display <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_acreDisplay;
 *
 * Public: No
 */

if (GVAR(acreRegistered)) exitWith {true};

private _add = missionNamespace getVariable "acre_api_fnc_addNotificationDisplay";

if (isNil "_add") exitWith {false};

[IDD_ARSENAL] call _add;

GVAR(acreRegistered) = true;

true
