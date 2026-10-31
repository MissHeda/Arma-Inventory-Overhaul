#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows the red glass screen for a vanilla Virtual Arsenal that is not allowed, with the sound of a refused
 * item. A second call while it is up is ignored.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_arsenal_fnc_showBlocked;
 *
 * Public: No
 */

if (!isNull (findDisplay IDD_ARSENAL_BLOCKED)) exitWith {};

private _parent = [] call BIS_fnc_displayMission;

// The curator's display, when it is open, is the one that has the keys; but Zeus is never blocked, so this is
// the mission's own.
if (isNull _parent) exitWith {};

_parent createDisplay "AIO_ArsenalBlocked";

["addItemFailed", "warn"] call EFUNC(gui,playClass);
