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

GVAR(hoverNote) = "";

[] call FUNC(onFrame);

private _took = (diag_tickTime - _from) * 1000;

private _moved = GVAR(hoverNote) isNotEqualTo "" && {GVAR(lastMouse) isNotEqualTo _before};

private _kind = if (GVAR(dragging) || {GVAR(band)}) then {
    "drag"
} else {
    [GVAR(hoverNote), "idle"] select !_moved
};

[_kind, _took] call FUNC(logFrame);
