#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Has every paged compartment's bar say what is true now (fnc_drawPageBar): how many entries of the hands' queue wait on
 * tiles of the pages not shown changes with every move that finishes and every one that is queued or cancelled. A bar
 * whose words did not change is left alone (fnc_drawPageBar compares), so this costs a count over the tiles of each paged
 * box and no control. Called at the end of fnc_drawQueue.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_gui_fnc_updatePageBars;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

{
    if ((_x getOrDefault ["pageRanges", []]) isNotEqualTo []) then {
        [_display, _x] call FUNC(drawPageBar);
    };
} forEach (uiNamespace getVariable [QGVAR(grids), []]);
