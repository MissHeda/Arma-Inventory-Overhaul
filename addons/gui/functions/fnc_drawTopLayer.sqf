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
 * come up, and lie over all of it. The name at the mouse is the exception that is kept on top the other
 * way: an outline made after it on the display - the hover ring of a slot - would lie over it, so
 * fnc_raiseTooltip makes the name again after such an outline (fnc_updateHover, fnc_drawSelection).
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

// The name at the mouse (fnc_updateHover places it; fnc_raiseTooltip makes it again over a ring or frame
// made after it).
ctrlDelete (uiNamespace getVariable [QGVAR(tooltip), controlNull]);
uiNamespace setVariable [QGVAR(tooltip), [_display] call FUNC(makeTooltip)];

// The inspect card, over everything, where it was (fnc_drawInspect).
call FUNC(drawInspect);

// What the search field leaves out fades (fnc_applyFilter).
if (GVAR(filter) isNotEqualTo "" || {GVAR(groupFilters) isNotEqualTo []}) then {
    [] call FUNC(applyFilter);
};

GVAR(lastMouse) = getMousePosition;
[_display, GVAR(lastMouse), true] call FUNC(updateHover);
