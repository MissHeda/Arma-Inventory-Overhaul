#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes the window - the display it is drawn on - and says why. Every way the window closes itself goes
 * through here, so the RPT names it (fnc_onUnload: "window closed: <reason>"), and a window that closes
 * with no reason given was closed by something else: another mod's closeDialog or closeDisplay.
 *
 * Two reasons are read by key: "move" (a movement key - the soldier walks off) and "taken" (taken away from
 * the loot, fnc_checkTaken - no closing sound). Any other is only told.
 *
 * Arguments:
 * 0: Why <STRING>
 *
 * Return Value:
 * There was a window to close <BOOL>
 *
 * Example:
 * ["the close button"] call einv_gui_fnc_closeDisplay;
 *
 * Public: No
 */

params [["_reason", "", [""]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {false};

GVAR(closeReason) = _reason;
_display closeDisplay 2;

true
