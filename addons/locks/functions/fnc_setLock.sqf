#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Locks a crate's or a vehicle's inventory to one side, one group or the admins - or opens it again.
 * Runs anywhere; the server keeps the list of locked objects (aio_locks_objects, public) and tells
 * every machine, so each one locks the engine's own inventory where it has to (fnc_refresh) - also for
 * players who join later. A client only asks: the server event does the work.
 *
 * The lock is [mode, who] on the object (aio_locks_lock, public). Who passes: the members, logged-in
 * admins always, Zeus while aio_locks_zeusOpens is on (fnc_isAllowed). People cannot be locked -
 * a living person's gear has its own switch in the window's settings.
 *
 * Arguments:
 * 0: Crate or vehicle <OBJECT>
 * 1: "side", "group", "admins", or "" to open it again <STRING> (default: "")
 * 2: Who - a side for "side"; a group, or a group's callsign, for "group" <SIDE, GROUP or STRING> (default: "")
 *
 * Return Value:
 * Accepted <BOOL>
 *
 * Example:
 * [_crate, "side", west] call aio_locks_fnc_setLock;
 *
 * Public: Yes
 */

params [
    ["_object", objNull, [objNull]],
    ["_mode", "", [""]],
    ["_who", "", ["", sideUnknown, grpNull]]
];

_mode = toLowerANSI _mode;

if (isNull _object || {_object isKindOf "CAManBase"}) exitWith {
    ERROR_1("Only crates and vehicles can be locked - not %1.",_object);
    false
};

private _valid = switch (_mode) do {
    case "": {true};
    case "side": {_who isEqualType sideUnknown && {_who in [west, east, independent, civilian]}};
    case "group": {(_who isEqualType grpNull && {!isNull _who}) || {_who isEqualType "" && {_who isNotEqualTo ""}}};
    case "admins": {true};
    default {false};
};

if (!_valid) exitWith {
    ERROR_3("Cannot lock %1 with mode '%2' and %3.",_object,_mode,_who);
    false
};

// The server decides and keeps the list.
if (!isServer) exitWith {
    [QGVAR(set), [_object, _mode, _who]] call CBA_fnc_serverEvent;
    true
};

private _objects = (missionNamespace getVariable [QGVAR(objects), []]) select {!isNull _x && {_x isNotEqualTo _object}};

if (_mode isEqualTo "") then {
    _object setVariable [QGVAR(lock), nil, true];
} else {
    private _stored = _who;

    if (_mode isEqualTo "admins") then {
        _stored = "";
    };

    _object setVariable [QGVAR(lock), [_mode, _stored], true];
    _objects pushBack _object;

    // Out of the list when the object goes.
    if !(_object getVariable [QGVAR(watched), false]) then {
        _object setVariable [QGVAR(watched), true];
        _object addEventHandler ["Deleted", {
            params ["_deleted"];

            missionNamespace setVariable [QGVAR(objects), (missionNamespace getVariable [QGVAR(objects), []]) select {!isNull _x && {_x isNotEqualTo _deleted}}, true];
        }];
    };
};

// The list goes out before the event (same sender, in order), so a client handling the event has it.
missionNamespace setVariable [QGVAR(objects), _objects, true];
[QGVAR(changed), [_object]] call CBA_fnc_globalEvent;

true
