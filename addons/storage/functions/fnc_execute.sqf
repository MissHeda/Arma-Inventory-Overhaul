#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Runs the ops of one phase on this machine - the root's authority -, journaled (GVAR(journal)). Each
 * op's checks first: every holder it names under the phase's root (fnc_verifyChain, else "Moved"; the
 * unit of takeOff, putOn and migrate is the root itself, the holders of migrate its three containers),
 * the requester's reach (fnc_inReach, else "OutOfReach") and every guard (GVAR(guards)) - reach and
 * guards not for settlement -; then its function (GVAR(ops)). An input an earlier op of this phase
 * produced is filled in here; any other ref still in the args was never produced, and the op says
 * "Skipped". Every payload that leaves a container is noted the moment it left, and marked consumed
 * the moment it landed (fnc_journalNote).
 *
 * Every holder the ops touched - named, or with places changed - is laid out against the buffered
 * records and written once (fnc_writePlaces); then the continuation gets [results, revisions,
 * continuation args]. A script error inside stops the phase: armed through fnc_nextFrame before the
 * first op, fnc_phaseFinalize answers it from the journal the next frame - nothing taken stays in limbo.
 *
 * The context the ops get carries, besides what the driver put in, "phase" (the phase's index), "ops",
 * "opIndex" and "batch" (what a take of a whole class took out for the takes after it, fnc_opTake).
 * Ops never ask for a transaction of their own: that would start another phase inside this one.
 *
 * Arguments:
 * 0: Ops, [[op, args], ...] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement", optionally "phase" (else read from
 *    the key) <HASHMAP>
 * 2: Journal key, "id|phase|attempt" <STRING>
 * 3: Continuation, given [results, revisions, continuation args] <CODE>
 * 4: Continuation args <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_ops, _context, "2:14|0|0", {}, []] call einv_storage_fnc_execute;
 *
 * Public: No
 */

params [
    ["_ops", [], [[]]],
    ["_context", createHashMap, [createHashMap]],
    ["_key", "", [""]],
    ["_continuation", {}, [{}]],
    ["_continuationArgs", []]
];

// Whatever a phase before left behind - one a script error stopped - is not this one's.
GVAR(executing) = false;
GVAR(buffer) = [];
GVAR(cache) = createHashMap;

private _results = [];
private _touched = [];
private _journal = ["running", _results, [], diag_tickTime, []];

GVAR(journal) set [_key, _journal];
GVAR(journalKey) = _key;

private _root = _context getOrDefault ["root", objNull];
private _requester = _context getOrDefault ["requester", objNull];
private _settlement = _context getOrDefault ["settlement", false];
private _phase = _context getOrDefault ["phase", parseNumber ((_key splitString "|") param [1, "-1"])];
private _batch = createHashMap;

// A settlement step's number counts as the flag.
if !(_settlement isEqualType true) then {
    _settlement = _settlement isEqualType 0 && {_settlement > 0};
};

_context set ["settlement", _settlement];
_context set ["phase", _phase];
_context set ["ops", _ops];
_context set ["batch", _batch];

// Armed before the first op: should a script error stop the phase, it is answered from the journal the
// next frame - SQF cannot catch the engine's errors.
[{_this call FUNC(phaseFinalize)}, [_key, _ops, _context, _continuation, _continuationArgs, _touched]] call FUNC(nextFrame);

// One requester, one root: reach is one question per phase. The system putting things back does not ask.
private _inReach = _settlement || {[_requester, _root] call FUNC(inReach)};

private _fnc_isRef = {
    params ["_arg"];

    _arg isEqualType [] && {(_arg param [0, ""]) isEqualTo "#ref"}
};

GVAR(executing) = true;

