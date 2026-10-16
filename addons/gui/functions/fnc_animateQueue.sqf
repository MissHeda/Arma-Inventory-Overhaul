#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The hands' queue, every frame while it holds something (fnc_onFrame): the first entry is the one the hands
 * are busy with. Its ring fills as its time runs - the same pictures as the search's ring, changed only when
 * the step changes, for all the circles of the queue in this one place - and once the time is up it is sent
 * (fnc_runQueue) and the next one begins. The time the window stood still under another window does not
 * count, as the search's does not.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Now, diag_tickTime <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, diag_tickTime] call einv_gui_fnc_animateQueue;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_now"];

private _gap = _now - GVAR(handLast);
GVAR(handLast) = _now;

if (GVAR(handQueue) isEqualTo []) exitWith {
    GVAR(handStarted) = -1;
};

if (GVAR(handStarted) >= 0 && {_gap > QUEUE_PAUSE}) then {
    GVAR(handStarted) = GVAR(handStarted) + _gap;
};

if (GVAR(handStarted) < 0) then {
    GVAR(handStarted) = _now;
};

private _head = GVAR(handQueue) select 0;
private _progress = ((_now - GVAR(handStarted)) / ((_head get "time") max 0.05)) min 1;

if (_progress >= 1) exitWith {
    [_display] call FUNC(runQueue);
};

private _arc = _head getOrDefault ["arc", controlNull];

if (isNull _arc) exitWith {};

private _step = ((ceil (_progress * SEARCH_FRAMES)) max 1) min SEARCH_FRAMES;

if (_step != (_head get "step")) then {
    _arc ctrlSetText SEARCH_RING(_step);
    _head set ["step", _step];
};
