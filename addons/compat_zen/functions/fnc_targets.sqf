#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the Zeus menu's lock choices act on: the entity under the mouse when it is a crate or a vehicle,
 * else the selected ones that are. Lockable is anything that holds cargo and is no person (a person's
 * gear has its own switch in the window's settings).
 *
 * Arguments:
 * 0: Selected objects <ARRAY of OBJECTs> (default: [])
 * 1: Entity under the mouse - an object, a group, a waypoint, a marker or nothing <ANY> (default: objNull)
 *
 * Return Value:
 * Lockable objects <ARRAY of OBJECTs>
 *
 * Example:
 * [_selected, _hovered] call aio_compat_zen_fnc_targets;
 *
 * Public: No
 */

params [["_objects", [], [[]]], ["_hovered", objNull]];

private _fnc_lockable = {
    params ["_entity"];

    _entity isEqualType objNull && {!isNull _entity} && {!(_entity isKindOf "CAManBase")} && {maxLoad _entity > 0}
};

if ([_hovered] call _fnc_lockable) exitWith {[_hovered]};

_objects select {[_x] call _fnc_lockable}
