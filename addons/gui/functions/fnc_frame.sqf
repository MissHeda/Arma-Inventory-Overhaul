#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The frame of the window with its time taken, for "Log window timings (debug)" (einv_gui_debugTiming): fnc_startFrame
 * lets the driver call this instead of fnc_onFrame when the setting is on as the window opens. It runs
 * fnc_onFrame, and hands what the frame cost to fnc_logFrame under what the frame was: "idle" (the mouse
 * stood still), "held", "same" or "new" (the mouse moved, and the hover ended at once in the cell it was
 * in, found the same thing again, or found something new - fnc_updateHover) and "drag" (something is held
 * or a frame is dragged). That is the script's share of a frame; what the engine draws for the controls on
 * the display is not in it.
 *
 * Beside it, where the script's time goes (fnc_notePhase - the parts fnc_onFrame names: the hover, the drag,
 * searching, the hands' queue, the answers, the checks and the contents check with its redraws), and how
 * long the whole frame was (diag_deltaTime, the last frame the engine drew): the frame time the game shows as FPS,
 * against which the script's share says whether a low FPS is the script or the engine drawing the controls.
 *
 * Arguments:
 * None - it is called by the driver of the frame (fnc_startFrame)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_gui_fnc_frame;
 *
 * Public: No
 */

private _from = diag_tickTime;
private _before = GVAR(lastMouse);

// The whole frame the engine took last (diag_deltaTime: exact where diag_tickTime is coarse late in a long session) -
// from the window's second frame on, so nothing before it counts.
if (GVAR(frameLast) >= 0) then {
    private _whole = diag_deltaTime * 1000;
    private _record = GVAR(phaseTally) getOrDefault ["frame", [0, 0, 0]];

    _record set [0, (_record select 0) + _whole];
    _record set [1, (_record select 1) max _whole];
    _record set [2, (_record select 2) + 1];
    GVAR(phaseTally) set ["frame", _record];
};

GVAR(frameLast) = _from;
GVAR(hoverNote) = "";
GVAR(phase) = ["start", _from];

[] call FUNC(onFrame);

[""] call FUNC(notePhase);
GVAR(phase) = nil;

private _took = (diag_tickTime - _from) * 1000;

private _moved = GVAR(hoverNote) isNotEqualTo "" && {GVAR(lastMouse) isNotEqualTo _before};

private _kind = if (GVAR(dragging)) then {
    "drag"
} else {
    [GVAR(hoverNote), "idle"] select !_moved
};

[_kind, _took] call FUNC(logFrame);