{
    _x params [["_name", "", [""]], ["_args", [], [[]]]];

    private _opIndex = _forEachIndex;
    private _skipped = false;
    private _holders = [];

    // Inputs an earlier op of this phase produced, copied. A ref still left was never produced - the
    // driver fills in those of earlier phases - and so is one to nothing (the old item of a putOn that
    // took nothing off).
    _args = _args apply {
        private _arg = _x;

        if ([_arg] call _fnc_isRef) then {
            _arg params ["", ["_p", -1, [0]], ["_o", -1, [0]], ["_n", -1, [0]]];

            private _payload = [];

            if (_p == _phase && {_o >= 0} && {_o < _opIndex}) then {
                _payload = ((_results select _o) param [1, []]) param [_n, []];
            };

            if (_payload isEqualType [] && {_payload isNotEqualTo []}) then {
                +_payload
            } else {
                _skipped = true;
                _arg
            };
        } else {
            _arg
        };
    };

    _context set ["opIndex", _opIndex];

    private _result = call {
        if (_skipped) exitWith {["Skipped", [], []]};

        private _function = GVAR(ops) getOrDefault [_name, ""];

        _function = if (_function isEqualTo "") then {nil} else {missionNamespace getVariable _function};

        if (isNil "_function") exitWith {
            ERROR_2("Op %1 of phase %2 is not known here - it did nothing.",_name,_key);
            ["Failed", [], []]
        };

        // Every holder it names has to lie under the phase's root - walked through the real cargo here,
        // whatever the requester thought.
        private _units = [];

        switch (_name) do {
            case "takeOff";
            case "putOn": {
                _units pushBack (_args param [0, objNull]);
            };
            case "putGround": {};
            case "migrate";
            case "strict": {
                // The unit is the root; the containers it moves cargo between are the holders it touches.
                private _unit = _args param [0, objNull];

                _units pushBack _unit;

                if (!isNull _unit) then {
                    _holders append ([uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x});
                };
            };
            case "move": {
                _holders append [_args param [0, objNull], _args param [1, objNull]];
            };
            case "repack": {
                // Its parts are [container, class, before, after, cell]: every container among them.
                {
                    if (_x isEqualType []) then {
                        _holders pushBack (_x param [0, objNull]);
                    };
                } forEach (_args param [0, []]);
            };
            case "put": {
                // A put into something gone bounces (fnc_opPut) - nothing to walk.
                private _to = _args param [0, objNull];

                if (_to isEqualType "" || {!isNull _to}) then {
                    _holders pushBack _to;
                };
            };
            case "place";
            case "placeMany";
            case "split";
            case "sort";
            case "normalize";
            case "take": {
                _holders pushBack (_args param [0, objNull]);
            };
            default {
                // Another addon's op (GVAR(ops)): the holders it names - its keys of a holder type, and
                // the containers among its arguments.
                {
                    if (
                        (_x isEqualType "" && {":" in _x} && {((_x splitString ":") param [0, ""]) in GVAR(holderTypes)})
                        || {_x isEqualType objNull && {!isNull _x} && {!(_x isKindOf "CAManBase")}}
                    ) then {
                        _holders pushBack _x;
                    };
                } forEach _args;
            };
        };

        if (_holders findIf {!([_x, _root] call FUNC(verifyChain))} >= 0) exitWith {["Moved", [], []]};

        // Laid out and written at the end - only what lies under this root: this machine is its
        // authority.
        {
            _touched pushBackUnique _x;
        } forEach _holders;
        if (_units findIf {isNull _x || {_x isNotEqualTo _root}} >= 0) exitWith {["Moved", [], []]};
        if (!_inReach) exitWith {["OutOfReach", [], []]};

        // The first guard with a reason refuses it (a living person's rules, later the locks).
        private _refusal = "";

        if (!_settlement) then {
            {
                private _said = [_name, _args, _requester, _root] call _x;

                if (!isNil "_said" && {_said isEqualType ""} && {_said isNotEqualTo ""}) exitWith {
                    _refusal = _said;
                };
            } forEach GVAR(guards);
        };

        if (_refusal isNotEqualTo "") exitWith {[_refusal, [], []]};

        [_args, _context] call _function
    };

    // An op that answered nothing may still have taken something out before it broke off: what the
    // journal says left in it and did not land is handed on, so it settles back instead of being lost.
    if (isNil "_result" || {!(_result isEqualType [])}) then {
        ERROR_2("Op %1 of phase %2 answered nothing - counted as failed.",_name,_key);
        _result = ["Failed", ((_journal select 4) select {(_x select 0) == _opIndex && {!(_x select 2)}}) apply {+(_x select 1)}, []];
    };

    _result params [["_status", "Failed", [""]], ["_produced", [], [[]]], ["_extra", []]];

    // A take refused here after a take before it in this phase took its item out along with the rest of
    // its class (fnc_opTake): that item is handed on all the same, and settles back.
    private _stash = _batch getOrDefault [_opIndex, []];

    if (_stash isNotEqualTo []) then {
        _batch deleteAt _opIndex;
        _produced = _produced + ((_stash param [1, []]) select {_x isEqualType [] && {_x isNotEqualTo []}});
    };

    // Copied: the journal and the hub keep these arrays, and a later op may change what it got.
    _results pushBack [_status, _produced apply {if (_x isEqualType []) then {+_x} else {_x}}, _extra];

    // A pile it chose itself (putGround) is touched as well.
    if (_status isEqualTo "" && {_extra isEqualType []}) then {
        {
            if (_x isEqualType objNull && {!isNull _x} && {!(_x isKindOf "CAManBase")}) then {
                _touched pushBackUnique _x;
            };
        } forEach _extra;
    };

    // What another addon's op did to a holder this execution does not follow: laid out anew when asked.
    if !(_name in ["place", "placeMany", "split", "normalize", "move", "take", "put", "putGround", "takeOff", "putOn"]) then {
        {
            GVAR(cache) deleteAt (if (_x isEqualType "") then {_x} else {netId _x});
        } forEach (_holders select {_x isEqualType "" || {!isNull _x}});
    };
} forEach _ops;

