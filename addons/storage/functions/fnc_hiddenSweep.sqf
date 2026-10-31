#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes every unit local here that carries a hidden holder for a look at its surplus and its holder
 * (fnc_queueMigrate -> fnc_requestMigrate -> op "strict"), bodies included: the net under everything no
 * event tells about. A player who left and whose unit stays as an AI, a Zeus who let a unit go, a setting
 * switched away from Strict, a body whose death this machine did not see, a holder a crashed phase left
 * half settled - each is found within STRICT_SWEEP seconds and put right by the unit's owner. A unit without
 * a holder costs one variable read; a machine without such units costs the walk over allUnits.
 *
 * Run every STRICT_SWEEP seconds (XEH_postInit) and when a setting changes (fnc_useRefresh). Nothing in Eden.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * How many units were noted <NUMBER>
 *
 * Example:
 * [] call aio_storage_fnc_hiddenSweep;
 *
 * Public: No
 */

if (is3DEN) exitWith {0};

private _noted = 0;

{
    if (local _x && {!isNil {_x getVariable QGVAR(hidden)}}) then {
        [_x] call FUNC(queueMigrate);
        _noted = _noted + 1;
    };
} forEach (allUnits + allDeadMen);

_noted
