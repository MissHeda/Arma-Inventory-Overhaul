#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The answer to one of the window's transactions (the callback fnc_sendMoves gives
 * einv_storage_fnc_request): kept (GVAR(answers)) until fnc_onFrame finishes it - once this machine
 * reads every revision it names (a holder gone null counts as read) or ANSWER_WAIT seconds after it
 * arrived - by handing it to fnc_afterAction: the in-flight entry gone, what moved learnt, the hint -
 * moved some, went back, put on the ground, put elsewhere, or why not -, the window built again.
 *
 * The next chunk of the same moves goes now (fnc_sendMoves): it was planned with this one's cells
 * taken. With the window closed meanwhile there is nothing to wait for: finished at once.
 *
 * Arguments:
 * 0: Request id <STRING>
 * 1: Summary (einv_storage_fnc_onAnswer) <ARRAY>
 * 2: Revisions, [[holder, revision], ...] <ARRAY>
 * 3: Args fnc_sendMoves gave along, [move records, options, moves of the next chunks] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["2:14", _summary, _revisions, [_records, _options, []]] call einv_gui_fnc_onAnswer;
 *
 * Public: No
 */

params [["_id", "", [""]], ["_summary", [], [[]]], ["_revisions", [], [[]]], ["_args", []]];

if !(_args isEqualType []) then {
    _args = [];
};

_args params [["_records", [], [[]]], ["_options", createHashMap, [createHashMap]], ["_rest", [], [[]]]];

if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) then {
    [_id, _summary, _revisions, _args] call FUNC(afterAction);
} else {
    GVAR(answers) pushBack [_id, _summary, _revisions, _args, diag_tickTime];
};

// After this answer is kept: in single player the next chunk is answered within this call, and its
// answer comes after this one's.
if (_rest isNotEqualTo []) then {
    [_rest, _options] call FUNC(sendMoves);
};
