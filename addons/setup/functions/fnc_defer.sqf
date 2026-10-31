#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Runs code a moment later, outside the event that asks for it. A button that redraws the wizard deletes
 * itself, which must not happen inside its own click - so every widget of the wizard hands its code over
 * through here.
 *
 * Not through CBA: its frame handlers and CBA_fnc_execNextFrame start in postInit, which Eden never
 * reaches - in Eden, and in CBA's menu opened there, they would never run. So the wizard keeps a queue of
 * its own and empties it two ways, whichever comes first: its display's mouse events, which fire every
 * frame while the mouse moves or rests on it (fnc_onMouse - CBA's own export window relies on the same),
 * and the scheduler, which runs everywhere.
 *
 * Arguments:
 * 0: Code, called with the arguments as _this <CODE>
 * 1: Arguments <ANY> (default: [])
 * 2: Not before this many seconds have passed <NUMBER> (default: 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [{systemChat str _this}, [1, 2]] call aio_setup_fnc_defer;
 *
 * Public: No
 */

params [["_code", {}, [{}]], ["_arguments", []], ["_delay", 0, [0]]];

private _queue = uiNamespace getVariable [QGVAR(deferred), []];
_queue pushBack [_code, _arguments, diag_tickTime + _delay];
uiNamespace setVariable [QGVAR(deferred), _queue];

// isNil runs it unscheduled, the way an event would, so nothing in it can be cut in half by the
// scheduler.
[_delay] spawn {
    params ["_delay"];

    if (_delay > 0) then {
        uiSleep _delay;
    };

    isNil {
        call (uiNamespace getVariable [QFUNC(runDeferred), {}]);
    };
};
