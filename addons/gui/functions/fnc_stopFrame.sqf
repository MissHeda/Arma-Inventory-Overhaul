#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ends whichever driver runs the window's frame (fnc_startFrame). Called by fnc_onUnload, and by
 * fnc_onFrame itself once its display is gone without the unload handler having run.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_stopFrame;
 *
 * Public: No
 */

GVAR(frameDriver) params [["_driver", "", [""]], ["_id", -1, [0]]];

// Cleared first: removing a handler from inside itself must not start it twice.
GVAR(frameDriver) = ["", -1];

if (_id < 0) exitWith {};

switch (_driver) do {
    case "pfh": {[_id] call CBA_fnc_removePerFrameHandler};
    case "draw3d": {removeMissionEventHandler ["Draw3D", _id]};
    default {};
};
