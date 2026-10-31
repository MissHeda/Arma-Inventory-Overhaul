#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The hands' queue, every frame while it holds something (fnc_onFrame): the first entry is the one the hands
 * are busy with. Once its time is up it is sent (fnc_runQueue) and the next one begins. The time the window stood
 * still under another window does not count, as the search's does not. Nothing is drawn per frame: what the box's
 * caption line says changes when an entry finishes (fnc_animateStatus reads it).
 *
 * Also where the marks are brought up to date after a change of the queue (GVAR(queueDirty), set when
 * entries were queued or cancelled): fnc_drawQueue runs here, once, however many entries changed in the frame.
 * Without that, a frame is a handful of reads - the same for any length of queue.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Now, diag_tickTime <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, diag_tickTime] call aio_gui_fnc_animateQueue;
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

if (GVAR(queueDirty)) then {
    [_display, GVAR(queueFrom)] call FUNC(drawQueue);
};

if (GVAR(handStarted) >= 0 && {_gap > QUEUE_PAUSE}) then {
    GVAR(handStarted) = GVAR(handStarted) + _gap;
};

if (GVAR(handStarted) < 0) then {
    GVAR(handStarted) = _now;
};

private _head = GVAR(handQueue) select 0;

if ((_now - GVAR(handStarted)) >= ((_head get "time") max 0.05)) then {
    [_display] call FUNC(runQueue);
};
