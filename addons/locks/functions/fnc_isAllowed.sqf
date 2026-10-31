#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit passes a lock. Members pass (the unit's group's side, or its group, or the callsign
 * of its group), logged-in admins always (fnc_isAdmin), and a game master while aio_locks_zeusOpens is
 * on - also when remote controlling a unit.
 *
 * The side is the group's, not the unit's: ACE's captives are civilians to the engine while handcuffed.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Lock, [mode, who] as fnc_getLock gives it <ARRAY>
 *
 * Return Value:
 * [allowed, how] - how is "" when not locked or refused, "member", "admin" or "zeus" <ARRAY>
 *
 * Example:
 * [player, [_crate] call aio_locks_fnc_getLock] call aio_locks_fnc_isAllowed;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_lock", [], [[]]]];

_lock params [["_mode", "", [""]], ["_who", ""]];

if (_mode isEqualTo "") exitWith {[true, ""]};
if ([_unit] call FUNC(isAdmin)) exitWith {[true, "admin"]};

// A game master - also while remote controlling a unit, which BI marks with its controller.
private _controller = _unit getVariable ["bis_fnc_moduleRemoteControl_owner", objNull];

if (!(_controller isEqualType objNull)) then {
    _controller = objNull;
};

if (GVAR(zeusOpens) && {
    !isNull getAssignedCuratorLogic _unit
    || {!isNull getAssignedCuratorLogic _controller}
}) exitWith {[true, "zeus"]};

private _member = false;

switch (_mode) do {
    case "side": {
        _member = (side group _unit) isEqualTo _who;
    };
    case "group": {
        if (_who isEqualType grpNull) then {
            _member = (group _unit) isEqualTo _who;
        } else {
            _member = (groupId group _unit) == _who;
        };
    };
};

[_member, ["", "member"] select _member]
