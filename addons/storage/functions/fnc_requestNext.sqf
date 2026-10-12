#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a request of this machine on as far as this machine may: the next phase whose root is local here
 * (fnc_isLocalRoot) runs at once (fnc_execute, journal key "id|phase|0", refs filled in from the results
 * so far) and comes back here; the first one that is not goes to the server's hub with the results so
 * far (einv_storage_hubStart). Once every phase ran, what is left is settled here (fnc_settle) - a step
 * that cannot run here goes to the hub as a silent transaction of its own, sent in the same frame - and
 * the request is answered (fnc_onAnswer).
 *
 * Settlement phases are appended to the transaction's phases with their step (fnc_settle) and run like
 * the others. A step for the hub is a transaction [id, requester, machine, where, phases, silent true,
 * settlement true] with the transaction's "where" - without the vehicle when it is the vehicle step, so
 * what bounces there goes to the ground instead of the vehicle once more. Its payloads travel as the
 * results of a first phase that already ran ([objNull, [["carried", []]]], produced: the payloads), and
 * its ops name them by refs: the hub's books (fnc_settle) follow refs only, so a put there that does not
 * run - its root went away, was never local - leaves its payload to the hub's own settlement instead of
 * losing it. With no hub to hand it to (fnc_hubReady: the server never answered), the vehicle is
 * skipped and the ground step runs here, onto a fresh pile of this machine's own (fnc_opPutGround).
 *
 * The answer's summary: [per phase asked for, per op [status, extra]; [went back, into the requester's
 * vehicle, onto the ground] - payloads settlement landed there, those handed to the hub counted where
 * they were sent; the first ground pile anything was put on, objNull for none].
 *
 * Arguments:
 * 0: Request id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["2:14"] call einv_storage_fnc_requestNext;
 *
 * Public: No
 */

params [["_id", "", [""]]];

private _request = GVAR(requests) getOrDefault [_id, []];

if (_request isEqualTo []) exitWith {};

_request params ["_tx", "_results", "", "", "", "_revisions", "_step", "_original", "_sent"];
_tx params ["", "_requester", "", "_where", "_phases", "_silent"];

private _index = count _results;

// The payloads earlier phases produced, copied into the args where a ref names them. A ref to nothing is
// left as it is - its op says "Skipped" (fnc_execute) -, and so is one to this very phase.
private _fnc_fill = {
    params ["_ops", "_before"];

    _ops apply {
        _x params [["_name", "", [""]], ["_args", [], [[]]]];

        [_name, _args apply {
            private _arg = _x;

            if (_arg isEqualType [] && {(_arg param [0, ""]) isEqualTo "#ref"}) then {
                _arg params ["", ["_p", -1, [0]], ["_o", -1, [0]], ["_n", -1, [0]]];

                private _payload = [];

                if (_p >= 0 && {_p < _before}) then {
                    _payload = (((_results select _p) param [_o, []]) param [1, []]) param [_n, []];
                };

                if (_payload isEqualType [] && {_payload isNotEqualTo []}) then {+_payload} else {_arg}
            } else {
                _arg
            };
        }]
    }
};

// The next phase.
if (_index < count _phases) exitWith {
    (_phases select _index) params [["_root", objNull, [objNull]], ["_ops", [], [[]]], ["_settle", 0, [0]]];

    if (
        !([_root] call FUNC(isLocalRoot))
        && {!(_settle == 3 && {!(call FUNC(hubReady))})}
    ) exitWith {
        // From here on the hub carries it: the results so far go along, and the payloads in them.
        [QGVAR(hubStart), [_tx, _results]] call CBA_fnc_serverEvent;

        // A silent one is never answered.
        if (_silent) then {
            GVAR(requests) deleteAt _id;
        };
    };

    private _key = format ["%1|%2|0", _id, _index];
    private _context = createHashMapFromArray [
        ["requester", _requester],
        ["where", _where],
        ["txId", _id],
        ["root", _root],
        ["settlement", _settle > 0],
        ["phase", _index]
    ];

    [[_ops, _index] call _fnc_fill, _context, _key, {
        params ["_results", "_revisions", "_args"];
        _args params ["_id", "_key"];

        // Only the hub ever sends a phase again - one that ran here needs no journal once it is answered.
        GVAR(journal) deleteAt _key;

        private _request = GVAR(requests) getOrDefault [_id, []];

        if (_request isEqualTo []) exitWith {};

        (_request select 1) pushBack +_results;

        // The latest revision of each holder.
        private _known = _request select 5;

        {
            _x params ["_holder", "_revision"];

            private _at = _known findIf {(_x select 0) isEqualTo _holder};

            if (_at < 0) then {
                _known pushBack [_holder, _revision];
            } else {
                _known set [_at, [_holder, _revision]];
            };
        } forEach _revisions;

        [_id] call FUNC(requestNext);
    }, [_id, _key]] call FUNC(execute);
};