// Every holder whose places an op changed is touched too.
{
    private _holder = _x param [0, objNull];

    if (_holder isEqualType "" || {!isNull _holder}) then {
        _touched pushBackUnique _holder;
    };
} forEach GVAR(buffer);

// Of what can be laid out: an object still there, or a key of a known holder type.
_touched = _touched select {
    if (_x isEqualType "") then {
        ((_x splitString ":") param [0, ""]) in GVAR(holderTypes)
    } else {
        !isNull _x
    }
};

// The uniforms, vests and backpacks lying in them get their ids first, as in every normalise
// (fnc_tagNested): the records are keyed by them.
GVAR(executing) = false;

{
    if (_x isEqualType objNull) then {
        [_x] call FUNC(tagNested);
    };
} forEach _touched;

// Each laid out against what the ops changed (the buffer), so the records cover everything it holds -
// pure, the same picture every machine draws from the same data.
GVAR(executing) = true;

private _final = _touched apply {
    private _holder = _x;
    private _entries = if (_holder isEqualType "") then {
        private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];

        [_holder] call (_type getOrDefault ["entries", {[]}])
    } else {
        [_holder] call FUNC(getContents)
    };

    if (isNil "_entries" || {!(_entries isEqualType [])}) then {
        _entries = [];
    };

    private _records = ([_holder] call FUNC(readPlaces)) param [1, []];

    [_holder, ([_holder, _entries, false, _records] call FUNC(getLayout)) getOrDefault ["records", _records]]
};

// Written once each, as the authority, outside the buffer.
GVAR(executing) = false;
GVAR(buffer) = [];
GVAR(cache) = createHashMap;

private _revisions = [];

{
    _x params ["_holder", "_records"];

    private _revision = [_holder, _records] call FUNC(writePlaces);

    if (!isNil "_revision" && {_revision isEqualType 0} && {_revision >= 0}) then {
        _revisions pushBack [_holder, _revision];
    };
} forEach _final;

// A scripted ground pile (fnc_getGroundHolder) that this phase emptied is ours to delete: the engine leaves
// those alone. A frame later and looked at again then, so the answer and the window's rebuild are done with
// it first.
{
    if (_x isEqualType objNull) then {
        [_x] call FUNC(pruneScriptedPile);
    };
} forEach _touched;

// A looter's move in this player's own gear: their window waits for these places - out at once, not
// within OWN_WRITE_DELAY.
if (!isNull _root && {_root isEqualTo player} && {_requester isNotEqualTo player}) then {
    call FUNC(flushPlaces);
};

_journal set [0, "done"];
_journal set [2, _revisions];
_journal set [3, diag_tickTime];
GVAR(journalKey) = "";

[_results, _revisions, _continuationArgs] call _continuation;
