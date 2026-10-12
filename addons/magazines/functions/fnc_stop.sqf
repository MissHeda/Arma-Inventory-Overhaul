#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ends the repack, however it ended, and writes the state reached at the last finished step of ACE's
 * schedule (fnc_commit) - rounds already moved stay moved, as when ACE's own repack is interrupted. Nothing
 * moved yet: nothing is written, and the hint says so.
 *
 *   "Done"        - after the last step; the schedule's final state
 *   "Stopped"     - a mouse press or Escape in the window
 *   "Interrupted" - ACE's conditions failed, another window lies over this one, a magazine's tile is gone
 *   "Closed"      - the window closed (einv_gui_fnc_onUnload); the result is told the way ACE tells it
 *
 * The job is idle again before anything else happens: what follows builds the window, which must not
 * draw this job a second time.
 *
 * Arguments:
 * 0: Why - "Done", "Stopped", "Interrupted" or "Closed" <STRING> (default: "Stopped")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Stopped"] call einv_magazines_fnc_stop;
 *
 * Public: No
 */

params [["_why", "Stopped", [""]]];

private _job = GVAR(job);

if (count _job == 0) exitWith {};

// Idle first: what follows builds the window, which must not draw this job again.
GVAR(job) = createHashMap;

private _counts = if (_why isEqualTo "Done") then {
    ((_job get "events") select -1) select 2
} else {
    _job get "counts"
};

if (_counts isEqualTo (_job get "startCounts")) exitWith {
    ["Nothing", createHashMapFromArray [
        ["class", _job get "class"], ["capacity", _job get "capacity"], ["picture", _job get "picture"],
        ["why", _why], ["counts", _counts], ["parts", []]
    ]] call FUNC(finish);
};

[_job, _counts, _why] call FUNC(commit);
