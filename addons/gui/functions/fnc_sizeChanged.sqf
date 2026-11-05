#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A size of the window changed - the tile scale, the text size or the rows per page (fnc_sizeDefs) - in the size popover
 * (fnc_sizeSet) or in CBA's own options (the settings' scripts, initSettings.inc.sqf): the popover shows the new values in place
 * (fnc_updateSizeMenu), and an open window is built again at the new size, on the next frame (fnc_later, fnc_buildSoon: a
 * slider's own press must not delete it) - the build forgets the cell it had (fnc_getCell, which the words follow, fnc_textScale)
 * and keeps the popover open over it (fnc_build). Nothing is built where the sizes are those the window was built with
 * (uiNamespace aio_gui_sizeBuilt, fnc_build) - the popover writing to CBA comes back here with what is shown already -, and
 * nothing at all while no window is open: the next one starts from the settings as they are (fnc_attach).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_gui_fnc_sizeChanged;
 *
 * Public: No
 */

if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};

[] call FUNC(updateSizeMenu);

private _sizes = (call FUNC(sizeDefs)) apply {missionNamespace getVariable [_x select 0, -1]};

if ((uiNamespace getVariable [QGVAR(sizeBuilt), []]) isEqualTo _sizes) exitWith {};

[{[] call FUNC(buildSoon)}] call FUNC(later);
