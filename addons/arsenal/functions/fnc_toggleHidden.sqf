#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Hides or shows the panels (Backspace, the eye in the header): header, footer, columns and catalog go,
 * hover and drag with them, and the camera gets the whole screen. ace_arsenal_showToggle is raised as ACE's
 * own button raises it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_toggleHidden;
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

// Not while something is held: a build would pull it from under the mouse.
if (isNull _display || {EGVAR(gui,dragging)}) exitWith {};

GVAR(hidden) = !GVAR(hidden);

// What lay over the window goes with the panels, and the cursor goes to the sink - a field that is hidden
// must not keep the keys.
call EFUNC(gui,closeMenu);
call EFUNC(gui,closeInspect);
ctrlSetFocus (uiNamespace getVariable [QEGVAR(gui,filterSink), controlNull]);

// Built again: the layout gives the camera the whole screen while hidden (fnc_layout), and fnc_afterBuild
// hides what that build drew.
[_display] call EFUNC(gui,build);

[QACEGVAR(arsenal,showToggle), [_display, !GVAR(hidden)]] call CBA_fnc_localEvent;
