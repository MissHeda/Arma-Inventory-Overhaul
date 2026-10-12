#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Runs code on the next frame - for what a click does that rebuilds the window, which deletes the very
 * control that was clicked and must not happen inside its own event. In a mission it is CBA's next
 * frame; in Eden, where CBA's per-frame handler does not run, a script run unscheduled
 * (einv_storage_fnc_nextFrame).
 *
 * Arguments:
 * 0: Code <CODE>
 * 1: Arguments for it <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [{systemChat str _this}, [1, 2]] call einv_gui_fnc_later;
 *
 * Public: No
 */

_this call EFUNC(storage,nextFrame)
