#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Looks at the units whose cargo changed (fnc_queueMigrate) once their wait is over: at most
 * MIGRATE_PER_TICK of them each time, each taken out of the list before it is looked at, so a script error
 * in one of them costs that one unit's look and not the others'. A unit under an open arsenal waits
 * MIGRATE_WAIT seconds more (ARSENAL_OPEN); the arsenals leave the cargo to themselves and ask again when
 * they are closed.
 *
 * An empty list costs one comparison, which is all this does on a machine where nothing changes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_storage_fnc_tickMigrate;
 *
 * Public: No
 */

if (GVAR(migrateDue) isEqualTo []) exitWith {};

private _now = diag_tickTime;

for "_n" from 1 to MIGRATE_PER_TICK do {
    private _index = GVAR(migrateDue) findIf {(_x select 1) <= _now};

    if (_index < 0) exitWith {};

    (GVAR(migrateDue) deleteAt _index) params ["_unit", "", "_tries", "_requester"];

    if (isNull _unit) then {continue};

    // Under an open arsenal the surplus waits and the unit is looked at again (fnc_requestMigrate asks only
    // for Strict mode's holder then, which gives everything back for the arsenal).
    if (ARSENAL_OPEN) then {
        [_unit, MIGRATE_WAIT, _tries, _requester] call FUNC(queueMigrate);
    };

    [_unit, _requester, _tries] call FUNC(requestMigrate);
};
