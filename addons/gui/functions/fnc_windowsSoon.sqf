#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the kit windows again for a click that opened or closed one (fnc_openWindow, fnc_closeWindow), at most once per rest
 * (fnc_coalesce, key "windows") whatever the number of clicks: every window is made anew by a draw, and a kit opened and closed
 * fast would make them all again for each click. The order of the windows is already changed by the caller; a build draws them
 * too (fnc_build) and so takes the waiting draw's place.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_gui_fnc_windowsSoon;
 *
 * Public: No
 */

["windows", {
    disableSerialization;

    private _display = uiNamespace getVariable [QGVAR(display), displayNull];

    if (isNull _display) exitWith {};

    [_display] call FUNC(drawWindows);

    // The marks of the hands' queue (fnc_queueMoves) on its tiles, which are new controls.
    if (GVAR(handQueue) isNotEqualTo []) then {
        [_display] call FUNC(drawQueue);
    };
}, [], COALESCE_GAP] call FUNC(coalesce);
