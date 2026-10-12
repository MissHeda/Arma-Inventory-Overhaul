#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What an object is locked to: the lock fnc_setLock wrote on it.
 *
 * Arguments:
 * 0: Crate or vehicle <OBJECT>
 *
 * Return Value:
 * [mode, who] - "side" with a side, "group" with a group or a callsign, "admins" with "";
 * ["", ""] when it is not locked <ARRAY>
 *
 * Example:
 * [_crate] call einv_locks_fnc_getLock;
 *
 * Public: Yes
 */

params [["_object", objNull, [objNull]]];

if (isNull _object) exitWith {["", ""]};

private _lock = _object getVariable [QGVAR(lock), []];

if (!(_lock isEqualType []) || {count _lock < 2}) exitWith {["", ""]};

_lock
