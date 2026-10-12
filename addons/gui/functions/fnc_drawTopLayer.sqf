#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Makes again what has to lie over the kit windows - the name at the mouse and the inspect card - after
 * every build and whenever a window opens, closes or comes to the top (fnc_drawWindows,
 * fnc_raiseWindow): the engine draws controls made later over earlier ones, and has no other order.
 * Then fades what the search field leaves out, the new windows' tiles as well, and finds what the mouse
 * is on again.
 *
 * The context menu, the dragged ghost, its footprint and its counter are made later still, when they
 * come up, and lie over all of it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_drawTopLayer;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

if (isNull _display) exitWith {};

private _theme = GVAR(theme);

// The name at the mouse (fnc_updateHover places it).
ctrlDelete (uiNamespace getVariable [QGVAR(tooltip), controlNull]);

private _tooltip = [
    _display, controlNull, [0, 0, 0, UNIT * 0.85], "", UNIT * 0.58,
    _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]], _theme getOrDefault ["font", "PuristaMedium"], 2
] call FUNC(uiLabel);

_tooltip ctrlSetBackgroundColor (_theme getOrDefault ["tooltipBg", [0.06, 0.066, 0.08, 0.94]]);
_tooltip ctrlShow false;
uiNamespace setVariable [QGVAR(tooltip), _tooltip];

// The inspect card, over everything, where it was (fnc_drawInspect).
call FUNC(drawInspect);

// What the search field leaves out fades (fnc_applyFilter).
if (GVAR(filter) isNotEqualTo "") then {
    call FUNC(applyFilter);
};

GVAR(lastMouse) = getMousePosition;
[_display, GVAR(lastMouse), true] call FUNC(updateHover);
