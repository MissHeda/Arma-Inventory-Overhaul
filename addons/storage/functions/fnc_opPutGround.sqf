#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "putGround", on the server (root objNull): a payload onto the ground at the transaction's ground
 * point (fnc_getGroundHolder with its "where", in sight from the requester's eyes) - the nearest
 * non-empty server-local pile within GROUND_RANGE, else a fresh one; a rest into a second fresh pile at
 * the same point. What even that would not take bounces (an RPT error names it) - settled like any
 * bounce, back where it came from. Never into an empty pile, never in the air; first fit on the pile -
 * the end of the phase lays it out and writes it (einv_storage_fnc_execute). A fresh pile that took
 * nothing is deleted again (fnc_pruneScriptedPile).
 *
 * A client runs it only when it could not hand it to the hub (einv_storage_fnc_requestNext: the server
 * never answered): then onto a fresh pile of its own.
 *
 * The pile a backpack went onto is looked at again a frame later and the RPT says what is there. One that
 * went onto a pile alone, should that pile be gone, goes down once more onto a fresh one (an RPT error
 * says so; see below).
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

if ((_payload param [0, ""]) isEqualTo "backpack") then {
    private _bagClass = _payload param [1, ""];

    INFO_4("Backpack %1 goes onto pile %2 (%3) at frame %4",_bagClass,netId _pile,typeOf _pile,diag_frameNo);
    private _items = (getItemCargo _pile) param [0, []];
    private _held = count ([_pile] call FUNC(getContents));

    INFO_3("  ... pile holds backpacks %1, items %2, contents %3",everyBackpack _pile,_items,_held);
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
            "einv drop: %1 %2 - piles %3, gone %4, backpacks there %5, at %6",
            _txId, _when, _piles, _piles apply {isNull _x}, _piles apply {if (isNull _x) then {[]} else {everyBackpack _x}},
            _piles apply {if (isNull _x) then {[]} else {getPosASL _x}}
        ];
    };

    [_fnc_look, [_txId, _piles, "a frame later"]] call FUNC(nextFrame);
    [_fnc_look, [_txId, _piles, "two seconds later"], 2] call CBA_fnc_waitAndExecute;
};

// The pile a backpack went onto is looked at again a frame later and the RPT says what is there - always,
// not only with einv_storage_debugDrop. A backpack dragged out of the window left no pile in the window and
// nothing on the ground (Mia, 0.4.0), where a vest dropped the same way did. In a pile a backpack is an
// object of its own, not item cargo, and the engine deletes an ordinary pile it takes for empty. The piles
// are GroundWeaponHolder_Scripted now (fnc_getGroundHolder), which the engine leaves alone, so what follows
// is the net under that: a backpack that went onto a pile alone (a fresh one, or the second) and finds it
// gone a frame later went with it - it goes down once more onto a fresh pile at the same point and the RPT
// says so - once only, a second loss is reported. A pile still there is left alone: a backpack taken from
// it is whoever took it.
if (_rest isEqualTo [] && {(_payload param [0, ""]) isEqualTo "backpack"}) then {
    private _last = _piles select (count _piles - 1);

    [{
        params ["_pile", "_netId", "_payload", "_where", "_requester", "_txId", "_putAgain"];

        private _class = _payload param [1, ""];
        private _state = if (isNull _pile) then {"gone"} else {
            format ["there with %1 backpacks", count (everyBackpack _pile)]
        };

        INFO_3("Backpack %1 on pile %2 a frame later: pile %3",_class,_netId,_state);

        // Only looked at again, no second put-down: a pile that is there a frame later and gone after that
        // is something else's doing, and the RPT is where it shows.
        [{
            params ["_pile", "_netId", "_class"];

            private _state = if (isNull _pile) then {"gone"} else {
                format ["there with %1 backpacks", count (everyBackpack _pile)]
            };

            INFO_3("Backpack %1 on pile %2 two seconds later: pile %3",_class,_netId,_state);
        }, [_pile, _netId, _class], 2] call CBA_fnc_waitAndExecute;

        if (!_putAgain || {!isNull _pile}) exitWith {};

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
    }, [_last, netId _last, +_payload, _where, _requester, _txId, _alone || {count _piles > 1}]] call FUNC(nextFrame);
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

["", [], _piles]
