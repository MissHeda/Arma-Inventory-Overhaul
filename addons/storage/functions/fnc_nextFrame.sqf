#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Runs code a frame later, in a mission and in Eden alike: CBA_fnc_execNextFrame in a mission; spawned
 * and run unscheduled in Eden, which runs no CBA per-frame handler.
 *
 * Arguments:
 * 0: Code, given the args <CODE>
 * 1: Args <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [{systemChat str _this}, [1, 2]] call aio_storage_fnc_nextFrame;
 *
 * Public: No
 */

params [["_code", {}, [{}]], ["_args", []]];

// CBA's next frame never comes in Eden - its per-frame handler does not run there. A spawned script
// does run, a frame later at the earliest, and isNil runs the code unscheduled as CBA would.
if (is3DEN) exitWith {
    [_code, _args] spawn {
        params ["_code", "_args"];

        isNil {_args call _code};
    };
};

[_code, _args] call CBA_fnc_execNextFrame;
