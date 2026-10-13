#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "putGround", on the server (root objNull): a payload onto the ground at the transaction's ground
 * point (fnc_getGroundHolder with its "where", in sight from the requester's eyes) - the nearest
 * non-empty server-local pile within GROUND_RANGE, else a fresh one; a rest into a second fresh pile at
 * the same point. What even that would not take bounces (an RPT error names it) - settled like any
 * bounce, back where it came from. Never into an empty pile, never in the air; first fit on the pile -
 * the end of the phase lays it out and writes it (einv_storage_fnc_execute).
 *
 * A client runs it only when it could not hand it to the hub (einv_storage_fnc_requestNext: the server
 * never answered): then onto a fresh pile of its own.
 *
 * Extra: [the pile it went onto, the second pile when it took a rest].
 *
 * Arguments:
 * 0: Args, [payload or ref] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done, else why not ("Gone", "Taken", "NoRoom", "NotLocal", "Moved",
 *     "IntoItself", "OutOfReach", "Bounced", "Skipped", "Failed", a guard's reason or a reason already
 *     in words)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (einv_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[_payload], _context] call einv_storage_fnc_opPutGround;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_payload", [], [[]]]];

if (_payload isEqualTo []) exitWith {["Skipped", [], []]};

private _where = _context getOrDefault ["where", []];
private _requester = _context getOrDefault ["requester", objNull];
private _debug = (_payload param [0, ""]) isEqualTo "backpack" && {DROP_DEBUG};
private _txId = _context getOrDefault ["txId", ""];

// The piles it may join are the server's own; a client cut off from the hub makes one of its own.
private _fresh = isMultiplayer && {!isServer};
private _pile = [_where, _requester, _fresh] call FUNC(getGroundHolder);

// Not even a position to put it at (a request made with no unit): where the requester stands now.
if (isNull _pile && {!isNull _requester}) then {
    _pile = [_requester, _requester, _fresh] call FUNC(getGroundHolder);
};

if (isNull _pile) exitWith {
    ERROR_1("Nowhere on the ground to put %1 - it goes back.",_payload);

    if (_debug) then {
        diag_log text format ["einv drop: %1 putGround on %2 - no pile, ground point %3, bounced", _txId, clientOwner, _where param [0, []]];
    };

    ["Bounced", [+_payload], []]
};

if (_debug) then {
    diag_log text format [
        "einv drop: %1 putGround %2 on %3 - pile %4 (%5, netId %6, local %7) at %8, ground point %9, held before %10",
        _txId, _payload param [1, ""], clientOwner, _pile, typeOf _pile, netId _pile, local _pile, getPosASL _pile,
        _where param [0, []], count ([_pile] call FUNC(getContents))
    ];
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

// Logged now, a frame later and two seconds later: whether the pile and the backpack in it are still
// there - an engine that dropped a fresh pile it thought empty would show here and nowhere else.
if (_debug) then {
    diag_log text format [
        "einv drop: %1 putGround done - left over %2, piles %3, backpacks there %4",
        _txId, [_rest param [0, ""], _rest param [1, ""]], _piles, _piles apply {everyBackpack _x}
    ];

    private _fnc_look = {
        params ["_txId", "_piles", "_when"];

        diag_log text format [
            "einv drop: %1 %2 - piles %3, gone %4, backpacks there %5",
            _txId, _when, _piles, _piles apply {isNull _x}, _piles apply {if (isNull _x) then {[]} else {everyBackpack _x}}
        ];
    };

    [_fnc_look, [_txId, _piles, "a frame later"]] call FUNC(nextFrame);
    [_fnc_look, [_txId, _piles, "two seconds later"], 2] call CBA_fnc_waitAndExecute;
};

if (_rest isNotEqualTo []) exitWith {
    ERROR_1("Could not put %1 on the ground - it goes back.",_rest);

    if (_rest isNotEqualTo _payload) then {
        ["in", _payload] call FUNC(journalNote);
        ["out", _rest] call FUNC(journalNote);
    };

    ["Bounced", [+_rest], _piles]
};

["in", _payload] call FUNC(journalNote);

["", [], _piles]
