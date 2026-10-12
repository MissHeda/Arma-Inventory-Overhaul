#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a repack is running in the window (fnc_begin, fnc_stop). The window keeps its hands off
 * everything else meanwhile (einv_gui_fnc_onFrame, fnc_onMouseButton, fnc_onKeyDown).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A repack runs <BOOL>
 *
 * Example:
 * call einv_magazines_fnc_isBusy;
 *
 * Public: No
 */

count GVAR(job) > 0
