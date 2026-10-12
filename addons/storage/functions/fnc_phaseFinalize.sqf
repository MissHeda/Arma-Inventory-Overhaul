#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Answers a phase the frame after it started (armed by fnc_execute). One still "running" was stopped by
 * a script error: its finished ops keep their results, the op that was running answers "Failed" with
 * what it took out and did not land as produced - its notes in the journal, and what a take of a whole
 * class took out for the takes still to come (fnc_opTake) - so settlement puts it back; every later op
 * "Failed". The execution's state is reset, the phase marked done, its continuation called - the
 * transaction goes on -, then every holder it touched normalised, and an RPT error names the phase and
 * the op.
 *
 * A phase that finished: nothing.
 *
 * Arguments:
 * 0: Journal key, "id|phase|attempt" <STRING>
 * 1: Ops of the phase <ARRAY> (default: [])
 * 2: Context it ran with (fnc_execute) <HASHMAP> (default: empty)
 * 3: Continuation, given [results, revisions, continuation args] <CODE> (default: {})
 * 4: Continuation args <ANY> (default: [])
 * 5: Holders it touched so far <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["2:14|0|0"] call einv_storage_fnc_phaseFinalize;
 *
 * Public: No
 */

params [
    ["_key", "", [""]],
    ["_ops", [], [[]]],
    ["_context", createHashMap, [createHashMap]],
    ["_continuation", {}, [{}]],
    ["_continuationArgs", []],
    ["_touched", [], [[]]]
];

private _journal = GVAR(journal) getOrDefault [_key, []];

if ((_journal param [0, ""]) isNotEqualTo "running") exitWith {};

_journal params ["", "_results", "", "", "_notes"];

private _running = count _results;

if (_running < count _ops) then {
    private _name = (_ops select _running) param [0, ""];

    ERROR_2("Phase %1 was stopped by a script error in op %2 - answered from the journal, what it took out is put back.",_key,_name);

    // What the op that was running took out and did not land.
    private _produced = (_notes select {(_x select 0) == _running && {!(_x select 2)}}) apply {+(_x select 1)};

    // What a take of a whole class took out for the takes after it - theirs, and not handed on yet.
    {
        if (_x >= _running) then {
            _produced append (((_y param [1, []]) select {_x isEqualType [] && {_x isNotEqualTo []}}) apply {+_x});
        };
    } forEach (_context getOrDefault ["batch", createHashMap]);

    _results pushBack ["Failed", _produced, []];

    for "_i" from (_running + 1) to (count _ops - 1) do {
        _results pushBack ["Failed", [], []];
    };
} else {
    ERROR_1("Phase %1 was stopped by a script error after its ops - answered from the journal.",_key);
};

// Nothing of the stopped phase may leak into the next one.
GVAR(executing) = false;
GVAR(buffer) = [];
GVAR(cache) = createHashMap;
GVAR(journalKey) = "";

_journal set [0, "done"];
_journal set [3, diag_tickTime];

// The transaction goes on first: should the error strike again below, nothing taken stays in limbo.
[_results, [], _continuationArgs] call _continuation;

// What the error left half done is persisted as it lies.
{
    if (_x isEqualType "" || {!isNull _x}) then {
        [_x] call FUNC(normalize);
    };
} forEach _touched;
