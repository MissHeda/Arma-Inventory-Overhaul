#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Sends the phase a transaction waits for to its root's authority, one machine per root at a time
 * (GVAR(rootWaits)): a phase on objNull - the server's ground work - and on the server's own roots runs
 * here; any other goes to the root's owner (aio_storage_runPhase [id, phase, attempt, root, ops,
 * requester, where, settlement]). It is held (GVAR(held)) while another machine still holds phases of
 * that root it was sent, for LOCALITY_SETTLE seconds after the root changed owner - the engine tells the
 * old and the new owner separately, so for a moment both can see it local -, and while the owner is a
 * machine that left. A root that went away meanwhile, or whose owner left and that found no new one
 * within ROUTE_TIMEOUT seconds, finishes the phase at once: every op "Moved", nothing ran, and
 * settlement returns whatever the phase was to carry - an op that never ran consumed nothing.
 *
 * What a phase carries stays in the hub's books until it is answered (GVAR(waiting)): the escrow.
 *
 * Arguments:
 * 0: Request id <STRING>
 * 1: Phase index <NUMBER>
 *
 * Return Value:
 * Finished at once - the caller drives the transaction on (fnc_hubNext) <BOOL>
 *
 * Example:
 * ["2:14", 1] call aio_storage_fnc_hubRoute;
 *
 * Public: No
 */

params [["_id", "", [""]], ["_index", 0, [0]]];

if (!isServer) exitWith {false};

private _key = format ["%1|%2", _id, _index];
private _entry = GVAR(hub) getOrDefault [_id, []];

// A late look at a transaction that finished or moved on: nothing to route any more.
if (_entry isEqualTo [] || {count (_entry select 1) != _index} || {((_entry select 7) param [0, -1]) != _index}) exitWith {
    GVAR(held) deleteAt _key;
    false
};

_entry params ["_tx", "_results", "", "", "", "", "_info", "_current"];
_current params ["", "_send", "_map", "_attempt", "_settlement"];

private _root = ((_tx select 4) select _index) select 0;
private _now = diag_tickTime;

// Held before: the first hold counts for ROUTE_TIMEOUT.
private _heldSince = (GVAR(held) getOrDefault [_key, []]) param [2, _now];

private _fnc_hold = {
    params ["_retryAt", "_reason"];

    GVAR(held) set [_key, [_attempt, _retryAt, _heldSince, _reason, _id, _index]];
    false
};

private _fnc_moved = {
    GVAR(held) deleteAt _key;
    _results pushBack (_map apply {[["Moved", [], []], ["Skipped", [], []]] select (_x < 0)});
    true
};

private _fnc_send = {
    params ["_owner", "_rootId"];

    GVAR(held) deleteAt _key;
    GVAR(waiting) set [_key, [_owner, _root, _attempt, _send, _now, _rootId, _id, _index]];

    // A copy: the machine that runs it fills in its own refs, and the hub keeps the ops for a re-send.
    // To the server itself CBA raises the event in-process.
    [QGVAR(runPhase), [_id, _index, _attempt, _root, +_send, _tx select 1, _tx select 3, _settlement], _owner] call CBA_fnc_ownerEvent;
    false
};

// objNull from the start: the server's own work, nobody else can hold it.
if (!(((_info select _index) select 1))) exitWith {
    [2, ""] call _fnc_send
};

// The root went away meanwhile - a pile emptied by someone else, a body cleaned up. Nothing of the
// phase can run; what it was to carry is settled.
if (isNull _root) exitWith {
    call _fnc_moved
};

// The owner as the server knows it decides; one local here runs here.
private _owner = owner _root;
if (local _root) then {_owner = 2};

private _rootId = netId _root;
private _wait = GVAR(rootWaits) getOrDefault [_rootId, []];

if (_wait isEqualTo []) then {
    _wait = [_owner, [], 0, _now];
    GVAR(rootWaits) set [_rootId, _wait];
};

_wait params ["_waitOwner", "_keys", "_changedAt"];

private _result = false;

switch (true) do {
    // Another machine still holds phases of this root: wait for its answers, so the old and the new
    // owner never both hold work for it (fnc_hubPhaseDone re-routes as soon as the last one came).
    case (_keys isNotEqualTo [] && {_waitOwner != _owner}): {
        _result = [_now + HUB_TICK, "root"] call _fnc_hold;
    };

    // A new owner: its first phase a moment later, once it surely knows it is the owner and the old
    // owner's last changes reached it.
    case (_waitOwner != _owner): {
        GVAR(rootWaits) set [_rootId, [_owner, [], _now, _now]];
        _result = [_now + LOCALITY_SETTLE, "time"] call _fnc_hold;
    };

    case (_now < _changedAt + LOCALITY_SETTLE): {
        _result = [_changedAt + LOCALITY_SETTLE, "time"] call _fnc_hold;
    };

    // The owner left and the engine has not handed the root to anyone yet.
    case (_owner in GVAR(gone)): {
        if (_now - _heldSince >= ROUTE_TIMEOUT) then {
            WARNING_2("Phase %1: machine %2 left and its container found no new owner - put back.",_key,_owner);
            _result = call _fnc_moved;
        } else {
            _result = [_now + HUB_TICK, "gone"] call _fnc_hold;
        };
    };

    default {
        _keys pushBack _key;
        _wait set [3, _now];
        _result = [_owner, _rootId] call _fnc_send;
    };
};

_result
