#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Picks a container as the target of quick moves (fnc_quickTarget), or lets it go when it is the one picked already: a click on a
 * free cell of its grid, on its picture beside the grid (fnc_drawSection), or on a uniform, vest or backpack slot
 * (fnc_onMouseButton). The window is built again at once (fnc_buildSoon - fnc_requestRebuild only builds when the contents
 * changed, so the outline never showed), and its picture shows the outline - or no longer.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [vestContainer player] call aio_gui_fnc_pickTarget;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container || {!(call FUNC(isInventoryMode))}) exitWith {};

GVAR(quickTarget) = [_container, objNull] select (GVAR(quickTarget) isEqualTo _container);

[] call FUNC(buildSoon);
