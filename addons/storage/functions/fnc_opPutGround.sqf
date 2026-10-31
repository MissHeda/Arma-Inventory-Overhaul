#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "putGround", on the server (root objNull): a payload onto the ground at the transaction's ground
 * point (fnc_getGroundHolder with its "where", in sight from the requester's eyes) - the nearest
 * non-empty server-local pile within GROUND_RANGE, else a fresh one; a rest into a second fresh pile at
 * the same point. What even that would not take bounces (an RPT error names it) - settled like any
 * bounce, back where it came from. Never into an empty pile, never in the air; first fit on the pile -
 * the end of the phase lays it out and writes it (aio_storage_fnc_execute). A fresh pile that took
 * nothing is deleted again (fnc_pruneScriptedPile).
 *
 * A client runs it only when it could not hand it to the hub (aio_storage_fnc_requestNext: the server
 * never answered): then onto a fresh pile of its own.
 *
 * A backpack joins only a pile of ours (a GroundWeaponHolder_Scripted) or a fresh one - the plain holder
 * the engine keeps a backpack just taken off in is gone at the end of the frame (fnc_getGroundHolder) -,
 * and the RPT names the pile it goes onto.
 *
 * Extra: [the pile it went onto, the second pile when it took a rest].
 *
 * Event "aio_storage_groundPut" (local, on this machine) when it landed: [requester, payload, piles]. The
 * engine's "Put" event never comes for a drop through the storage.
 *
 * Arguments:
 * 0: Args, [payload or ref] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (aio_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Taken", "NoRoom", "NotLocal", "Moved",
 *     "IntoItself", "OutOfReach", "Bounced", "Skipped", "Failed", a guard's reason or a reason already
 *     in words)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (aio_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[_payload], _context] call aio_storage_fnc_opPutGround;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_payload", [], [[]]]];

if (_payload isEqualTo []) exitWith {["Skipped", [], []]};

private _where = _context getOrDefault ["where", []];
private _requester = _context getOrDefault ["requester", objNull];

// The piles it may join are the server's own; a client cut off from the hub makes one of its own.
private _fresh = isMultiplayer && {!isServer};

// A backpack joins only a pile of ours: the plain holder the engine keeps a backpack just taken off in
// looks like a pile with something in it and is gone at the end of the frame (fnc_getGroundHolder).
private _ownOnly = (_payload param [0, ""]) isEqualTo "backpack";
private _pile = [_where, _requester, _fresh, _ownOnly] call FUNC(getGroundHolder);

// Not even a position to put it at (a request made with no unit): where the requester stands now.
if (isNull _pile && {!isNull _requester}) then {
    _pile = [_requester, _requester, _fresh, _ownOnly] call FUNC(getGroundHolder);
};

if (isNull _pile) exitWith {
    ERROR_1("Nowhere on the ground to put %1 - it goes back.",_payload);

    ["Bounced", [+_payload], []]
};

if ((_payload param [0, ""]) isEqualTo "backpack") then {
    private _bagClass = _payload param [1, ""];

    INFO_2("Backpack %1 goes onto pile %2",_bagClass,netId _pile);
};

private _piles = [_pile];
private _rest = [_pile, _payload] call FUNC(addPayload);

if (isNil "_rest" || {!(_rest isEqualType [])}) then {
    _rest = [];
};

if (_rest isNotEqualTo []) then {
    // What that pile would not take goes onto a second, fresh one at the same point.
    private _second = [_where, _requester, true] call FUNC(getGroundHolder);

    if (!isNull _second) then {
        _piles pushBack _second;
        _rest = [_second, _rest] call FUNC(addPayload);

        if (isNil "_rest" || {!(_rest isEqualType [])}) then {
            _rest = [];
        };
    };
};

if (_rest isNotEqualTo []) exitWith {
    ERROR_1("Could not put %1 on the ground - it goes back.",_rest);

    // A fresh pile that took nothing is an empty scripted one now, which the engine no longer deletes.
    {
        [_x] call FUNC(pruneScriptedPile);
    } forEach _piles;

    if (_rest isNotEqualTo _payload) then {
        ["in", _payload] call FUNC(journalNote);
        ["out", _rest] call FUNC(journalNote);
    };

    ["Bounced", [+_rest], _piles]
};

["in", _payload] call FUNC(journalNote);

// For addons that answer a drop on the ground the way the engine's "Put" event would have (compat_mavic).
[QGVAR(groundPut), [_requester, _payload, _piles]] call CBA_fnc_localEvent;

["", [], _piles]
