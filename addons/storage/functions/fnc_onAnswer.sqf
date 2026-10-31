#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The answer to a request of this machine (event einv_storage_answer, or the local path of
 * fnc_requestNext): the request is forgotten (GVAR(requests)) and its callback called with [id, summary,
 * revisions, callback args]. An answer to a request this machine does not know does nothing.
 *
 * Arguments:
 * 0: Request id <STRING>
 * 1: Summary <ARRAY>
 *    0: per phase of the request, in order, per op [status, extra] - the payloads they produced stay
 *       with whoever drove the transaction
 *    1: what settlement did with what was left, [went back, into the requester's vehicle, onto the
 *       ground] - how many payloads
 *    2: the ground pile something was put on, objNull for none
 * 2: Revisions - the places written, [[holder, revision], ...] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["2:14", _summary, _revisions] call einv_storage_fnc_onAnswer;
 *
 * Public: No
 */

params [["_id", "", [""]], ["_summary", [], [[]]], ["_revisions", [], [[]]]];

private _request = GVAR(requests) getOrDefault [_id, []];

// Answered already, or never asked here: a late copy, or one the clean-up gave up on (fnc_tick).
if (_request isEqualTo []) exitWith {};

GVAR(requests) deleteAt _id;

_request params ["", "", ["_callback", {}, [{}]], ["_callbackArgs", []]];

// Something may have moved from one container to another: where the magazines lie is noted again.
if (hasInterface) then {
    [] call FUNC(useTrack);
};

[_id, _summary, _revisions, _callbackArgs] call _callback;
