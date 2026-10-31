#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A machine left (mission event PlayerDisconnected - players and headless clients). The server handles
 * a machine's messages in the order they were sent, so every answer it got out has been handled: every
 * phase still waiting there did not run. Each is routed again now as the next attempt (fnc_hubRoute) -
 * to the root's new owner once the engine moved it, held while it has none, and finished with every op
 * "Moved" when the root went with the machine or found no owner within ROUTE_TIMEOUT seconds; what it
 * was to carry is then settled. Nothing is ever sent to that machine again (GVAR(gone)).
 *
 * A transaction whose requester left goes on to the end, without reach checks (its requester counts as
 * nobody now) and without an answer (fnc_hubNext): what was meant for its own containers goes to its
 * unit at the unit's new owner if the unit stays, else back where it came from, else onto the ground.
 *
 * Should that machine have run a phase whose answer was lost with the connection (R1 in the docs), the
 * phase may run twice; the RPT names every phase routed again.
 *
 * Arguments:
 * 0: Id <NUMBER>
 * 1: UID <STRING>
 * 2: Name <STRING>
 * 3: Joined in progress <BOOL>
 * 4: Owner - the machine that left <NUMBER>
 * 5: Id as a string <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_id, _uid, _name, _jip, _owner, _idstr] call aio_storage_fnc_hubDisconnect;
 *
 * Public: No
 */

params [
    ["_id", 0, [0]],
    ["_uid", "", [""]],
    ["_name", "", [""]],
    ["_jip", false, [false]],
    ["_owner", -1, [0]],
    ["_idstr", "", [""]]
];

// The server itself never leaves a running mission; ids below it are no machine.
if (!isServer || {_owner <= 2}) exitWith {};

GVAR(gone) pushBackUnique _owner;

// Its requests go on without it: no reach check from a unit nobody controls any more, no answer.
{
    private _tx = _y select 0;

    if ((_tx select 2) == _owner) then {_tx set [1, objNull]};
} forEach GVAR(hub);

private _lost = [];

{
    if ((_y select 0) == _owner) then {_lost pushBack _x};
} forEach GVAR(waiting);

private _again = [];

{
    private _key = _x;
    (GVAR(waiting) deleteAt _key) params ["", "", "_attempt", "", "", "_rootId", "_txId", "_index"];

    // That machine holds nothing of the root any more.
    private _wait = GVAR(rootWaits) getOrDefault [_rootId, []];

    if (_wait isNotEqualTo []) then {
        private _keys = _wait select 1;
        private _at = _keys find _key;

        if (_at >= 0) then {_keys deleteAt _at};
        if (_keys isEqualTo []) then {_wait set [3, diag_tickTime]};
    };

    private _entry = GVAR(hub) getOrDefault [_txId, []];

    if (_entry isNotEqualTo [] && {((_entry select 7) param [0, -1]) == _index}) then {
        WARNING_3("Machine %1 (%2) left while phase %3 waited there - routed again.",_owner,_name,_key);

        (_entry select 7) set [3, _attempt + 1];
        _again pushBack [_txId, _index];
    };
} forEach _lost;

{
    _x params ["_txId", "_index"];

    if ([_txId, _index] call FUNC(hubRoute)) then {
        [_txId] call FUNC(hubNext);
    };
} forEach _again;
