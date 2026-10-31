#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Runs code after a number of seconds. In a mission that is CBA's wait (a per-frame handler); in the Eden
 * editor, where ACE Arsenal's panel runs and CBA's per-frame handlers do not, a script that sleeps on the
 * interface's clock and then runs the code unscheduled. For the sounds' delayed layers and cut pieces
 * (fnc_playLayer).
 *
 * Arguments:
 * 0: Code, given the arguments <CODE>
 * 1: Arguments <ANY> (default: [])
 * 2: Seconds <NUMBER> (default: 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [{hint str _this}, "later", 2] call aio_gui_fnc_delay;
 *
 * Public: No
 */

params [["_code", {}, [{}]], ["_args", []], ["_seconds", 0, [0]]];

if (is3DEN) exitWith {
    [_code, _args, _seconds] spawn {
        params ["_code", "_args", "_seconds"];

        uiSleep _seconds;

        isNil {
            _args call _code
        };
    };
};

[_code, _args, _seconds] call CBA_fnc_waitAndExecute;
