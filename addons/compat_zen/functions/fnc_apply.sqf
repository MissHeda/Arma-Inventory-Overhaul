#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Locks the objects the Zeus menu or the module chose - or opens them again - and tells the game master
 * what was done. Mode "pick" asks which group first (fnc_groupDialog). The lock itself is
 * aio_locks_fnc_setLock, which from a client goes to the server.
 *
 * Arguments:
 * 0: Objects <ARRAY of OBJECTs>
 * 1: "side", "group", "admins", "" for open again, or "pick" for a group to be chosen <STRING>
 * 2: Who - a side or a group <SIDE, GROUP or STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [[_crate], "side", east] call aio_compat_zen_fnc_apply;
 *
 * Public: No
 */

params [["_objects", [], [[]]], ["_mode", "", [""]], ["_who", ""]];

if (_objects isEqualTo []) exitWith {};

if (_mode isEqualTo "pick") exitWith {
    [_objects] call FUNC(groupDialog);
};

{
    [_x, _mode, _who] call EFUNC(locks,setLock);
} forEach _objects;

// Said in the game master's own corner of the screen, the way Zeus says its own results.
private _text = LLSTRING(Feedback_Open);

if (_mode isNotEqualTo "") then {
    _text = format [LLSTRING(Feedback_Locked), [[_mode, _who]] call EFUNC(locks,describe)];
};

[objNull, _text] call BIS_fnc_showCuratorFeedbackMessage;