// Every phase ran: what is left is settled, step by step.
private _next = false;

while {!_next && {_step < 3}} do {
    _step = _step + 1;
    _request set [6, _step];

    private _new = [_tx, _results, _step] call FUNC(settle);

    if (_new isNotEqualTo []) then {
        private _here = _new findIf {!([_x select 0] call FUNC(isLocalRoot))} < 0;

        if (_here) then {
            // As the next phases of this request.
            _phases append _new;
            _next = true;
        } else {
            if (call FUNC(hubReady)) then {
                // The hub takes it from here, as a silent transaction of its own; this request is answered
                // now. What bounces off the vehicle goes to the ground, not to the vehicle again. The
                // payloads go as what its first phase - one that already ran - produced, each op naming
                // its payload by a ref to that: the hub settles by refs, so one whose put never runs is
                // still put somewhere.
                private _carried = 0;
                private _payloads = [];
                private _handed = _new apply {
                    _x params ["_root", "_ops", ["_settle", _step]];

                    _carried = _carried + count _ops;

                    [_root, _ops apply {
                        _x params [["_name", "", [""]], ["_args", [], [[]]]];

                        [_name, _args apply {
                            private _arg = _x;

                            // A ref to what this request's phases produced: the payload joins what the
                            // first phase produced, and the ref names it there. A ref to nothing names
                            // nothing there either - the op is skipped.
                            if (_arg isEqualType [] && {(_arg param [0, ""]) isEqualTo "#ref"}) then {
                                _arg params ["", ["_p", -1, [0]], ["_o", -1, [0]], ["_n", -1, [0]]];

                                private _payload = [];

                                if (_p >= 0 && {_p < count _results}) then {
                                    _payload = (((_results select _p) param [_o, []]) param [1, []]) param [_n, []];
                                };

                                if (_payload isEqualType [] && {_payload isNotEqualTo []}) then {
                                    _payloads pushBack +_payload;
                                    ["#ref", 0, 0, count _payloads - 1]
                                } else {
                                    ["#ref", -1, -1, -1]
                                };
                            } else {
                                _arg
                            };
                        }]
                    }, _settle]
                };

                _handed = [[objNull, [["carried", []]]]] + _handed;

                private _whereThen = +_where;

                if (_step == 2) then {
                    _whereThen set [2, objNull];
                };

                private _machine = call FUNC(machineId);
                private _settleId = format ["%1:%2-%3", _machine, GVAR(session), GVAR(nextRequest)];

                GVAR(nextRequest) = GVAR(nextRequest) + 1;

                // Silent, and settlement through and through (element 6): no reach, no guards. The first
                // phase counts as run, its one op having produced the payloads.
                [QGVAR(hubStart), [
                    [_settleId, _requester, _machine, _whereThen, _handed, true, true],
                    [[["", _payloads, []]]]
                ]] call CBA_fnc_serverEvent;

                _sent set [_step - 1, (_sent select (_step - 1)) + _carried];
                _step = 3;
                _request set [6, _step];
            } else {
                // No hub to hand it to: the vehicle is out of this machine's hands, the ground right here
                // is not (fnc_opPutGround).
                if (_step == 3) then {
                    _phases append _new;
                    _next = true;
                };
            };
        };
    };
};

if (_next) exitWith {
    [_id] call FUNC(requestNext);
};

// Answered: per phase asked for, per op its status and what it tells; what settlement did; the pile.
private _perPhase = [];

for "_p" from 0 to (_original - 1) do {
    _perPhase pushBack ((_results param [_p, []]) apply {[_x param [0, "Failed"], _x param [2, []]]});
};

private _counts = +_sent;
private _pile = objNull;

{
    private _phase = _phases param [_forEachIndex, []];
    private _settle = _phase param [2, 0];
    private _ops = _phase param [1, []];

    {
        _x params [["_status", "Failed"], "", ["_extra", []]];

        if (_status isEqualTo "") then {
            if (_settle isEqualType 0 && {_settle in [1, 2, 3]}) then {
                _counts set [_settle - 1, (_counts select (_settle - 1)) + 1];
            };

            if (isNull _pile && {((_ops param [_forEachIndex, []]) param [0, ""]) isEqualTo "putGround"} && {_extra isEqualType []}) then {
                private _onto = _extra param [0, objNull];

                if (_onto isEqualType objNull) then {
                    _pile = _onto;
                };
            };
        };
    } forEach _x;
} forEach _results;

if (_silent) exitWith {
    GVAR(requests) deleteAt _id;
};

[_id, [_perPhase, _counts, _pile], _revisions] call FUNC(onAnswer);
