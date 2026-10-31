#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A phase the hub sent to this machine (event aio_storage_runPhase - on every machine, a headless
 * client holds its AI's gear): journaled as queued and run whole in its turn (GVAR(queue), fnc_tick),
 * its answer sent to the server (aio_storage_phaseDone). One seen before - the hub sent it again
 * because the answer was slow or lost - is answered from the journal and never run twice; one still
 * waiting in the queue is answered when it runs.
 *
 * Arguments:
 * 0: Request id <STRING>
 * 1: Phase index <NUMBER>
 * 2: Attempt <NUMBER>
 * 3: Root <OBJECT>
 * 4: Ops, [[op, args], ...] <ARRAY>
 * 5: Requester <OBJECT>
 * 6: Where, [groundASL, eyeASL, vehicle, positionASL] <ARRAY>
 * 7: Settlement - the system putting things back: no reach, no guards; a settlement step's number
 *    (fnc_settle, element 2 of its phases) counts as true <BOOL or NUMBER> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["2:14", 1, 0, cursorObject, _ops, player, _where] call aio_storage_fnc_runPhase;
 *
 * Public: No
 */

params [
    ["_id", "", [""]],
    ["_index", 0, [0]],
    ["_attempt", 0, [0]],
    ["_root", objNull, [objNull]],
    ["_ops", [], [[]]],
    ["_requester", objNull, [objNull]],
    ["_where", [], [[]]],
    ["_settlement", false, [false, 0]]
];

private _key = format ["%1|%2|%3", _id, _index, _attempt];
private _entry = GVAR(journal) getOrDefault [_key, []];

// Seen before. A phase that ran is answered from the journal and never runs twice; one still waiting in
// the queue answers when it runs.
if (_entry isNotEqualTo []) exitWith {
    if ((_entry select 0) isEqualTo "done") then {
        [QGVAR(phaseDone), [_id, _index, _attempt, _entry select 1, _entry select 2]] call CBA_fnc_serverEvent;
    };
};

GVAR(journal) set [_key, ["queued", [], [], diag_tickTime, []]];

// Whole, in arrival order, within a frame's budget (fnc_tick), which looks at the root's locality again
// when its turn comes. No done mark on the root: the answer leaves in the same frame and from the same
// sender as the cargo changes, and the server handles one machine's messages in order.
GVAR(queue) pushBack [_key, _root, _ops, createHashMapFromArray [
    ["requester", _requester],
    ["where", _where],
    ["txId", _id],
    ["root", _root],
    ["settlement", _settlement isEqualTo true || {_settlement isEqualType 0 && {_settlement > 0}}],
    ["phase", _index]
], {
    params ["_results", "_revisions", "_args"];
    _args params ["_id", "_index", "_attempt"];

    [QGVAR(phaseDone), [_id, _index, _attempt, _results, _revisions]] call CBA_fnc_serverEvent;
}, [_id, _index, _attempt]];
