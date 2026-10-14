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
 * A backpack that went onto a pile alone is looked at again a frame later: should that pile be gone, it
 * goes down once more onto a fresh one (an RPT error says so; see below).
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

// A backpack onto a pile that holds nothing yet: the pile it lands on is looked at again a frame later
// (below).
private _alone = (_payload param [0, ""]) isEqualTo "backpack" && {([_pile] call FUNC(getContents)) isEqualTo []};

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
            "einv drop: %1 %2 - piles %3, gone %4, backpacks there %5, at %6",
            _txId, _when, _piles, _piles apply {isNull _x}, _piles apply {if (isNull _x) then {[]} else {everyBackpack _x}},
            _piles apply {if (isNull _x) then {[]} else {getPosASL _x}}
        ];
    };

    [_fnc_look, [_txId, _piles, "a frame later"]] call FUNC(nextFrame);
    [_fnc_look, [_txId, _piles, "two seconds later"], 2] call CBA_fnc_waitAndExecute;
};

// The pile a backpack went onto alone (a fresh one, or the second) is looked at again a frame later. A
// backpack dragged out of the window left no pile in the window and nothing on the ground (Mia, 0.4.0),
// where a vest dropped the same way did. In a pile a backpack is an object of its own, not item cargo,
// and the engine deletes the piles it takes for empty. Gone by then, the backpack went with it: it goes
// down once more onto a fresh pile at the same point and the RPT says so - once only, a second loss is
// reported. A pile still there is left alone: a backpack taken from it is whoever took it.
if (_rest isEqualTo [] && {(_payload param [0, ""]) isEqualTo "backpack"} && {_alone || {count _piles > 1}}) then {
    [{
        params ["_pile", "_payload", "_where", "_requester", "_txId"];

        if (!isNull _pile) exitWith {};

        private _class = _payload param [1, ""];

        ERROR_2("The pile %1 went onto was gone a frame later - it is put down again (%2).",_class,_txId);

        private _again = [_where, _requester, true] call FUNC(getGroundHolder);

        if (isNull _again && {!isNull _requester}) then {
            _again = [_requester, _requester, true] call FUNC(getGroundHolder);
        };

        private _left = if (isNull _again) then {_payload} else {[_again, _payload] call FUNC(addPayload)};

        if (DROP_DEBUG) then {
            diag_log text format [
                "einv drop: %1 a frame later the pile was gone - put down again on %2 at %3, left over %4",
                _txId, _again, if (isNull _again) then {[]} else {getPosASL _again}, [_left param [0, ""], _left param [1, ""]]
            ];
        };

        if (isNull _again || {_left isNotEqualTo []}) exitWith {
            ERROR_1("%1 could not be put down again - it is lost.",_class);
        };

        [{
            params ["_again", "_class", "_txId"];

            if (isNull _again) then {
                ERROR_2("The second pile %1 went onto was gone a frame later as well - it is lost (%2).",_class,_txId);
            };
        }, [_again, _class, _txId]] call FUNC(nextFrame);
    }, [_piles select (count _piles - 1), +_payload, _where, _requester, _txId]] call FUNC(nextFrame);
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
