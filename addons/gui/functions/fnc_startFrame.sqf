#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Starts what calls fnc_onFrame every frame while the window is open, and remembers it in
 * GVAR(frameDriver) so fnc_stopFrame can end exactly it. Two drivers:
 *
 *   "pfh"    - a CBA per-frame handler, the inventory's own
 *   "draw3d" - a Draw3D mission event handler, which also runs in the Eden editor, where CBA's per-frame
 *              handlers do not
 *
 * Only one runs at a time: a driver still running is ended first. With "Log window timings (debug)"
 * (aio_gui_debugTiming) on as the window opens, the frame goes through fnc_frame, which times it.
 *
 * Arguments:
 * 0: Driver - "pfh" or "draw3d" <STRING> (default: "pfh")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["draw3d"] call aio_gui_fnc_startFrame;
 *
 * Public: No
 */

params [["_driver", "pfh", [""]]];

call FUNC(stopFrame);

// The timed frame only while the player asked for the numbers: it costs a few commands of its own.
private _timed = missionNamespace getVariable [QGVAR(debugTiming), false];

// The whole frame is counted from this window's first frame on, not from the last window's last one.
GVAR(frameLast) = -1;
GVAR(phaseTally) = createHashMap;
GVAR(phase) = nil;

if (_driver isEqualTo "draw3d") then {
    GVAR(frameDriver) = ["draw3d", addMissionEventHandler ["Draw3D", [{call FUNC(onFrame)}, {[] call FUNC(frame)}] select _timed]];
} else {
    GVAR(frameDriver) = ["pfh", [[FUNC(onFrame), FUNC(frame)] select _timed, 0, []] call CBA_fnc_addPerFrameHandler];
};
