#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The next step of settling what a transaction produced and nothing consumed - its consumer failed, was
 * skipped, bounced with a rest or never existed -, built by whoever drives the transaction, the hub or
 * the requester. Each step's phases run like any other; the next step looks at what is still left.
 *
 * Step 1, back where it came from: one phase per origin root, a put without a cell (into a holder of
 * another type with that type's "put" op, GVAR(holderTypes)); what came off a slot (op takeOff) goes
 * back on that slot (op putOn) while the slot is still empty - a backpack whose drop went wrong is on
 * the back again rather than nowhere -, else it waits for step 2. Step 2, the requester's vehicle, when
 * alive: a forced put, room not asked. Step 3, the ground: putGround at the server, at the
 * transaction's ground point, else the terrain under the requester. Settlement phases skip reach and
 * guards: the system puts things back.
 *
 * The books: a payload is the n-th one an op produced, named by its ref ["#ref", phase, op, n]; an op
 * that landed ("") or bounced ("Bounced") consumed every ref among its arguments - what bounced is a
 * payload of its own, produced by that op, and inherits the origin of what it was given. Where a payload
 * came from: the holder a take or move (also a holder type's "take" and "move" op) took it out of, at
 * that phase's root; for a takeOff the unit and slot, [unit, slot], at the unit. So the transaction's
 * phases must keep their refs - a driver fills the refs in a copy of each phase it runs - and the phases
 * of each step are appended to the transaction's phases, their results to the results: a step's ops hold
 * refs as well, filled in like any other.
 *
 * Arguments:
 * 0: Transaction, [id, requester, requester's machine, where, phases, silent] <ARRAY>
 * 1: Results so far, per phase the results of its ops <ARRAY>
 * 2: Step - 1 the origin, 2 the requester's vehicle, 3 the ground <NUMBER>
 *
 * Return Value:
 * Phases of that step, [] when nothing is left for it - each [root, ops, step]: the step marks it as a
 * settlement phase (no reach, no guards; einv_storage_runPhase's 8th argument) <ARRAY>
 *
 * Example:
 * [_tx, _results, 1] call einv_storage_fnc_settle;
 *
 * Public: No
 */

params [["_tx", [], [[]]], ["_results", [], [[]]], ["_step", 1, [0]]];

_tx params ["", "", "", ["_where", [], [[]]], ["_phases", [], [[]]]];

private _fnc_isRef = {
    params ["_arg"];

    _arg isEqualType [] && {(_arg param [0, ""]) isEqualTo "#ref"}
};

// Ops that take out of a holder: what they produce goes back there.
private _sources = ["take", "move"];

{
    _sources pushBackUnique (_y getOrDefault ["take", ""]);
    _sources pushBackUnique (_y getOrDefault ["move", ""]);
} forEach GVAR(holderTypes);

_sources = _sources - [""];

// Every ref an op consumed: it landed, or it bounced - and what bounced was produced anew.
private _consumed = createHashMap;

{
    private _ops = (_phases param [_forEachIndex, []]) param [1, []];

    {
        if ((_x param [0, ""]) in ["", "Bounced"]) then {
            {
                if ([_x] call _fnc_isRef) then {
                    _consumed set [format ["%1|%2|%3", _x param [1, -1], _x param [2, -1], _x param [3, -1]], true];
                };
            } forEach ((_ops param [_forEachIndex, []]) param [1, []]);
        };
    } forEach _x;
} forEach _results;

// Where a payload came from: [holder, root] - the holder [unit, slot] when it came off a slot -, or []
// when it was carried in as it was.
private _fnc_origin = {
    params ["_p", "_o", "_n", ["_depth", 0]];

    private _phase = _phases param [_p, []];

    ((_phase param [1, []]) param [_o, []]) params [["_name", "", [""]], ["_args", [], [[]]]];

    if (_name in _sources) exitWith {[_args param [0, objNull], _phase param [0, objNull]]};
    if (_name isEqualTo "takeOff") exitWith {[[_args param [0, objNull], _args param [1, ""]], _phase param [0, objNull]]};

    // Only what bounced inherits an origin: that of what it was given. The old item of a putOn that
    // bounced came off a slot.
    if (
        (((_results param [_p, []]) param [_o, []]) param [0, ""]) isNotEqualTo "Bounced"
        || {_depth > 10}
        || {_name isEqualTo "putOn" && {_n == 0}}
    ) exitWith {[]};

    private _input = _args param [_args findIf {[_x] call _fnc_isRef}, []];

    if (_input isEqualTo []) exitWith {[]};

    [_input param [1, -1], _input param [2, -1], _input param [3, -1], _depth + 1] call _fnc_origin
};

// What is left: every payload produced and not consumed, by its ref.
private _left = [];

{
    private _p = _forEachIndex;

    {
        private _o = _forEachIndex;

        {
            if (_x isEqualType [] && {_x isNotEqualTo []} && {!((format ["%1|%2|%3", _p, _o, _forEachIndex]) in _consumed)}) then {
                _left pushBack ["#ref", _p, _o, _forEachIndex];
            };
        } forEach (_x param [1, []]);
    } forEach _x;
} forEach _results;

if (_left isEqualTo []) exitWith {[]};

private _phasesOut = [];

if (_step == 1) then {
    // Back where it came from - one phase per root, a put without a cell, first fit there.
    {
        private _ref = _x;
        private _origin = [_ref select 1, _ref select 2, _ref select 3] call _fnc_origin;

        if (_origin isNotEqualTo []) then {
            _origin params ["_holder", "_root"];

            private _op = [];

            switch (true) do {
                // Off a slot: back on, only into an empty slot - anything worn there now stays, and the
                // payload waits for the vehicle or the ground. Asked here, again where the unit is local
                // (op putOn: what it would take off is handed on, never lost).
                case (_holder isEqualType []): {
                    _holder params [["_unit", objNull, [objNull]], ["_slot", "", [""]]];

                    if (!isNull _unit && {_slot isNotEqualTo ""} && {count ([_unit, _slot] call FUNC(getSlot)) == 0}) then {
                        _op = ["putOn", [_unit, _slot, _ref]];
                    };
                };
                case (_holder isEqualType ""): {
                    private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];
                    private _put = _type getOrDefault ["put", ""];

                    if (_put isNotEqualTo "") then {
                        _op = [_put, [_holder, _ref, []]];
                    };
                };
                default {
                    _op = ["put", [_holder, _ref, [], false]];
                };
            };

            if (_op isNotEqualTo [] && {_root isEqualType objNull}) then {
                private _at = _phasesOut findIf {(_x select 0) isEqualTo _root};

                if (_at < 0) then {
                    _phasesOut pushBack [_root, [_op], 1];
                } else {
                    ((_phasesOut select _at) select 1) pushBack _op;
                };
            };
        };
    } forEach _left;
};

if (_step == 2) then {
    // The requester's vehicle: seated players never get anything put "on the ground" under them in the
    // air. Room is not asked - an overflow row is fine, the cargo commands take it.
    private _vehicle = _where param [2, objNull];

    if (_vehicle isEqualType objNull && {!isNull _vehicle} && {alive _vehicle}) then {
        _phasesOut pushBack [_vehicle, _left apply {["put", [_vehicle, _x, [], true]]}, 2];
    };
};

if (_step == 3) then {
    // The ground, at the server: that always lands (fnc_opPutGround).
    _phasesOut pushBack [objNull, _left apply {["putGround", [_x]]}, 3];
};

// A backpack among what is left: where this step sends it.
if (DROP_DEBUG) then {
    private _bags = _left select {
        (((((_results param [_x select 1, []]) param [_x select 2, []]) param [1, []]) param [_x select 3, []]) param [0, ""]) isEqualTo "backpack"
    };

    if (_bags isNotEqualTo []) then {
        diag_log text format [
            "einv drop: %1 settle step %2 - backpacks left %3, phases %4",
            _tx param [0, ""], _step, _bags, _phasesOut apply {[_x select 0, (_x select 1) apply {_x select 0}]}
        ];
    };
};

_phasesOut
