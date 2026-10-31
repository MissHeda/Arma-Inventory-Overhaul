#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Drives a transaction on at the server, from the first phase without results: its refs filled in from
 * the results (copied), and routed (fnc_hubRoute) - the transaction then waits until that phase is
 * answered (fnc_hubPhaseDone), unless the route finished it at once ("Moved"). An op whose input was
 * never produced is "Skipped" here and not sent at all; a phase of nothing but such ops is not sent
 * either.
 *
 * After the request's own phases come the settlement steps 1-3 (fnc_settle): each step's phases are
 * added to the transaction and its results, and run like any other, so the next step sees what the
 * earlier ones did. After the last step the requester's machine gets the answer (aio_storage_answer -
 * not for a silent transaction, nor when that machine left) and the transaction is forgotten.
 *
 * Answer: [id, summary, revisions] - summary [per own phase per op [status, extra], [went back, into
 * the requester's vehicle, onto the ground] - payloads settlement put there, the ground pile something
 * was put on or objNull] (aio_storage_fnc_onAnswer).
 *
 * Arguments:
 * 0: Request id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["2:14"] call aio_storage_fnc_hubNext;
 *
 * Public: No
 */

params [["_id", "", [""]]];

if (!isServer) exitWith {};

private _entry = GVAR(hub) getOrDefault [_id, []];

if (_entry isEqualTo []) exitWith {};

_entry params ["_tx", "_results", "", "_step", "_revisions", "_own", "_info"];

private _phases = _tx select 4;

// [ops to send, op map]: the phase's ops with every ref to an earlier phase replaced by a copy of the
// payload it names - the hub keeps the original for settlement, and the machine that runs the phase
// has no results of its own. Refs within the phase stay refs for that machine to fill in as it goes,
// renumbered past the ops left out. The op map gives per op its index among the ops sent, -1 for one
// left out as "Skipped": an input it needed never came (its producer failed, or nothing came off a
// slot), or it needs what such an op would have made.
private _fnc_fill = {
    params ["_ops", "_index"];

    private _send = [];
    private _map = [];

    {
        private _op = _x;
        private _args = _op param [1, [], [[]]];
        private _skip = !(_op isEqualType []) || {!((_op param [0, 0]) isEqualType "")};

        private _filled = _args apply {
            private _arg = _x;

            if (
                !_skip
                && {_arg isEqualType []}
                && {count _arg == 4}
                && {(_arg select 0) isEqualTo "#ref"}
            ) then {
                _arg params ["", ["_phase", -1, [0]], ["_opIndex", -1, [0]], ["_n", -1, [0]]];

                if (_phase < 0 || {_opIndex < 0} || {_n < 0}) then {
                    _skip = true;
                    _arg
                } else {
                    if (_phase == _index) then {
                        private _sent = _map param [_opIndex, -1];

                        if (_sent < 0) then {
                            _skip = true;
                            _arg
                        } else {
                            ["#ref", _phase, _sent, _n]
                        };
                    } else {
                        private _produced = ((_results param [_phase, []]) param [_opIndex, []]) param [1, [], [[]]];
                        private _payload = _produced param [_n, [], [[]]];

                        if (_payload isEqualTo []) then {
                            _skip = true;
                            _arg
                        } else {
                            +_payload
                        };
                    };
                };
            } else {
                _arg
            };
        };

        if (_skip) then {
            _map pushBack -1;
        } else {
            _map pushBack (count _send);
            _send pushBack [_op select 0, _filled];
        };
    } forEach _ops;

    [_send, _map]
};

private _done = false;

while {!_done} do {
    // Phases run one after the other, so the results hold exactly the phases that finished.
    private _index = count _results;

    if (_index < count _phases) then {
        private _ops = (_phases select _index) param [1, [], [[]]];

        ([_ops, _index] call _fnc_fill) params ["_send", "_map"];

        if (_send isEqualTo []) then {
            _results pushBack (_map apply {["Skipped", [], []]});
        } else {
            // Settlement phases skip reach and guards wherever they run: the system puts things back.
            private _settlement = ((_info select _index) select 0) > 0 || {_tx param [6, false, [false]]};

            _entry set [2, _index];
            _entry set [7, [_index, _send, _map, 0, _settlement]];

            // On its way - or held - until answered. Finished at once ("Moved"): go on.
            _done = !([_id, _index] call FUNC(hubRoute));
        };
    } else {
        if (_step < 3) then {
            _step = _step + 1;
            _entry set [3, _step];

            private _new = [_tx, _results, _step] call FUNC(settle);

            if (!(_new isEqualType [])) then {_new = []};

            {
                if (
                    _x isEqualType []
                    && {(_x param [0, 0]) isEqualType objNull}
                    && {(_x param [1, 0]) isEqualType []}
                ) then {
                    _phases pushBack (+_x);
                    _info pushBack [_step, !isNull (_x select 0)];
                } else {
                    ERROR_2("Transaction %1: settlement step %2 made a broken phase - left out.",_id,_step);
                };
            } forEach _new;
        } else {
            _done = true;

            // What the window needs to tell the player: how each of its own ops ended, how many payloads
            // settlement put back, into the vehicle or onto the ground, and the pile it may adopt.
            private _perPhase = [];

            for "_index" from 0 to (_own - 1) do {
                _perPhase pushBack ((_results param [_index, []]) apply {
                    [_x param [0, "Failed", [""]], _x param [2, []]]
                });
            };

            private _counts = [0, 0, 0];
            private _pile = objNull;
            private _lost = 0;

            {
                private _phaseIndex = _forEachIndex;
                private _phaseStep = (_info param [_phaseIndex, [0, true]]) select 0;
                private _ops = (_phases param [_phaseIndex, []]) param [1, [], [[]]];

                {
                    private _status = _x param [0, "Failed", [""]];

                    if (_status isEqualTo "") then {
                        if (_phaseStep > 0) then {
                            _counts set [_phaseStep - 1, (_counts select (_phaseStep - 1)) + 1];
                        };

                        if (isNull _pile && {((_ops param [_forEachIndex, []]) param [0, ""]) isEqualTo "putGround"}) then {
                            _pile = (_x param [2, [], [[]]]) param [0, objNull, [objNull]];
                        };
                    } else {
                        // "Skipped" carried nothing; anything else at the ground step stays nowhere.
                        if (_phaseStep == 3 && {_status isNotEqualTo "Skipped"}) then {_lost = _lost + 1};
                    };
                } forEach _x;
            } forEach _results;

            if (_lost > 0) then {
                ERROR_2("Transaction %1: %2 payloads could not even be put on the ground - see the errors above.",_id,_lost);
            };

            private _requesterOwner = _tx select 2;

            if (!(_tx select 5) && {_requesterOwner >= 2} && {!(_requesterOwner in GVAR(gone))}) then {
                [QGVAR(answer), [_id, [_perPhase, _counts, _pile], _revisions], _requesterOwner] call CBA_fnc_ownerEvent;
            };

            GVAR(hub) deleteAt _id;
        };
    };
};
