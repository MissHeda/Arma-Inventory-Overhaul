#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The button of a caption line's activity chip (fnc_updateStatus), run a frame after the click:
 *   hands - cancels what of this box still waits in the hands' queue (fnc_cancelQueued with the box); what was sent
 *     already finishes on its own
 *   search - stops the search of this box, or - when it was stopped - lets it go on (GVAR(searchPaused)); the items
 *     already found stay found, the one being searched starts again from nothing when it is taken up again
 *
 * Arguments:
 * 0: The box's container <OBJECT>
 * 1: "hands" or "search" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate, "search"] call einv_gui_fnc_stopStatus;
 *
 * Public: No
 */

disableSerialization;

params [["_holder", objNull, [objNull]], ["_kind", "", [""]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display || {isNull _holder}) exitWith {};

if (_kind isEqualTo "hands") then {
    [0, _holder] call FUNC(cancelQueued);

    // The marks of the others and the chip: at once, not in the next frame.
    [_display, 0] call FUNC(drawQueue);
} else {
    if (_holder in GVAR(searchPaused)) then {
        GVAR(searchPaused) = GVAR(searchPaused) - [_holder];
    } else {
        GVAR(searchPaused) pushBackUnique _holder;
    };

    // The next box takes up the search at once, or none does.
    GVAR(searchStarted) = -1;
    GVAR(searchHead) = [];

    [_display] call FUNC(updateStatus);
};
