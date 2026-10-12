#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ends an unloading without unloading anything: the handler goes, the bar goes, and the cards are drawn
 * with their Unload button again. A click on the bar, Escape (the window closing), the player or the
 * vehicle moving out of ACE's rules, and the end of a finished unloading all come here.
 *
 * Arguments:
 * 0: Why it stopped, shown in the hint - "" for quietly <STRING> (default: "")
 * 1: Build the window again <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["", true] call einv_compat_ace_cargo_fnc_stopUnload;
 *
 * Public: No
 */

params [["_text", "", [""]], ["_build", true, [true]]];

if (GVAR(unloadPFH) >= 0) then {
    [GVAR(unloadPFH)] call CBA_fnc_removePerFrameHandler;
};

GVAR(unloadPFH) = -1;
GVAR(unloading) = [];
uiNamespace setVariable [QGVAR(bar), []];

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

if (isNull _display) exitWith {};

// The hint is written after the build: the build makes the footer anew.
if (_build) then {
    [_display] call EFUNC(gui,build);
};

if (_text isNotEqualTo "") then {
    [_text] call EFUNC(gui,flashHint);
};
