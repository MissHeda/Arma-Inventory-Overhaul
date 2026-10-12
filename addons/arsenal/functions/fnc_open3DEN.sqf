#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Eden's right click menu on a unit, Arsenal > Enhanced Arsenal: opens the window on that entity at once -
 * Eden has no frame to wait for. Should the window not open, ACE's own Arsenal opens for the same entity,
 * so the menu entry is never a dead end.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_open3DEN;
 *
 * Public: No
 */

// The entity the menu was opened on (the same place ACE's open3DEN reads).
private _entity = (uiNamespace getVariable ["BIS_fnc_3DENEntityMenu_data", []]) param [1, objNull];

if ([_entity, _entity, true, nil, findDisplay 313, "eden"] call FUNC(openWindow)) exitWith {true};

call ACEFUNC(arsenal,open3DEN);

false
