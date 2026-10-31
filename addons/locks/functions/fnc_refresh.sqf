#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Looks again whether the player here may open a locked object, and locks or frees the engine's own
 * inventory on this machine to match: lockInventory works on the machine that runs it only, which is
 * what makes a lock per player possible. The key, the scroll action and any script that asks the
 * engine to open the object all stop at it.
 *
 * Only ever undoes the lock this machine set itself (einv_locks_engineMine): a lock the mission set is
 * never lifted here, and never taken over. When the answer changes, the window's signature changes with
 * it (einv_locks_stamp).
 *
 * Arguments:
 * 0: Locked object, or one that was locked a moment ago <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate] call einv_locks_fnc_refresh;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

private _player = missionNamespace getVariable ["ACE_player", objNull];

if (isNull _object || {isNull _player}) exitWith {};

private _allowed = ([_player, [_object] call FUNC(getLock)] call FUNC(isAllowed)) select 0;
private _mine = _object getVariable [QGVAR(engineMine), false];

if (_allowed) then {
    if (_mine) then {
        _object lockInventory false;
        _object setVariable [QGVAR(engineMine), false];
    };
} else {
    if (!_mine && {!lockedInventory _object}) then {
        _object lockInventory true;
        _object setVariable [QGVAR(engineMine), true];
    };
};

if (_allowed isNotEqualTo (_object getVariable [QGVAR(allowedHere), true])) then {
    _object setVariable [QGVAR(allowedHere), _allowed];
    GVAR(stamp) = GVAR(stamp) + 1;
};
