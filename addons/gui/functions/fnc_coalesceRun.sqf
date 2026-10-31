#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Runs what fnc_coalesce kept for a key, and sets how long the key rests afterwards: the gap, or COALESCE_REST times the
 * time the run took when that is longer.
 *
 * Arguments:
 * 0: The key <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["build"] call aio_gui_fnc_coalesceRun;
 *
 * Public: No
 */

params [["_key", "", [""]]];

private _state = GVAR(coalesced) getOrDefault [_key, []];

if (_state isEqualTo []) exitWith {};

_state params ["_code", "_args", "", "", "_gap"];

// Nothing waits any more. Should the code ask for the same key again, it rests (provisionally the gap) and waits.
private _start = diag_tickTime;

_state set [2, -1];
_state set [3, _start + _gap];

_args call _code;

private _end = diag_tickTime;

_state set [3, _end + (_gap max ((_end - _start) * COALESCE_REST))];
