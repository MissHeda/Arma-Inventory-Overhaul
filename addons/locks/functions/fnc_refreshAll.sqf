#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * fnc_refresh for every locked object (aio_locks_objects): what a joining player received with the
 * mission's variables, and - once a second - whatever changed about the player since: side, group, admin
 * login, Zeus, respawn.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_locks_fnc_refreshAll;
 *
 * Public: No
 */

{
    [_x] call FUNC(refresh);
} forEach (missionNamespace getVariable [QGVAR(objects), []]);
